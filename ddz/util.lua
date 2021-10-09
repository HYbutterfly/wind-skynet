-----------------------------------------------------------------
-- 斗地主经典算法(一副牌)
-----------------------------------------------------------------

local util = {}


local function vv(t)
	for i,v in ipairs(t) do
		t[v] = v
	end
	return t
end

local TYPE = vv{
	"dan",
	"dui",
	"tuple",
	"sandaiyi",
	"sandaiyidui",
	"feiji_budai",
	"feiji_daidan",
	"feiji_daidui",
	"liandui",
	"shunzi",
	"sidaier",
	"sidailiangdui",
	"zhadan",
	"wangzha"
}

local function C(card)
	return card>>4
end

local function V(card)
	return card&0x0f
end

local function successive(list)
	assert(#list > 1)
	for i=2,#list do
		if list[i] ~= list[i-1] + 1 then
			return false
		end
	end
	return true
end

local function between(n, mix, max)
	return mix <= n and n <= max
end


-----------------------------------------------------------------
util.TYPE = TYPE
util.value = V
util.color = C

function util.one_deck_cards()
	return {
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d,
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d,
		0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d,
		0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d,
		0x5e, 0x5f
	}
end

function util.shuffle(cards)
	return table.randsort(cards)
end


local function cards_count(cards)
	local count = {}			-- value: count
	local maxc = 0 				-- max count 
	local maxc_values = {} 		-- 达到maxc 的 value list

	for _,card in ipairs(cards) do
		local v = V(card)
		count[v] = (count[v] or 0) + 1
		if maxc < count[v] then
			maxc = count[v]
		end
	end

	for v,c in pairs(count) do
		if c == maxc then
			maxc_values[#maxc_values+1] = v
		end
	end

	table.sort(maxc_values, function (a, b)
		return a < b
	end)
	
	return count, maxc, maxc_values
end

local function find_first(cc)
	for i=1,0xf do
		if cc[i] then
			return i
		end
	end
end

local function is_shunzi(cc, len)
	local first_v = find_first(cc)
	if first_v+len-1 > 0xc then
		return false
	end

	for i=1,len do
		if cc[first_v+i-1] ~= 1 then
			return false
		end
	end
	return TYPE.shunzi, first_v, len
end

local function is_liandui(cc, len)
	if len%2 ~= 0 then
		return false
	end
	local n = len//2
	local first_v = find_first(cc)
	if first_v+n-1 > 0xc then
		return false
	end

	for i=1,n do
		if cc[first_v+i-1] ~= 2 then
			return false
		end
	end
	return TYPE.liandui, first_v, n
end

local function is_sandaiyidui(cc, maxc_values)
	for v,n in pairs(cc) do
		if n == 2 then
			return TYPE.sidailiangdui, maxc_values[1]
		end
	end
end

local function is_feiji_budai(cc, maxc_values, len)
	local n = len//3
	if len%3 == 0 and n == #maxc_values then
		if successive(maxc_values) then
			return TYPE.feiji_budai, maxc_values[1], n
		end
	end
end

local function is_feiji_daidan(cc, maxc_values, len)
	if len%4 ~= 0 then
		return
	end

	local n = len//4
	assert(n >= 2)

	local function find_first()
		for v=1,0xb do
			if cc[v] and cc[v] >= 3 then
				return v
			end
		end
	end

	local first_v = find_first()
	if first_v then
		for v=first_v+1,first_v+n-1 do
			if not cc[v] or cc[v] < 3 then
				return
			end
		end
	end

	return TYPE.feiji_daidan, first_v, n
end

local function is_feiji_daidui(cc, maxc_values, len)
	if len%5 ~= 0 then
		return
	end

	local n = len//5
	if n == #maxc_values and successive(maxc_values) then
		local main = {}
		for i,v in ipairs(maxc_values) do
			main[v] = true
		end

		for v,n in pairs(cc) do
			if not main[v] and n ~= 2 then
				return false
			end
		end

		return TYPE.feiji_daidui, maxc_values[1], n
	end
end

local feiji_funcs = {
	is_feiji_budai,
	is_feiji_daidan,
	is_feiji_daidui
}

local function is_feiji(cc, maxc_values, len)
	for i,f in ipairs(feiji_funcs) do
		local t, w, l = f(cc, maxc_values, len)
		if t then
			return t, w, l
		end
	end
end

local function over4type(cards, len)
	local cc, maxc, maxc_values = cards_count(cards)
	if maxc == 4 then 		-- 四带二, 四带两队
		if len == 6 then
			return TYPE.sidaier, maxc_values[1]
		elseif len == 8 and #maxc_values == 1 then
			for v,n in pairs(cc) do
				if v ~= maxc_values[1] and n ~= 2 then
					goto check_feiji
				end
			end
			return TYPE.sidailiangdui, maxc_values[1]
		end
		::check_feiji::
		return is_feiji(cc, maxc_values, len)
	elseif maxc == 3 then 	-- 三带一对, 飞机不带, 飞机带单, 飞机带对
		if len == 5 then
			return is_sandaiyidui(cc, maxc_values)
		else
			return is_feiji(cc, maxc_values, len)
		end
	elseif maxc == 2 then
		return is_liandui(cc, len)
	else
		assert(maxc == 1)
		return is_shunzi(cc, len)
	end
end


function util.gt(cards, cards2)
	local t1, w1, len1 = util.type(cards)
	local t2, w2, len2 = util.type(cards2)

	if t1 == TYPE.wangzha then
		return true
	end

	if t2 == TYPE.wangzha then
		return false
	end

	if t1 == TYPE.zhadan and t2 == TYPE.zhadan then
		return w1 > w2
	end

	if t1 == TYPE.zhadan then
		return true
	end

	if t2 == TYPE.zhadan then
		return false
	end

	if t1 == t2 then
		return len1 == len2 and w1 > w2
	end
end

-------------------------------------------------
local display = {}

local function display_sorter(a, b)
	local v1 = V(a)
	local v2 = V(b)

	if v1 == v2 then
		return C(a) < C(b)
	else
		return v1 > v2
	end
end

local function color_sorter(a, b)
	return C(a) < C(b)
end


function display.sandaiyi(cards, w, l)
	local main = {}
	local other = {}

	for i,card in ipairs(cards) do
		if V(card) == w then
			table.insert(main, card)
		else
			table.insert(other, card)
		end
	end

	table.sort(main, color_sorter)
	table.sort(other, display_sorter)

	for i,v in ipairs(other) do
		table.insert(main, v)
	end

	return main
end

function display.feiji_daidan(cards, w, l)
	local main = {}
	local other = {}

	local tmp = {}

	for i,card in ipairs(cards) do
		local v = V(card)
		if between(v, w, w+l-1) and tmp[v] ~= 3 then
			tmp[v] = (tmp[v] or 0) + 1
			table.insert(main, card)
		else
			table.insert(other, card)
		end
	end

	table.sort(main, display_sorter)
	table.sort(other, display_sorter)

	for i,v in ipairs(other) do
		table.insert(main, v)
	end

	return main
end

display.sandaiyidui 	= display.sandaiyi
display.sidaier 		= display.sandaiyi
display.sidailiangdui 	= display.sandaiyi

display.feiji_daidui 	= display.feiji_daidan

function util.display_cards(cards)
	local t, w, l = util.type(cards)
	assert(t, "invalid cards, no type")

	local f = display[t]
	if f then
		return f(cards, w, l)
	else
		local r = {}
		for i,v in ipairs(cards) do
			r[i] = v
		end
		table.sort(r, display_sorter)
		return r
	end
end


function util.type(_cards)
	local cards = {}
	for i,v in ipairs(_cards) do
		cards[i] = v
	end
	table.sort(cards, function (a, b)
		return V(a) < V(b)
	end)

	local len = #cards
	if len == 1 then
		return TYPE.dan, V(cards[1])
	elseif len == 2 then
		local v1 = V(cards[1])
		local v2 = V(cards[2])
		if v1 == v2 then
			return TYPE.dui, v1
		else
			if v1 == 0xe and v2 == 0xf then
				return TYPE.wangzha
			end
		end
	elseif len == 3 then
		local v1 = V(cards[1])
		local v2 = V(cards[2])
		local v3 = V(cards[3])
		if v1 == v2 and v2 == v3 then
			return TYPE.tuple, v1
		end
	elseif len == 4 then
		local v1 = V(cards[1])
		local v2 = V(cards[2])
		local v3 = V(cards[3])
		local v4 = V(cards[4])

		if v2 == v3 then
			if v1 == v2 then
				if v3 == v4 then
					return TYPE.zhadan, v1
				else
					return TYPE.sandaiyi, v1
				end
			else
				if v3 == v4 then
					return TYPE.sandaiyi, v2
				end
			end
		end
	else
		return over4type(cards, len)
	end
end


return util