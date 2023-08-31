local function camera()
	-- lookat needs to be called before pos 
	set_camera_lookat(0, 2, 1.5)
	set_camera_pos(6, 2, 1.5)

	-- return 1 to disable the clients camera functions
	-- NOTE to disable WASD keys you need to hook key presses
	return 1
end

add_hook("camera", "freecam", camera)

