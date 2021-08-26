local skynet = require "skynet"
local wind = require "wind"
local query = wind.query

local helper = {}


function helper.new_timer(delay, func, iteration, on_end)
	local iteration = iteration or 1
	local count = 0

	local mgr = query("timer-mgr")
	local id = mgr.id + 1
	mgr.id = id
	mgr.active[mgr.id] = true

	local function tick()
		local mgr = wind.slice("timer-mgr")
		if mgr.active[id] then
			func()
			count = count + 1
			if count == iteration then
				if on_end then
					on_end()
				end
			else
				skynet.timeout(delay, tick)
			end
		end
	end

	skynet.timeout(delay, tick)

	return id
end


function helper.cancel_timer(id)
	local mgr = query("timer-mgr")
	mgr.active[id] = nil
end



function helper.gen_room_id()
	local s = query("uniqueid-room")
	s.id = s.id + 1
	return tostring(s.id)
end


function helper.mquery(names, f)
	local function pack(...)
		return {...}		
	end

	local list
	if f then
		list = {}
		for i,v in ipairs(names) do
			list[i] = f(v)
		end
	else
		list = names
	end

	return pack(query(table.unpack(list)))
end



return helper