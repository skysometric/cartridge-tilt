--[[
	cli.lua

	Provides a basic command line parser. Supports arguments with spaces (such as file
	names), but does not support multiple options at once (such as "-alR").
]]

Cli = {
	defaultCallback = nil,
	options = {},

	helpTable = {},
	helpText = "",
	longestOptionLength = 0,
	optionGroup = "",
	usageText = ""
}

function Cli:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	self:setOptionGroup("Arguments")
	return o
end

-- Adds a new option to the CLI parser with a shortname (such as "-d"), a longname (such as
-- "--directory"), a callback function to execute, and a description for the help text. The
-- callback function should take a string as its argument.
function Cli:addOption(shortname, longname, callback, description)
	local optionHelp = {}

	if shortname and shortname ~= "" then
		self.options[shortname] = callback
		optionHelp.shortname = shortname
	end

	if longname and longname ~= "" then
		self.options[longname] = callback
		optionHelp.longname = longname

		self.longestOptionLength = math.max(
			self.longestOptionLength, string.len(longname))
	end

	if description and description ~= "" then
		optionHelp.description = description
	end

	table.insert(self.helpTable[self.optionGroup], optionHelp)
end

-- Group options in the help dialog
function Cli:setOptionGroup(group)
	self.optionGroup = group
	if not self.helpTable[group] then
		self.helpTable[group] = {}
	end
end

-- Prints a help dialog using the CLI's help text and each argument's description.
function Cli:printHelp()
	print('Usage:', self.usageText, "\n")
	print(self.helpText, "\n")
	for name, group in pairs(self.helpTable) do
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
	local options = {default = {}}
	local option = "default"

	for _, token in ipairs(arg) do
		if token:find('^-') then
			option = token
			options[option] = {}
		else
			table.insert(options[option], token)
		end
	end

	local exit = false

	for f, a in pairs(options) do
		if f == "default" and self.defaultCallback then
			exit = self.defaultCallback(table.concat(a, ' ')) or exit
		elseif f == "-h" or f == "--help" then
			exit = self:printHelp() or exit
		elseif self.options[f] then
			local callback = self.options[f]
			exit = callback(table.concat(a, ' ')) or exit
		else
			print('Unknown option:', f)
		end
	end

	return exit
end
