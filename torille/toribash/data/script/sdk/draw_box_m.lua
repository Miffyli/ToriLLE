--draw_box_m(number pos_x, number pos_y, number pos_z, number size_x, number size_y, number size_z, table matrix_rot)
local size_x, size_y, size_z = 0.4, 0.4, 0.2

local function draw_box()
        set_color(0, 1, 1, 1)
	body = get_body_info(0, 0)
        draw_box_m(body.pos.x, body.pos.y, body.pos.z, size_x, size_y, size_z, body.rot)
end

add_hook("draw3d", "draw_box", draw_box)
