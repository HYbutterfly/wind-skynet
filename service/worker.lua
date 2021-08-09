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




skynet.start(function()
	skynet.fork(function ()
		if ID == '1' then
			local pid = '123'
			local u = find_or_register(pid)
			dump(u)
			wind.new('user@'..pid, u)

		elseif ID == '2' then
			local u <close> = wind.query('user@123')
			u.gold = u.gold + 1000
			dump(u)
			skynet.sleep(100)

		elseif ID == '3' then
			local u <close> = wind.query('user@123')
			u.gold = u.gold + 1000
			dump(u)
			skynet.sleep(200)

		elseif ID == '4' then
			local u <close> = wind.query('user@123')
			u.gold = u.gold + 1000
			dump(u)
		end
	end)
end)