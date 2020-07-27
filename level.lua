--[[
	level.lua

	Provides data structures and functions used to store and manipulate a level.
]]

require("tileset")

--[[
	Cell

	A cell is a single space in the level. It contains a tile ID and up to one entity,
	as well as pointers to cells in each cardinal direction.

	Tile IDs are relative to the custom tileset, and constants can be found in tileset.lua.
	The absolute tile ID in-game is calculated based on the palette used. If the palette is
	set to zero, the calculation is skipped and the tile ID is expected to already be absolute.
	(This is used for anything not in the custom tileset, such as coins, ? blocks, and air.)
]]

Cell = {
	-- Points to cells in each direction
	up = nil,
	left = nil,
	down = nil,
	right = nil,

	-- By default the tile is blank (air) with no palette and no entity
	tile = BLANK,
	palette = 0,
	entity = nil
}

function Cell:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Returns true if the tile in this cell has collision. Only works when using tiles
-- from the custom tileset, AKA when the palette is set; the custom tileset was
-- intentionally designed to make this easy.
function Cell:solid()
	return self.palette > 0 and self.tile <= LAST_SOLID_TILE
end

-- Returns true if the tile in this cell does not have collision, and the tile
-- beneath it does. Useful logic for spawners.
function Cell:nonsolidAboveSolid()
	return self.down and self.down:solid() and not self:solid()
end

-- Set a custom-tileset relative tile ID and a palette for this cell.
-- Set the palette to 0 to use an absolute tile ID (and access tiles from the base tileset.)
function Cell:setTileByPalette(tile, palette)
	self.tile = tile
	self.palette = palette or self.palette
end

-- Converts the cell to a string used by the level format.
function Cell:__tostring()
	local s
	if self.palette > 0 then
		s = CUSTOM_TILES_OFFSET + (self.palette - 1) * TILES_PER_PALETTE + self.tile
	else
		s = tostring(self.tile)
	end

	if self.entity then
		s = s .. "-" .. tostring(self.entity)
	end
	return s
end

--[[
	Cursor

	A cursor points to a single cell, and provides functions to quickly traverse the level.
]]

Cursor ={
	cell = nil
}

function Cursor:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Cursor:atTopmost()
	return not self.cell.up
end

function Cursor:atLeftmost()
	return not self.cell.left
end

function Cursor:atBottommost()
	return not self.cell.down
end

function Cursor:atRightmost()
	return not self.cell.right
end

-- Moves the cursor by the number of cells specified in each direction. Positive
-- values move right and down. The cursor is bounded and will not move off the map.
function Cursor:move(rows, cols)
	if rows < 0 then
		for i = -1, rows, -1 do
			self.cell = self.cell.left or self.cell
		end
	else
		for i = 1, rows do
			self.cell = self.cell.right or self.cell
		end
	end
	if cols < 0 then
		for i = -1, cols, -1 do
			self.cell = self.cell.up or self.cell
		end
	else
		for i = 1, cols do
			self.cell = self.cell.down or self.cell
		end
	end
end

--[[
	Helper functions
]]

-- Creates an empty level table of linked cells, made of a certain number of
-- square Sections of a certain Size (in cells).
function createLevelTable(size, sections)
	local levelTable = {}
	local rowLength = size * sections

	for i = 1, rowLength * size do
		local newCell = Cell:new()

		-- Horizontal link
		if i % rowLength ~= 1 then
			newCell.left = levelTable[i - 1]
			newCell.left.right = newCell
		end

		-- Vertical link
		if i > rowLength then
			if i % rowLength == 1 then
				newCell.up = levelTable[i - rowLength]
				newCell.up.down = newCell
			else
				newCell.up = newCell.left.up.right
				newCell.up.down = newCell
			end
		end

		levelTable[i] = newCell
	end

	return levelTable
end
