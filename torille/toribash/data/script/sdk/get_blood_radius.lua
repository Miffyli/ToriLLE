-- radius = get_blood_radius(integer blood_index)

-- USE: returns the radius of a blood particle
-- NOTES: -

for i=0,get_num_blood_particles()-1 do
	echo("get_blood_radius( " .. i .. ") = " .. get_blood_radius(i))
end
