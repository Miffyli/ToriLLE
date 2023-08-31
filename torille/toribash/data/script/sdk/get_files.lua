-- get_files(string directory)

-- USE: Gets all files in a directory
-- NOTES: -

Files = get_files("data/script", "lua")

echo('get_files("data/script","lua")')
for i = 1, #Files do
    echo(Files[i])
end