--The command hook is triggered by entering in a "/abcd" and will have "abcd" as a parameter.

function CommandInput(cmd)
	if(cmd == "test") then
		echo("This is a test!")
		
		--return 1 to stop it being processed.
		return 1
	end
	
	if(string.sub(cmd, 0, 3) == "set") then
		--won't be sent as it's a built in toribash command.
		echo("Will this be echoed?")
		
		--this won't stop it being processed as it's a built in toribash command.
		return 1
	end
end

add_hook("command", "sdk", CommandInput)


--Variable setter and getter.
--Demonstrates the "command" hook.
--Useful for debugging.

add_hook("command", "",
	function(cmd)
		if(cmd:sub(0,8) == "setvalue") then -- if the string incoming is a set variable command.
			texttoparse = cmd:sub(10)
			if(texttoparse:find("=")) then -- if it's valid.
				if(texttoparse:sub(-1) ~= ";") then -- add ; to the end if it doesn't have it.
					texttoparse = texttoparse .. ";"
				end
				texttoparse = string.gsub(texttoparse,"%s","") -- Get Rid of spaces.
				for k, v in string.gmatch(texttoparse, "(.-)=(.-)%;") do -- Go through each "k=v;".
					_G[k] = v -- Set the variable k to v
					echo("\"" .. k .. "\" := \"" .. v .. "\"") -- Echo to confirm change.
				end
			end
			return 1
		elseif(cmd:sub(0,8) == "getvalue") then -- if the string incoming is a get variable command.
			texttoparse = cmd:sub(10)
			if(texttoparse:sub(-1) ~= ";") then -- add ; to the end if it doesn't have it.
				texttoparse = texttoparse .. ";"
			end
			texttoparse = string.gsub(texttoparse,"%s","") -- Get Rid of spaces.
			for k, v in string.gmatch(texttoparse, "(.-)%;") do -- Go through each "k;k;k;k;".
				echo("\"".. k .. "\" == \"" .. _G[k] .. "\"") -- Echo to confirm change.
			end
			return 1
		end
	end
)