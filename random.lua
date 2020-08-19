--[[
	random.lua

	Provides functions and classes for certain kinds of random number generation.
]]

-- Returns true or false at random. Accepts an optional weight between 0 and 1; higher
-- values are more likely to return true. When no weight is given, it's a 50/50 chance.
function coinflip(weight)
	local weight = weight or 0.5
	return MT:random() < weight
end

-- Sequentially attempts a 1 / max chance of returning 1, 2 / max chance of returning 2...
-- Most likely to return something around max / 3, extremely unlikely to return max.
function diminishingRandom(max)
	if max < 1 then return max end
	local result = 1
	while MT:random() > result / max do
		result = result + 1
	end
	return result
end

-- Two arguments: picks a random number between 1 and a, skewed toward b.
-- Three arguments: picks a random number between a and b, skewed toward c.
-- The skew applied is linear; neighboring values are also pretty likely to be chosen.
function skewedRandom(a, b, c)
	-- Sort arguments
	local lower = c and a or 1
	local upper = c and b or a
	local skew = c and c or b

	assert(lower <= upper, "skewedRandom(): Interval is empty")
	assert(lower <= skew and skew <= upper, "skewedRandom(): Skew is out of range")
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

-- Shuffles the elements of a table using the Fisher-Yates algorithm.
-- https://www.programming-idioms.org/idiom/10/shuffle-a-list/2019/lua
function shuffle(table)
	for i = #table, 2, -1 do
		local j = MT:random(i)
		table[i], table[j] = table[j], table[i]
	end
end

--[[
	WeightedRandomSelector

	A specialized table for random selection where each entry has a certain weight.
	The higher the weight compared to other entries, the more likely it is to be
	selected; a value with a weight of 6 is twice as likely to be selected as a value
	with a weight of 3. Weights are expressed as whole numbers.
]]

WeightedRandomSelector = {
	-- Tracks the total weight of all entries, used when selecting a value
	totalWeight = 0
}

function WeightedRandomSelector:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Adds a new value with a certain weight. If no weight is given, a weight of 1 is applied.
function WeightedRandomSelector:add(value, weight)
	local weight = weight or 1
	table.insert(self, {
		value = value,
		weight = weight
	})
	self.totalWeight = self.totalWeight + weight
end

-- Selects and returns a value at random, based on the weights given for each.
function WeightedRandomSelector:select()
	-- Select a random value out of the total weight
	local selected = MT:random(self.totalWeight)

	-- Count the weight of each entry up to the selected value
	local iteratedWeight = 0
	for i, v in ipairs(self) do
		iteratedWeight = iteratedWeight + v.weight
		if selected <= iteratedWeight then
			return v.value
		end
	end
end
