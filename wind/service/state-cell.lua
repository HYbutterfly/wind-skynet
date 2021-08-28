local skynet = require "skynet"
local ltdiff = require "ltdiff"
local db = require "wind.mongo"
local persistence = require "conf.persistence"

local ID = ...
local t
local version = 0
local patches = {}

local collname = ID:match("(%w+)@(.+)")
local conf, query, fliter


local S = {}


function S.init(...)
	t = ...
	assert(type(t) == "table")

	if collname and persistence[collname] then
		conf = persistence[collname]
		conf.delay = conf.delay or 0

		query = {_id = assert(t._id)}
		t._id = nil

		if conf.fliter then
			fliter = function(t)
				local new = {}
				for k,v in pairs(t) do
					if conf.fliter[k] then
						new[k] = v
					end
				end
				return new
			end
		else
			fliter = function(t)
				return t
			end
		end
	else
		collname = nil
	end
end


local timing = false

local function delay_save(delay)
	if timing == false then
		timing = true
		skynet.timeout(delay*100, function ()
			timing = false
			db[collname].update(query, {["$set"] = fliter(t)})
		end)
	end
end


function S.patch(diff)
	patches[#patches + 1] = diff
	version = version + 1
	t = ltdiff.patch(t, diff)

	if conf then
		if conf.delay > 0 then
			delay_save(conf.delay)
		else
			db[collname].update(query, {["$set"] = fliter(t)})
		end
	end
end


function S.slice()
	return t
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
	if timing then
		db[collname].update(query, {["$set"] = fliter(t)})
	end
	skynet.error(string.format("State cell[%s] exit", ID))
	skynet.exit()
end


skynet.start(function()
	skynet.info_func(function ()
		return t
	end)
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = S[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
end)