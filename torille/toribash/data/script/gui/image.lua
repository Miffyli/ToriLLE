-- image.lua
-- A static image class
dofile ("gui/ui_element.lua")

do
	local Image = GUI.UIElement:new { texture=nil, color={1,1,1,1} }

	function Image:draw()
		local sx, sy = self:get_absolute_pos()
		set_color(unpack(self.color))
		if self.texture ~= nil then
			draw_quad(sx, sy, self.dim.w, self.dim.h, self.texture)
		else
			draw_quad(sx, sy, self.dim.w, self.dim.h)
		end
	end

	GUI = GUI or { }
	GUI.Image = Image
end

