-- set_joint_state (integer player_index, integer joint_index, integer joint_state)

-- USE: Sets the state of a specified joint
-- NOTES: 1,2 = Apply force on joint, 3 = Hold joint, 4 = Release_joint

local player_index, joint_state = 0, 1
for i=0,19 do
   echo ("set_joint_state (" .. player_index .. ", " .. i .. ", " .. joint_state .. ")")
   set_joint_state (player_index, i, joint_state)
end

run_cmd("exportworld jointsWide.tbm") --saves state to external file
