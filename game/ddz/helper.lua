local wind = require "wind"
local query = wind.query

local helper = {}


function helper.gen_room_id()
	local s = query("uniqueid-room")
	s.id = s.id + 1
	return tostring(s.id)
end


function helper.mquery(names, f)
	local function pack(...)
		return {...}		
	end

	local list
	if f then
		list = {}
		for i,v in ipairs(names) do
			list[i] = f(v)
		end
	else
		list = names
	end

	return pack(query(table.unpack(list)))
end



return helper