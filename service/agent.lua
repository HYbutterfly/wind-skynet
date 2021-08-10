local skynet = require "skynet"
local socket = require "skynet.socket"
local db = require "wind.mongo"


local S = {}


function S.init(id, addr, pid)
	skynet.error("agent init ===================", id, addr, pid)
	skynet.fork(function ()
		socket.start(id)
		while true do
			local msg = socket.readline(id)
			skynet.error("client:", msg)
			socket.write(id, msg)
		end
	end)
end


function S.exit()
	skynet.exit()
end


skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = S[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
end)