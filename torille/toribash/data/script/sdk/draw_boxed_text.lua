-- draw_boxed_text(string text, number pos_x, number pos_y, number box_width, number box_height, number line_height, [, integer font_type])

-- USE: Draws text that wraps around and is bound to a width and a height
-- NOTES: Words are seperated via space characters ' '.

local longstring = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam tincidunt, ante ut dignissim sagittis, arcu urna consectetur tellus, vitae viverra leo neque at ligula. Nullam gravida, ipsum ut pulvinar rhoncus."

local function draw_text_example()
      set_color(0, 0, 0, 1)
      draw_boxed_text(longstring, 5, 100, 200, 400, 15, 1)
end

add_hook("draw2d", "draw_boxed_text_example", draw_text_example)
