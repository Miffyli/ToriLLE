-- container.lua
-- A UI element container
dofile ("gui/ui_element.lua")

do
	local Container = GUI.UIElement:new { pos={x=0, y=0}, dim={w=10, h=10}, enabled=true, visible=true, children=nil }

	function Container:add(ui_element)
		self.children = self.children or { }
		ui_element.parent = self
		table.insert(self.children, ui_element)
	end

	function Container:remove(ui_element)
		if (self.children ~= nil) then
			for k,v in ipairs(self.children) do
				if (v == ui_element) then
					ui_element.parent = nil
					table.remove(self.children, k)
					return
				end
			end
		end
	end

	function Container:hide()
		self.visible = false
		self.enabled = false
	end

	function Container:display()
		self.visible = true
		self.enabled = true
	end

	function Container:mouse_move(x, y)
		if self.enabled == false then
			return
		end

		if (self.children ~= nil) then
		for k,v in ipairs(self.children) do
			local retVal = v:mouse_move(x, y)
			if retVal and retVal ~= 0 then
				return retVal
			end
		end
		end
	end

	function Container:mouse_up(mousebtn, x, y)
		if self.enabled == false then
			return
		end

		if (self.children ~= nil) then
		for k,v in ipairs(self.children) do
			local retVal = v:mouse_up(mousebtn, x, y)
			if (retVal and retVal ~= 0) then
				return retVal
			end
		end
		end
	end

	function Container:mouse_down(mousebtn, x, y)
		if self.enabled == false then
			return
		end

		if (self.children ~= nil) then
		for k,v in ipairs(self.children) do
			local retVal = v:mouse_down(mousebtn, x, y)
			if (retVal and retVal ~= 0) then
				return retVal
			end
		end
		end
	end

	function Container:draw()
		if self.visible == false then
			return
		end

		if (self.children ~= nil) then
		for k,v in ipairs(self.children) do
			v:draw()
		end
		end
	end

	function Container:update(delta_time)
		if (self.children ~= nil) then
		for k,v in ipairs(self.children) do
			v:update(delta_time)
		end
		end

		GUI.UIElement.update(self, delta_time)
	end

	GUI = GUI or { }
	GUI.Container = Container
end

