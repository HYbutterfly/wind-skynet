local crypt = require "skynet.crypt"
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode


local token = {}


function token.encode(pid, agent)
	return string.format("%s@%s", b64encode(pid), b64encode(tostring(agent)))
end


function token.decode(t)
	local pid, agent = t:match("([^@]*)@(.+)")
	if agent then
		return b64decode(pid), b64decode(agent)
	end
end



return token