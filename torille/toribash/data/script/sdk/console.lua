local function console(s, i)
	-- echo doesn't retrigger console output
	echo(string.format("CONSOLE (%i): %s", i, s))

	-- return 1 to skip internal handling of console message
	return 1
end

add_hook("console", "console", console)

