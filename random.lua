--[[
	random.lua

	Provides functions and classes for certain kinds of random number generation.
]]

-- Returns true or false at random.
function coinflip(weight)
	local weight = weight or 0.5
	return math.random() < weight
end

-- Attempts a 1 / max chance of returning 1, 2 / max chance of returning 2, etc.
-- Most likely to return something around max / 3, extremely unlikely to return max.
function diminishingRandom(max)
	if max < 1 then return max end
	local result = 1
	while math.random() > result / max do
		result = result + 1
	end
	return result
end

-- Two arguments: picks a random number between 1 and a, skewed toward b.
-- Three arguments: picks a random number between a and b, skewed toward c.
function skewedRandom(a, b, c)
	-- Sort arguments
	local lower = c and a or 1
	local upper = c and b or a
	local skew = c and c or b

	assert (lower <= upper, "skewedRandom(): Interval is empty")
	assert (lower <= skew and skew <= upper, "skewedRandom(): Skew is out of range")
	if lower == upper then return upper end

	local selector = WeightedRandomSelector:new()
	local max = math.max(upper - skew, skew - lower)
	for i = max, 1, -1 do
		j = max - i

		if j > 0 then
			if skew + j <= upper then
				selector:add(skew + j, i)
			end
			if skew - j >= lower then
				selector:add(skew - j, i)
			end
		else	-- First step
			selector:add(skew, i)
		end
	end

	return selector:select()
end

-- Shuffles the elements of a table.
-- https://www.programming-idioms.org/idiom/10/shuffle-a-list/2019/lua
function shuffle(table)
	for i = #table, 2, -1 do
		local j = math.random(i)
		table[i], table[j] = table[j], table[i]
	end
end

--[[
	WeightedRandomSelector

	A specialized table for random selection where each entry has a certain weight.
	The higher the weight compared to other entries, the more likely it is to be
	selected. Weight is expressed as a whole number.
]]

WeightedRandomSelector = {
	totalWeight = 0
}

function WeightedRandomSelector:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function WeightedRandomSelector:add(value, weight)
	local weight = weight or 1
	table.insert(self, {
		value = value,
		weight = weight
	})
	self.totalWeight = self.totalWeight + weight
end

function WeightedRandomSelector:select()
	local selected = math.random(self.totalWeight)
	local iteratedWeight = 0
	for i, v in ipairs(self) do
		iteratedWeight = iteratedWeight + v.weight
		if selected <= iteratedWeight then
			return v.value
		end
	end
end
