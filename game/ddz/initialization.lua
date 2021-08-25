local wind = require "wind"


local function init()
	wind.new("match1", {})
	wind.new("match2", {})
	wind.new("match3", {})

	wind.new("uniqueid-room", {id = 100000})
end



return init