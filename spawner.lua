--[[
	spawner.lua

	Provides logic for spawning entities in the level.
]]

require("entities")
require("level")

--[[
	Spawner

	The base spawner. Really just exists to ensure that each spawner is a class
	and has a generate function.
]]

Spawner = {
	width = 0,
	height = 0
}

function Spawner:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Given a cursor to the top left of the section, generates entities within that section.
-- All logic is subclass-specific; the base class does nothing.
function Spawner:generate(topleft)
	-- Do nothing
end

--[[
	StartSpawner

	Spawns the starting location by checking for the first instance of tiles with collision.
]]

StartSpawner = Spawner:new()
-- Checks each column from the bottom up to find a start position on a nonsolid tile
-- over a solid tile. Prioritizes columns 3, 4, and 5.
function StartSpawner:generate(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Place the spawn entity and clear out all surrounding entities (such as enemies)
	local function placeSpawn(center)
		local topleft = Cursor:new({cell = center.cell})
		topleft:move(-4, -4)
		local cursor = Cursor:new({cell = topleft.cell})
		for col = 1, 9 do
			cursor:move(0, col - 1)
			for row = 1, 9 do
				cursor.cell.entity = nil
				cursor:move(1, 0)
			end
			cursor.cell = topleft.cell
		end
		center.cell.entity = SPAWN
	end

	-- Go from the top down in each column until we find a nonsolid tile
	-- above a solid tile
	local function checkColumn()
		for row = 1, self.height - 2 do
			if cursor.cell:nonsolidAboveSolid() and cursor.cell.right:nonsolidAboveSolid() then
				placeSpawn(cursor)
				return true
			end
			cursor:move(0, 1)
		end
		return false
	end

	-- Start at the top of each column and search in priority order
	cursor:move(2, 2)					-- Column 3
	if checkColumn() then return true end
	cursor:move(1, 3 - self.height)		-- Column 4
	if checkColumn() then return true end
	cursor:move(1, 3 - self.height)		-- Column 5
	if checkColumn() then return true end
	cursor:move(-3, 3 - self.height)	-- Column 2
	if checkColumn() then return true end
	cursor:move(-1, 3 - self.height)	-- Column 1
	if checkColumn() then return true end

	cursor:move(5, 3 - self.height)

	for col = 6, self.width - 1 do
		if checkColumn() then return true end
		cursor:move(1, 3 - self.height)
	end

	-- If that didn't work, search along the top two rows of blocks
	local function checkRow()
		for col = 1, self.width do
			if cursor.cell:nonsolidAboveSolid() and cursor.cell.right:nonsolidAboveSolid() then
				placeSpawn(cursor)
				return true
			end
			cursor:move(1, 0)
		end
		return false
	end

	cursor.cell = topleft.cell.down		-- Second from top row
	if checkRow() then return true end
	cursor.cell = topleft.cell			-- Top row
	if checkRow() then return true end

	return false
end

ChaosSpawner = Spawner:new({world = 0, level = 0})
function ChaosSpawner:generate(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Determine how many enemies will be placed in this section
	local enemies = skewedRandom(self.world + 1, math.ceil(self.world / 2) + 1) - 1
	if enemies < 1 then
		return
	end

	-- Shuffle the columns of this section
	local columns = {}
	for i = 1, WORLDS do
		columns[i] = i
	end
	shuffle(columns)

	for i = 1, enemies do
		-- Move the cursor to some column (from the shuffled list)
		cursor:move(columns[i] - 1, 2)

		-- Scan this column for the number of open spaces to place enemies
		local locations = {}
		while not cursor:atBottommost() do
			cursor:move(0, 1)
			if cursor.cell:nonsolidAboveSolid() then
				table.insert(locations, cursor.cell)
			end
		end

		-- If there are no open locations, then there is no floor
		if #locations == 0 then
			-- Pick a random location in the air
			cursor:move(0, -math.random(0, self.height - 2))

			-- Select enemy based on level type
			if self.level == 2 then -- Underground/underwater
				local enemyPalette = WeightedRandomSelector:new()
				enemyPalette:add(CHEEPRED, 2)
				enemyPalette:add(CHEEPWHITE, 2)
				enemyPalette:add(SQUID, 1)
				cursor.cell.entity = enemyPalette:select()
			elseif self.level == LEVELS then -- Castle
				cursor.cell.entity = UPFIRE
			else -- Overworld
				cursor.cell.entity = KOOPAREDFLYING
			end
		-- Otherwise, there is at least one position to place an enemy
		else
			local enemyPalette = WeightedRandomSelector:new()
			enemyPalette:add(GOOMBA, WORLDS - self.world)
			enemyPalette:add(KOOPA, math.ceil(WORLDS / 2))
			enemyPalette:add(KOOPARED, math.ceil(WORLDS / 2))
			enemyPalette:add(BEETLE, self.world)
			enemyPalette:add(SPIKEY, math.ceil(self.world / 2))
			-- Mix in a hammerbro if there's another platform for it to jump to
			if #locations > 1 then
				enemyPalette:add(HAMMERBRO, math.ceil(self.world / 2))
			-- Mix in a koopaflying if there's enough space for it to jump around
			else
				enemyPalette:add(KOOPAFLYING, math.ceil(WORLDS / 2))
			end

			-- Place a randomly selected enemy in a randomly selected open position
			local location = #locations > 1 and math.random(#locations) or 1
			locations[location].entity = enemyPalette:select()
		end

		-- Reset cursor for next enemy
		cursor.cell = topleft.cell
	end
end
