-- renderman.lua

-- USE: Generates a RIB file (and a shadow RIB file) for rendering in the Renderman format
-- NOTES: Running this script will produce two RIB files in the renderman subdirectory. Render
-- the shadow RIB first before rendering the main RIB. The output of the render should produce
-- a SHD file and a TIF file.

-- Shaders used: "plastic", "background"

-- get_body_from_joint
-- Useful for finding which body part a joint is connected to
function get_body_from_joint (joint)
	if joint == "NECK" then return 0
	elseif joint == "CHEST" then return 1 
	elseif joint == "LUMBAR" then return 2
	elseif joint == "ABS" then return 3
	elseif joint == "RIGHT PECS" then return 5
	elseif joint == "RIGHT SHOULDER" then return 6
	elseif joint == "RIGHT ELBOW" then return 7
	elseif joint == "LEFT PECS" then return 8
	elseif joint == "LEFT SHOULDER" then return 9
	elseif joint == "LEFT ELBOW" then return 10
	elseif joint == "RIGHT WRIST" then return 11
	elseif joint == "LEFT WRIST" then return 12
	elseif joint == "RIGHT GLUTE" then return 13
	elseif joint == "LEFT GLUTE" then return 14
	elseif joint == "RIGHT HIP" then return 15
	elseif joint == "LEFT HIP" then return 16
	elseif joint == "RIGHT KNEE" then return 15
	elseif joint == "LEFT KNEE" then return 16
	elseif joint == "RIGHT ANKLE" then return 18
	elseif joint == "LEFT ANKLE" then return 17
	else return -1
	end
end

-- placecam
-- Places the camera in the world correctly
function placecam (cam, file)
	local direction = {x=cam.lookat.x-cam.pos.x, y=cam.lookat.y-cam.pos.y, z=cam.lookat.z-cam.pos.z}
	local length = math.sqrt(direction.x^2+direction.y^2+direction.z^2)
	local angle1 = math.deg(math.atan2(direction.x,direction.y))
	local angle2 = math.deg(math.atan2(math.sqrt(direction.x^2+direction.y^2), direction.z))
	file:write("Scale 1 -1 1\n")
	file:write("Translate 0 0 " .. length .. "\n")
	file:write("Rotate " .. angle2 .. " 1 0 0\n")
	file:write("Rotate " .. angle1 .. " 0 0 1\n")
	file:write("Translate " .. -cam.lookat.x .. " " .. -cam.lookat.y .. " " .. -cam.lookat.z .. "\n")
end

-- Variables
local rib = "main.rib"
local shadow_rib = "shadow.rib"
local image_name = "main.tif"
local shadow_name = "shadow.shd"
local shader_joint = "plastic"
local shader_body = "plastic"
local bgcolor = { r = 1.0, g = 1.0, b = 1.0 }
local fps = 100
local frame_len = 1/fps
local pixel_samples = 4 -- higher values for better quality (longer rendering time)
local shadow_pixel_samples = 2
local display_mode = "file"
local res_width = 800
local res_height = 3*res_width/4
local shadow_res = 1024 
-- shadow map resolution should be bigger than actual resolution
-- and to the power of 2 i.e. (2^n)
-- height is not required because it is a square

local fov = 49.0
local cam = {
	pos = {	x=get_camera_info().pos.x,
		y=get_camera_info().pos.y,
		z=get_camera_info().pos.z},
	lookat={x=get_camera_info().lookat.x,
		y=get_camera_info().lookat.y,
		z=get_camera_info().lookat.z}
	}
-- focus on the chest of player 0
local focus = {x = get_body_info(0,2).pos.x, y = get_body_info(0,2).pos.y, z = get_body_info(0,2).pos.z}
local dof = math.sqrt((cam.pos.x - focus.x)^2 + (cam.pos.y - focus.y)^2 + (cam.pos.z - focus.z)^2)
local fstop = 16.0

file = io.open("renderman/" .. rib,"w")
shadow = io.open("renderman/" .. shadow_rib,"w")

echo ("Saved to renderman/" .. rib .. " and renderman/" .. shadow_rib)

-- Image Properties
file:write("# Image properties\n")
file:write("Display \"" .. image_name .. "\" \"" .. display_mode .. "\" \"rgb\"\n")
file:write("Format " .. res_width .. " " .. res_height .. " " .. 1.0 .. "\n")
file:write("PixelSamples " ..  pixel_samples .. " " .. pixel_samples .. "\n")
file:write("Option \"limits\" \"eyesplits\" 16\n")
file:write("\n")

shadow:write("# Image properties\n")
shadow:write("Display \"" .. shadow_name .. "\" \"shadow\" \"z\"\n")
shadow:write("Format " .. shadow_res .. " " .. shadow_res .. " " .. 1.0 .. "\n")
shadow:write("PixelSamples " ..  shadow_pixel_samples .. " " .. shadow_pixel_samples .. "\n")
shadow:write("ShadingRate 1\n")
shadow:write("PixelFilter \"box\" 1 1\n")
shadow:write("Hider \"hidden\" \"depthfilter\" \"midpoint\"\n")
shadow:write("\n")

-- Camera Settings
file:write("# Camera settings\n")
file:write("Projection \"perspective\" \"fov\" " .. fov .. "\n")
file:write("DepthOfField " .. fstop .. " 1.0 " .. dof .. "\n")
file:write("\n")

placecam(cam, file)
file:write("\n")

shadow:write("# Camera settings\n")
shadow:write("Projection \"perspective\" \"fov\" " .. fov*2 .. "\n")
shadow:write("\n")

-- Lighting and Shadows
local light1 = {pos = {x=4, y=1, z=5},
		lookat = {x=cam.lookat.x, y=cam.lookat.y, z=0},
		intensity = 1}

placecam(light1, shadow)
shadow:write("\n")

file:write("# Declare\n")
file:write("Declare \"shadowname\" \"string\"\n")
file:write("\n")

file:write("# Lighting\n")
file:write("LightSource \"ambientlight\" 0 \"intensity\" 0.2\n")
file:write("LightSource \"shadowdistant\" 1 \"intensity\" [" .. light1.intensity .. "] \"from\"\n")
file:write("[" .. light1.pos.x .. " " .. light1.pos.y .. " " .. light1.pos.z .. "] \"to\"\n")
file:write("[" .. light1.lookat.x .. " " .. light1.lookat.y .. " " .. light1.lookat.z .. "] \"shadowname\" [\"" .. shadow_name .. "\"] \"width\" [8]\n") 

----------

file:write("FrameBegin 1\n")
file:write("\n")

-- Background
file:write("Declare \"background\" \"color\"\n")
file:write("Imager \"background\" \"background\" [ " .. bgcolor.r .. " " .. bgcolor.g .. " " .. bgcolor.b .. "]\n\n")

file:write("WorldBegin\n")
file:write("\n")

shadow:write("WorldBegin\n")
shadow:write("\n")

local joints = {}

for player_index = 0, 1 do
	file:write("# ---=== Player " .. player_index .. " ===---\n")
	file:write("\n")

	shadow:write("# ---=== Player " .. player_index .. " ===---\n")
	shadow:write("\n")

	-- Joints
	file:write("# - JOINTS -\n")
	file:write("Surface \"" .. shader_joint .. "\"\n")
	shadow:write("# - JOINTS -\n")
	shadow:write("Surface \"null\"\n")

	if player_index == 0 then		
		file:write("Color [1 0.5 0]\n")
		file:write("\n")
	else
		file:write("Color [0 0.25 1]\n")
		file:write("\n")
	end
---[[
	for i=0, 19 do
		local x, y, z = get_joint_pos(player_index, i)
		local joint_radius = get_joint_radius(player_index, i)
		local joint_name = get_joint_info(player_index, i).name
		local linear_vel_x, linear_vel_y, linear_vel_z = get_body_linear_vel(player_index, get_body_from_joint(joint_name))
		local prevX, prevY, prevZ =  x-(linear_vel_x*frame_len), y-(linear_vel_y*frame_len), z-(linear_vel_z*frame_len)
		file:write("# " .. joint_name .. "\n")
		file:write("TransformBegin\n")
	
		file:write("MotionBegin [0 1]\n")
		file:write("Translate " .. prevX .. " " .. prevY.. " " .. prevZ .. "\n")
		file:write("Translate " .. x .. " " .. y .. " " .. z .. "\n")
		file:write("MotionEnd\n")

		file:write("Sphere " .. joint_radius .. " -" .. joint_radius .. " " .. joint_radius .. " 360\n")

		file:write("TransformEnd\n")
		file:write("\n")

		shadow:write("# " .. joint_name .. "\n")
		shadow:write("TransformBegin\n")
		shadow:write("Translate " .. x .. " " .. y .. " " .. z .. "\n")
		shadow:write("Sphere " .. joint_radius .. " -" .. joint_radius .. " " .. joint_radius .. " 360\n")
		shadow:write("TransformEnd\n")
		shadow:write("\n")
	end
--]]
	-- Body
	file:write("# - BODY -\n")
	file:write("Surface \"" .. shader_body .. "\"\n")
	file:write("Color [1 1 1]\n")
	file:write("\n")
---[[
	for i=0, 20 do		
		local body_info = get_body_info(player_index, i)
		local x, y, z = body_info.pos.x, body_info.pos.y, body_info.pos.z
		local rot = body_info.rot
		local sideX,sideY,sideZ = body_info.sides.x/2, body_info.sides.y/2, body_info.sides.z/2
		local linear_vel_x, linear_vel_y, linear_vel_z = get_body_linear_vel(player_index, i)
		local prevX, prevY, prevZ =  x-(linear_vel_x*frame_len), y-(linear_vel_y*frame_len), z-(linear_vel_z*frame_len)

		file:write("# " .. i .. " " .. body_info.name .. "\n")
		file:write("TransformBegin\n")

		file:write("Transform [\n")
		file:write(rot.r0 .. " " .. rot.r4 .. " " .. rot.r8 .. " " .. 0
		 .. "\n" .. rot.r1 .. " " .. rot.r5 .. " " .. rot.r9 .. " " .. 0
		 .. "\n" .. rot.r2 .. " " .. rot.r6 .. " " .. rot.r10 .. " " .. 0
		 .. "\n" .. 0 .. " " .. 0 .. " " .. 0 .. " " .. 1
		 .. "\n")
		file:write("]\n")
		file:write("\n")
	
		file:write("MotionBegin [0 1]\n")
	
		file:write("Transform [\n")
		file:write(rot.r0 .. " " .. rot.r4 .. " " .. rot.r8 .. " " .. 0
		 .. "\n" .. rot.r1 .. " " .. rot.r5 .. " " .. rot.r9 .. " " .. 0
		 .. "\n" .. rot.r2 .. " " .. rot.r6 .. " " .. rot.r10 .. " " .. 0
		 .. "\n" .. prevX .. " " .. prevY .. " " .. prevZ .. " " .. 1
		 .. "\n")
		file:write("]\n")
		file:write("\n")

		file:write("ConcatTransform [\n")
		file:write(rot.r0 .. " " .. rot.r4 .. " " .. rot.r8 .. " " .. 0
		 .. "\n" .. rot.r1 .. " " .. rot.r5 .. " " .. rot.r9 .. " " .. 0
		 .. "\n" .. rot.r2 .. " " .. rot.r6 .. " " .. rot.r10 .. " " .. 0
		 .. "\n" .. x .. " " .. y .. " " .. z .. " " .. 1
		 .. "\n")
		file:write("]\n")
		file:write("\n")
		
		file:write("MotionEnd\n")
		
		shadow:write("# " .. i .. " " .. body_info.name .. "\n")
		shadow:write("TransformBegin\n")
		shadow:write("Transform [\n")
		shadow:write(rot.r0 .. " " .. rot.r4 .. " " .. rot.r8 .. " " .. 0
		 .. "\n" .. rot.r1 .. " " .. rot.r5 .. " " .. rot.r9 .. " " .. 0
		 .. "\n" .. rot.r2 .. " " .. rot.r6 .. " " .. rot.r10 .. " " .. 0
		 .. "\n" .. x .. " " .. y .. " " .. z .. " " .. 1
		 .. "\n")
		shadow:write("]\n")
		shadow:write("\n")
		
		-- Head
		if i==0 then
			file:write("Sphere " .. body_info.sides.x .. " -" .. body_info.sides.x .. " " .. body_info.sides.x .. " 360\n")
			file:write("\n")
			shadow:write("Sphere " .. body_info.sides.x .. " -" .. body_info.sides.x .. " " .. body_info.sides.x .. " 360\n")
			shadow:write("\n")

		-- Legs
		elseif (i >=15 and i <=18) then
			file:write("Cylinder ")
			file:write(body_info.sides.x .. " -" .. sideY .. " " .. sideY .. " 360\n")
			file:write("\n")
			
			file:write("ConcatTransform [\n")
			file:write( 1 .. " " .. 0 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 1 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. 1 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. sideY .. " " .. 1
			 .. "\n")
			file:write("]\n")
			
			file:write("Sphere " .. body_info.sides.x .. " " .. 0 .. " " .. body_info.sides.x .. " 360\n")
			file:write("\n")
		
			file:write("ConcatTransform [\n")
			file:write( 1 .. " " .. 0 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 1 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. 1 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. -2*sideY .. " " .. 1
			 .. "\n")
			file:write("]\n")
			file:write("\n")
			
			file:write("Sphere " .. body_info.sides.x .. " -" .. body_info.sides.x .. " " .. 0 .. " 360\n")
			file:write("\n")

			shadow:write("Cylinder ")
			shadow:write(body_info.sides.x .. " -" .. sideY .. " " .. sideY .. " 360\n")
			shadow:write("\n")
			
			shadow:write("ConcatTransform [\n")
			shadow:write( 1 .. " " .. 0 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 1 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. 1 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. sideY .. " " .. 1
			 .. "\n")
			shadow:write("]\n")
			
			shadow:write("Sphere " .. body_info.sides.x .. " " .. 0 .. " " .. body_info.sides.x .. " 360\n")
			shadow:write("\n")
		
			shadow:write("ConcatTransform [\n")
			shadow:write( 1 .. " " .. 0 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 1 .. " " .. 0 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. 1 .. " " .. 0
			 .. "\n" .. 0 .. " " .. 0 .. " " .. -2*sideY .. " " .. 1
			 .. "\n")
			shadow:write("]\n")
			shadow:write("\n")
			
			shadow:write("Sphere " .. body_info.sides.x .. " -" .. body_info.sides.x .. " " .. 0 .. " 360\n")
			shadow:write("\n")

		-- The Rest		
		else

			file:write("PointsPolygons\n")
			file:write("\n")

			file:write("\t[ 4 4 4 4 4 4 ] \n")
			file:write("\n")

			file:write("\t[\n")
			file:write("\t\t 4 5 6 7\n") -- front
			file:write("\t\t 5 1 2 6\n") -- right
			file:write("\t\t 0 4 7 3\n") -- left
			file:write("\t\t 4 0 1 5\n") -- top
			file:write("\t\t 7 6 2 3\n") -- bottom
			file:write("\t\t 1 0 3 2\n") -- rear
			file:write("\t]\n\n")
			file:write("\n")

			file:write("\t\"P\" [\n")
			file:write("\t -" .. sideX .. "  " .. sideY .. " -" .. sideZ .. "\n") -- 0 left top rear
			file:write("\t  " .. sideX .. "  " .. sideY .. " -" .. sideZ .. "\n") -- 1 right top rear
			file:write("\t  " .. sideX .. " -" .. sideY .. " -" .. sideZ .. "\n") -- 2 right bottom rear
			file:write("\t -" .. sideX .. " -" .. sideY .. " -" .. sideZ .. "\n") -- 3 left bottom rear
			file:write("\t -" .. sideX .. "  " .. sideY .. "  " .. sideZ .. "\n") -- 4 left top front
			file:write("\t  " .. sideX .. "  " .. sideY .. "  " .. sideZ .. "\n") -- 5 right top front
			file:write("\t  " .. sideX .. " -" .. sideY .. "  " .. sideZ .. "\n") -- 6 right bottom front
			file:write("\t -" .. sideX .. " -" .. sideY .. "  " .. sideZ .. "\n") -- 7 left bottom front

			file:write("\t]\n")
			file:write("\n")

			shadow:write("PointsPolygons\n")
			shadow:write("\n")

			shadow:write("\t[ 4 4 4 4 4 4 ] \n")
			shadow:write("\n")

			shadow:write("\t[\n")
			shadow:write("\t\t 4 5 6 7\n") -- front
			shadow:write("\t\t 5 1 2 6\n") -- right
			shadow:write("\t\t 0 4 7 3\n") -- left
			shadow:write("\t\t 4 0 1 5\n") -- top
			shadow:write("\t\t 7 6 2 3\n") -- bottom
			shadow:write("\t\t 1 0 3 2\n") -- rear
			shadow:write("\t]\n\n")
			shadow:write("\n")

			shadow:write("\t\"P\" [\n")
			shadow:write("\t -" .. sideX .. "  " .. sideY .. " -" .. sideZ .. "\n") -- 0 left top rear
			shadow:write("\t  " .. sideX .. "  " .. sideY .. " -" .. sideZ .. "\n") -- 1 right top rear
			shadow:write("\t  " .. sideX .. " -" .. sideY .. " -" .. sideZ .. "\n") -- 2 right bottom rear
			shadow:write("\t -" .. sideX .. " -" .. sideY .. " -" .. sideZ .. "\n") -- 3 left bottom rear
			shadow:write("\t -" .. sideX .. "  " .. sideY .. "  " .. sideZ .. "\n") -- 4 left top front
			shadow:write("\t  " .. sideX .. "  " .. sideY .. "  " .. sideZ .. "\n") -- 5 right top front
			shadow:write("\t  " .. sideX .. " -" .. sideY .. "  " .. sideZ .. "\n") -- 6 right bottom front
			shadow:write("\t -" .. sideX .. " -" .. sideY .. "  " .. sideZ .. "\n") -- 7 left bottom front

			shadow:write("\t]\n")
			shadow:write("\n")
		end

		file:write("TransformEnd\n")
		file:write("\n")
		shadow:write("TransformEnd\n")
		shadow:write("\n")
	end
	--]]

end

----------

-- Blood
local active_blood_particles = get_active_bloods()
local num_segments = 16
local blood = {}

for i=0, num_segments do
	blood[i] = math.floor(i*#active_blood_particles/num_segments)
end

file:write("# BLOOD\n")
file:write("Color 1 0 0\n")
file:write("\n")

file:write("TransformBegin\n")
file:write("\n")

-- Blood (Using "Blobby")
--[[
for j=1, num_segments do
	local num_particles = blood[j] - blood[j-1]
	file:write("Identity\n")
	file:write("Blobby " .. num_particles .. "\n")
	file:write("[")
	for i=0, num_particles-1 do
		file:write("1001 " .. i*16 .. "\n")
	end
	file:write("0 " .. num_particles .. "\n")
	for i=0, num_particles-1 do
		file:write(i .. " ")
	end
	file:write("]\n")
	file:write("[")

	for i=blood[j-1], blood[j]-1 do
		local bloodx,bloody,bloodz = get_blood_pos(i)
		local blood_radius = get_blood_radius(i)*2.5

		-- Weird bug with blood coordinates, fix by making the blood particles tiny (for now)
		if (bloodx == 0 and bloody == i+20) then
			bloody, bloodz = 0.1, 0.1
			blood_radius = 0.000001
		end
		file:write (blood_radius .. " 0 0 0  0 " .. blood_radius .. " 0 0  0 0 " .. blood_radius .. " 0  " .. bloodx .. " " .. bloody .. " " .. bloodz .. " 1\n")
	end

	file:write("]\n")
	file:write("[\"\"]\n")
	file:write("\n")

end
--]]

-- Blood (Using Spheres)
---[[
for i=0,#active_blood_particles-1 do
	local bloodx,bloody,bloodz = get_blood_pos(i)
	local blood_radius = get_blood_radius(i)*2.5
	local linear_vel_x, linear_vel_y, linear_vel_z = get_blood_vel(i)
	local prevX, prevY, prevZ =  bloodx-(linear_vel_x*frame_len), bloody-(linear_vel_y*frame_len), bloodz-(linear_vel_z*frame_len)
	file:write("TransformBegin\n")
	file:write("MotionBegin [0 1]\n")
	file:write("Translate " .. prevX .. " " .. prevY .. " " .. prevZ .. "\n")
	file:write("Translate " .. bloodx .. " " .. bloody .. " " .. bloodz .. "\n")
	file:write("MotionEnd\n")
	file:write("Sphere " .. get_blood_radius(i) .. " " .. -1*get_blood_radius(i) .. " " .. get_blood_radius(i) .. " 360\n")
	file:write("TransformEnd\n")
	file:write("\n")
end
--]]

file:write("TransformEnd\n")
file:write("\n")

----------


-- Floor
file:write("TransformBegin\n")
file:write("Scale 50 50 1\n")
file:write("Color [1 1 1]\n")
file:write("\n")
file:write("Patch \"bilinear\" \"P\"\n")
file:write("[" .. -1 .. " " .. -1 .. " 0\n")
file:write(1 .. " " .. -1 .. " 0\n")
file:write(-1 .. " " .. 1 .. " 0\n")
file:write(1 .. " " .. 1 .. " 0]\n")
file:write("TransformEnd\n\n")
file:write("\n")

file:write("WorldEnd\n")
file:write("\n")

file:write("FrameEnd\n")
file:write("\n")

file:write("# EOF")

file:close()

shadow:write("WorldEnd\n")
shadow:write("\n")

shadow:write("# EOF")

shadow:close()
