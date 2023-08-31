-- 3D UI class
dofile('toriui/uielement.lua')

CUBE = 1
SPHERE = 2
CAPSULE = 3
CUSTOMOBJ = 4

TORI = 0
UKE = 1

OBJMODELCACHE = OBJMODELCACHE or {}
OBJMODELINDEX = OBJMODELINDEX or 0

do
	UIElement3DManager = UIElement3DManager or {}
	UIVisual3DManager = UIVisual3DManager or {}
	
	if (not UIElement3D) then 
		UIElement3D = UIElement:new()
	end
	
	function UIElement3D:new(o)
		local elem = {
			globalid = 0,
			parent = nil,
			child = {},
			rotXYZ = { x = 0, y = 0, z = 0 },
			pos = {},
			shift = {},
			bgColor = { 1, 1, 1, 1 },
			shapeType = CUBE,
			customDisplay = function() end
		}
		setmetatable(elem, UIElement3D)
		self.__index = self
		
		o = o or nil
		if (o) then
			if (o.playerAttach) then
				elem.playerAttach = o.playerAttach
				elem.attachBodypart = o.attachBodypart
				elem.attachJoint = o.attachJoint
			end
			if (o.parent) then
				elem.globalid = o.parent.globalid
				elem.parent = o.parent
				table.insert(elem.parent.child, elem)
				elem.shift = { x = o.pos[1], y = o.pos[2], z = o.pos[3] }
				elem.rotXYZ = { x = elem.parent.rotXYZ.x, y = elem.parent.rotXYZ.y, z = elem.parent.rotXYZ.z }
				elem:setChildShift()
				for i,v in pairs(elem.shift) do
					elem.pos[i] = elem.parent.pos[i] + elem.shift[i]
				end
			else
				elem.pos = { x = o.pos[1], y = o.pos[2], z = o.pos[3] }
			end
			elem.size = { x = o.size[1], y = o.size[2], z = o.size[3] }
			if (o.rot) then
				elem.rotXYZ.x = elem.rotXYZ.x + o.rot[1]
				elem.rotXYZ.y = elem.rotXYZ.y + o.rot[2]
				elem.rotXYZ.z = elem.rotXYZ.z + o.rot[3]
			end
			elem:updateRotations(elem.rotXYZ)
			if (o.objModel) then
				elem.shapeType = CUSTOMOBJ
				elem:updateObj(o.objModel)
			end
			if (o.globalid) then
				elem.globalid = o.globalid
			end
			if (o.bgColor) then
				elem.bgColor = o.bgColor
			end
			if (o.hoverColor) then
				elem.hoverColor = o.hoverColor
			end
			if (o.pressedColor) then
				elem.pressedColor = o.pressedColor
			end
			if (o.shapeType) then
				elem.shapeType = o.shapeType
			end
			if (o.interactive) then
				elem.interactive = o.interactive
				table.insert(UIMouseHandler, elem)
			end
			if (o.hoverSound) then
				elem.hoverSound = o.hoverSound
			end
			if (o.upSound) then
				elem.upSound = o.upSound
			end
			if (o.downSound) then
				elem.downSound = o.downSound
			end
			
			table.insert(UIElement3DManager, elem)
			table.insert(UIVisual3DManager, elem)
		end
		
		return elem
	end
	
	function UIElement3D:kill(childOnly)
		for i,v in pairs(self.child) do
			v:kill()
		end
		if (childOnly) then
			self.child = {}
			return true
		end
		
		for i,v in pairs(UIMouseHandler) do
			if (self == v) then
				table.remove(UIMouseHandler, i)
				break
			end
		end
		for i,v in pairs(UIVisual3DManager) do
			if (self == v) then
				table.remove(UIVisual3DManager, i)
				break
			end
		end
		for i,v in pairs(UIElement3DManager) do
			if (self == v) then
				table.remove(UIElement3DManager, i)
				break
			end
		end
		self = nil
	end
	
	function UIElement3D:addCustomEnterFrame(func)
		self.customEnterFrameFunc = func
		func()
	end
	
	function UIElement3D:display()
		if (self.hoverState ~= false and self.hoverColor) then
			for i = 1, 4 do
				if ((self.bgColor[i] > self.hoverColor[i] and self.animateColor[i] > self.hoverColor[i]) or (self.bgColor[i] < self.hoverColor[i] and self.animateColor[i] < self.hoverColor[i])) then
					self.animateColor[i] = self.animateColor[i] - math.floor((self.bgColor[i] - self.hoverColor[i]) * 150) / 1000
				end
			end
		else
			if (self.animateColor) then
				for i = 1, 4 do
					self.animateColor[i] = self.bgColor[i]
				end
			end
		end
		if (self.customDisplayBefore) then
			self.customDisplay()
		end
		if (not self.customDisplayTrue) then
			if (self.hoverState == BTN_HVR and self.hoverColor) then
				set_color(unpack(self.animateColor))
			elseif (self.hoverState == BTN_DN and self.pressedColor) then
				set_color(unpack(self.pressedColor))
			else
				set_color(unpack(self.bgColor))
			end
			if (self.shapeType == CUBE) then
				if (self.playerAttach) then
					local body = get_body_info(self.playerAttach, self.attachBodypart)
					draw_box_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, self.size.y, self.size.z, body.rot)
				else
					draw_box(self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z)
				end
			elseif (self.shapeType == SPHERE) then
				if (self.playerAttach) then
					if (self.attachBodypart) then
						local body = get_body_info(self.playerAttach, self.attachBodypart)
						draw_sphere_m(body.pos.x + self.pos.x, body.pos.y + self.pos.y, body.pos.z + self.pos.z, self.size.x, body.rot)
					elseif (self.attachJoint) then
						local joint = get_joint_pos2(self.playerAttach, self.attachJoint)
						local radius = get_joint_radius(self.playerAttach, self.attachJoint)
						draw_sphere(joint.x + self.pos.x, joint.y + self.pos.y, joint.z + self.pos.z, radius * self.size.x)
					end
				else
					draw_sphere(self.pos.x, self.pos.y, self.pos.z, self.size.x)
				end
			elseif (self.shapeType == CAPSULE) then
				if (self.playerAttach) then
					if (self.attachBodypart) then
						local body = get_body_info(self.playerAttach, self.attachBodypart)					
						draw_capsule_m(body.pos.x, body.pos.y, body.pos.z, self.size.y, self.size.x, body.rot)
					elseif (self.attachJoint) then
						local joint = get_joint_pos2(self.playerAttach, self.attachJoint)
						draw_capsule(joint.x, joint.y, joint.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z)
					end
				else
					draw_capsule(self.pos.x, self.pos.y, self.pos.z, self.size.y, self.size.x, self.rot.x, self.rot.y, self.rot.z)
				end
			elseif (self.shapeType == CUSTOMOBJ) then
				draw_obj(self.objModel, self.pos.x, self.pos.y, self.pos.z, self.size.x, self.size.y, self.size.z, self.rot.x, self.rot.y, self.rot.z)
			end
		end
		if (not self.customDisplayBefore) then
			self.customDisplay()
		end
	end
	
	function UIElement3D:drawVisuals(globalid)
		for i, v in pairs(UIVisual3DManager) do
			if (v.globalid == globalid) then
				v:display()
			end
		end
	end
	
	function UIElement3D:playFrameFunc(globalid)
		for i,v in pairs(UIVisual3DManager) do
			if (v.globalid == globalid) then
				if (v.customEnterFrameFunc ~= nil) then
					v.customEnterFrameFunc()
				end
			end
		end
	end
	
	function UIElement3D:show(forceReload)
		local num = nil
		
		if (self.noreload and not forceReload) then
			return false
		elseif (forceReload) then
			self.noreload = nil
		end
		
		for i,v in pairs(UIVisual3DManager) do
			if (self == v) then
				num = i
				break
			end
		end
		
		if (not num) then
			table.insert(UIVisual3DManager, self)
			if (self.interactive) then
				table.insert(UIMouseHandler, self)
			end
		end
		
		for i,v in pairs(self.child) do
			v:show()
		end
	end
	
	function UIElement3D:hide(noreload)
		local num = nil
		for i,v in pairs(self.child) do
			v:hide(noreload)
		end
		
		if (noreload) then 
			self.noreload = true
		end
		
		if (self.interactive) then
			for i,v in pairs(UIMouseHandler) do
				if (self == v) then
					num = i
					break
				end
			end
			if (num) then
				table.remove(UIMouseHandler, num)
			else
				err(UIMouseHandlerEmpty)
			end
		end
		
		for i,v in pairs(UIVisual3DManager) do
			if (self == v) then
				num = i
				break
			end
		end
		
		if (num) then
			table.remove(UIVisual3DManager, num)
		else
			err(UIElementEmpty)
		end
	end
	
	function UIElement3D:updatePos()
		for i,v in pairs(self.child) do
			v:updateChildPos()
		end
	end
	
	function UIElement3D:setChildShift()
		local rotMatrix = self.parent.rotMatrix
		local pos = self.parent.pos
		local shift = self.shift
		
		local rotatedShift = UIElement3D:multiply({ { shift.x, shift.y, shift.z } }, rotMatrix)
		local newShift = rotatedShift[1]
		
		self.shift.x = newShift[1]
		self.shift.y = newShift[2]
		self.shift.z = newShift[3]
	end 
	
	function UIElement3D:updateChildPos(rotMatrix, pos, shift)
		local rotMatrix = rotMatrix or self.parent.rotMatrix
		local pos = pos or self.parent.pos
		local shift = shift and { x = shift.x + self.shift.x, y = shift.y + self.shift.y, z = shift.z + self.shift.z } or self.shift
		
		local newPos = UIElement3D:multiply({ { shift.x, shift.y, shift.z } }, rotMatrix)
		local vector = newPos[1]
		
		self.pos.x = pos.x + vector[1]
		self.pos.y = pos.y + vector[2]
		self.pos.z = pos.z + vector[3]
		
		for i,v in pairs(self.child) do
			v:updateChildPos(rotMatrix, pos, shiftSum)
		end
	end
	
	function UIElement3D:moveTo(x, y, z)
		if (self.playerAttach) then
			return
		end
		if (self.parent) then
			if (x) then self.shift.x = self.shift.x + x end
			if (y) then self.shift.y = self.shift.y + y end
			if (z) then self.shift.z = self.shift.z + z end
		else
			if (x) then self.pos.x = self.pos.x + x end
			if (y) then self.pos.y = self.pos.y + y end
			if (z) then self.pos.y = self.pos.z + z end
		end
		self:updateChildPos()
	end
	
	function UIElement3D:rotate(x, y, z)
		local x = x or 0
		local y = y or 0
		local z = z or 0
		if (x == 0 and y == 0 and z == 0) then
			return
		end
		
		local rot = self.rotXYZ
		rot.x = (rot.x + x) % 360
		rot.y = (rot.y + y) % 360
		rot.z = (rot.z + z) % 360
		self:updateRotations(rot)
		
		for i,v in pairs(self.child) do
			v:rotate(x, y, z)
		end
		self:updatePos()
	end
	
	function UIElement3D:updateRotations(rot)
		self.rotMatrix = UIElement3D:getRotMatrixFromEulerAngles(math.rad(rot.x), math.rad(rot.y), math.rad(rot.z))
		local relX, relY, relZ = self:getEulerZYXFromRotationMatrix(self.rotMatrix)
		self.rot = { x = relX, y = relY, z = relZ }
	end
	
	function UIElement3D:getEulerZYXFromRotationMatrix(R)
		local clamp = R[3][1] > 1 and 1 or (R[3][1] < -1 and -1 or R[3][1])
		local x, y, z
		
		y = math.asin(-clamp)
		if (0.99999 > math.abs(R[3][1])) then
			x = math.atan2(R[3][2], R[3][3])
			z = math.atan2(R[2][1], R[1][1])
		else
			x = 0
			z = math.atan2(-R[1][2], R[2][2])
		end
		return math.deg(x), math.deg(y), math.deg(z) 
	end
	
	function UIElement3D:getEulerAnglesFromMatrixTB(rTB)
		return UIElement3D:getEulerZYXFromRotationMatrix({
			{ rTB.r0, rTB.r1, rTB.r2, rTB.r3 },
			{ rTB.r4, rTB.r5, rTB.r6, rTB.r7 },
			{ rTB.r8, rTB.r9, rTB.r10, rTB.r11 },
			{ rTB.r12, rTB.r13, rTB.r14, rTB.r15 },
		})
	end
	
	function UIElement3D:getRotMatrixFromEulerAngles(x, y, z)
		local R_x = {
			{ 1, 0, 0 },
			{ 0, math.cos(x), -math.sin(x) },
			{ 0, math.sin(x), math.cos(x) }
		}
		local R_y = {
			{ math.cos(y), 0, math.sin(y) },
			{ 0, 1, 0 },
			{ -math.sin(y), 0, math.cos(y) }
		}
		local R_z = {
			{ math.cos(z), -math.sin(z), 0 },
			{ math.sin(z), math.cos(z), 0 },
			{ 0, 0, 1 }
		}
		local R = UIElement3D:multiply(UIElement3D:multiply(R_y, R_x), R_z)
		return R
	end
	
	function UIElement3D:multiply(a, b)
		if (#a[1] ~= #b) then
			return false
		end
		
		local matrix = {}
		
		for aRow = 1, #a do
			matrix[aRow] = {}
			for bCol = 1, #b[1] do
				local sum = matrix[aRow][bCol] or 0
				for bRow = 1, #b do
					sum = sum + a[aRow][bRow] * b[bRow][bCol]
				end
				matrix[aRow][bCol] = sum
			end
		end
		
		return matrix
	end
	
	function UIElement:updateObj(model, noreload)
		local filename
		if (model) then
			if (model:find("%.%./", 4)) then
				filename = model:gsub("%.%./%.%./", "")
			elseif (model:find("%.%./")) then
				filename = model:gsub("%.%./", "data/")
			else
				filename = "data/script/" .. model:gsub("^/", "")
			end
		end
		filename = filename .. ".obj"
		
		if (not noreload and self.objModel) then
			local count, id = 0, 0
			for i,v in pairs(OBJMODELCACHE) do
				if (v == self.objModel) then
					count = count + 1
					id = i
				end
			end
			if (count == 1) then
				unload_obj(self.objModel)
				OBJMODELINDEX = OBJMODELINDEX - 1
			else
				table.remove(OBJMODELCACHE, id)
			end		
			self.objModel = nil		
		end
		
		if (not model) then
			return
		end
		
		if (OBJMODELINDEX > 127) then
			return false
		end
		
		local tempobj = io.open(filename, "r", 1)
		if (not tempobj) then
			return false
		else
			local objid = 0
			for i = 0, 127 do
				if (not OBJMODELCACHE[i]) then
					objid = i
				end
			end
			if (load_obj(objid, model)) then
				self.objModel = objid
			end
			OBJMODELINDEX = OBJMODELINDEX > objid and OBJMODELINDEX or objid
			table.insert(OBJMODELCACHE, self.objModel)
			io.close(tempobj)
		end
	end
end