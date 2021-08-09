local skynet = require "skynet"
local conf = require "conf"
local wind = require "wind"

skynet.start(function ()

	skynet.error("=============================================")
	skynet.error(os.date("%Y/%m/%d %H:%M:%S ").."Server start")
	skynet.error("=============================================")

	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console", 5555)


	for i=1,conf.nworker do
		skynet.newservice("worker", i)
	end

	skynet.exit()
end)