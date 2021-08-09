local skynet = require "skynet"

local state = {}
local locked = {}
local waitting = {}


local function try_lock(names)
	for _,name in ipairs(names) do
		if not state[name] or locked[name] then
			return false
		end
	end
	for _,name in ipairs(names) do
		locked[name] = true
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
	local done, names

	while true do
		done = true
		for i=index,#waitting do
			names = waitting[i]
			index = i
			if try_lock(names) then
				table.remove(waitting, i)
				skynet.wakeup(names)
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


function S.newstate(name, t)
	assert(type(t) == "table")
	assert(not state[name], string.format("state[%s] already exists", name))

	state[name] = skynet.newservice("state-cell", name)
	skynet.call(state[name], "lua", "init", t)
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


function S.lock(names)
	if try_lock(names) then
		return querystates(names)
	else
		waitting[#waitting + 1] = names
		skynet.wait(names)
		return querystates(names)
	end
end


function S.unlock(patch_map)
	for name,patch in pairs(patch_map) do
		if patch then
			skynet.call(state[name], "lua", "patch", patch)
		end
		locked[name] = false
	end

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