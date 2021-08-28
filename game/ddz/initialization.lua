local skynet = require "skynet"
local service = require "skynet.service"
local wind = require "wind"

local service_ranklist = require "game.ddz.service.ranklist"


local function init()
	wind.new("timer-mgr", {id = 0, active = {}})
	wind.new("room-mgr", {id = 100000, count = {0, 0, 0}})

	wind.new("match1", {})
	wind.new("match2", {})
	wind.new("match3", {})


	service.new("ranklist", service_ranklist)
end



return init