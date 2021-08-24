local skynet = require "skynet"
local wind = require "wind"
local db = require "wind.mongo"

local ID = ...

local function find_or_register(pid)
	local u = db.user.find_one{id = pid}
	if not u then
		u = {id = pid, gold = 0, diamond = 0}
		u._id = db.user.insert(u)
	end
	return u
end


local request = {}


function request:bet(params)
	return {ok = true}
end



-----------------------------------------------------------------------

local S = {}


function S.testlcok1()
	local q1 = wind.query("match1")
	skynet.sleep(100)
	local q2 = wind.query("match2")
	local q3 = wind.query("match3")
	q3[1] = "123"

	return "testlcok1 done"
end

function S.testlcok2()
	local q2 = wind.query("match2")
	skynet.sleep(100)
	local q1 = wind.query("match1")

	skynet.fork(function ()
		local q3 = wind.query("match3")
		skynet.sleep(100)
		skynet.error("q3[1] =", q3[1])
	end)
	return "testlcok2 done"
end


function S.player_login(pid, addr)
	local u = find_or_register(pid)
	wind.new("user@"..pid, u)
	skynet.error(string.format("Player %s Logged in", pid))
end


function S.player_request(pid, name, params)
	local p = wind.query("user@"..pid)
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