local skynet = require "skynet"
local wind = require "wind"
local helper = require "game.ddz.helper"
local ddzconf = require "conf.ddz"

local query = wind.query
local mquery = helper.mquery


local function qusers(uid_list)
	return mquery(uid_list, function (uid)
		return "user@"..uid
	end)
end


local function between(n, min, max)
	return min <= n and n <= max
end


local function match_room_info(id, lv, users)
	local room = {id = id, lv = lv, users = {}}
	for i,u in ipairs(users) do
		room.users[i] = {
			id = u.id,
			nick = u.nick,
			head = u.head,
			gold = u.gold,
			gamestatus = u.gamestatus
		}
	end
	return room
end

local function send2client(u, name, params)
	skynet.send(u.agent, "lua", "send2client", name, params)
end

local function radio(users, name, params)
	for _,u in ipairs(users) do
		send2client(u, name, params)
	end
end


local function match_ok(lv, uid_list)
	skynet.sleep(100)

	local users = qusers(uid_list)
	local mgr = query("room-mgr")
	mgr.id = mgr.id + 1
	mgr.count[lv] = mgr.count[lv] + 1

	local id = tostring(mgr.id)

	wind.new("room"..id, {
		id = id,
		lv = lv,
		users = uid_list
	})

	for _,u in ipairs(users) do
		u.status = "game"
		u.roomid = id
		u.gamestatus = "init"
	end
	radio(users, "match_ok", {room = match_room_info(id, lv, users)})
end

---------------------------------------------------------------------------
local request = {}


local function cancel_match(u)
	local lv = assert(u.match_lv)
	local queue = query("match"..lv)
	local index = table.find_one(queue, u.id)
	table.remove(queue, index)

	u.status = "idle"
end


function request:start_match(params)

	local lv = assert(params.lv)
	local limit = ddzconf.room[lv].limit

	assert(self.status == "idle")
	assert(between(lv, 1, 3))
	assert(between(self.gold, limit[1], limit[2]))

	local queue = query("match"..lv)

	if #queue == 2 then
		local uid_list = table.splice(queue, 1, 2)
		local others = qusers(uid_list)
		
		for _,u in ipairs(others) do
			helper.cancel_timer(u.match_timerid)
			u.status = "match_ok"
			u.match_lv = nil
			u.match_timerid = nil
		end
		self.status = "match_ok"
		self.match_lv = nil

		skynet.fork(match_ok, lv, table.append(uid_list, self.id))
		return {}
	else
		self.status = "matching"
		self.match_lv = lv

		-- 30S 后自动取消匹配
		self.match_timerid = helper.new_timer(30*100, function ()
			local me = query("user@"..self.id)
			if me.status == "matching" then
				cancel_match(me)
				me.match_timerid = nil
				send2client(me, "match_failed")
			end
		end) 

		table.insert(queue, self.id)
		return {}
	end
end


function request:cancel_match()
	assert(self.status == "matching")
	cancel_match(self)
	helper.cancel_timer(self.match_timerid)
	self.match_timerid = nil
	return {}
end


return request