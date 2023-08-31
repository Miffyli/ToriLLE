-- spectators = get_spectators()

-- USE: Returns an array of spectator names
-- NOTES: -

local spectators = get_spectators()

echo ("spectators = get_spectators()")
for i=0,table.getn(spectators) do
    echo( spectators[i] )
end
