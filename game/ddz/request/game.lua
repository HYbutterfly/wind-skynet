local skynet = require "skynet"
local wind = require "wind"
local helper = require "game.ddz.helper.game"
local ddzconf = require "conf.ddz"

local query = wind.query
local mquery = helper.mquery

local function qusers(uid_list)
	return mquery(uid_list, function (uid)
		return "user@"..uid
	end)
end

local function send2client(u, name, params)
	skynet.send(u.agent, "lua", "send2client", name, params)
end

local function radio(users, name, params)
	for _,u in ipairs(users) do
		send2client(u, name, params)
	end
end

---------------------------------------------------------------------------
local request = {}

local function all_ready_ok(users)
	for _,u in ipairs(users) do
		if u.game.status ~= "ready_ok" then
			return false
		end
	end
	return true
end


local function u_canceltimer(u)
	local timerid = u.game.timerid
	if timerid then
		helper.cancel_timer(timerid)
		u.game.timerid = nil
	end
end

local function u_newtimer(u, f, time, on_end)
	u_canceltimer(u)
	u.game.clock = time
	u.game.timerid = helper.new_timer(100, f, time, on_end)
end


local function u_autoplay(u)
	local room = query("room"..u.roomid)
	-- todo
end


local function please_playcard(u)
	u.game.status = "playing"

	local function tick()
		u.game.clock = u.game.clock -1
	end
	local function on_end()
		u_autoplay(u)
	end
	u_newtimer(u, tick, 30, on_end)
end

local function gamestart(room, users)
	local pool = helper.shuffle(helper.one_deck_cards())
	for i,u in ipairs(users) do
		u.game.status = "waiting"
		u.game.hand = table.splice(pool, 1, 17)
	end
	room.final_cards = pool

	-- idx == chair
	local landlord_idx = math.random(1, #users)
	local landlord = users[landlord_idx]

	for i,u in ipairs(users) do
		u.game.is_landlord = u == landlord
		send2client(u, "gamestart", {final_cards = room.final_cards, landlord_id = landlord.id, hand = u.game.hand})
	end

	please_playcard(landlord)
end


function request:ready()
	assert(self.status == "game")
	assert(self.game.status == "init")
	local room = query("room"..self.roomid)
	local users = qusers(room.users)

	self.game.status = "ready_ok"
	radio(users, "p_ready_ok", {pid = self.id})

	dump(users)
	if all_ready_ok(users) then
		gamestart(room, users)
	end
	
	return {}
end











return request