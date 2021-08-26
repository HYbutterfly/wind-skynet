local wind = require "wind"
local query = wind.query

local helper = {}



local function gen_timer_id()
	local s = query("uniqueid-timer")
	s.id = s.id + 1
	return tostring(s.id)
end


function helper.new_timer(delay, func, iteration, on_end)
	iteration = iteration or 1
	local id = gen_timer_id()
	local count = 0

	local time_mgr = query("time_mgr")
	time_mgr[id] = true 

	skynet.fork(function ()
		while true do
			skynet.sleep(delay)
			local time_mgr = wind.slice("time_mgr")
			if time_mgr[id] then
				skynet.fork(func)
				count = count + 1
				if count == iteration then
					if on_end then
						on_end()
					end
					break
				end
			else
				break
			end
		end
	end)

	return id
end

function helper.cancel_timer(id)
	local time_mgr = query("time_mgr")
	time_mgr[id] = nil
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