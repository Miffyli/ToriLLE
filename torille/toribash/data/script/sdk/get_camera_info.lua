-- camera_info = get_camera_info()

-- USE: Returns an array containing camera information
-- NOTES: The example displays the field 'pos'

camera_info = get_camera_info()

echo("camera_info = get_camera_info()")
for key,value in pairs(camera_info.pos) do 
        echo (key ..  ": " .. value)
end

