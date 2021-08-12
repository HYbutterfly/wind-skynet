package.cpath = "luaclib/?.so;skynet/luaclib/?.so;"
package.path = "lualib/?.lua"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

function string:split(sep)
    local splits = {}
    
    if sep == nil then
        -- return table with whole str
        table.insert(splits, self)
    elseif sep == "" then
        -- return table with each single character
        local len = #self
        for i = 1, len do
            table.insert(splits, self:sub(i, i))
        end
    else
        -- normal split use gmatch
        local pattern = "[^" .. sep .. "]+"
        for str in string.gmatch(self, pattern) do
            table.insert(splits, str)
        end
    end
    
    return splits
end

----------------------------------------------------------------------------------
local socket = require "client.socket"
local json = require "json"

local login = false
local last = ""


local fd = assert(socket.connect("127.0.0.1", 6666))
socket.send(fd, "WIND\n") 		-- auth token
socket.send(fd, "123456\n") 	-- handshake, use `pid` to login


local session = 0

local function send_request(name, params)
	session = session + 1
	local pack = json.encode{session, name, params}
	print("send", name)
	socket.send(fd, string.pack(">s2", pack))
end

local function print_package()
	local size = #last
	if size < 2 then
		return
	end

	local sz = last:byte(1)*256 + last:byte(2)
	if size < sz + 2 then
		return
	end

	local pack = last:sub(3, 2+sz)
	print(pack)
	last = last:sub(3+sz)
	print_package()
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

----------------------------------------------------------------------------------
local CMD = {}

function CMD.bet(n)
	n = n and tonumber(n) or 1000
	send_request("bet", {gold = n})
end


while true do
	dispatch_message()
	local cmd = socket.readstdin()
	if cmd then
		if cmd == "exit" then
			break
		else
			local t = cmd:split(" ")
			local f = CMD[t[1]]
			if f then
				f(table.unpack(t, 2))
			else
				print("Unknown cmd", t[1])
			end
		end
	else
		socket.usleep(100)
	end
end


socket.close(fd)