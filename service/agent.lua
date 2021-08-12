local skynet = require "skynet"
local socket = require "skynet.socket"
local db = require "wind.mongo"
local json = require "json"
local conf = require "conf"

local p = {}
local balance, workers


local function worker()
	balance = balance + 1
	if balance == #workers + 1 then
		balance = 1
	end
	return workers[balance]
end



local function decode(pack)
	local t = json.decode(pack)
	local session = t[1]
	local name = assert(t[2])
	local params = t[3]

	local function response(result)
		local s = json.encode{session, result}
		return string.pack(">s2", s)
	end

	return name, params, response
end



local S = {}


local function start_socket(id)
	skynet.error("start socket", id)
	socket.start(id)
	while true do
		local s = socket.read(id, 2)
		if s == false then
			break
		end
		local sz = s:byte(1)*256 + s:byte(2)
		local pack = socket.read(id, sz)
		if pack == false then
			break
		end
		local ok, name, params, response = pcall(decode, pack)
		if ok then
			local r = skynet.call(worker(), "lua", "player_request", p.id, name, params)
			if response then
				socket.write(id, response(r))
			end
		else
			skynet.error(string.format("agent decode error, pack: %s, err:%s", pack, name))
		end
	end
	socket.close(id)
	skynet.error("socket closed", id)
end


function S.init(_workers, id, addr, pid)
	workers = _workers
	balance = math.random(0, #workers-1)

	p.sock = id
	p.id = pid
	p.addr = addr

	skynet.call(worker(), "lua", "player_login", pid, addr)

	skynet.fork(function ()
		start_socket(id)
	end)
end


function S.exit()
	skynet.exit()
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