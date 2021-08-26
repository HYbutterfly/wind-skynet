local wind = require "wind"


local function init()
	wind.new("timer-mgr", {id = 0, active = {}})
	wind.new("room-mgr", {id = 100000, count = {0, 0, 0}})

	wind.new("match1", {})
	wind.new("match2", {})
	wind.new("match3", {})
end



return init