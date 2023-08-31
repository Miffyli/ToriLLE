-- x, y, z = get_body_linear_vel (number player_index, number body_index)

-- USE: Returns an array containing body parts linear velocity
-- NOTES: -

local player_index, body_index = 0, 0

local x, y, z = get_body_linear_vel (player_index, body_index)
echo (x .. ", " .. y .. ", " .. z .. " = get_body_linear_vel (" .. player_index .. ", " .. body_index .. ")")
