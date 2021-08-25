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

local function radio(users, name, params)
	for _,u in ipairs(users) do
		skynet.error("send ", u.agent, name, params)
		skynet.send(u.agent, "lua", "send2client", name, params)
	end
end

-----------------------------------------------------------
local request = {}


function request:baseinfo()
	return self
end


local function match_ok(lv, uid_list)
	skynet.sleep(100)

	local users = qusers(uid_list)
	local id = helper.gen_room_id()

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
			u.status = "match_ok"
			u.match_lv = nil
		end
		self.status = "match_ok"
		self.match_lv = nil

		skynet.fork(match_ok, lv, table.append(uid_list, self.id))
		return {}
	else
		self.status = "matching"
		self.match_lv = lv
		table.insert(queue, self.id)
		return {}
	end
end


function request:cancel_match()
	assert(self.status == "matching")

	local lv = assert(self.match_lv)
	local queue = query("match"..lv)
	local index = table.find_one(queue, self.id)
	table.remove(queue, index)

	self.status = "idle"
	return {}
end



return request