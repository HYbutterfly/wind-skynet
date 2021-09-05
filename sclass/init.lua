-- state classes

local classes = {
	"user",
	"room"
}


for _,name in ipairs(classes) do
	classes[string.lower(name)] = require("sclass."..name)
end


return classes