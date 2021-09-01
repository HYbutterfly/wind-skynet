local skynet = require "skynet"


local User = {}


function User:send2client(...)
	skynet.send(self.agent, "lua", "send2client", ...)
end




return {__index = User}