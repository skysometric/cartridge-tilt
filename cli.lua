--[[
	cli.lua

	Provides a basic command line parser.
]]

Cli = {
	defaultCallback = nil,
	flags = {},
	helpText = ""
}

function Cli:new(o)
	local o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Adds a new flag to the CLI parser with a shortname (such as "-d"), a longname (such as
-- "--directory"), a callback function to execute, and a description for the help text. The
-- callback function should take a string as its argument.
function Cli:addFlag(shortname, longname, callback, description)
	local data = {callback = callback, description = description}

	if shortname and shortname ~= "" then
		self.flags[shortname] = data
	end

	if longname and longname ~= "" then
		self.flags[longname] = data
	end
end

-- Prints a help dialog using the CLI's help text and each argument's description. Because
-- of the way flags are stored and parsed, short- and longnames are not grouped together in
-- the resulting help text.
function Cli:printHelp()
	print(self.helpText)
	print('Arguments:')
	for i, v in pairs(self.flags) do
		print(i, "\t", v.description)
	end

	return true
end

-- Processes all arguments and runs callbacks as necessary. Returns true if the program
-- should exit (such as for an error or printing help text).
function Cli:processArgs(arg)
	local flags = {default = {}}
	local flag = "default"

	for _, token in ipairs(arg) do
		if token:find('^-') then
			flag = token
			flags[flag] = {}
		else
			table.insert(flags[flag], token)
		end
	end

	local exit = false

	for f, a in pairs(flags) do
		if f == "default" and self.defaultCallback then
			exit = self.defaultCallback(table.concat(a, ' ')) or exit
		elseif f == "-h" or f == "--help" then
			exit = self:printHelp() or exit
		elseif self.flags[f] then
			exit = self.flags[f].callback(table.concat(a, ' ')) or exit
		else
			print('Unknown flag:', f)
		end
	end

	return exit
end
