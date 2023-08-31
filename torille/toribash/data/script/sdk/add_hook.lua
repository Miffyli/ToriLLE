-- add_hook(string hookname, string unique_name, function lua_function)

-- USE: Adds a hook
-- NOTES: See other functions for more use of this function

echofunc = function()
     echo(".")
end

add_hook("draw2d", "add_hook", echofunc);
