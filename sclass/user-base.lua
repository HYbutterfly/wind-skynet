local skynet = require "skynet"
local wind = require "wind"


local user = {}


function user:send2client(...)
	skynet.send(self.agent, "lua", "send2client", ...)
end


function user:self()
	return wind.query("user@"..self.id)
end


return user