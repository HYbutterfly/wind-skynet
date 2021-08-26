local wind = require "wind"


local function init()
	wind.new("timer")

	wind.new("match1", {})
	wind.new("match2", {})
	wind.new("match3", {})

	wind.new("uniqueid-room", {id = 100000})
	wind.new("uniqueid-timer", {id = 0})
end



return init