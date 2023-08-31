-- set_volume(integer volume) 
-- USE: set_volume for ingame sounds 0-100 

local volume = 39
echo("Setting volume to " .. volume);
set_volume(volume)
echo("Current volume is " .. get_volume())
