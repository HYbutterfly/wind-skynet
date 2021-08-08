local skynet = require "skynet"
local wind = require "wind"
local ID = ...






skynet.start(function ()
	if ID == '1' then
		local p <close> = wind.query("player0")
		dump(p)
		p.gold = p.gold + 1000

	elseif ID == '2' then
		local p <close> = wind.query("player0")
		dump(p)
		
	elseif ID == '3' then
		wind.release("player0")
	end
end)