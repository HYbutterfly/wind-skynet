local skynet = require "skynet"
local user = require "sclass.user-base"


local modules = {
	"user-ddz-init",
	"user-ddz-please",
	"user-ddz-action"
}


for _,name in ipairs(modules) do
	local t = require(string.format("sclass.%s", name))
	for k,v in pairs(t) do
		assert(not user[k], "Repeated method, "..k)
		user[k] = v
	end
end



return {__index = user}