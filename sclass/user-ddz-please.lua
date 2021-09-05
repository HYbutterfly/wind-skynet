local skynet = require "skynet"



local user = {}


function user:please_playcard()
	self.game.status = "playing"

	local function tick()
		self = self:self()
		self.game.clock = self.game.clock -1
	end

	local function on_end()
		self:autoplay()
	end
	
	self:newtimer(tick, 30, on_end)
	self:send2client("please_playcard", {clock = 30})
end




return user