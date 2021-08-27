local wind = require "wind"


local moudles = {
	"base",
	"match",
	"game",
}


local function load_moudles()
	local request = {}
	for _,name in ipairs(moudles) do
		local m = require(string.format("game.ddz.request.%s", name))
		for k,v in pairs(m) do
			assert(not request[k], k)
			request[k] = v
		end
	end
	return request
end


return load_moudles()