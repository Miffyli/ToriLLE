-- Modern UI shaders & atmosheres screen
-- DO NOT MODIFY THIS FILE

dofile("toriui/uielement3d.lua")
dofile("system/iofiles.lua")
dofile("system/menu_manager.lua")
dofile("system/atmospheres_manager.lua")
dofile("system/atmospheres_defines.lua")

if (ATMO_MENU_MAIN_ELEMENT) then
	ATMO_MENU_MAIN_ELEMENT:kill()
	ATMO_MENU_MAIN_ELEMENT = nil
	return
end
Atmospheres:showMain()
