-- joint_info = get_joint_info(number player_index, number joint_index)

-- USE: Returns an array containing joint information
-- NOTES: -

local player_index, joint_index = 0, 0
local joint_info = get_joint_info(player_index, joint_index)

echo ("joint_info = get_joint_info(" .. player_index .. ", " .. joint_index .. ")")
for key,value in pairs(joint_info) do 
        echo (key ..  ": " .. value)
end
