#!/usr/bin/env lua

require("cli")
require("entities")
require("generator")
require("level")
require("random")
require("spawner")
require("structures")
require("tileset")

-- Global variables
CHUNK_SIZE = 15
DIRECTORY = ""
MODE = "1.6"
RANDOM_SEED = "Cartridge Tilt"

WORLDS = 8
LEVELS = 4

function main()
	cli = Cli:new()
	cli.helpText = 'This script randomly generates 32 glitchy-looking levels for Mari0 using a structure-based generation system.'
	cli.defaultCallback = setDirectory
	cli:addFlag('-d', '--directory', setDirectory,
				'Set the directory to generate the files in')
	cli:addFlag('-s', '--seed', function(seed) RANDOM_SEED = seed end,
				'Set the random seed used to generate levels (defaults to "Cartridge Tilt")')
	cli:addFlag('', '--AE', function() MODE = "AE" end,
				'Generate levels in AE format')
	if cli:processArgs(arg) then return end

	-- Set the seed used to generate levels
	math.randomseed(table.concat({string.byte(RANDOM_SEED, 1, string.len(RANDOM_SEED))}))
	math.random()
	math.random()
	math.random()
	math.random()

	for world = 1, WORLDS do
		for level = 1, LEVELS do
			print("Generating " .. world .. "-" .. level .. "...")
			generateLevel(world, level)
		end
	end

	print("All 32 levels generated successfully.")
end

function generateLevel(world, level)
	-- Open file for this level
	io.output(DIRECTORY .. "/" ..world .. "-" .. level .. ".txt")

	-- Create a blank level table
	local sections = math.random(8, 12)
	local levelTable = createLevelTable(CHUNK_SIZE, sections)

	-- Generate structures
	local topleft = Cursor:new({cell = levelTable[1]})
	local cursor = Cursor:new({cell = topleft.cell})

	-- Set defaults parameters for all generators used in the level
	Generator.width = CHUNK_SIZE
	Generator.height = CHUNK_SIZE
	Generator.groundPalette = math.random(PALETTES)
	Generator.blockPalette = math.random(PALETTES)
	Generator.plantPalette = math.random(PALETTES)
	Generator.pipePalette = math.random(PALETTES)
	Generator.weatherPalette = math.random(PALETTES)

	Generator.groundTile = math.random(FIRST_GROUND_TILE, LAST_GROUND_TILE)
	Generator.blockTile = math.random(FIRST_BLOCK_TILE, LAST_BLOCK_TILE)
	Generator.altBrick = coinflip()
	Generator.altSkyBridge = coinflip()
	Generator.altTreetop = coinflip()
	Generator.altTreetopBase = coinflip()
	Generator.altBackgroundTree = coinflip()

	-- Add lava if this is a castle level
	if level == LEVELS then

	end

	-- Build the level
	for i = 1, sections do
		local baseLevel, distortions, enemies
		if i == sections then
			baseLevel = LevelEndGenerator:new() --level == 4 and CastleEndGenerator:new() or LevelEndGenerator:new()
			distortions = DistortionGenerator:new({world = world, level = level, cosmetic = true})
			enemies = Spawner:new()
		else
			baseLevel = ChaosGenerator:new({world = world, level = level})
			distortions = DistortionGenerator:new({world = world, level = level})
			enemies = ChaosSpawner:new({
				width = CHUNK_SIZE, height = CHUNK_SIZE, world = world, level = level})
		end

		baseLevel:generate(cursor)
		enemies:generate(cursor)
		distortions:generate(cursor)

		cursor:move(CHUNK_SIZE, 0)
	end

	cursor.cell = topleft.cell
	local startSpawner = StartSpawner:new({width = CHUNK_SIZE * sections, height = CHUNK_SIZE})
	startSpawner:generate(cursor)

	-- Write the level table to the file
	for i, v in ipairs(levelTable) do
		if i > 1 then
			io.write(",", tostring(v))
		else
			io.write(tostring(v))
		end
	end

	-- Set the height for AE mode
	if MODE == "AE" then
		io.write(";height=", CHUNK_SIZE)
	end

	-- Generate the background
	local background = {math.random(0, 255), math.random(0, 255), math.random(0, 255)}

	-- AE combines the background colors into one element
	if MODE == "AE" then
		io.write(";background=", table.concat(background, ","))
	-- SE lists each color component as a separate element
	elseif MODE == "SE" then
		io.write(";backgroundr=", background[1],
				 ";backgroundg=", background[2],
				 ";backgroundb=", background[3])
	-- 1.6 only had three colors to choose from: Light Blue, Dark Blue, and Black
	else -- mode == "1.6", or there was some weird error
		local b
		if background[3] > 170 then
			b = 3
		elseif background[3] > 85 then
			b = 2
		else
			b = 1
		end
		io.write(";background=", b)
	end

	-- Finish the level
	io.write(";spriteset=", math.random(4))
	io.write(";music=", math.random(2, 6))
	io.write(";timelimit=0")
	io.write(";scrollfactor=0")

	-- Save and close file
	io.output():flush()
	io.output():close()
end

function setDirectory(d)
	if d and d ~= "" then
		DIRECTORY = d
		return false
	end

	print("No directory specified.")
	return true
end

-- Actually run the script
main()
