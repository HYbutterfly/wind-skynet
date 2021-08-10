package.cpath = "luaclib/?.so;skynet/luaclib/?.so;"
package.path = "lualib/?.lua"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

local socket = require "client.socket"

local login = false
local last = ""

local fd = assert(socket.connect("127.0.0.1", 6666))
socket.send(fd, "WIND\n") 		-- auth token
socket.send(fd, "123456\n") 	-- handshake, use `pid` to login


local function print_package()
	print(last)
	last = ""
end


local function dispatch_message()
	local r = socket.recv(fd)
	if r and #r>0 then
		if login then
			last = last .. r
			print_package()
		else
			login = true
			print(r)
		end
	end
end



while true do
	dispatch_message()
	local cmd = socket.readstdin()
	if cmd then
		if cmd == "exit" then
			break
		else
			socket.send(fd, cmd.."\n")
		end
	else
		socket.usleep(100)
	end
end


socket.close(fd)