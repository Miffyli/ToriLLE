function unload()
	echo("Goodbye")
	--save any data
	--remove any overrides
end

--called when the game loads another script.
add_hook("unload", "", unload)