-- get_joint_dismember (integer player_index, integer joint_index)

-- USE: Returns the 'dismember' state of a joint
-- NOTES: -

local player_index = 0

for i=0,19 do 
    joint_state = get_joint_dismember(player_index,i)
    if (joint_state) then
       echo ("TRUE = get_joint_dismember(" .. player_index .. ", " .. i .. ")")
    else
       echo ("FALSE = get_joint_dismember(" .. player_index .. ", " .. i .. ")")
    end   
end
