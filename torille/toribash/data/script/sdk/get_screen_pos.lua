-- x, y = get__screen_pos (number x, number y, number z)

-- USE: Returns the screen coordinates of a set of specified world coordinates
-- NOTES: -

local x, y, z = 0, 0, 0

local posx, posy = get_screen_pos(x, y, z)
echo(posx .. ", " .. posy .. " = get_screen_pos (" .. x .. ", " .. y .. ", " .. z .. ")")
