local skynet = require "skynet"

local mongod
local cache = {}


local function collection(coll)
    local c = cache[coll]
    if not c then
        c = setmetatable({}, {__index = setmetatable({}, {__index = function (_, cmd)
            return function (...)
                return skynet.call(mongod, "lua", cmd, coll, ...)
            end
        end})})
        cache[coll] = c
    end
    return c
end


-----------------------------------------------------------

skynet.init(function ()
    mongod = skynet.uniqueservice "mongod"
end)

-----------------------------------------------------------
local mongo = {}


function mongo.disconnect()
    pcall(skynet.call, mongod, "lua", "exit")
end


return setmetatable(mongo, {__index = function (_, name)
	return collection(name)
end})