-- x,y,z = get_blood_vel(integer blood_index)

-- USE: returns the velocity of a blood particle
-- NOTES: -

for i=0,get_num_blood_particles()-1 do
	local x,y,z = get_blood_vel(i)
	echo("get_blood_vel( " .. i .. ") = " .. x .. ", " .. y .. ", " .. z)
end
