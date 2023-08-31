-- set_joint_radius (integer player_index, integer joint_index, number radius)

-- USE: Sets the radius of a specified joint
-- NOTES: -

local player_index, radius = 0, 0.2

for i=0,19 do
   echo ("set_joint_radius ( " .. player_index .. ", " .. i .. ", " .. radius .. ")")
   set_joint_radius (player_index, i, radius)
end

run_cmd("exportworld jointsWide.tbm") --saves state to external file
