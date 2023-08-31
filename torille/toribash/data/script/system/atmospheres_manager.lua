-- Atmospheres 2.0 manager
-- Do not modify this file

DEFAULT_SHADER = nil
ATMO_STORED_OPTS = ATMO_STORED_OPTS or {}
ATMO_SELECTED_SCREEN = ATMO_SELECTED_SCREEN or 2
ATMO_MENU_POS = ATMO_MENU_POS or { x = 10, y = 10 }
ATMO_LIST_SHIFT = ATMO_LIST_SHIFT or { 0 }

do
	Atmospheres = {}
	Atmospheres.__index = Atmospheres
	local cln = {}
	setmetatable(cln, Atmospheres)
	
	function Atmospheres:quit()
		for i,v in pairs(ATMO_STORED_OPTS) do
			set_option(v.name, v.value)
		end
		ATMO_STORED_OPTS = {}
		_ATMO = nil
		if (entityHolder) then
			entityHolder:kill()
		end
		if (DEFAULT_SHADER) then
			UIElement:runCmd("lws " .. DEFAULT_SHADER:gsub("^data/shader/", ""))
		end
		remove_hook("draw3d", "atmospheres")
	end
	
	function Atmospheres:readAtmoFile(data)
		local atmosphere = { entities = {}, shaderopts = {}, opts = {} }
		for i, ln in pairs(data) do
			local ln = ln:gsub("^%s*", ""):gsub("[\r\n]", "")
			if (ln:find("^shader ")) then
				local shader = ln:gsub("^shader ", "")
				if (not shader:find("%.inc.?$")) then
					shader = shader .. ".inc"
				end
				atmosphere.shader = shader
			elseif (ln:find("^shaderopt ")) then
				local data = { ln:gsub("^shaderopt ", ""):match(("([^ ]+) *"):rep(5)) }
				data[1] = tonumber(data[1]) and tonumber(data[1]) or SHADER_OPTIONS[data[1]:upper()]
				for i = 2, 5 do
					data[i] = tonumber(data[i])
				end
				atmosphere.shaderopts[data[1]] = { data[2], data[3], data[4], data[5] }
			elseif (ln:find("^opt ")) then
				local data = { ln:gsub("^opt ", ""):match(("([^ ]+) *"):rep(2)) }
				table.insert(atmosphere.opts, { name = data[1], value = tonumber(data[2]) })
			elseif (ln:find("^env_obj ")) then
				local entityid = ln:gsub("^env_obj ", "")
				atmosphere.entities[#atmosphere.entities + 1] = {
					name = entityid,
					pos = { 0, 0, 0 },
					rot = { 0, 0, 0 },
					size = { 1, 1, 1 },
					color = { 1, 1, 1, 1 },
					shape = CUBE
				}
			elseif (#atmosphere.entities > 0) then
				local data, dataName = {}, ""
				if (ln:find("^parent ")) then
					atmosphere.entities[#atmosphere.entities].parent = ln:gsub("^parent ", "")
				elseif (ln:find("^shape ")) then
					local shape = ln:gsub("^shape ", "")
					local model = nil
					if (shape:find("box") or shape:find("cube")) then
						shape = CUBE
					elseif (shape:find("cylinder") or shape:find("capsule")) then
						shape = CAPSULE
					elseif (shape:find("sphere")) then
						shape = SPHERE
					elseif (shape:find("custom")) then
						model = shape:gsub("^custom ", "")
						shape = CUSTOMOBJ
					end
					atmosphere.entities[#atmosphere.entities].shape = shape
					atmosphere.entities[#atmosphere.entities].model = model
				elseif (ln:find("^size ") or ln:find("^sides ")) then
					data = { ln:gsub("^si[zd]e[s]? ", ""):match(("([^ ]+) *"):rep(3)) }
					dataName = "size"
				elseif (ln:find("^randomsize ")) then
					data = { ln:gsub("^randomsize ", ""):match(("([^ ]+) *"):rep(3)) }
					dataName = "rsize"
				elseif (ln:find("^pos ")) then
					data = { ln:gsub("^pos ", ""):match(("([^ ]+) *"):rep(3)) }
					dataName = "pos"
				elseif (ln:find("^randompos ")) then
					data = { ln:gsub("^randompos ", ""):match(("([^ ]+) *"):rep(3)) }
					dataName = "rpos"
				elseif (ln:find("^rot ")) then
					data = { ln:gsub("^rot ", ""):match(("([^ ]+) *"):rep(3)) }
					dataName = "rot"
				elseif (ln:find("^rotate ")) then
					data = { ln:gsub("^rotate ", ""):match(("([^ ]+) *"):rep(3)) }
					dataName = "rotation"
					atmosphere.entities[#atmosphere.entities].animated = true
				elseif (ln:find("^move ")) then
					data = { ln:gsub("^move ", ""):match(("([^ ]+) *"):rep(3)) }
					dataName = "movement"
					atmosphere.entities[#atmosphere.entities].animated = true
				elseif (ln:find("^colo[u]?r ")) then
					data = { ln:gsub("^colo[u]?r ", ""):match(("([^ ]+) *"):rep(4)) }
					if (tonumber(data[1]) > 2 or tonumber(data[2]) > 2 or tonumber(data[3]) > 2) then
						for i = 1, 3 do
							data[i] = data[i] / 256
						end
					end
					dataName = "color"
				elseif (ln:find("^randomcolo[u]?r ")) then
					data = { ln:gsub("^randomcolo[u]?r ", ""):match(("([^ ]+) *"):rep(4)) }
					if (tonumber(data[1]) > 2 or tonumber(data[2]) > 2 or tonumber(data[3]) > 2) then
						for i = 1, 3 do
							data[i] = data[i] / 256
						end
					end
					dataName = "rcolor"
				elseif (ln:find("^count ")) then
					local count = ln:gsub("^count ", "")
					atmosphere.entities[#atmosphere.entities].count = tonumber(count)
				end
				if (#data > 0) then
					if (not atmosphere.entities[#atmosphere.entities][dataName]) then
						atmosphere.entities[#atmosphere.entities][dataName] = {}
					end
					for i,v in pairs(data) do
						if (tonumber(v)) then
							atmosphere.entities[#atmosphere.entities][dataName][i] = v + 0
						elseif (dataName == "rotation" or dataName == "movement") then
							atmosphere.entities[#atmosphere.entities][dataName][i] = v
						end
					end
				end
			end
		end
		return atmosphere
	end
	
	function Atmospheres:getWorldShader()
		local file = Files:new("../custom.cfg")
		local data = file:readAll()
		if (data) then
			for i, ln in pairs(data) do
				if (ln:find("^customworldshader ")) then
					DEFAULT_SHADER = ln:gsub("customworldshader ", ""):gsub("\"", "")
					if (DEFAULT_SHADER:len() < 5) then
						DEFAULT_SHADER = "default.inc"
					end
					break
				end
			end
		end
	end
	
	function Atmospheres:spawnToggle(viewElement, x, y, w, h, toggleTable, i)
		local maxVal = toggleTable.maxValue or 1
		local minVal = toggleTable.minValue or 0
		local name = toggleTable.names[i] or ""
		local toggleView = UIElement:new({
			parent = viewElement,
			pos = { x, y },
			size = { w, h }
		})
		local minText = UIElement:new({
			parent = toggleView,
			pos = { 0, 0 },
			size = { 30, 15 }
		})
		minText:addAdaptedText(false, minVal .. "", nil, nil, 4, LEFTMID, 0.5)
		local maxText = UIElement:new({
			parent = toggleView,
			pos = { -30, 0 },
			size = { 30, 15 }
		})
		maxText:addAdaptedText(false, maxVal .. "", nil, nil, 4, RIGHTMID, 0.5)
		local nameText = UIElement:new({
			parent = toggleView,
			pos = { toggleView.size.w / 3, 0 },
			size = { toggleView.size.w / 3, 15 }
		})
		nameText:addAdaptedText(false, name, nil, nil, 4, nil, 0.7)
		local toggleBG = UIElement:new({
			parent = toggleView,
			pos = { 0, 30 },
			size = { toggleView.size.w, toggleView.size.h - 40 },
			bgColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			interactive = true
		})
		local togglePos = 0
		if (toggleTable and i) then
			toggleTable[i] = tonumber(toggleTable[i]) > maxVal and 1 or tonumber(toggleTable[i]) / maxVal
			togglePos = toggleTable[i] * (toggleBG.size.w - 10)
		end
		local toggle = UIElement:new({
			parent = toggleBG,
			pos = { togglePos, -toggleBG.size.h - toggleBG.shift.y + 15 },
			size = { 10, toggleView.size.h - 20 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		toggle:addMouseHandlers(function()
				toggle.pressed = true
				toggle.pressedPos = toggle:getLocalPos()
			end, function()
				toggle.pressed = false
				UIElement:runCmd("worldshader " .. toggleTable.id .. " " .. toggleTable[1] .. " " .. toggleTable[2] .. " " .. toggleTable[3] .. " " .. toggleTable[4])
			end, function()
				if (toggle.pressed) then
					local xPos = MOUSE_X - toggleView.pos.x - toggle.pressedPos.x
					if (xPos < 0) then
						xPos = 0
					elseif (xPos > toggleView.size.w - toggle.size.w) then
						xPos = toggleView.size.w - toggle.size.w
					end
					if (toggleTable.boolean) then
						if (xPos + toggle.size.w / 2 > toggleView.size.w / 2) then
							xPos = toggleView.size.w - toggle.size.w
						else
							xPos = 0
						end
					end
					toggle:moveTo(xPos, nil)
					toggleTable[i] = xPos / (toggleView.size.w - 10) * (maxVal - minVal) + minVal
				end
			end)
		toggleBG:addMouseHandlers(function()
			local pos = toggleBG:getLocalPos()
			local xPos = pos.x - toggle.size.w / 2
			if (xPos < 0) then
				xPos = 0
			elseif (xPos > toggleView.size.w - toggle.size.w) then
				xPos = toggleView.size.w - toggle.size.w
			end
			if (toggleTable.boolean) then
				if (xPos + toggle.size.w / 2 > toggleView.size.w / 2) then
					xPos = toggleView.size.w - toggle.size.w
				else
					xPos = 0
				end
			end
			toggle:moveTo(xPos)
			toggleTable[i] = xPos / (toggleView.size.w - 10) * (maxVal - minVal) + minVal
			UIElement:runCmd("worldshader " .. toggleTable.id .. " " .. toggleTable[1] .. " " .. toggleTable[2] .. " " .. toggleTable[3] .. " " .. toggleTable[4])
		end)
		return toggle
	end
	
	function Atmospheres:showShaderControls()
		if (not SHADER_OPTIONS.FLOOR_COLOR) then
			return
		end
		local options = { { name = "hint", value = 0 }, { name = "feedback", value = 0 } }
		for i,v in pairs(options) do
			local found = false
			for j,k in pairs(ATMO_STORED_OPTS) do
				if (k.name == v.name) then
					found = true
				end
			end
			if (not found) then
				table.insert(ATMO_STORED_OPTS, { name = v.name, value = get_option(v.name) })
			end
			set_option(v.name, v.value)
		end
		local viewElement = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { WIN_W / 10, WIN_H - 70 },
			size = { WIN_W / 10 * 8, 60 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 10
		})
		local toggleView = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 4, 5 },
			size = { viewElement.size.w / 2, viewElement.size.h - 10 }
		})
		local currentControl = {}
		local shaderList = {}
		
		local function spawnToggles()
			for i = 1, currentControl.count do
				Atmospheres:spawnToggle(toggleView, (i - 1) * toggleView.size.w / currentControl.count + 5, 0, toggleView.size.w / currentControl.count - 10, toggleView.size.h, currentControl, i)
			end
		end
		
		for i,v in pairs(SHADER_OPTIONS) do
			if (v < 16) then
				local dropAction = function()
					currentControl = ATMO_CURRENT_SHADER[i]
					toggleView:kill(true)
					spawnToggles()
				end
				table.insert(shaderList, { text = i:gsub("_", " "), action = dropAction })
			end
		end
		currentControl = ATMO_CURRENT_SHADER.BACKGROUND_COLOR
		spawnToggles()
		
		local dropdownView = UIElement:new({
			parent = viewElement,
			pos = { 10, 10 },
			size = { viewElement.size.w / 4 - 20, viewElement.size.h - 20 },
			shapeType = ROUNDED,
			rounded = 5
		})
		TBMenu:spawnDropdown(dropdownView, shaderList, 25, WIN_H - 100, nil, 0.7, nil, 0.6)
		
		local closeButton = UIElement:new({
			parent = viewElement,
			pos = { -viewElement.size.h + 10, 10 },
			size = { viewElement.size.h - 20, viewElement.size.h - 20 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		local closeIcon = UIElement:new({
			parent = closeButton,
			pos = { 10, 10 },
			size = { closeButton.size.w - 20, closeButton.size.h - 20 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		closeButton:addMouseHandlers(nil, function()
				viewElement:kill()
				for i,v in pairs(options) do
					for j,k in pairs(ATMO_STORED_OPTS) do
						if (v.name == k.name) then
							set_option(k.name, k.value)
							break
						end
					end
				end
			end)
		local saveButton = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 4 * 3 + 10, 10 },
			size = { viewElement.size.w / 4 - 65, viewElement.size.h - 20 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 5
		})
		saveButton:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSSAVESHADER)
		saveButton:addMouseHandlers(nil, function()
				add_hook("key_up", "tbAtmospheresKeyboard", function(s) UIElement:handleKeyUp(s) return 1 end)
				add_hook("key_down", "tbAtmospheresKeyboard", function(s) UIElement:handleKeyDown(s) return 1 end)
				TBMenu:showConfirmationWindowInput(TB_MENU_LOCALIZED.SHADERSSAVING, TB_MENU_LOCALIZED.SHADERSINPUTNAME, function(name)
					local name = name:gsub("%.inc.?$", "")
					local function save()
						local file = Files:new("../data/shader/" .. name .. ".inc", FILES_MODE_WRITE)
						for i,v in pairs(ATMO_CURRENT_SHADER) do
							local line = i:lower() .. " " .. v[1] .. " " .. v[2] .. " " .. v[3] .. " " .. v[4]
							file:writeLine(line)
						end
						file:close()
						remove_hooks("tbAtmospheresKeyboard")
					end
					local file = Files:new("../data/shader/" .. name .. ".inc", FILES_MODE_READ)
					if (file.data) then
						file:close()
						TBMenu:showConfirmationWindow(TB_MENU_LOCALIZED.SHADERSERRORFILEEXISTS, save)
					else
						save()
					end
				end, function() remove_hooks("tbAtmospheresKeyboard") end)
			end)
	end
	
	function Atmospheres:setShaderInfo()
		ATMO_CURRENT_SHADER = {}
		Atmospheres:getShaderOpts()
	end
	
	function Atmospheres:getShaderOptName(id)
		for i,v in pairs(SHADER_OPTIONS) do
			if (id == v) then
				return i
			end
		end
	end
	
	function Atmospheres:getShaderOpts(id)
		local id = id or 0
		add_hook("console", "atmospheresSystem", function(ln)
				if (ln:find("worldshader")) then
					remove_hooks("atmospheresSystem")
					if (id < 33) then
						Atmospheres:getShaderOpts(id + 1)
					end
					return 1
				elseif (ln:match("[^ ]+ [^ ]+ [^ ]+ [^ ]+ *")) then
					local data = { ln:match(("([^ ]+) *"):rep(4)) }
					for i = 1, 4 do
						data[i] = tonumber(data[i]) .. ""
					end
					data.id = id
					Atmospheres:getShaderOptionData(data)
					ATMO_CURRENT_SHADER[Atmospheres:getShaderOptName(id)] = data
					return 1
				end
			end)
		UIElement:runCmd("worldshader " .. id, false, true)
	end
	
	function Atmospheres:getShaderOptionData(opt)
		if (opt.id == 2) then
			opt.count = 4
			opt.names = { "R", "G", "B", "A" }
		elseif (opt.id == 5) then
			opt.count = 1
			opt.names = { "Distance" }
			opt.minValue = -50
			opt.maxValue = 50
		elseif (opt.id == 6 or opt.id == 7) then
			opt.count = 1
			opt.names = { "Enable" }
			opt.boolean = true
		elseif (opt.id == 9 or opt.id == 8) then
			opt.count = 3
			opt.names = { "X", "Y", "Z" }
		elseif (opt.id == 15) then
			opt.count = 1
			opt.names = { "Power" }
		else
			opt.count = 3
			opt.names = { "R", "G", "B" }
		end
	end
	
	function Atmospheres:setDefaultAtmo(filename)
		local config = Files:new("../data/atmospheres/atmo.cfg", FILES_MODE_WRITE)
		config:writeLine(filename)
		config:close()
	end
	
	function Atmospheres:loadDefaultAtmo()
		local config = Files:new("../data/atmospheres/atmo.cfg")
		if (not config.data) then
			return
		end
		Atmospheres:loadAtmo(config:readAll()[1]:gsub("\r", ""):gsub("\n", ""))
		config:close()
		DEFAULT_ATMOSPHERE_ISSET = true
	end
	
	function Atmospheres:loadAtmo(filename)
		Atmospheres:quit()
		if (filename:lower() == "default.atmo") then
			return
		end
		
		add_hook("draw3d", "atmospheres", function() UIElement3D:drawVisuals(TB_ATMOSPHERES_GLOBALID) end)
		_ATMO = {}
		if (not DEFAULT_SHADER) then
			Atmospheres:getWorldShader()
		end
		if (entityHolder) then
			entityHolder:kill()
		end
		entityHolder = UIElement3D:new({
			globalid = TB_ATMOSPHERES_GLOBALID,
			pos = { 0, 0, 0 },
			size = { 0, 0, 0 }
		})
		entityHolder:addCustomDisplay(true, function()
			ATMOSPHERES_ANIMATED = (get_world_state().game_paused==0 and is_game_frozen()==1 and get_world_state().replay_mode==1) or (get_world_state().game_paused==0 and is_game_frozen()==0 and get_world_state().replay_mode==0 ) or (get_world_state().replay_mode==2 and get_world_state().game_paused==0)
		end)
		
		local file = Files:new("../data/atmospheres/" .. filename)
		if (not file.data) then
			return false
		end
		
		local atmoData = Atmospheres:readAtmoFile(file:readAll())
		file:close()
		
		local entityList = {}
		for i, entity in pairs(atmoData.entities) do
			if (entity.count) then					
				for i = 1, entity.count do
					local entityRandom = cloneTable(entity)
					entityRandom.name = entity.name .. i
					if (entity.rpos) then
						entityRandom.pos = {
							entity.pos[1] + math.random(-entity.rpos[1] * 100, entity.rpos[1] * 100) / 100,
							entity.pos[2] + math.random(-entity.rpos[2] * 100, entity.rpos[2] * 100) / 100,
							entity.pos[3] + math.random(-entity.rpos[3] * 100, entity.rpos[3] * 100) / 100
						}
					end
					if (entity.rsize) then
						entityRandom.size = {
							entity.size[1] + math.random(-entity.rsize[1] * 100, entity.rsize[1] * 100) / 100,
							entity.size[2] + math.random(-entity.rsize[2] * 100, entity.rsize[2] * 100) / 100,
							entity.size[3] + math.random(-entity.rsize[3] * 100, entity.rsize[3] * 100) / 100
						}
					end
					if (entity.rcolor) then
						entityRandom.color = {
							entity.color[1] + math.random(-entity.rcolor[1] * 100, entity.rcolor[1] * 100) / 100,
							entity.color[2] + math.random(-entity.rcolor[2] * 100, entity.rcolor[2] * 100) / 100,
							entity.color[3] + math.random(-entity.rcolor[3] * 100, entity.rcolor[3] * 100) / 100,
							entity.color[4] + math.random(-entity.rcolor[4] * 100, entity.rcolor[4] * 100) / 100
						}
					end
					Atmospheres:spawnObject(entityHolder, entityList, entityRandom)
				end
			else
				Atmospheres:spawnObject(entityHolder, entityList, entity)
			end
		end
		
		if (atmoData.shader) then
			UIElement:runCmd("lws " .. atmoData.shader)
		end
		for i,v in pairs(atmoData.shaderopts) do
			UIElement:runCmd("worldshader " .. i .. " " .. v[1] .. " " .. v[2] .. " " .. v[3] .. " " .. v[4])
		end
		Atmospheres:setShaderInfo()
		for i,v in pairs(atmoData.opts) do
			local found = false
			for j,k in pairs(ATMO_STORED_OPTS) do
				if (k.name == v.name) then
					found = true
				end
			end
			if (not found) then
				table.insert(ATMO_STORED_OPTS, { name = v.name, value = get_option(v.name) })
			end
			set_option(v.name, v.value)
		end
	end
	
	function Atmospheres:spawnObject(entityHolder, entityList, entity)
		local item = UIElement3D:new({
			parent = entity.parent and entityList[entity.parent] or entityHolder,
			pos = { unpack(entity.pos) },
			rot = { unpack(entity.rot) },
			size = { unpack(entity.size) },
			bgColor = { unpack(entity.color) },
			shapeType = entity.shape,
			objModel = entity.model
		})
		entityList[entity.name] = item
		if (TB_MENU_DEBUG) then
			local itemText = UIElement:new({
				globalid = TB_MENU_HUB_GLOBALID,
				pos = { 0, 0 },
				size = { 60, 20 }
			})
			itemText:addAdaptedText(true, entity.name)
			item:addCustomDisplay(false, function()
					local x, y = get_screen_pos(item.pos.x, item.pos.y, item.pos.z)
					itemText:moveTo(x, y)
				end)
		end
		if (entity.animated) then
			local rotate, move = function() end, function() end
			if (entity.rotation) then
				local r = {}
				for i,v in pairs(entity.rotation) do
					r[i] = Atmospheres:getFunction(i, v, entity, item, "rot")
				end
				rotate = function()
						item:rotate(r[1](), r[2](), r[3]())
					end
			end
			if (entity.movement) then
				local m = {}
				for i,v in pairs(entity.movement) do
					m[i] = Atmospheres:getFunction(i, v, entity, item, "pos")
				end
				move = function()
						item:moveTo(m[1](), m[2](), m[3]())
					end
			end
			item:addCustomDisplay(false, function()
					if (ATMOSPHERES_ANIMATED) then
						move()
						rotate()
					end
				end)
		end
	end
	
	function Atmospheres:getFunction(i, v, entity, obj, ftype)
		local r
		if (type(v) == "number") then
			if (ftype == "pos" and v == 0) then
				r = function()
					return nil
				end
			else
				r = function()
					return v
				end
			end
		else
			local val = entity[ftype][i]
			if (v:find("lock%b();")) then
				val = val + (v:gsub("^lock%(", ""):gsub("%);.*", "") + 0)
				v = v:gsub("lock%b();[_]?", "")
			end
			v = v:gsub("_", " "):gsub("X", "_ATMO['" .. entity.name .. i .. ftype .. "']"):gsub("entity", "_ATMO['" .. entity.name .. "info']")
			v = v:gsub("%Aos%.", ""):gsub("%Aio%.", ""):gsub("%Atable%.", ""):gsub("_G", "")
			_ATMO[entity.name .. i .. ftype] = val
			_ATMO[entity.name .. "info"] = { pos = obj.pos, size = obj.size }
			r = function()
				local f, err = loadstring(v)
				if (not err) then
					return f()
				end
				return 0
			end
		end
		return r
	end	
	
	function Atmospheres:spawnMainList(listingHolder, toReload, elementHeight, path, ext, func, searchField)
		if (listingHolder.scrollBar) then
			listingHolder.scrollBar:kill()
		end
		listingHolder:kill(true)
		listingHolder:moveTo(nil, 0)
		
		local search = searchField and searchField.textfieldstr[1] or ""
		local listElements = {}
		local atmos = get_files(path, ext)
		
		local default = UIElement:new({
			parent = listingHolder,
			pos = { 0, 0 },
			size = { listingHolder.size.w, elementHeight },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
		})
		table.insert(listElements, default)
		local defaultIcon = UIElement:new({
			parent = default,
			pos = { 5, 0 },
			size = { elementHeight, elementHeight },
			bgImage = "../textures/menu/general/back.tga"
		})
		local defaultText = UIElement:new({
			parent = default,
			pos = { elementHeight, 0 },
			size = { default.size.w - elementHeight, elementHeight }
		})
		if (search == "") then
			defaultText:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSRESETTODEFAULT, 10, nil, 4, LEFTMID, 0.8)
			default:addMouseHandlers(nil, function()
					func("default." .. ext)
				end)
		else
			defaultText:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK, 10, nil, 4, LEFTMID, 0.8)
			default:addMouseHandlers(nil, function()
					searchField:clearTextfield()
					Atmospheres:spawnMainList(listingHolder, toReload, elementHeight, path, ext, func, searchField)
				end)
		end
		
		for i, file in pairs(atmos) do
			if (file:lower():find(search) and not (file:lower():match("default")) and not (file:lower():match("atmo.cfg"))) then
				local element = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight },
					interactive = true,
					bgColor = TB_MENU_DEFAULT_BG_COLOR,
					hoverColor = TB_MENU_DEFAULT_DARKER_COLOR,
					pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
				})
				table.insert(listElements, element)
				element:addAdaptedText(false, file:gsub("%." .. ext .. "$", ""), 10, nil, 4, LEFTMID, 0.8, 0.8)
				element:addMouseHandlers(nil, function()
						func(file)
					end)
			end
		end
		if (#listElements == 0) then
			local element = UIElement:new({
				parent = listingHolder,
				pos = { 0, 0 },
				size = { listingHolder.size.w, listingHolder.size.h },
			})
			table.insert(listElements, element)
			element:addAdaptedText(false, TB_MENU_LOCALIZED.NOFILESFOUND .. " :(")
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, ATMO_LIST_SHIFT)
	end
	
	function Atmospheres:showMain()
		Atmospheres:setShaderInfo()
		local mainView = UIElement:new({
			globalid = TB_MENU_HUB_GLOBALID,
			pos = { ATMO_MENU_POS.x, ATMO_MENU_POS.y },
			size = { WIN_W / 4, WIN_H / 4 * 3 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		ATMO_MENU_MAIN_ELEMENT = mainView
		ATMO_MENU_POS = mainView.pos
		local mainMoverHolder = UIElement:new({
			parent = mainView,
			pos = { 0, 0 },
			size = { mainView.size.w, 30 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = mainView.shapeType,
			rounded = mainView.rounded
		})
		local mainMover = UIElement:new({
			parent = mainMoverHolder,
			pos = { 0, 0 },
			size = { mainMoverHolder.size.w, mainMoverHolder.size.h },
			interactive = true,
			bgColor = UICOLORWHITE,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTEST_COLOR
		})
		mainMover:addCustomDisplay(true, function()
				set_color(unpack(mainMover:getButtonColor()))
				local posX = mainMover.pos.x + mainMover.size.w / 2 - 15
				draw_quad(posX, mainMover.pos.y + 10, 30, 2)
				draw_quad(posX, mainMover.pos.y + 18, 30, 2)
			end)
		mainMover:addMouseHandlers(function(s, x, y)
					mainMover.pressedPos.x = x - mainMover.pos.x
					mainMover.pressedPos.y = y - mainMover.pos.y
				end, nil, function(x, y)
				if (mainMover.hoverState == BTN_DN) then
					local x = x - mainMover.pressedPos.x
					local y = y - mainMover.pressedPos.y
						x = x < 0 and 0 or (x + mainView.size.w > WIN_W and WIN_W - mainView.size.w or x)
					y = y < 0 and 0 or (y + mainView.size.h > WIN_H and WIN_H - mainView.size.h or y)
					mainView:moveTo(x, y)
				end
			end)
		
		local shaderEditorHolder = UIElement:new({
			parent = mainView,
			pos = { 0, -55 },
			size = { mainView.size.w, 55 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 4
		})
		local shaderEditorButton = UIElement:new({
			parent = shaderEditorHolder,
			pos = { 5, 10 },
			size = { shaderEditorHolder.size.w - 10, shaderEditorHolder.size.h - 15 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 5
		})
		shaderEditorButton:addAdaptedText(false, TB_MENU_LOCALIZED.SHADERSEDITOR)
		shaderEditorButton:addMouseHandlers(nil, function()
				remove_hooks("tbAtmospheresKeyboard")
				mainView:kill()
				ATMO_MENU_MAIN_ELEMENT = nil
				Atmospheres:showShaderControls()
			end)
			
		local mainList = UIElement:new({
			parent = mainView,
			pos = { 0, mainMoverHolder.size.h },
			size = { mainView.size.w, mainView.size.h - mainMoverHolder.size.h - shaderEditorHolder.size.h + 5 }
		})
		local elementHeight = 25
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(mainList, 50, 35, 15)
		
		local search = TBMenu:spawnTextField(botBar, 5, 5, botBar.size.w - 10, botBar.size.h - 10, nil, nil, 1, nil, nil, "Start typing to search...")
		
		local mainList = {
			{ text = TB_MENU_LOCALIZED.SHADERSATMOSNAME, action = function(searchText, noreload) if (not noreload) then ATMO_LIST_SHIFT[1] = 0 end ATMO_SELECTED_SCREEN = 1 Atmospheres:spawnMainList(listingHolder, toReload, elementHeight, "data/atmospheres", "atmo", function(file) Atmospheres:loadAtmo(file) Atmospheres:setDefaultAtmo(file) end, search) end },
			{ text = TB_MENU_LOCALIZED.SHADERSNAME, action = function(searchText, noreload) if (not noreload) then ATMO_LIST_SHIFT[1] = 0 end ATMO_SELECTED_SCREEN = 2 Atmospheres:spawnMainList(listingHolder, toReload, elementHeight, "data/shader", "inc", function(file) DEFAULT_SHADER = file UIElement:runCmd("lws " .. file) end, search) end }
		}
		mainList[ATMO_SELECTED_SCREEN].action(nil, true)
		local dropdownView = UIElement:new({
			parent = topBar,
			pos = { 5, 5 },
			size = { topBar.size.w - 10, topBar.size.h - 10 },
			shapeType = ROUNDED,
			rounded = 5
		})
		TBMenu:spawnDropdown(dropdownView, mainList, 40, WIN_H - 100, mainList[ATMO_SELECTED_SCREEN], 0.6, FONTS.BIG, 0.8, FONTS.MEDIUM)
		
		add_hook("key_up", "tbAtmospheresKeyboard", function(s) return(UIElement:handleKeyUp(s)) end)
		add_hook("key_down", "tbAtmospheresKeyboard", function(s) return(UIElement:handleKeyDown(s)) end)
		search:addKeyboardHandlers(nil, function()
				mainList[ATMO_SELECTED_SCREEN].action(search.textfieldstr[1])
			end)
		
		local quitButton = UIElement:new({
			parent = mainMoverHolder,
			pos = { -mainMoverHolder.size.h, 0 },
			size = { mainMoverHolder.size.h , mainMoverHolder.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			interactive = true,
			shapeType = ROUNDED,
			rounded = 4
		})
		local quitIcon = UIElement:new({
			parent = quitButton,
			pos = { 2, 2 },
			size = { quitButton.size.w - 4, quitButton.size.h - 4 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		quitButton:addMouseHandlers(nil, function()
				remove_hooks("tbAtmospheresKeyboard")
				mainView:kill()
				ATMO_MENU_MAIN_ELEMENT = nil
			end)
	end
end
