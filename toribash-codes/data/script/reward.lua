-- daily login rewards script
-- made by sir

-- Commented out for Torille to avoid prevent
-- presenting the reward window which slows the game down
--[[
dofile("system/login_daily_manager.lua")
dofile("toriui/uielement.lua")

if (ARG1 == '') then
	return
end

local days_cons = ARG1:gsub("%s%d$", "")
local is_available = ARG1:gsub("^%d%s", "")

if (is_available == "1") then
	rewards = LoginDaily:create()
	LoginDaily:getRewardData()
	LoginDaily:showMain(true, tonumber(days_cons))

	add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
	add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
	add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
	add_hook("draw2d", "dailyLoginVisual", function() LoginDaily:drawVisuals() end)
end
]]--