local skynet = require "skynet"
require "skynet.manager"
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

	

	-- ddz states

	wind.new("match1", {})
	wind.new("match2", {})
	wind.new("match3", {})
	
	-- end

	local workers = {}
	for i=1,conf.nworker do
		workers[i] = skynet.newservice("worker", i)
	end
	
	skynet.call(skynet.newservice("gate"), "lua", "init", workers)
	skynet.call(skynet.newservice("test"), "lua", "init", workers)

	skynet.exit()
end)