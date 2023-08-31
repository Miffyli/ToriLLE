-- x, y, z = get_joint_pos (integer player_index, integer joint_index)

-- USE: Returns the world coordinates of a joint
-- NOTES: The following example draws the '+' symbol on all the joint positions

local joints = {}

local function get_joint_3d()
	for i=0,19 do
		joints[i] = {}
		x, y, z = get_joint_pos(0, i)
		joints[i]['x'], joints[i]['y'] = get_screen_pos(x, y, z);
	end
end

local function draw_stuff()
        for i=0,19 do
                draw_text("+", joints[i].x, joints[i].y)
        end
end

add_hook("draw2d", "draw_stuff", draw_stuff)
add_hook("draw3d", "get_joint_3d", get_joint_3d)


