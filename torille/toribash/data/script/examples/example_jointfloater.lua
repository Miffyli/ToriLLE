-- x, y, z = get_joint_screen_pos(integer player_index, integer joint_index)

joint_screenpos_data = {}

local function init()
    for i=0, 1
    do
	joint_screenpos_data[i] = {}
	for j=0, 19
	do
		joint_screenpos_data[i][j] = {}
		for k=0, 2
		do
			joint_screenpos_data[i][j][k] = -50
		end
	end
    end  
end

local function draw_3d()
    for i=0, 1
    do
	for j=0, 19
	do
		for k=0, 2
		do
			joint_screenpos_data[i][j][0], joint_screenpos_data[i][j][1], joint_screenpos_data[i][j][2] = get_joint_screen_pos( i, j )
		end
	end
    end  
end

local function draw_2d()
	for i=0, 19
	do
		x0, y0, z0 = get_joint_pos( 0, i )
		x1, y1, z1 = get_joint_pos( 1, i )
		
		draw_text( x0 .. ", " .. y0 .. ", " .. z0, joint_screenpos_data[0][i][0], joint_screenpos_data[0][i][1] )
		draw_text( x1 .. ", " .. y1 .. ", " .. z1, joint_screenpos_data[1][i][0], joint_screenpos_data[1][i][1] )
        end
end


init()
add_hook("draw3d", "get_joint_screen_pos", draw_3d)
add_hook("draw2d", "get_joint_screen_pos", draw_2d)
