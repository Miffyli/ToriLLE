-- color_info = get_color_info (integer color_index)

-- USE: Returns the color info of a specific color
-- NOTES: -

local color_index = 42
local color_info = get_color_info(color_index)

echo ("color_info = get_color_info(" .. color_index .. ")")
echo ("R: " .. color_info.r .. " G: "  .. color_info.g .. " B: " .. color_info.b)
