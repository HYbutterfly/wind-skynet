local skynet = require "skynet"
local service = require "skynet.service"
local ltdiff = require "ltdiff"

local state_mgr
local state_map = {}
local state_version = {}
local request = {}			-- thread : {session, source, fork:{}, timeout:{}}

local skynet_dispatch = skynet.dispatch
local skynet_fork = skynet.fork
local skynet_timeout = skynet.timeout


local function update_state(name, version, state, patches)
	if version == state_version[name] then
		return state_map[name]
	else
		state_version[name] = version
		
		if state then
			state_map[name] = state
		else
			local s = assert(state_map[name])
			for _,diff in ipairs(patches) do
				s = ltdiff.patch(s, diff)
			end
			state_map[name] = s
		end
		return state_map[name]		
	end
end


local wind = {}


function wind.new(name, t)
	assert(type(name) == "string")
	assert(type(t) == "table")
	skynet.call(state_mgr, "lua", "newstate", name, t)
end


function wind.release(name)
	return skynet.call(state_mgr, "lua", "releasestate", name)
end



function wind.slice(name)
	return skynet.call(state_mgr, "lua", "slice", name)
end

local ERR_ROLLBACK <const> = {}

local function find_in_locked(req, name)
	for _,item in ipairs(req.locked) do
		if item.name == name then
			return item.new
		end
	end
end

function wind.query(...)
	local req = request[coroutine.running()]
	local names = {...}
	local addrs = skynet.call(state_mgr, "lua", "lock", req.id, names)
	assert(addrs, ERR_ROLLBACK)
	local results = {}

	for i,addr in ipairs(addrs) do
		local name = names[i]
		local new = find_in_locked(req, name)
		if not new then
			local version, state, patches = skynet.call(addr, "lua", "query", state_version[name])
			local old = update_state(name, version, state, patches)
			new = table.copy(old)
			table.insert(req.locked, {name = name, old = old, new = new})
		end
		results[i] = new
	end

	return table.unpack(results)
end


local function unlock(req)
	local patch_map = {}

	for _,item in ipairs(req.locked) do
		local name = item.name
		local old = item.old
		local new = item.new		
		local diff = ltdiff.diff(old, new) or false

		patch_map[name] = diff
		if diff then
			state_version[name] = state_version[name] + 1
			state_map[name] = new
		end
	end
	if next(patch_map) then
		skynet.send(state_mgr, "lua", "unlock", req.id, patch_map)
	end
end

local function hook(f)
	return function (...)
		local req = {id = string.format("%x@%s", skynet.self(), tostring(coroutine.running()))}
		request[coroutine.running()] = req
		local count = 0

		::rollback::
		req.locked = {}
		req.forks = {}
		req.timeouts = {}

		local ok, err = pcall(f, ...)
		if ok then
			unlock(req)
			for i=1,#req.forks,2 do
				skynet_fork(hook(req.forks[i]), table.unpack(req.forks[i+1]))
			end
			for i=1,#req.timeouts,2 do
				skynet_timeout(req.timeouts[i], hook(req.timeouts[i+1]))
			end
		else
			if err == ERR_ROLLBACK then
				count = count + 1
				skynet.sleep(count)
				if count%5 == 0 then
					skynet.error(string.format("WARNING: thread[%s] rollback %d times", tostring(coroutine.running()), count), ...)
				end 
				goto rollback
			else
				skynet.error("worker running error:", err, ...)
				unlock(req)
			end
		end
	end
end

function skynet.timeout(time, f)
	local req = request[coroutine.running()]
	if req then
		table.insert(req.timeouts, time)
		table.insert(req.timeouts, f)
	else
		return skynet_timeout(time, hook(f))
	end
end

function skynet.fork(f, ...)
	local req = request[coroutine.running()]
	if req then
		table.insert(req.forks, f)
		table.insert(req.forks, {...}) 
	else
		return skynet_fork(hook(f), ...)
	end
end

function skynet.dispatch(msg_type, f)
	skynet_dispatch(msg_type, hook(f))
end


skynet.init(function ()
	state_mgr = skynet.uniqueservice "state-mgr"
end)


return wind