-- info = get_player_info (number player_index)

-- USE: Returns an array containing player information
-- NOTES: -

local player_index = 0
local info = get_player_info(player_index)

echo ("info = get_player_info(" .. player_index .. ")")
for key,value in pairs(info) do 
        echo (key ..  ": " .. value)
end
