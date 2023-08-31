-- get_joint_fracture (integer player_index, integer joint_index)

-- USE: Returns the 'fracture' state of a joint
-- NOTES: -

local player_index = 1

for i=0,19 do 
    joint_state = get_joint_fracture(player_index,i)
    if (joint_state) then
       echo ("TRUE = get_joint_fracture(" .. player_index .. ", " .. i .. ")")
    else
       echo ("FALSE = get_joint_fracture(" .. player_index .. ", " .. i .. ")")
    end   
end

