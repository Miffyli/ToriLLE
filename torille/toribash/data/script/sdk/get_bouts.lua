-- bouts = get_bouts()

-- USE: Returns an array of bout names
-- NOTES: -

local bouts = get_bouts()

echo ("bouts = get_bouts()")
for i=0,table.getn(bouts) do
    echo( bouts[i] )
end
