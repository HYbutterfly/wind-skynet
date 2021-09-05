local skynet = require "skynet"


local user = {}


function user:ready()
	assert(self.status == "game")
	assert(self.game.status == "init")

	self.game.status = "ready_ok"

	local room = self:myroom()
	room:radio("p_ready_ok", {pid = self.id})

	if room:all_ready_ok() then
		room:gamestart()
	end
end




return user