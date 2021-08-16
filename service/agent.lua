local skynet = require "skynet"
local socket = require "skynet.socket"
local db = require "wind.mongo"
local json = require "json"
local conf = require "conf"
local token = require "wind.token"

local p = {}
local worker


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

		if id ~= p.sock then
			skynet.error("agent alreay use new socket id, this pack will been ignore")
			break
		end
		local ok, name, params, response = pcall(decode, pack)
		if ok then
			local r = skynet.call(worker, "lua", "player_request", p.id, name, params)
			if response then
				socket.write(id, response(r))
			end
		else
			skynet.error(string.format("agent decode error, pack: %s, err:%s", pack, name))
		end
	end
	
	socket.close(id)
	skynet.error("socket closed", id)
	if id == p.sock then
		skynet.error("socket closed by client, you can do something here")
	end
end


function S.reconnect(id)
	socket.close(p.sock)
	p.sock = id

	socket.start(id)
	socket.write(id, "200 OK\n")
	skynet.fork(start_socket, id)
end


-- client re-login or new client(device) login
function S.login(id)
	socket.close(p.sock)
	p.sock = id

	socket.start(id)
	socket.write(id, string.format("200 OK, %s\n", token.encode(p.id, skynet.self())))
	skynet.fork(start_socket, id)
end


-- real login in server (client first login)
function S.init(_worker, id, addr, pid)
	worker = _worker

	p.sock = id
	p.id = pid
	p.addr = addr

	skynet.call(worker, "lua", "player_login", pid, addr)

	socket.start(id)
	socket.write(id, string.format("200 OK, %s\n", token.encode(p.id, skynet.self())))
	skynet.fork(start_socket, id)
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