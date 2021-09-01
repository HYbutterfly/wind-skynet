local skynet = require "skynet"
local wind = require "wind"
local db = require "wind.mongo"
local helper = require "ddz.helper"
local query = wind.query


local function radio(users, name, params)
	for _,u in ipairs(users) do
		u:send2client(name, params)
	end
end

local function match_room_info(id, lv, users)
	local room = {id = id, lv = lv, users = {}}
	for i,u in ipairs(users) do
		room.users[i] = {
			id = u.id,
			nick = u.nick,
			head = u.head,
			gold = u.gold,
			status = u.game.status
		}
	end
	return room
end


local function match_ok(lv, uid_list)
	local users = helper.qusers(uid_list)
	local mgr = query("room-mgr")
	mgr.id = mgr.id + 1
	mgr.count[lv] = mgr.count[lv] + 1

	local id = tostring(mgr.id)

	wind.new("room#"..id, {
		id = id,
		lv = lv,
		users = uid_list
	})

	for i,u in ipairs(users) do
		u.status = "game"
		u.roomid = id
		u.game = {status = "init", chair = i}
	end
	radio(users, "match_ok", {room = match_room_info(id, lv, users)})
end


return function ()
	wind.new("match1", {})
	wind.new("match2", {})
	wind.new("match3", {})


	local function tick(lv)
		local name = "match"..lv

		return function ()
			local queue = query(name)
			local len = #queue
			if len < 3 then
				return
			end

			local n = len//3
			for i=1,n do
				match_ok(lv, table.splice(queue, 1, 3))
			end
		end
	end

	helper.new_timer(100, tick(1), -1)
	helper.new_timer(100, tick(2), -1)
	helper.new_timer(100, tick(3), -1)
end