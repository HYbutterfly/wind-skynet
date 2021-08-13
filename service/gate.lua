local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "json"

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

local function token_encode(pid)
	return pid
end

local function token_decode(t)
	local pid = t
	return pid
end

--[[
	msg: {"cmd": "login", "pid": "123456"}
	msg: {"cmd": "reconnect", "token": "TOKEN", "msgindex": 10}
]]
local function hanshake(id, msg, addr)
	local msg = json.decode(msg)

	if msg.cmd == "login" then
		local pid = assert(msg.pid)
		local token = token_encode(pid)
		socket.write(id, "Login success!" .. token .."\n")
		socket.abandon(id)

		local agent = logged[pid]
		
		if agent then
			-- client re-login or new client(device) login
			skynet.call(agent, "lua", "login", id, addr)
		else
			-- real logic login in server
			agent = skynet.newservice "agent"
			logged[pid] = agent
			skynet.call(agent, "lua", "init", worker(), id, addr, pid)
		end
	else
		assert(msg.cmd == "reconnect")

	end
end


local function accept(id, addr)
	skynet.fork(function()
		socket.start(id)
		local token = socket.readline(id)
		if token == AUTH_TOKNE then
			local msg = socket.readline(id)
			local ok = msg and hanshake(id, msg, addr)
			if ok then
				-- pass
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