-- set_body_sides (integer player_index, integer body_index, number x, number y, number z)

-- USE: Sets the body sides
-- NOTES: -

for i=0,20 do
	b = get_body_info(0, i)
	echo ("Setting " .. b.name)
	set_body_sides(0, i, b.sides.x*i*0.1+0.1, b.sides.y, b.sides.z)
end

run_cmd("exportworld wide4.tbm") --saves state to external file
