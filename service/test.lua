local skynet = require "skynet"





local S = {}

function S.init(workers)
	skynet.sleep(100)
	skynet.fork(function ()
		skynet.error("call testlcok1")
		skynet.error(skynet.call(workers[1], "lua", "testlcok1"))
	end)
	skynet.fork(function ()
		skynet.error("call testlcok2")
		skynet.error(skynet.call(workers[2], "lua", "testlcok2"))
	end)
end


skynet.start(function ()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = S[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
end)