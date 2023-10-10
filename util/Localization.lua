 --[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff
]]

local table_Copy = table.Copy

local assert = assert
local getfenv = getfenv
local rawget = rawget -- Avoid __index calls
local setfenv = setfenv
local type = type
local tostring = tostring

local hook_Add = hook.Add

local LOCALIZED_DATA = {}
local LOCALIZED_REGISTRY = {}

local _Registry = debug.getregistry()

function GetLocalTable()
	return LOCALIZED_DATA
end

function GetLocalRegistry()
	return LOCALIZED_REGISTRY
end

--[[
	Properly localizes something from either the specified table or the global table.
	Last two arguments are optional, although a second argument is recommended.

	Returns the localized copy of the global.

	Example Usage:
		local MyLocalizedVariables = {}

		LocalizeGlobal("surface", MyLocalizedVariables, _G)
]]

function LocalizeGlobal(name, to, from)
	assert(type(name) == "string", "Bad argument #1 to 'LocalizeGlobal' (string expected, got " .. type(name) .. ")")

	if to ~= nil then
		assert(type(to) == "table", "Bad argument #2 to 'LocalizeGlobal' (table expected, got " .. type(to) .. ")")
	end

	to = to or GetLocalTable()

	if from ~= nil then
		assert(type(from) == "table", "Bad argument #3 to 'LocalizeGlobal' (table expected, got " .. type(from) .. ")")
	end

	from = from or getfenv() -- _G

	local Target = rawget(from, name)

	if type(Target) == "table" then
		to[name] = table_Copy(Target)
	else
		to[name] = Target
	end

	return to[name]
end

--[[
	Properly localizes something from either the specified registry or the default registry.
	Law two arguments are optional, althought second is recommended.

	Returns the localized copy of the registry.
]]

function LocalizeRegistry(name, to, from)
	assert(type(name) == "string", "Bad argument #1 to 'LocalizeRegistry' (string expected, got " .. type(name) .. ")")

	if to ~= nil then
		assert(type(to) == "table", "Bad argument #2 to 'LocalizeRegistry' (table expected, got " .. type(to) .. ")")
	end

	to = to or GetLocalRegistry()

	if from ~= nil then
		assert(type(from) == "table", "Bad argument #3 to 'LocalizeRegistry' (table expected, got " .. type(from) .. ")")
	end

	from = from or _Registry

	local Target = rawget(from, name)

	if type(Target) == "table" then -- Registry objects are (usually) always tables but just in case there's some shenanigans going on I'll leave the check
		to[name] = table_Copy(Target)
	else
		to[name] = Target
	end

	return to[name]
end

--[[
	Registers a function into the specified local environment or the default one that is above.
	Second argument is optional, but recommended.

	Returns the modified function.
]]

function SetFunctionInEnvironment(func, environment)
	assert(type(func) == "function", "Bad argument #1 to 'SetFunctionInEnvironment' (function expected, got " .. type(func) .. ")")

	if environment ~= nil then
		assert(type(environment) == "table", "Bad argument #2 to 'SetFunctionInEnvironment' (table expected, got " .. type(environment) .. ")")
	end

	environment = environment or GetLocalTable()

	return setfenv(func, environment)
end

--[[
	Creates a function within the specified local environment or the default one that is above.
	Name is optional, but recommended.
	Environment is optional, but recommended.

	Returns the modified function.
]]

function CreateFunctionInEnvironment(func, name, environment)
	assert(type(func) == "function", "Bad argument #1 to 'CreateFunctionInEnvironment' (function expected, got " .. type(func) .. ")")

	if name ~= nil then
		if type(name) == "table" then -- Allows you to not need to specify a name for the function
			environment = name
			name = tostring(func)
		else
			assert(type(name) == "string", "Bad argument #2 to 'CreateFunctionInEnvironment' (string expected, got " .. type(name) .. ")")
		end
	end

	if environment ~= nil then
		assert(type(environment) == "table", "Bad argument #3 to 'CreateFunctionInEnvironment' (table expected, got " .. type(environment) .. ")")
	end

	environment = environment or GetLocalTable()

	local nfunc = setfenv(func, environment) -- Dumb but whatever
	environment[name] = nfunc

	return nfunc
end

--[[
	Creates a hook whose function uses the specified local environment or the default one that is above.
	Fouth argument is optional, but recommended.

	Returns the modified function.
]]

function CreateHookInEnvironment(htype, name, func, environment)
	assert(type(htype) == "string", "Bad argument #1 to 'CreateHookInEnvironment' (string expected, got " .. type(htype) .. ")")
	assert(type(name) == "string", "Bad argument #2 to 'CreateHookInEnvironment' (string expected, got " .. type(name) .. ")")
	assert(type(func) == "function", "Bad argument #3 to 'CreateHookInEnvironment' (function expected, got " .. type(func) .. ")")

	if environment ~= nil then
		assert(type(environment) == "table", "Bad argument #4 to 'CreateHookInEnvironment' (table expected, got " .. type(environment) .. ")")
	end

	environment = environment or GetLocalTable()

	local nfunc = setfenv(func, environment)
	hook_Add(htype, name, nfunc)

	return nfunc
end
