local skynet = require "skynet"
local wind = require "wind"
local action = require "sclass.user-ddz-action"



local request = {}


for k,_ in pairs(action) do
	request[k] = function (self, params)
		return self[k](self, params, true)
	end
end


return request