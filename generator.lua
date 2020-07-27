--[[
	generator.lua

	Provides logic for spawning tiles and structures in the level.
]]

require("level")
require("random")
require("structures")

--[[
	Generator

	The base generator. Generators act on a section of the level by selecting and
	building structures; these may be a specific set of structures, or randomly chosen,
	depending on the subclass's generate() function.

	Generators have a set of palettes and choices of tiles, but each generator may use
	them for different things; some palettes/tiles may not be used at all. For best results and
	consistency across the whole level, set the palettes and tiles on the base generator class,
	before using specific generators throughout the level.
]]

Generator = {
	-- Size
	width = 0,
	height = 0,

	-- Palettes
	groundPalette = 0,
	blockPalette = 0,
	plantPalette = 0,
	pipePalette = 0,
	weatherPalette = 0,

	-- Tiles
	groundTile = 0,
	blockTile = 0,
	altBrick = false,
	altSkyBridge = false,
	altTreetop = false,
	altTreetopBase = false,
	altBackgroundTree = false
}

function Generator:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Given a cursor to the top left of the section, randomly generates structures within
-- that section. All logic is subclass-specific; the base class generates nothing.
function Generator:generate(topleft)
	-- Do nothing
end

ChaosGenerator = Generator:new({world = 1, level = 1})
function ChaosGenerator:generate(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local chaosTable = WeightedRandomSelector:new()
	local width, height

	-- Calculate chaos levels based on the current world
	local chaos = self.world
	local inverseChaos = WORLDS - self.world + 1
	local halfChaos = math.ceil(self.world / 2)
	local inverseHalfChaos = math.ceil((WORLDS - self.world + 1) / 2)

	-- Define a list of elements to potentially build

	-- Ceiling
	for i = 1, 2 do
		height = math.random(5)
		width = self.width - diminishingRandom(self.width - 10) - chaos
		chaosTable:add({RectangleStructure:new({
			width = width,
			height = height,
			palette = self.groundPalette,
			tile = self.groundTile
		}), i == 2 and self.width - width or 0, 2}, self.level ^ 2 * 2)
	end

	-- Floor
	for i = 1, 2 do
		height = math.random(5)
		width = self.width - diminishingRandom(self.width - 10) - chaos
		chaosTable:add({RectangleStructure:new({
			width = width,
			height = height,
			palette = self.groundPalette,
			tile = self.groundTile
		}), i == 2 and self.width - width or 0, self.height - height}, inverseChaos * 8)
	end

	-- Stairs
	width = math.random(2, 2 + halfChaos)
	height = math.random(2, width)
	chaosTable:add({StairStructure:new({
		width = width,
		height = height,
		palette = self.blockPalette,
		tile = self.blockTile,
		openCorner = skewedRandom(4, halfChaos)
	}), math.random(self.width - width) - 1, math.random(self.height - height) - 1}, WORLDS * 4)

	-- Pits
	for i = 1, chaos do
		chaosTable:add({ColumnStructure:new({
			height = self.height,
			palette = 0,
			tile = BLANK
		}), math.random() - 1, 0}, chaos)
	end

	-- Vertical pipes
	for i = 1, inverseHalfChaos do
		height = skewedRandom(3, 6 - self.level + chaos, 3)
		chaosTable:add({VerticalPipeStructure:new({
			height = height,
			palette = self.plantPalette,
			active = coinflip(0.1 * chaos)
		}), math.random(self.width - 2) - 1, math.random(self.height - height) - 1}, 5 - self.level)
	end

	-- Horizontal pipes
	for i = 1, inverseHalfChaos do
		width = skewedRandom(3, 6 - self.level + chaos, 3)
		chaosTable:add({HorizontalPipeStructure:new({
			width = width,
			palette = self.plantPalette
		}), math.random(self.width - width) - 1, math.random(self.height - 2) - 1}, 5 - self.level)
	end

	-- Blasters
	for i = 1, inverseHalfChaos do
		height = math.random(2, math.ceil(self.height / 2) - self.level)
		chaosTable:add({BlasterStructure:new({
			height = height,
			palette = self.blockPalette,
			active = coinflip(0.1 * chaos)
		}), math.random(self.width) - 1, math.random(self.height - height) - 1}, chaos * 2)
	end

	-- Cloud platforms
	for i = 1, inverseHalfChaos do
		width = math.random(2, math.ceil(self.width / 2) - self.level)
		chaosTable:add({CloudPlatformStructure:new({
			width = width,
			palette = self.weatherPalette
		}), math.random(self.width - width) - 1, math.random(self.height) - 1}, chaos * 2)
	end

	-- Treetops platforms
	for i = 1, halfChaos do
		width = math.random(3, 10)
		height = math.random(3, 10)
		chaosTable:add({TreetopsStructure:new({
			width = width,
			height = height,
			basePalette = self.blockPalette,
			treePalette = self.plantPalette,
			altBase = self.altTreetopBase,
			altTree = self.altTreetop
		}), math.random(self.width - width) - 1, self.height - height}, inverseHalfChaos)
	end

	-- Mushroom platforms
	for i = 1, inverseHalfChaos do
		width = math.random(3, 10)
		height = math.random(3, 10)
		chaosTable:add({MushroomStructure:new({
			width = width,
			height = height,
			basePalette = self.blockPalette,
			mushroomPalette = self.plantPalette
		}), math.random(self.width - width) - 1, self.height - height}, halfChaos)
	end

	-- Sky bridges
	for i = 1, inverseHalfChaos do
		width = math.random(3, 10)
		chaosTable:add({SkyBridgeStructure:new({
			width = width,
			height = 2,
			basePalette = self.blockPalette,
			ropePalette = self.plantPalette,
			altBridge = self.altSkyBridge
		}), math.random(self.width - width) - 1, math.random(self.height - height) - 1}, halfChaos)
	end

	-- Castle bridges
	for i = 1, halfChaos do
		width = math.random(3, 10)
		height = math.random(width)
		chaosTable:add({CastleBridgeStructure:new({
			width = width,
			height = height,
			palette = self.pipePalette
		}), math.random(self.width - width) - 1, math.random(self.height - height) - 1}, inverseHalfChaos)
	end

	-- Flagpoles
	for i = 1, halfChaos * 2 do
		height = skewedRandom(3, 10, 2 + inverseChaos)
		chaosTable:add({FlagpoleStructure:new({
			height = height,
			basePalette = self.blockPalette,
			polePalette = self.pipePalette,
			blockTile = self.blockTile
		}), math.random(self.width) - 1, math.random(self.height - height) - 1}, inverseHalfChaos * 2)
	end

	-- Hills
	height = math.random(4, 4 + halfChaos)
	chaosTable:add({HillStructure:new({
		height = height,
		palette = self.plantPalette
	}), skewedRandom(self.width, math.ceil(self.width / 2)) - 1, self.height - height}, inverseHalfChaos * 4)

	-- Bushes
	for i = 1, 2 do
		width = skewedRandom(3, 3 + halfChaos, 3)
		chaosTable:add({BushStructure:new({
			width = width,
			palette = self.plantPalette
		}), math.random(self.width - width) - 1, skewedRandom(math.ceil(self.height / 2), self.height, math.ceil(self.height * 3 / 4)) - 1}, (LEVELS - self.level + 1) * 2)
	end

	-- Background clouds
	for i = 1, 2 do
		width = skewedRandom(3, 3 + halfChaos, 3)
		chaosTable:add({CloudStructure:new({
			width = width,
			palette = self.weatherPalette
		}), math.random(self.width - width) - 1, skewedRandom(math.ceil(self.height / 2), math.ceil(self.height / 4)) - 1}, (LEVELS - self.level + 1) * 2)
	end

	-- Trees
	for i = 1, 4 do
		height = skewedRandom(2, 4, 2)
		chaosTable:add({TreeStructure:new({
			height = height,
			treePalette = self.plantPalette,
			trunkPalette = self.blockPalette,
			altTree = self.altTree
		}), math.random(self.width) - 1, skewedRandom(self.height - height, self.height - height)}, inverseChaos * 2)
	end

	-- Fences
	for i = 1, 2 do
		width = math.random(halfChaos + 1, chaos + 2)
		chaosTable:add({RowStructure:new({
			width = width,
			palette = self.blockPalette,
			tile = FENCE
		}), math.random(self.width - width) - 1, skewedRandom(self.height, math.ceil(self.height * 3 / 4)) - 1}, WORLDS / 2)
	end

	-- Rows of coins
	for i = 1, 2 do
		width = math.random(inverseHalfChaos, inverseChaos + 1)
		chaosTable:add({RowStructure:new({
			width = width,
			palette = 0,
			tile = COIN
		}), math.random(self.width - width) - 1, math.random(self.height) - 2}, inverseChaos)
	end

	-- Groups of coins
	height = math.random(2, 3)
	width = math.random(inverseHalfChaos, inverseChaos + 1)
	chaosTable:add({CheckerboardStructure:new({
		width = width,
		height = height,
		palette = 0,
		tile = COIN,
		startWithTile = height % 2 ~= 0
	}), math.random(self.width - width) - 1, math.random(self.height) - 2}, inverseHalfChaos)

	-- Build several of the elements in a random order
	local structuresToBuild = math.random (CHUNK_SIZE, CHUNK_SIZE + chaos * 2)
	for i = 1, structuresToBuild do
		selected = chaosTable:select()
		cursor:move(selected[2], selected[3])
		selected[1]:build(cursor)
		cursor.cell = topleft.cell
	end
end

DistortionGenerator = Generator:new({world = 1, level = 1, cosmetic = false})
function DistortionGenerator:generate(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local distortions = math.random(self.world * self.level, math.ceil(CHUNK_SIZE / 4) * self.world * self.level)
	local palettes = WeightedRandomSelector:new()
	palettes:add(self.groundPalette)
	palettes:add(self.blockPalette)
	palettes:add(self.plantPalette)
	palettes:add(self.pipePalette)
	palettes:add(self.weatherPalette)

	for i = 1, distortions do
		-- Move to a random cell
		cursor:move(math.random(0, self.width), math.random(0, self.height))

		-- Set the range of tiles to select from. If distortions are set to cosmetic, then
		-- the tile's collision cannot change, and the range is adjusted accordingly.
		local minTile = 1
		local maxTile = TILES_PER_PALETTE
		if self.cosmetic and cursor.cell:solid() then
			maxTile = LAST_SOLID_TILE
		elseif self.cosmetic then
			minTile = LAST_SOLID_TILE + 1
		end

		-- Set the cell to a random tile (preserving palette if there is one,
		-- or selecting a random palette as well if there is not)
		cursor.cell:setTileByPalette(
			math.random(minTile, maxTile),
			cursor.cell.palette > 0 and cursor.cell.palette or palettes:select()
		)

		-- Reset cursor location for next distortion
		cursor.cell = topleft.cell
	end
end

LevelEndGenerator = Generator:new()
function LevelEndGenerator:generate(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	-- Ensure that nothing can get in the way of the end of the level
	cursor:move(1, 0)
	local clear = RectangleStructure:new({
		width = 3,
		height = self.height,
		tile = 1
	})
	clear:build(cursor, BLANK)

	-- Start from the top of the flagpole
	cursor:move(-1, self.height - 13)
	local flagpole = FlagpoleStructure:new({
		height = 11,
		basePalette = self.blockPalette,
		polePalette = self.plantPalette,
		active = true
	})
	flagpole:build(cursor)

	cursor:move(0, 11)
	local ground = RectangleStructure:new({
		width = self.width,
		height = 2,
		palette = self.groundPalette,
		tile = self.groundTile
	})
	ground:build(cursor, self.groundTile, true)

	cursor:move(4, -5)
	local castle = CastleStructure:new({
		palette = self.blockPalette,
		altBrick = self.altBrick
	})
	castle:build(cursor)
end
