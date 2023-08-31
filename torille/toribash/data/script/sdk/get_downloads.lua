-- downloads = get_downloads()

-- USE: Returns an array of pending downloads  
-- NOTES: -

local downloads = get_downloads()

echo ("downloads = get_downloads()")
for i=0,table.getn(downloads) do
    echo(downloads[i])
end
