-- x, y, z = get_joint_pos2 (integer player_index, integer joint_index)

-- USE: Returns the world coordinates of a joint
-- NOTES: -

local player_index, joint_index = 0, 0

joint_pos = get_joint_pos2 (player_index, joint_index)

echo ("joint_pos = get_joint_pos2 (" .. player_index .. ", " .. joint_index .. ")")
for key,value in pairs(joint_pos) do 
        echo (key ..  ": " .. value)
end
