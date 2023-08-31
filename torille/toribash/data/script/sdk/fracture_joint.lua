-- fracture_joint (integer player_index, integer joint_index)

-- USE: Fractures a specified joint
-- NOTES: -

local player_index = 1

for i=0,19 do
    echo ("fracture_joint(" .. player_index .. ", " .. i .. ")")
    fracture_joint(player_index, i)
end
echo ("Press Space to see effect")
