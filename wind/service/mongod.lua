local skynet = require "skynet"
local mongo = require "skynet.db.mongo"
local conf = require "conf.mongo"

local client, db


local S = {}


function S.insert(coll_name, obj)
    db[coll_name]:insert(obj)
    return obj._id
end


function S.remove(coll_name, query, single)
    return db[coll_name]:delete(query, single)
end


function S.find_one(coll_name, query, fields)
    return db[coll_name]:findOne(query, fields)
end


function S.find_all(coll_name, query, fields, sorter, limit, skip)
    local t = {}
    local it = db[coll_name]:find(query, fields)
    if not it then
        return t
    end

    if sorter then
        if #sorter > 0 then
            it = it:sort(table.unpack(sorter))
        else
            it = it:sort(sorter)
        end
    end

    if limit then
        it:limit(limit)
        if skip then
            it:skip(skip)
        end
    end

    while it:hasNext() do
        local obj = it:next()
        table.insert(t, obj)
    end

    return t
end


function S.update(coll_name, query, update, upsert, multi)
    return db[coll_name]:safe_update(query, update, upsert, multi)
end


function S.count(coll_name, query)
    local it = db[coll_name]:find(query)
    return it:count()
end


-- Ex
function S.sum(coll_name, query, key)
    local pipeline = {}
    if query then
        table.insert(pipeline,{["$match"] = query})
    end
   
    table.insert(pipeline,{["$group"] = {_id = false, [key] = {["$sum"] = "$" .. key}}})
   
    local result = db:runCommand("aggregate", coll_name, "pipeline", pipeline, "cursor", {}, "allowDiskUse", true)

    if result and result.ok and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            local r = result.cursor.firstBatch[1]
            return r and r[key] or 0
        end
    end
    return 0
end


function S.exit()
	client:disconnect()
	skynet.exit()
end


skynet.init(function ()
    client = mongo.client(conf)
    db = client:getDB(conf.dbname)
end)


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