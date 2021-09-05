local skynet = require "skynet"
local wind = require "wind"
local helper = require "ddz.helper.game"


local user = {}



function user:autoplay()
	skynet.error(self.id, "autoplay ~~~~~~~~~~~~~~~~")
end


function user:canceltimer()
	local timerid = self.game.timerid
	if timerid then
		helper.cancel_timer(timerid)
		self.game.timerid = nil
	end
end


function user:newtimer(f, time, on_end)
	self:canceltimer()
	self.game.clock = time
	self.game.timerid = helper.new_timer(100, f, time, on_end)
end


function user:myroom()
	local room, users = wind.query(self.game._room, self.game._users)
	return wind.attach(room, {users = users})
end

return user