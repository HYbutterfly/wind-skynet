local skynet = require "skynet"
local socket = require "skynet.socket"

local AUTH_TOKNE <const> = "WIND"

local connection = {}
local workers
local balance = 0


local function worker()
	balance = balance + 1
	if balance > #workers then
		balance = 1
	end
	return workers[balance]
end


local function hanshake(id, msg, addr)
	local pid = msg
	local agent = skynet.newservice "agent"

	connection[id] = {
		id = id,
		pid = pid,
		addr = addr,
		agent = agent
	}

	socket.write(id, "Login success!\n")
	socket.abandon(id)
	skynet.call(agent, "lua", "init", worker(), id, addr, pid)
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