-- x, y, z = get_body_angular_vel (number player_index, number body_index)

-- USE: Returns an array containing body parts angular velocity
-- NOTES: -

local player_index, body_index = 0, 0

local x, y, z = get_body_angular_vel (player_index, body_index)
echo (x .. ", " .. y .. ", " .. z .. " = get_body_angular_vel (" .. player_index .. ", " .. body_index .. ")")
