local skynet = require "skynet"
local conf = require "conf"
local initialization = require "game.ddz.initialization"


skynet.start(function ()

	skynet.error("=============================================")
	skynet.error(os.date("%Y/%m/%d %H:%M:%S ").."Server start")
	skynet.error("=============================================")

	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console", 5555)

	initialization.init()

	local workers = {}
	for i=1,conf.nworker do
		workers[i] = skynet.newservice("worker", i)
	end
	
	skynet.call(skynet.newservice("gate"), "lua", "init", workers)
	skynet.exit()
end)