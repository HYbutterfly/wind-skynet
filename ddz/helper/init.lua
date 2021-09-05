local skynet = require "skynet"
local wind = require "wind"
local query = wind.query

local helper = {}


function helper.quser(uid)
	return query("user@"..uid)
end


function helper.qusers(uid_list)
	local list = {}
	for i,v in ipairs(uid_list) do
		list[i] = "user@"..v
	end
	return query(list)
end


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




return helper