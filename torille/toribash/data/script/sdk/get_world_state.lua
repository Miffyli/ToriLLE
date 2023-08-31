-- worldstate = get_world_state()

-- USE: Returns an array containing world state information
-- NOTES: -

local worldstate = get_world_state()

echo ("worldstate = get_world_state()")
for key,value in pairs(worldstate) do 
        echo (key ..  ": " .. value)
end
