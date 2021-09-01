local skynet = require "skynet"
local wind = require "wind"
local helper = require "ddz.helper"
local ddzconf = require "conf.ddz"
local query = wind.query


local function between(n, min, max)
	return min <= n and n <= max
end

local function send2client(u, name, params)
	skynet.send(u.agent, "lua", "send2client", name, params)
end

---------------------------------------------------------------------------
local request = {}


local function cancel_match(u)
	local lv = assert(u.match_lv)
	local queue = query("match"..lv)
	local index = table.find_one(queue, u.id)
	table.remove(queue, index)

	u.status = "idle"
end


function request:start_match(params)

	local lv = assert(params.lv)
	local limit = ddzconf.room[lv].limit

	assert(self.status == "idle")
	assert(between(lv, 1, 3))
	assert(between(self.gold, limit[1], limit[2]))

	local queue = query("match"..lv)

	table.insert(queue, self.id)
	self.status = "matching"
	self.match_lv = lv

	-- 30S 后自动取消匹配
	self.match_timerid = helper.new_timer(30*100, function ()
		local me = query("user@"..self.id)
		if me.status == "matching" then
			cancel_match(me)
			me.match_timerid = nil
			send2client(me, "match_failed")
		end
	end) 
	
	return {}
end


function request:cancel_match()
	assert(self.status == "matching")
	cancel_match(self)
	helper.cancel_timer(self.match_timerid)
	self.match_timerid = nil
	return {}
end


return request