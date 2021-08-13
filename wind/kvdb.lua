local skynet = require "skynet"
local service = require "skynet.service"


local function service_db(...)
	local skynet = require "skynet"

	local db = {}

	local command = {}

	function command.get(key)
		return db[key]
	end

	function command.set(key, value)
		local old = db[key]
		db[key] = value
		return old
	end

	-- skynet.start is compatible
	skynet.dispatch("lua", function(session, address, cmd, ...)
		skynet.ret(skynet.pack(command[cmd](...)))
	end)
end


local service_cache = {}

local function query(name)
	if not service_cache[name] then
		service_cache[name] = service.new(name, service_db)
	end
	return service_cache[name]
end


local db_cache = {}

local function db(name)
	local c = db_cache[name]
	if not c then
		local service_name = "kvdb."..name
		c = setmetatable({}, {
				__index = function (_, k)
					return skynet.call(query(service_name), "lua", "get", k)
				end,
				__newindex = function(_, k, v)
					return skynet.call(query(service_name), "lua", "set", k, v)
				end
			}
		)
		db_cache[name] = c
	end

	return c
end



return setmetatable({}, {__index = function (_, name)
	return db(name)
end})