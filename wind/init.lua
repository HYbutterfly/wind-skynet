local skynet = require "skynet"
local service = require "skynet.service"
local ltdiff = require "ltdiff"

local state_mgr
local state_map = {}
local state_version = {}
local request = {}			-- thread : {session, source, fork:{}, timeout:{}}


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

local ERR_RETRY <const> = {}

function wind.query(...)
	local req = request[coroutine.running()]
	local names = {...}
	local addrs = skynet.call(state_mgr, "lua", "lock", req.id, names)
	assert(addrs, ERR_RETRY)
	local results = {}

	for i,addr in ipairs(addrs) do
		local name = names[i]
		local version, state, patches = skynet.call(addr, "lua", "query", state_version[name])
		local old = update_state(name, version, state, patches)
		local new = table.clone(old)

		table.insert(req.locked, {name = name, old = old, new = new})
		results[i] = new
	end

	return table.unpack(results)
end


function wind.fork(f, ...)
	local req = request[coroutine.running()]
	if req then
		req.forks = req.forks or {}
		table.insert(req.forks, f, {...}) 
	else
		return skynet.fork(f, ...)
	end
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


function wind.dispatch(msg_type, f)
	skynet.dispatch(msg_type, function (session, source, ...)
		local req = {id = string.format("%04x@%04x", source, session)}
		request[coroutine.running()] = req

		::retry::
		req.locked = {}
		req.forks = {}
		
		local ok, err = pcall(f, session, source, ...)
		if ok then
			unlock(req)
			if req.forks then
				for i=1,#req.forks,2 do
					skynet.fork(req.forks[i], req.forks[i+1])
				end
			end
		else
			if err == ERR_RETRY then
				skynet.error("will retry", ...)
				goto retry
			else
				skynet.error("worker dispatch error:", err, ...)
			end
		end
	end)
end


skynet.init(function ()
	state_mgr = skynet.uniqueservice "state-mgr"
end)


return wind