local wind = require "wind"
local db = require "wind.mongo"
local helper = require "ddz.helper"
local query = wind.query

local INTERVAL <const> = 5*60
local FILEDS <const> = {_id = false, id = 1, nick = 1, gold = 1}
local SORT <const> = {gold = 1}


local function wealth_list()
	return db.user.find_all(nil, FILEDS, SORT, 10)
end


return function ()

	wind.new("wealth_list", wealth_list())

	helper.new_timer(INTERVAL*100, function ()
		local s = query("wealth_list")

		for i=#s,1,-1 do
			s[i] = nil
		end

		for i,v in ipairs(wealth_list()) do
			s[i] = v
		end
	end, -1)
end