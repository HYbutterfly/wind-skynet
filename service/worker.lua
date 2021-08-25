local skynet = require "skynet"
local wind = require "wind"
local db = require "wind.mongo"
local request = require "game.ddz.request"

local ID = ...

local function find_or_register(uid)
	local u = db.user.find_one{id = uid}
	if not u then
		u = {id = uid, gold = 0, diamond = 0}
		u._id = db.user.insert(u)
	end
	return u
end


local S = {}


function S.login(uid, addr)
	local u = find_or_register(uid)
	wind.new("user@"..uid, u)
	skynet.error(string.format("User %s login", uid))
end


function S.request(uid, name, params)
	local u = wind.query("user@"..uid)
	local f = assert(request[name], name)
	return f(u, params)
end


function S.logout(uid)

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