local util = {}

local TYPE = {
	dan = 1,
	dui = 2,
	tuple = 3,
	sandaiyi = 4,
	sandaiyidui = 5,
	feiji = 6,
	liandui = 7,
	shunzi = 8,
	sidaier = 9,
	sidailiangdui = 10,
	zhadan = 11,
	wangzha = 12
}

local function C(card)
	return card>>4
end

local function V(card)
	return card&0x0f
end


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

local function over4type(cards, len)
	local cc, maxc, maxc_values = cards_count(cards)
	if maxc == 4 then 		-- 四带二, 四带两队
		if len == 6 then
			return TYPE.sidaier, maxc_values[1]
		elseif len == 8 then
			-- TODO
		end
	elseif maxc == 3 then 	-- 三带一对, 飞机不带, 飞机带单, 飞机带对

	elseif maxc == 2 then
		return is_liandui(cc, len)
	else
		assert(maxc == 1)
		return is_shunzi(cc, len)
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
			if (v1 == 0x5e and v2 == 0x5f) or (v1 == 0x5f and v2 == 0x5e) then
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