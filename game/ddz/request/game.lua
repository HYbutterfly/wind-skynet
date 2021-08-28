local skynet = require "skynet"
local wind = require "wind"
local helper = require "game.ddz.helper.game"
local ddzconf = require "conf.ddz"

local query = wind.query
local mquery = helper.mquery

local function quser(uid)
	return query("user@"..uid)
end

local function qusers(uid_list)
	local list = {}
	for i,v in ipairs(uid_list) do
		list[i] = "user@"..v
	end
	return query(list)
end

local function qroom(roomid)
	local room = query("room"..roomid)
	local users = qusers(room.users)
	return room, users	
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


local function u_autoplay(roomid, uid)
	local room, users = qroom(roomid)
	skynet.error("autoplay...", uid)
end


local function please_playcard(room, u)
	u.game.status = "playing"

	local function tick()
		local u = quser(u.id)
		u.game.clock = u.game.clock -1
	end
	local function on_end()
		u_autoplay(room.id, u.id)
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

	please_playcard(room, landlord)
end


function request:ready()
	assert(self.status == "game")
	assert(self.game.status == "init")
	local room, users = qroom(self.roomid)

	self.game.status = "ready_ok"
	radio(users, "p_ready_ok", {pid = self.id})

	if all_ready_ok(users) then
		gamestart(room, users)
	end
	
	return {}
end











return request