-- rules = get_game_rules()

-- USE: Returns an array containing game rules
-- NOTES: -

local rules = get_game_rules()

echo ("rules = get_game_rules()")
for key,value in pairs(rules) do 
       echo (key ..  ": " .. value)
end
