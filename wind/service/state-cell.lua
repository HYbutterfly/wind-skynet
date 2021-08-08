local skynet = require "skynet"
local ltdiff = require "ltdiff"

local ID <const> = ...
local t
local version = 0
local patches = {}


local S = {}


function S.init(...)
	t = ...
end


function S.patch(diff)
	patches[#patches + 1] = diff
	version = version + 1
	t = ltdiff.patch(t, diff)
end


function S.query(v)
	v = v or 0

	if v == 0 then
		return version, t
	end

	if v == version then
		return version
	end

	if patches[v+1] then
		local list = {}

		for i=v+1, #patches do
			table.insert(list, patches[i])
		end
		return version, nil, list
	else
		return version, t
	end
end


function S.exit()
	skynet.error(string.format("State cell[%s] exit", ID))
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