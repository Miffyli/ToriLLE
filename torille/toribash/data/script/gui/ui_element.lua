-- ui_element.lua
-- Base class for UI elements

do
	local UIElement = { pos={x=0, y=0}, dim={w=10, h=10}, visible=true, enabled=true, draggable=false, parent=nil, behavior=nil }

	function UIElement:new(o)
		local element = o or { }
		setmetatable(element, self)
		self.__index = self
		return element
	end

	function UIElement:get_absolute_pos()
		local x, y = self.pos.x, self.pos.y
		if (self.parent ~= nil) then
			local px, py = self.parent:get_absolute_pos()
			x, y = x + px, y + py
		end
		return x, y
	end

	function UIElement:set_pos(x, y)
		self.pos.x = x
		self.pos.y = y
	end

	function UIElement:translate(dx, dy)
		self.pos.x = self.pos.x + dx
		self.pos.y = self.pos.y + dy
	end

	function UIElement:hit(x, y)
		local sx, sy = self:get_absolute_pos()
		return not ( (x < sx or x > sx + self.dim.w) or (y < sy or y > sy + self.dim.h) )
	end

	function UIElement:mouse_move(x, y)
	end

	function UIElement:mouse_up(mousebtn, x, y)
	end

	function UIElement:mouse_down(mousebtn, x, y)
	end

	function UIElement:draw()
	end

	function UIElement:update(delta_time)
		if (self.behavior ~= nil) then
			self.behavior(self, delta_time)
		end
	end

	GUI = GUI or { }
	GUI.UIElement = UIElement
end

