--[[
	Generally useful script.
	By: Blam
	Date: 17/12/2010
	
	Commands:
		• '/lua [code]'
			Runs the input, echoes out any errors, doesn't halt execution on error.
			ex: '/lua echo("Hello World")' outputs "Hello World"
		• '/svar [a]=[b]; [c]=[d]'
			Sets variables.
			ex: '/svar hello = world' makes the variable 'hello' = 'world'
		• '/print [a]; [b]'
			Prints out variables.
			ex: '/print hello' outputs '"hello" == "world"'
		• '/echof [text]'
			Echo's out the string replacing encapsulated variable names with their values.
			Check out 'getmetatable("").__unm' for examples.
	
	Functions:
		• callstr(inp)
			Implementation of /lua command.
		• set(var)
			Implementation of /svar command.
		• printl(var)
			Implementation of /print command.
		• echof(str)
			Implementation of /echof command.
		• print(o)
			Echoes the string value of o.
			ex: 'print(true)' echoes: "true"
			
	Operator Overloads:
		• String modulus (string1 % string2)
			Returns true if string1 starts with string2
			See 'getmetatable("").__mod' for usage examples.
		• String negation (-string1)
			Same as echof.
]]


--[['a % s' will return true if a starts with s
	ex:
		a = "Hello World"
		b = "Hello"
		c = "World"
		echo(tostring(a % b))
		echo(tostring(a % c))
	out:
		true
		false
]]
getmetatable("").__mod = function(self, s) 
	if(self:sub(0,#s) == s) then return true end
	return false
end

--[['-a', where a contains variables surrounded by |'s will change the vars for their values.
	ex: 
		AdultPrice = 15
		KidsPrice = 5
		echo(-"Adult: £|AdultPrice|, Kids: £|KidsPrice|!")
	output:
		"Adult: £15, Kids: £10!"
]]
getmetatable("").__unm = function(self)
	local me = self
	local spos = me:find("|")
	local epos = 0
	local pre = ""
	local post = ""
	local act = ""
	while(spos ~= nil) do
		epos = me:find("|", spos+1)
		if(epos == nil) then return end
		
		pre = me:sub(0, spos-1)
		post = me:sub(epos+1)
		act = me:sub(spos+1, epos-1)
		
		if(_G[act] == nil) then
			me = pre .. " " .. act .. " " .. post
		else
			me = pre .. tostring(_G[act]) .. post
		end
		
		spos = me:find("|")
	end
	return me
end

function callstr(inp)
	f = loadstring(inp)
	success, err = pcall(f) --catch errors
	if(not success) then
		echo("^07[^02Failure^07] - \"^02" .. err .. "^07\"")
	end
end

function set(inp)
	if(inp:find("=")) then
		if(inp:sub(-1) ~= ";") then
			inp = inp .. ";"
		end
		inp = string.gsub(inp,"%s","") 
		for k, v in string.gmatch(inp, "(.-)=(.-)%;") do 
			_G[k] = v
			echo("\"" .. k .. "\" := \"" .. v .. "\"")
		end
	end
end

function print(inp)
	echo(tostring(inp))
end

function printl(inp)
	if(inp:sub(-1) ~= ";") then
		inp = inp .. ";"
	end
	inp = string.gsub(inp,"%s","")
	for k, v in string.gmatch(inp, "(.-)%;") do
		local value = tostring(_G[k])
		echo("\"".. k .. "\" == \"" .. value .. "\"")
	end
end

function echof(inp)
	print(-inp)
end

local commands = {
	lua = callstr,
	svar = set,
	print = printl,
	echof = echof
}


add_hook("command", "", 
	function(cmd)
		for k,v in pairs(commands) do
			if(cmd % k) then
				v(cmd:sub(#k+2))
				return 1
			end
		end
	end
)

local ______tmp = cmd --'back up' cmd incase it exists
for k,v in pairs(commands) do
	cmd = k
	print(-"^07Command Loaded: '^14|cmd|^07'")
end
cmd = ______tmp --set cmd back to it's original, so we don't mess up other scripts.
