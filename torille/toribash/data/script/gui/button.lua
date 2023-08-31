-- button.lua
-- A Button class
dofile ("gui/ui_element.lua")

do
local UIButtonState = { Up = 0, Hover = 1, Down = 2 }
-- Inherit from UIElement
local UIButton = GUI.UIElement:new { state = UIButtonState.Up, texture=nil, clickthrough=false, onClick=nil, onHold=nil, label=nil }
UIButton.back_colors = { normal={0.9, 0.9, 0.9, 1}, hover={1, 1, 1, 1}, down={0.6, 0.6, 0.6, 1}, disabled={0.4, 0.4, 0.4, 1} }
UIButton.text_colors = { normal={0, 0, 0, 1}, hover={0, 0, 0, 1}, down={0, 0, 0, 1}, disabled={0.5, 0.5, 0.5, 1} }

function UIButton:mouse_move(x, y)
	if (self.enabled == true and self:hit(x, y) == true) then
		if (self.state == UIButtonState.Up) then self.state = UIButtonState.Hover end
		return 1
	end
	self.state = UIButtonState.Up
	return 0
end

function UIButton:mouse_up(mouse_btn, x, y)
	if (self.clickthrough == false and self:hit(x, y) == true) then
		if (self.enabled == true) then
			self.state = UIButtonState.Hover
			if (GUI and GUI.UIManager and GUI.UIManager.get_focus() == self) then self.onClick(self) end
		end
		return 1
	end
	self.state = UIButtonState.Up
	return 0
end

function UIButton:mouse_down(mouse_btn, x, y)
	if (self.clickthrough == false and self:hit(x, y) == true) then
		if (self.enabled == true) then
			self.state = UIButtonState.Down
			if (GUI and GUI.UIManager) then GUI.UIManager.set_focus(self) end
		end
		return 1
	end
	return 0
end

function UIButton:draw()
	if (self.visible == false) then
		return
	end

	local x, y = self:get_absolute_pos()
	local w, h = self.dim.w, self.dim.h

	if (self.enabled == false) then
		set_color(unpack(self.back_colors.disabled))
	elseif self.state == UIButtonState.Hover then
		set_color(unpack(self.back_colors.hover))
	elseif self.state == UIButtonState.Down then
		set_color(unpack(self.back_colors.down))
	else
		set_color(unpack(self.back_colors.normal))
	end
	if self.texture then draw_quad(x, y, w, h, self.texture) else draw_quad(x, y, w, h) end

	if (self.label ~= nil) then
		if (self.enabled == false) then
			set_color(unpack(self.text_colors.disabled))
		elseif self.state == UIButtonState.Hover then
			set_color(unpack(self.text_colors.hover))
		elseif self.state == UIButtonState.Down then
			set_color(unpack(self.text_colors.down))
		else
			set_color(unpack(self.text_colors.normal))
		end
		local font = self.label.font or FONTS.SMALL
		draw_text(self.label.text, x, y, font)
	end
end

function UIButton:update(delta_time)
	-- Enable holding down of button
	if (self.state == UIButtonState.Down and self.onHold ~= nil) then
		self.onHold(self)
	elseif (self.state == UIButtonState.Hover and GUI and GUI.UIManager) then
		local mx, my = GUI.UIManager.get_mouse_pos()
		if not self:hit(mx, my) then
			self.state = UIButtonState.Up
		end
	end

	GUI.UIElement.update(self, delta_time)
end


GUI = GUI or { }
GUI.Button = UIButton

end

