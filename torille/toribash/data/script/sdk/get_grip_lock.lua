-- player, target_type, target_limb, gripx, gripy, gripz = get_grip_lock (number player_index, number joint_index)

-- USE: Returns grip lock info
-- NOTES: -


function hello() 

---[[
	local a, b, c, d, e, f
	a, b, c, d, e, f = get_grip_lock(1, BODYPARTS.L_HAND)
	echo ("Grips: " .. tostring(a) .. " " .. tostring(b) .. " " .. tostring(c) .. " " .. tostring(d) .. " " .. tostring(e) .. " " .. tostring(f))
	
	a, b, c, d, e, f = get_grip_lock(1, BODYPARTS.R_HAND)
	echo ("Grips: " .. tostring(a) .. " " .. tostring(b) .. " " .. tostring(c) .. " " .. tostring(d) .. " " .. tostring(e) .. " " .. tostring(f))
	
	a, b, c, d, e, f = get_grip_lock(0, BODYPARTS.L_HAND)
	echo ("Grips: " .. tostring(a) .. " " .. tostring(b) .. " " .. tostring(c) .. " " .. tostring(d) .. " " .. tostring(e) .. " " .. tostring(f))
	
	a, b, c, d, e, f = get_grip_lock(0, BODYPARTS.R_HAND)
	echo ("Grips: " .. tostring(a) .. " " .. tostring(b) .. " " .. tostring(c) .. " " .. tostring(d) .. " " .. tostring(e) .. " " .. tostring(f))
--]]

	--echo ("GRARRR!!")
	
	
end

add_hook("enter_frame", "testtest", hello)
