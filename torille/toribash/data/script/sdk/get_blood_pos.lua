-- x,y,z = get_blood_pos(integer blood_index)

-- USE: returns the position of a blood particle
-- NOTES: -

for i=0,get_num_blood_particles()-1 do
	local x,y,z = get_blood_pos(i)
	echo("get_blood_pos( " .. i .. ") = " .. x .. ", " .. y .. ", " .. z)
end
