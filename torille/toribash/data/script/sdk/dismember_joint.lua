-- dismember_joint (integer player_index, integer joint_index)

-- USE: Dismembers a specified joint
-- NOTES: -

local player_index = 0

for i=0,19 do
    echo ("dismember_joint(" .. player_index .. ", " .. i .. ")")
    dismember_joint(player_index, i)
end
echo ("Press Space to see effect")
