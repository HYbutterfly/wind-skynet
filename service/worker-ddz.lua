local skynet = require "skynet"
local wind = require "wind"
local db = require "wind.mongo"
local ddzconf = require "conf.ddz"

local ID = ...

local function find_or_register(pid, addr)
	local u = db.user.find_one{id = pid}
	if not u then
		u = {
				id = pid,
				gold = 500000,
				diamond = 0,
				reg_ip = addr:match "(.+):(%d+)"
			}
		u._id = db.user.insert(u)
	end
	return u
end


local request = {}

function request:start_match(params)
	local room_lv = assert(params.lv)
	local roomconf = assert(ddzconf.room[room_lv])

	assert(self.gold >= roomconf.limit[1] and self.gold <= roomconf.limit[2])
	local queue = wind.query("match"..room_lv)


end


function request:bet(params)
	return {ok = true}
end



-----------------------------------------------------------------------

local S = {}


function S.player_login(pid, addr)
	local u = find_or_register(pid, addr)
	wind.new("user@"..pid, u)
	skynet.error(string.format("Player %s Logged in", pid))
end


function S.player_request(pid, name, params)
	local p <close> = wind.query("user@"..pid)
	local f = assert(request[name], name)
	return f(p, params)
end


function S.player_logout(pid)
	-- body
end


skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = S[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
end)