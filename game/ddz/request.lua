local wind = require "wind"


local function between(n, min, max)
	return min <= n and n <= max
end


local request = {}


function request:baseinfo()
	return self
end


function request:start_match(params)
	local lv = assert(params.lv)
	assert(between(lv, 1, 3))
end


function request:cancel_match()
	-- body
end



return request