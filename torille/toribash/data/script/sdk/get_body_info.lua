-- dy_info = get_body_info (number player_index, number body_index)

-- USE: Returns an array containing body parts information
-- NOTES: -

local player_index, body_index = 0, 0

local body_info = get_body_info (player_index, body_index)
echo ("body_info = get_body_info (" .. player_index .. ", " .. body_index .. ")")
echo ("Name: " .. body_info.name)
echo ("PosX: " .. body_info.pos.x ..  " PosY: " .. body_info.pos.y .. " PosZ: " .. body_info.pos.z)
echo ("SideX: " .. body_info.sides.x ..  " SideY: " .. body_info.sides.y .. " SideZ: " .. body_info.sides.z)

--draw_box_m(0, 0, 0, 10, 10, 10, body_info.rot)
echo ("rot:")
echo ("r0: " .. body_info.rot.r0 .. " r1: " .. body_info.rot.r1 .. " r2: " .. body_info.rot.r2 .. " r3: " .. body_info.rot.r3)
echo ("r4: " .. body_info.rot.r4 .. " r5: " .. body_info.rot.r5 .. " r6: " .. body_info.rot.r6 .. " r7: " .. body_info.rot.r7)
echo ("r8: " .. body_info.rot.r8 .. " r9: " .. body_info.rot.r9 .. " r10: " .. body_info.rot.r10 .. " r11: " .. body_info.rot.r11)
echo ("r12: " .. body_info.rot.r12 .. " r13: " .. body_info.rot.r13 .. " r14: " .. body_info.rot.r14 .. " r15: " .. body_info.rot.r15)

