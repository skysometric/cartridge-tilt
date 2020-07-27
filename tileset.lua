--[[
	tileset.lua

	Provides a list of constants to use the tileset efficiently. The tileset is laid out
	with 88 unique tiles for each of 30 palettes.
]]

-- Points to the last base tile before the custom tileset begins
CUSTOM_TILES_OFFSET = 220

-- Number of palettes in the tileset
PALETTES = 30

-- Number of unique tiles in each palette
TILES_PER_PALETTE = 88

-- The first 44 tiles in each palette are solid; the rest are not
LAST_SOLID_TILE = 44

--[[
	Foreground tiles
]]

-- There are eight variations of ground tiles to choose from
FIRST_GROUND_TILE = 1
LAST_GROUND_TILE = 8

-- There are eight variations of block tiles to choose from
FIRST_BLOCK_TILE = 9
LAST_BLOCK_TILE = 16

-- Two styles of bricks can be switched with the alt offset
BRICK_TOP = 17
BRICK_CENTER = 15
BRICK_ALT_OFFSET = 1

-- Pipes
VERTICAL_PIPE_LEFT_SPOUT = 19
VERTICAL_PIPE_RIGHT_SPOUT = 20
VERTICAL_PIPE_LEFT_BASE = 21
VERTICAL_PIPE_RIGHT_BASE = 22

HORIZONTAL_PIPE_UPPER_SPOUT = 23
HORIZONTAL_PIPE_LOWER_SPOUT = 24
HORIZONTAL_PIPE_UPPER_BASE = 25
HORIZONTAL_PIPE_LOWER_BASE = 26

BLASTER_TOP = 27
BLASTER_MOUNT = 28
BLASTER_BASE = 29

CLOUD_PLATFORM_LEFT = 30
CLOUD_PLATFORM_CENTER = 31
CLOUD_PLATFORM_RIGHT = 32

-- Two styles of treetops can be switched with the alt offset
TREETOPS_LEFT = 33
TREETOPS_CENTER = 34
TREETOPS_RIGHT = 35
TREETOPS_ALT_OFFSET = 3

MUSHROOM_PLATFORM_LEFT = 39
MUSHROOM_PLATFORM_CENTER = 40
MUSHROOM_PLATFORM_RIGHT = 41

SKY_BRIDGE = 42
SKY_BRIDGE_ALT_OFFSET = 1

CASTLE_BRIDGE = 44

--[[
	Background tiles
]]

TREETOPS_BASE = 45
TREETOPS_BASE_ALT_OFFSET = 1
TREETOPS_NUM_ALTS = 2

MUSHROOM_PLATFORM_STALK = 48
MUSHROOM_PLATFORM_BASE = 69

SKY_BRIDGE_ROPE = 49

CASTLE_BRIDGE_CHAIN = 50

FLAGPOLE = 51
FLAGPOLE_TOP = 52

HILL_TOP = 53
HILL_LEFT = 54
HILL_RIGHT = 55
HILL_TREES = 56
HILL_TREES_ALT_OFFSET = 1
HILL_INSIDE = 58

LAVA_TOP = 59
LAVA_CENTER = 58

BUSH_LEFT = 60
BUSH_CENTER = 61
BUSH_RIGHT = 62

CLOUD_UPPER_LEFT = 60
CLOUD_UPPER_CENTER = 61
CLOUD_UPPER_RIGHT = 62
CLOUD_LOWER_LEFT = 63
CLOUD_LOWER_CENTER = 64
CLOUD_LOWER_RIGHT = 65

BG_TREE_BASE = 66
SMALL_BG_TREE = 67
LARGE_BG_TREE_UPPER = 68
LARGE_BG_TREE_CENTER = 69
LARGE_BG_TREE_LOWER = 70
BG_TREE_ALT_OFFSET = 4

FENCE = 75

CASTLE_TOP = 76
CASTLE_LEFT_WINDOW = 77
CASTLE_WALL = 78
CASTLE_RIGHT_WINDOW = 79
CASTLE_RAMPART = 80
CASTLE_DOORWAY = 81
CASTLE_ALT_OFFSET = 7

DOOR = 82

--[[
	Tiles from the base tileset; these are not paletted
]]

BLANK = 1
PRIZE_BLOCK = 8
COIN = 116
