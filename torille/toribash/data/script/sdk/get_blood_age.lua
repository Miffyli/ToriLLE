-- age = get_blood_age(integer blood_index)

-- USE: returns the age of a blood particle
-- NOTES: -

for i=0,get_num_blood_particles()-1 do
	echo("get_blood_age( " .. i .. ") = " .. get_blood_age(i))
end
