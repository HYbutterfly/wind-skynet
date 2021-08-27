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
		if u.gamestatus ~= "ready_ok" then
			return false
		end
	end
	return true
end

local function gamestart(room, users)
	-- body
end


function request:ready()
	assert(self.status == "game")
	assert(self.gamestatus == "init")
	local room = query("room"..self.roomid)
	local users = qusers(room.users)

	self.gamestatus = "ready_ok"
	radio(users, "p_ready_ok", {pid = self.id})

	dump(users)
	if all_ready_ok(users) then
		gamestart(room, users)
	end
	
	return {}
end











return request