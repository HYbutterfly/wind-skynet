local skynet = require "skynet"
local service = require "skynet.service"
local ltdiff = require "ltdiff"

local state_mgr
local state_map = {}
local state_version = {}


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


function wind.query(...)
	local names = {...}
	local addrs = skynet.call(state_mgr, "lua", "lock", names)
	local results = {}
	local old_list = {}
	local new_list = {}

	for i,addr in ipairs(addrs) do
		local name = names[i]
		local version, state, patches = skynet.call(addr, "lua", "query", state_version[name])
		local old = update_state(name, version, state, patches)
		local new = table.clone(old)

		old_list[i] = old
		new_list[i] = new

		if i < #addrs then
			results[i] = new
		else
			-- only lasted one has close function
			local mt = {__close = function ()
				skynet.fork(function ()
					local patch_map = {}

					for i=1,#names do
						local name = names[i]
						local old = old_list[i]
						local new = new_list[i]
						local diff = ltdiff.diff(old, new) or false

						patch_map[name] = diff
						if diff then
							state_version[name] = state_version[name] + 1
							state_map[name] = new
						end
					end
					skynet.send(state_mgr, "lua", "unlock", patch_map)
				end)
			end}
		
			results[i] = setmetatable(new, mt)
		end
	end

	return table.unpack(results)
end


skynet.init(function ()
	state_mgr = skynet.uniqueservice "state-mgr"
end)


return wind