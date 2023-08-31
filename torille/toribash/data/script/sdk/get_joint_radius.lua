-- radius = get joint radius (integer player_index, integer joint_index)

-- USE: Returns the radius of a specified joint
-- NOTES: -

local player_index, joint_index = 0, 0

local radius = get_joint_radius (player_index, joint_index)
echo (radius .. " = get_joint_radius (" .. player_index .. ", " .. joint_index .. ")")
