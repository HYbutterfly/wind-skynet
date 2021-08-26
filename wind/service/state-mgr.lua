local skynet = require "skynet"

local state = {}
local locked = {}
local waitting = {}
local request = {}		-- id: {time:123, locked:{name1, ...}, waiting:{name1, ...}}

local function try_lock(req, names)
	for _,name in ipairs(names) do
		if not state[name] or locked[name] then
			return false
		end
	end
	for _,name in ipairs(names) do
		table.insert(req.locked, name)
		locked[name] = req
	end
	return true
end


local function querystates(names)
	local list = {}
	for i,name in ipairs(names) do
		list[i] = state[name]
	end
	return list
end


local function try_wakup()
	local index = 1
	local done, token

	while true do
		done = true
		for i=index,#waitting do
			token = waitting[i]
			index = i
			if try_lock(token.req, token.names) then
				table.remove(waitting, i)
				skynet.wakeup(token)
				done = false
				break
			end
		end
		if done then
			break
		end
	end
end


---------------------------------------------------------------------------
local S = {}


function S.newstate(name, t, code)
	assert(type(t) == "table")
	assert(not state[name], string.format("state[%s] already exists", name))

	state[name] = skynet.newservice("state-cell", name)
	skynet.call(state[name], "lua", "init", t, code)
	locked[name] = false
	try_wakup()
end


function S.releasestate(name)
	if locked[name] then
		return false
	end

	local addr = state[name]
	if addr then
		state[name] = nil
		skynet.send(addr, "lua", "exit")
	end
	return true
end


function S.slice(name)
	local addr = state[name]
	if addr then
		return skynet.call(addr, "lua", "slice", name)
	end
end


local function join_waitting(req, names)
	for _,name in ipairs(names) do
		table.insert(req.waitting, name)
	end

	local token = {req = req, names = names}
	waitting[#waitting + 1] = token
	skynet.wait(token)

	if token.rollback then
		return false
	end

	assert(req.waitting[#req.waitting] == names[#names])
	for i=1,#names do
		req.waitting[#req.waitting] = nil
	end
	return querystates(names)
end


local function intersect(t1, t2)
	if #t2 == 0 then
		return false
	end

	for i,v in ipairs(t2) do
		if table.find_one(t1, v) then
			return true
		end
	end
	return false
end


--[[
	t1: {s1}, {s2}		-- s2 被 t2 锁定
	t2: {s2}, {s3}		-- s3 被 t3 锁定 
	t3: {s3}, {s1}		-- s1 被 t1 锁定
]]
local function deadlock(me, query)
	local function _deadlock(other)
		if intersect(me.locked, other.waitting) then
			return true
		else
			for _,name in ipairs(other.waitting) do
				local other2 = locked[name]
				if other2 and _deadlock(other2) then
					return true
				end
			end
		end
	end

	for _,name in ipairs(query) do
		local other = locked[name]
		if other and _deadlock(other) then
			return true
		end
	end
end


local function remove_from_waitting(req)
	for i,v in ipairs(waitting) do
		if v.req == req then
			return table.remove(waitting, i)
		end
	end
end


local function interrupt(req)
	for _,name in ipairs(req.locked) do
		locked[name] = false
	end

	req.locked = {}
	req.waitting = {}
end


function S.lock(req_id, names)
	local req = request[req_id]
	if not req then
		req = {id = req_id, time = skynet.now(), locked = {}, waitting = {}}
		request[req_id] = req
	end

	if try_lock(req, names) then
		return querystates(names)
	else
		if deadlock(req, names) then
			skynet.fork(function ()
				interrupt(req)
				try_wakup()
			end)
			return false
		else
			return join_waitting(req, names)
		end
	end
end


function S.unlock(req_id, patch_map)
	for name,patch in pairs(patch_map) do
		if patch then
			skynet.call(state[name], "lua", "patch", patch)
		end
		locked[name] = false
	end

	request[req_id] = nil
	
	try_wakup()
end


skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = S[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
end)