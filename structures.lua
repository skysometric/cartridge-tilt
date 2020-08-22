--[[
	level.lua

	Provides level structures used by the generator to build maps.
]]

--[[
	Structure

	The base structure. Really just exists to ensure that each structure is a class and
	has a build function.
]]

Structure = {
	width = 0,
	height = 0,
	palette = 0
}

function Structure:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Given a cursor to the top left of the section, builds a structure of tiles within that
-- section. All logic is subclass-specific; the base class does nothing.
function Structure:build(topleft)
	-- Do nothing
end

--[[
	BASIC STRUCTURES

	Structures that can be built with any tile.
]]

RowStructure = Structure:new({height = 1, tile = 1})
function RowStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	for w = 1, self.width do
		cursor.cell:setTileByPalette(self.tile, self.palette)
		cursor:move(1, 0)
	end
end

ColumnStructure = Structure:new({width = 1, tile = 1})
function ColumnStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	for h = 1, self.height do
		cursor.cell:setTileByPalette(self.tile, self.palette)
		cursor:move(0, 1)
	end
end

RectangleStructure = Structure:new({tile = 1})
function RectangleStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = self.tile
	})

	for h = 1, self.height do
		row:build(cursor)
		cursor:move(0, 1)
	end
end

-- Open corner is a numbered corner starting from top left, going clockwise
StairStructure = Structure:new({tile = 0, openCorner = 1})
function StairStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = self.tile
	})

	-- Select a corner and set up the loop step
	local hstep, vstep = 0, 1
	if self.openCorner == 1 then -- top left
		cursor:move(0, self.height - 1)
		hstep = 1
		vstep = -1
	elseif self.openCorner == 2 then -- top right
		cursor:move(0, self.height - 1)
		hstep = 0
		vstep = -1
	elseif self.openCorner == 3 then -- bottom left
		hstep = 1
		vstep = 1
	else -- bottom right or invalid value
		hstep = 0
		vstep = 1
	end

	for h = 1, self.height do
		row:build(cursor)
		row.width = row.width - 1
		cursor:move(hstep, vstep)
	end
end

-- Creates a checkerboard pattern of tiles. Most useful for coins.
CheckerboardStructure = Structure:new({tile = COIN, startWithTile = true})
function CheckerboardStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local rowStart = Cursor:new({cell = cursor.cell})
	local rowStartsWithTile = self.startWithTile

	for row = 1, self.height do
		local start = 1
		if not rowStartsWithTile then
			start = 2
			cursor:move(1, 0)
		end
		for col = start, self.width, 2 do
			cursor.cell:setTileByPalette(self.tile, self.palette)
			cursor:move(2, 0)
		end
		rowStartsWithTile = not rowStartsWithTile
		rowStart:move(0, 1)
		cursor.cell = rowStart.cell
	end
end

--[[
	SOLID STRUCTURES

	Specialized structures with entirely solid tiles.
]]

VerticalPipeStructure = Structure:new({width = 2, active = false})
function VerticalPipeStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Left side
	local column = ColumnStructure:new({
		height = self.height,
		palette = self.palette,
		tile = VERTICAL_PIPE_LEFT_BASE
	})
	column:build(cursor)

	-- Right side
	cursor:move(1, 0)
	column.tile = VERTICAL_PIPE_RIGHT_BASE
	column:build(cursor)

	-- Ends
	if cursor.cell.up and not cursor.cell.up:solid() and
	   cursor.cell.up.left and not cursor.cell.up.left:solid() then
		cursor.cell:setTileByPalette(VERTICAL_PIPE_RIGHT_SPOUT, self.palette)
		cursor.cell.left:setTileByPalette(VERTICAL_PIPE_LEFT_SPOUT, self.palette)

		if self.active then
			cursor.cell.up.left.entity = PLANT
		end
	end
	cursor:move(0, self.height - 1)
	if cursor.cell.down and not cursor.cell.down:solid() and
	   cursor.cell.down.left and not cursor.cell.down.left:solid() then
		cursor.cell:setTileByPalette(VERTICAL_PIPE_RIGHT_SPOUT, self.palette)
		cursor.cell.left:setTileByPalette(VERTICAL_PIPE_LEFT_SPOUT, self.palette)
	end
end

HorizontalPipeStructure = Structure:new({height = 2})
function HorizontalPipeStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Left side
	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = HORIZONTAL_PIPE_UPPER_BASE
	})
	row:build(cursor)

	-- Right side
	cursor:move(0, 1)
	row.tile = HORIZONTAL_PIPE_LOWER_BASE
	row:build(cursor)

	-- Ends
	if cursor.cell.left and not cursor.cell.left:solid() and
	   cursor.cell.left.up and not cursor.cell.left.up:solid() then
		cursor.cell:setTileByPalette(HORIZONTAL_PIPE_LOWER_SPOUT, self.palette)
		cursor.cell.up:setTileByPalette(HORIZONTAL_PIPE_UPPER_SPOUT, self.palette)
	end
	cursor:move(self.width - 1, 0)
	if cursor.cell.right and not cursor.cell.right:solid() and
	   cursor.cell.right.up and not cursor.cell.right.up:solid() then
		cursor.cell:setTileByPalette(HORIZONTAL_PIPE_LOWER_SPOUT, self.palette)
		cursor.cell.up:setTileByPalette(HORIZONTAL_PIPE_UPPER_SPOUT, self.palette)
	end
end

BlasterStructure = Structure:new({width = 1, active = false})
function BlasterStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local column = ColumnStructure:new({
		height = self.height,
		palette = self.palette,
		tile = BLASTER_BASE
	})
	column:build(cursor)

	cursor.cell:setTileByPalette(BLASTER_TOP, self.palette)
	if self.active then
		cursor.cell.entity = BULLETBILL
	end

	cursor:move(0, 1)
	cursor.cell:setTileByPalette(BLASTER_MOUNT, self.palette)
end

CloudPlatformStructure = Structure:new({height = 1})
function CloudPlatformStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = CLOUD_PLATFORM_CENTER
	})
	row:build(cursor)

	cursor.cell:setTileByPalette(CLOUD_PLATFORM_LEFT, self.palette)
	cursor:move(self.width - 1, 0)
	cursor.cell:setTileByPalette(CLOUD_PLATFORM_RIGHT, self.palette)
end

--[[
	SEMISOLID STRUCTURES

	Specialized structures with some solid and nonsolid tiles.
]]

TreetopsStructure = Structure:new({
	treePalette = 0, basePalette = 0, altTree = false, altBase = false})
function TreetopsStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Base of the tree
	local baseOffset = self.altBase and TREETOPS_BASE_ALT_OFFSET or 0
	local base = RectangleStructure:new({
		width = self.width - 2,
		height = self.height,
		palette = self.basePalette,
		tile = TREETOPS_BASE + baseOffset
	})

	-- Top of the tree
	local treeOffset = self.altTree and TREETOPS_ALT_OFFSET or 0
	local tree = RowStructure:new({
		width = self.width,
		palette = self.treePalette,
		tile = TREETOPS_CENTER + treeOffset
	})

	-- Build the tree
	cursor:move(1, 0)
	base:build(cursor)
	cursor:move(-1, 0)
	tree:build(cursor)
	cursor.cell:setTileByPalette(TREETOPS_LEFT + treeOffset, self.treePalette)
	cursor:move(self.width - 1, 0)
	cursor.cell:setTileByPalette(TREETOPS_RIGHT + treeOffset, self.treePalette)
end

MushroomStructure = Structure:new({basePalette = 0, mushroomPalette = 0})
function MushroomStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Stalk
	cursor:move(math.ceil(self.width / 2) - 1, 0)
	local stalk = ColumnStructure:new({
		height = self.height,
		palette = self.basePalette,
		tile = MUSHROOM_PLATFORM_BASE
	})
	stalk:build(cursor)
	if cursor.cell.down then
		cursor.cell.down:setTileByPalette(MUSHROOM_PLATFORM_STALK, self.basePalette)
	end

	-- Platform
	cursor.cell = topleft.cell
	local platform = RowStructure:new({
		width = self.width,
		palette = self.mushroomPalette,
		tile = MUSHROOM_PLATFORM_CENTER
	})
	platform:build(cursor)

	cursor.cell:setTileByPalette(MUSHROOM_PLATFORM_LEFT, self.mushroomPalette)
	cursor:move(self.width - 1, 0)
	cursor.cell:setTileByPalette(MUSHROOM_PLATFORM_RIGHT, self.mushroomPalette)
end

SkyBridgeStructure = Structure:new({
	basePalette = 0, ropePalette = 0, altBridge = false, blockTile = 0})
function SkyBridgeStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Ropes
	local row = RowStructure:new({
		width = self.width,
		palette = self.ropePalette,
		tile = SKY_BRIDGE_ROPE
	})
	row:build(cursor)

	-- Bridge
	local offset = self.altBridge and SKY_BRIDGE_ALT_OFFSET or 0
	row.palette = self.basePalette
	row.tile = SKY_BRIDGE + offset
	cursor:move(0, self.height > 1 and 1 or 0)
	row:build(cursor)

	-- Supports (if applicable)
	if self.height <= 2 then return end

	local column = ColumnStructure:new({
		height = self.height - 1,
		palette = self.basePalette,
		tile = self.blockTile
	})
	column:build(cursor)
	cursor:move(self.width - 1, 0)
	column:build(cursor)
end

CastleBridgeStructure = Structure:new({active = false})
function CastleBridgeStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	-- Bridge
	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = CASTLE_BRIDGE
	})
	cursor:move(0, self.height - 1)
	row:build(cursor)

	if self.active then
		cursor.cell.entity = BOWSER
	end

	-- Chain
	cursor:move(math.max(self.width - self.height + 1, 0), -1)
	for i = 1, math.min(self.width, self.height - 1) do
		cursor.cell:setTileByPalette(CASTLE_BRIDGE_CHAIN, self.palette)
		cursor:move(1, -1)
	end

	if self.active then
		cursor.cell.entity = AXE
	end
end

FlagpoleStructure = Structure:new({
	width = 1, basePalette = 0, polePalette = 0,
	blockTile = FIRST_BLOCK_TILE, active = false})
function FlagpoleStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local column = ColumnStructure:new({
		height = self.height,
		palette = self.polePalette,
		tile = FLAGPOLE
	})
	column:build(cursor)

	cursor.cell:setTileByPalette(FLAGPOLE_TOP, self.polePalette)
	cursor:move(0, self.height - 1)
	cursor.cell:setTileByPalette(self.blockTile, self.basePalette)
	if self.active then
		cursor.cell.entity = FLAG
	end
end

--[[
	BACKGROUND STRUCTURES

	Specialized structures with no solid tiles.
]]

HillStructure = Structure:new({width = 0})
function HillStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	for row = 1, self.height do
		local width = row * 2 - 1
		for col = 1, width do
			if width == 1 then
				cursor.cell:setTileByPalette(HILL_TOP, self.palette)
			elseif col == 1 then
				cursor.cell:setTileByPalette(HILL_LEFT, self.palette)
			elseif row <= 3 and col == 2 then
				cursor.cell:setTileByPalette(HILL_TREES, self.palette)
			elseif row <= 3 and col == width - 1 then
				cursor.cell:setTileByPalette(
					HILL_TREES + HILL_TREES_ALT_OFFSET, self.palette)
			elseif col == width then
				cursor.cell:setTileByPalette(HILL_RIGHT, self.palette)
			else
				cursor.cell:setTileByPalette(HILL_INSIDE, self.palette)
			end
			cursor:move(1, 0)
		end
		cursor:move(-width - 1, 1)
	end
end

LavaStructure = Structure:new()
function LavaStructure:build(topleft)
	local rect = RectangleStructure:new({
		width = self.width,
		height = self.height,
		palette = self.palette,
		tile = LAVA_CENTER
	})
	rect:build(topleft)

	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = LAVA_TOP
	})
	row:build(topleft)
end

BushStructure = Structure:new({height = 1})
function BushStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = BUSH_CENTER
	})
	row:build(cursor)

	cursor.cell:setTileByPalette(BUSH_LEFT, self.palette)
	cursor:move(self.width - 1, 0)
	cursor.cell:setTileByPalette(BUSH_RIGHT, self.palette)
end

CloudStructure = Structure:new({height = 2})
function CloudStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local row = RowStructure:new({
		width = self.width,
		palette = self.palette,
		tile = CLOUD_UPPER_CENTER
	})
	row:build(cursor)
	cursor:move(0, 1)
	row.tile = CLOUD_LOWER_CENTER
	row:build(cursor)

	cursor.cell:setTileByPalette(CLOUD_LOWER_LEFT, self.palette)
	cursor.cell.up:setTileByPalette(CLOUD_UPPER_LEFT, self.palette)
	cursor:move(self.width - 1, 0)
	cursor.cell:setTileByPalette(CLOUD_LOWER_RIGHT, self.palette)
	cursor.cell.up:setTileByPalette(CLOUD_UPPER_RIGHT, self.palette)
end

TreeStructure = Structure:new({
	width = 1, treePalette = 0, trunkPalette = 0, altTree = false})
function TreeStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local offset = self.altTree and BG_TREE_ALT_OFFSET or 0

	for row = 1, self.height do
		if row == 1 and row == self.height - 1 then
			cursor.cell:setTileByPalette(
				SMALL_BG_TREE + offset, self.treePalette)
		elseif row == 1 then
			cursor.cell:setTileByPalette(
				LARGE_BG_TREE_UPPER + offset, self.treePalette)
		elseif row == self.height - 1 then
			cursor.cell:setTileByPalette(
				LARGE_BG_TREE_LOWER + offset, self.treePalette)
		elseif row == self.height then
			cursor.cell:setTileByPalette(BG_TREE_BASE, self.trunkPalette)
		else
			cursor.cell:setTileByPalette(
				LARGE_BG_TREE_CENTER + offset, self.treePalette)
		end
		cursor:move(0, 1)
	end
end

CastleStructure = Structure:new({width = 5, height = 5, altBrick = false})
function CastleStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})
	local offset = self.altBrick and CASTLE_ALT_OFFSET or 0

	-- First row (roof)
	cursor:move(1, 0)
	local row = RowStructure:new({
		width = self.width - 2,
		palette = self.palette,
		tile = CASTLE_TOP + offset
	})
	row:build(cursor)

	-- Second row (windows)
	cursor:move(0, 1)
	row.tile = CASTLE_WALL + offset
	row:build(cursor)
	cursor.cell:setTileByPalette(CASTLE_LEFT_WINDOW + offset, self.palette)
	cursor:move(self.width - 3, 0)
	cursor.cell:setTileByPalette(CASTLE_RIGHT_WINDOW + offset, self.palette)

	-- Third row (rampart)
	cursor:move(3 - self.width, 1)
	row.tile = CASTLE_RAMPART + offset
	row:build(cursor)
	cursor:move(-1, 0)
	cursor.cell:setTileByPalette(CASTLE_TOP + offset, self.palette)
	cursor:move(self.width - 1, 0)
	cursor.cell:setTileByPalette(CASTLE_TOP + offset, self.palette)
	cursor:move(1 - self.width, 0)

	-- All other rows
	row.width = self.width
	row.tile = CASTLE_WALL + offset
	for i = 4, self.height do
		cursor:move(0, 1)
		row:build(cursor)
	end

	-- Door
	cursor:move(math.floor(self.width / 2), 0)
	cursor.cell:setTileByPalette(DOOR, self.palette)
	cursor:move(0, -1)
	cursor.cell:setTileByPalette(CASTLE_DOORWAY + offset, self.palette)
end

--[[
	UTILITY STRUCTURES

	Structures that alter what already exists rather than building something new.
]]

NonsolidStructure = Structure:new()
function NonsolidStructure:build(topleft)
	local cursor = Cursor:new({cell = topleft.cell})

	for row = 1, self.height do
		for col = 1, self.width do
			if cursor.cell:solid() then
				cursor.cell.tile = cursor.cell.tile + LAST_SOLID_TILE
			end
			cursor:move(1, 0)
		end
		cursor.cell = topleft.cell
		cursor:move(0, row)
	end
end
