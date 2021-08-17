local skynet = require "skynet"
local socket = require "skynet.socket"
local db = require "wind.mongo"
local json = require "json"
local conf = require "conf"
local token = require "wind.token"

local worker
local p = {}
local packidx = 0
local pack_list = {}


local function send_pack(pack)
	packidx = packidx + 1
	local pack = string.pack(">s2", pack..string.pack(">I4", packidx))
	pack_list[packidx] = pack

	-- cache up to 128 packages
	if packidx > 128 then
		pack_list[packidx-128] = nil
	end 

	if p.sock then
		socket.write(p.sock, pack)
	end
end

local function send_request(name, args)
	send_pack(json.encode{0, name, args})
end


local function decode(pack)
	local t = json.decode(pack)
	local session = t[1]
	local name = assert(t[2])
	local params = t[3]

	local function response(result)
		return json.encode{session, result}
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
				send_pack(response(r))
			end
		else
			skynet.error(string.format("agent decode error, pack: %s, err:%s", pack, name))
		end
	end
	
	socket.close(id)
	skynet.error("socket closed", id)
	if id == p.sock then
		p.sock = nil
	end
end


function S.send2client(name, args)
	send_request(name, args)
end


function S.reconnect(id, idx)
	socket.start(id)

	if idx > packidx or (packidx > idx and not pack_list[idx+1]) then
		skynet.error("invalid idx", idx, packidx)
		socket.write(id, "401 Pack Index Invalid\n")
		socket.close(id)
		return
	end

	socket.close(p.sock)
	p.sock = id
	socket.write(id, "200 OK\n")

	-- re-send packages
	for i=idx+1,packidx do
		print("send", i)
		socket.write(id, pack_list[i])
	end
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

	skynet.fork(function ()
		while true do
			skynet.sleep(500)
			send_request "heartbeat"
		end
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