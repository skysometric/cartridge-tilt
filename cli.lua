--[[
	cli.lua

	Provides a basic command line interface and option parser. Use "Cli:addOption()" to
	add arguments, and "Cli:processArgs" to process them from the command line.

	Supports:
		- Short and long names for the options (such as "-d" and "--directory")
		- Help text (via "-h" or "--help", which are reserved)
		- Arguments with spaces (such as file names); all tokens up to the next
		option are parsed as one argument
		- "Default" argument (without an option flag)
		- Early program exit; argument parser returns "true" to exit early

	Does not support:
		- Multiple options at once (such as "-alR")
		- The equals sign as argument assignment (such as "--color=red")

	Known issues:
		- Default argument must come before all other options; can't be set after
		- Help text is not formatted/spaced if it overflows the line
]]

Cli = {
	-- Callback function used for the default argument to the script
	defaultCallback = nil,
	-- Map of options to their callback functions
	options = {},

	-- Stores help text for each option
	helpTable = {},
	-- Stores the length of the longest option for formatting reasons
	longestOptionLength = 0,
	-- Current group that options will be added to in the help text
	optionGroup = "",
	-- Ordered list of option groups to print the help text, because using pairs() just
	-- printed them in a random order every time
	optionGroups = {},
	-- Summary of what this script does, used for the help text
	-- Ex: "This script processes arguments from the command line"
	summary = "",
	-- Example usage of the function, used for the help text
	-- Ex: "lua main.lua [OPTIONS]"
	usage = ""
}

function Cli:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:setOptionGroup("Arguments")
	return o
end

-- Adds a new option to the CLI parser with a shortname (such as "-d"), a longname (such
-- as "--directory"), a callback function to execute, and a description for the help text.
-- The callback function should expect a string as its argument.
function Cli:addOption(shortname, longname, callback, description)
	local optionHelp = {}

	-- Add shortname if it exists
	if shortname and shortname ~= "" then
		self.options[shortname] = callback
		optionHelp.shortname = shortname
	end

	-- Add longname if it exists
	if longname and longname ~= "" then
		self.options[longname] = callback
		optionHelp.longname = longname

		self.longestOptionLength = math.max(
			self.longestOptionLength, string.len(longname))
	end

	-- Add description if it exists
	if description and description ~= "" then
		optionHelp.description = description
	end

	-- Add this option to the help text
	table.insert(self.helpTable[self.optionGroup], optionHelp)
end

-- Set the current option group. Options added after this is called will be grouped
-- together in the help text.
function Cli:setOptionGroup(group)
	self.optionGroup = group
	if not self.helpTable[group] then
		self.helpTable[group] = {}
		table.insert(self.optionGroups, group)
	end
end

-- Prints the help dialog using the CLI's help text and each argument's description.
function Cli:printHelp()
	print('Usage:', self.usage, "\n")
	print(self.summary, "\n")
	for _, name in pairs(self.optionGroups) do
		local group = self.helpTable[name]
		print(string.format("%s:", name))
		for _, v in ipairs(group) do
			local shortname = string.format("%4s", v.shortname or " ")
			-- ...why doesn't lua's string.format support *??
			local longname = string.format(
				string.format("%%-%ds", self.longestOptionLength),
				v.longname or " "
			)
			local comma = v.shortname and v.longname and "," or " "
			print(string.format(
				'%s%s %s\t%s', shortname, comma, longname, v.description))
		end
	end

	return true
end

-- Processes all arguments and runs callbacks as necessary. Returns true if the program
-- should exit without running (such as for an error or printing help text).
function Cli:processArgs(arg)
	-- Map of options to their arguments
	local arguments = {}
	-- Currently selected option (starts with "default")
	local option = "default"

	-- Sort through the tokens passed into the program
	for _, token in ipairs(arg) do
		-- If the token is an option (starts with '-'), select it
		if token:find('^-') then
			option = token
			arguments[option] = ""
		-- If the token is part of a longer argument with spaces, append it
		elseif arguments[option] and arguments[option] ~= "" then
			arguments[option] = string.format(
				"%s %s", arguments[option], token)
		-- If the token is an argument, set it for the currently selected option
		else
			arguments[option] = token
		end
	end

	local exit = false

	for option, argument in pairs(arguments) do
		-- Apply default argument
		if option == "default" and self.defaultCallback then
			exit = self.defaultCallback(argument) or exit
		-- Apply help option
		elseif option == "-h" or option == "--help" then
			exit = self:printHelp() or exit
		-- Apply any other option
		elseif self.options[option] then
			local callback = self.options[option]
			exit = callback(argument) or exit
		else
			print('Unknown option:', option)
		end
	end

	return exit
end
