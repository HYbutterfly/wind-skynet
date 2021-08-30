local wind = require "wind"


local function init()
	wind.new("timer-mgr", {id = 0, active = {}})
	wind.new("room-mgr", {id = 100000, count = {0, 0, 0}})
end


local tasks = {
	"match",
	"ranklist"
}


return {init = init, tasks = tasks}