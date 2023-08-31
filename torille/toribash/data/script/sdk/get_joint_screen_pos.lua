-- x, y, z = get_joint_screen_pos (integer player_index, integer joint_index)

-- USE: Returns the screen coordinates of a specified joint
-- NOTES: -

local player_index, joint_index = 0, 0

x, y, z = get_joint_screen_pos(player_index, joint_index)
echo(x .. ", " .. y .. ", " .. z .. " = get_screen_pos (" .. player_index .. ", " .. joint_index .. ")")
