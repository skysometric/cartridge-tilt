--[[
	random.lua

	Provides functions and classes for certain kinds of random number generation.
]]

-- Returns true or false at random.
function coinflip(weight)
	local weight = weight or 0.5
	return math.random() < weight
end

-- Returns max at most, but is more likely to return something closer to max / 2.
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

WeightedRandomSelector = {}

function WeightedRandomSelector:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function WeightedRandomSelector:add(value, weight)
	local weight = weight or 1
	for i = 1, weight do
		table.insert(self, value)
	end
end

function WeightedRandomSelector:select()
	return self[math.random(#self)]
end
