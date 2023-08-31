-- label.lua
-- A label class
dofile ("gui/ui_element.lua")

do
	local LabelAlign = { LEFT=0, CENTER=1, RIGHT=2 }
	local Label = GUI.UIElement:new { pos={x=0, y=0}, text="", visible=true, color={0,0,0,1}, font=FONTS.SMALL, align=LabelAlign.LEFT }

	function Label:draw()
		if (self.visible == false) then
			return
		end

		local x, y = self:get_absolute_pos()
		set_color(unpack(self.color))
		if self.align == LabelAlign.CENTER then
			draw_centered_text(self.text, y, self.font)
		elseif self.align == LabelAlign.RIGHT then
			draw_right_text(self.text, get_window_size() - x, y, self.font)
		else
			draw_text(self.text, x, y, self.font)
		end
	end

	GUI = GUI or { }
	GUI.Label = Label
	GUI.LabelAlign = LabelAlign
end

