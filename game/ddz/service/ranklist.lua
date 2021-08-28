return function ()
	local skynet = require "skynet"

	local list = {}





	local command = {}

	function command.ranklist()
		return list
	end


	skynet.error("ranklist init")

	skynet.dispatch("lua", function(session, address, cmd, ...)
		skynet.ret(skynet.pack(command[cmd](...)))
	end)
end