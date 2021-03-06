local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "json"
local token = require "wind.token"

local AUTH_TOKNE <const> = "WIND"

local logged = {} 			-- pid : agent
local workers
local balance = 0


local function worker()
	balance = balance + 1
	if balance > #workers then
		balance = 1
	end
	return workers[balance]
end


local function token_auth(t)
	assert(t)
	local uid, agent = token.decode(t)
	if agent then
		agent = tonumber(agent)
		assert(agent == logged[uid])
		return agent
	end
end

--[[
	msg: {"cmd": "login", "uid": "123456"}
	msg: {"cmd": "reconnect", "token": "TOKEN", "packidx": 10}
]]
local function hanshake(id, msg, addr)
	skynet.error("hanshake", id, msg)
	local msg = json.decode(msg)

	if msg.cmd == "login" then
		local uid = assert(msg.uid)
		local agent = logged[uid]

		if agent then
			-- client re-login or new client(device) login
			skynet.send(agent, "lua", "login", id)
		else
			-- real logic login in server
			agent = skynet.newservice "agent"
			logged[uid] = agent
			skynet.send(agent, "lua", "init", worker(), id, addr, uid)
		end
	else
		assert(msg.cmd == "reconnect")
		assert(msg.packidx >= 0)
		local agent = assert(token_auth(msg.token))
		skynet.send(agent, "lua", "reconnect", id, msg.packidx)
	end
end


local function accept(id, addr)
	skynet.fork(function()
		socket.start(id)
		socket.limit(id, 1024)
		local token = socket.readline(id)
		if token == AUTH_TOKNE then
			local msg = socket.readline(id)
			local ok = msg and pcall(hanshake, id, msg, addr)
			if ok then
				socket.abandon(id)
			else
				socket.close(id)
			end
		else
			socket.close(id)
		end
	end)
end


local S = {}

function S.init(...)
	workers = ...
end


skynet.start(function ()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = S[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)

	local id = socket.listen("127.0.0.1", 6666)
	skynet.error("Listen socket :", "127.0.0.1", 6666)
	socket.start(id , function(id, addr)
		skynet.error("connect from " .. addr .. " " .. id)
		accept(id, addr)
	end)
end)