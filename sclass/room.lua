local skynet = require "skynet"
local helper = require "ddz.helper.game"

local room = {}


function room:gamestart()
	local pool = helper.shuffle(helper.one_deck_cards())
	for i,u in ipairs(self.users) do
		u.game.status = "waiting"
		u.game.hand = table.splice(pool, 1, 17)
	end
	room.final_cards = pool

	local index = math.random(1, #self.users)
	local landlord = self.users[index]

	for i,u in ipairs(self.users) do
		u.game.identity = u == landlord and "landlord" or "farmer"
		u:send2client("gamestart", {final_cards = room.final_cards, landlord_id = landlord.id, hand = u.game.hand})
	end

	landlord:please_playcard()
end


function room:all_ready_ok()
	for _,u in ipairs(self.users) do
		if u.game.status ~= "ready_ok" then
			return false
		end
	end
	return true
end


function room:radio(name, params)
	for _,u in ipairs(self.users) do
		u:send2client(name, params)
	end
end


return {__index = room}