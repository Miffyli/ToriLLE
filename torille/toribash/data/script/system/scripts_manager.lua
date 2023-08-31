-- Scripts manager

do
	Scripts = {}
	Scripts.__index = Scripts
	local cln = {}
	setmetatable(cln, Scripts)
	
	function Scripts:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Scripts:getNavigationButtons()
		local navigation = {
			{
				text = TB_MENU_LOCALIZED.NAVBUTTONTOMAIN,
				action = function() Scripts:quit() end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONTOMAIN, FONTS.BIG) * 0.65 + 30
			}
		}
		return navigation
	end
	
	function Settings:isDefaultFolder(folder)
		local defaultFolders = {
			"system", "toriui", "tutorial", "torishop", "modules", "gui", "examples", "clans"
		}
		for i,v in pairs(defaultFolders) do
			if (v == folder) then
				return true
			end
		end
		return false
	end
	
	function Scripts:getScriptFiles(path)
		local path = path or "data/script"
		local data = { name = path, files = {}, folders = {}, contents = {} }
		for i,v in pairs(get_files(path, "")) do
			if (v:match(".lua$") and (not v:match("^startup.lua") and path == "data/script")) then
				table.insert(data.files, v)
			elseif (not v:find("^%.+[%s%S]*$") and not v:find("%.%a+$") and not Settings:isDefaultFolder(v)) then
				table.insert(data.folders, v)
				data.contents[#data.folders] = Scripts:getScriptFiles(path .. "/" .. v, fullsearch)
				data.contents[#data.folders].parent = data
			end
		end
		return data
	end
	
	function Scripts:showScriptsList(viewElement, infoView, files)
		viewElement:kill(true)
		local elementHeight = 30
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 60, elementHeight, 20)
		TBMenu:addBottomBloodSmudge(botBar, 1)
		
		local windowTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 5 },
			size = { topBar.size.w - 20, topBar.size.h - 10 }
		})
		local shortPath = files.name:gsub("^data/script[/]?", "")
		windowTitle:addAdaptedText(true, TB_MENU_LOCALIZED.LUASCRIPTSNAME .. (shortPath ~= "" and ": " .. shortPath or ""), nil, nil, FONTS.BIG, LEFTMID, 0.65)
		
		local listElements = {} 
		if (shortPath ~= "") then
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
			defaultText:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK, 10, nil, 4, LEFTMID, 0.8, 0.8)
			default:addMouseHandlers(nil, function()
					Scripts:showScriptsList(viewElement, infoView, files.parent)
				end)
		end
		for i, folder in pairs(files.folders) do
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
			element:addAdaptedText(false, folder, elementHeight + 15, nil, 4, LEFTMID, 0.8, 0.8)
			element:addMouseHandlers(nil, function()
					Scripts:showScriptsList(viewElement, infoView, files.contents[i])
				end)
			local folderIcon = UIElement:new({
				parent = element,
				pos = { 10, 0 },
				size = { elementHeight, elementHeight },
				bgImage = "../textures/menu/general/folder.tga"
			})
		end
		for i, file in pairs(files.files) do
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
			element:addAdaptedText(false, file, 10, nil, 4, LEFTMID, 0.8, 0.8)
			element:addMouseHandlers(nil, function()
					Scripts:showRightView(infoView, shortPath .. "/" .. file)
				end)
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		listingHolder.scrollBar = scrollBar
		scrollBar:makeScrollBar(listingHolder, listElements, toReload, MODS_LIST_SHIFT)
	end
	
	function Scripts:showThirdPartyWarning(thirdPartyWarningView)
		local thirdPartyWarning1 = UIElement:new({
			parent = thirdPartyWarningView,
			pos = { 10, 0 },
			size = { thirdPartyWarningView.size.w - 20, thirdPartyWarningView.size.h / 4 }
		})
		thirdPartyWarning1:addAdaptedText(true, TB_MENU_LOCALIZED.LUASCRIPTSTHIRDPARTYWARNING1, nil, nil, nil, CENTERBOT)
		local thirdPartyWarning2 = UIElement:new({
			parent = thirdPartyWarningView,
			pos = { 10, thirdPartyWarningView.size.h / 4 },
			size = { thirdPartyWarningView.size.w - 20, thirdPartyWarningView.size.h / 4 }
		})
		thirdPartyWarning2:addAdaptedText(true, TB_MENU_LOCALIZED.LUASCRIPTSTHIRDPARTYWARNING2)
		local thirdPartyWarning3 = UIElement:new({
			parent = thirdPartyWarningView,
			pos = { 10, thirdPartyWarningView.size.h / 2 },
			size = { thirdPartyWarningView.size.w - 20, thirdPartyWarningView.size.h / 4 }
		})
		thirdPartyWarning3:addAdaptedText(true, TB_MENU_LOCALIZED.LUASCRIPTSTHIRDPARTYWARNING3, nil, nil, nil, CENTER)
		
		local scriptsBoardButton = UIElement:new({
			parent = thirdPartyWarningView,
			pos = { 10, thirdPartyWarningView.size.h / 4 * 3 + thirdPartyWarningView.size.h / 16 },
			size = { thirdPartyWarningView.size.w - 20, thirdPartyWarningView.size.h / 8 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		TBMenu:showTextExternal(scriptsBoardButton, TB_MENU_LOCALIZED.LUASCRIPTSFORUMBOARD)
		scriptsBoardButton:addMouseHandlers(nil, function()
				open_url("http://forum.toribash.com/forumdisplay.php?f=65")
			end)
	end
	
	function Scripts:showSource(info)
		local overlay = TBMenu:spawnWindowOverlay()
		local scriptData = UIElement:new({
			parent = overlay,
			pos = { WIN_W / 10, WIN_H / 8 },
			size = { WIN_W * 0.8, WIN_H / 8 * 6 },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
			end)
		local elementHeight = 16
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(scriptData, 50, elementHeight, 30, TB_MENU_DEFAULT_BG_COLOR)
		local quitButton = UIElement:new({
			parent = topBar,
			pos = { -45, 5 },
			size = { 40, 40 },
			rounded = 3,
			shapeType = ROUNDED,
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = { 1, 0, 0, 0.4 }
		})
		local quitIcon = UIElement:new({
			parent = quitButton,
			pos = { 5, 5 },
			size = { quitButton.size.w - 10, quitButton.size.h - 10 },
			bgImage = "../textures/menu/general/buttons/crosswhite.tga"
		})
		quitButton:addMouseHandlers(nil, function()
				overlay:kill()
			end)
		local sourceTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 60, topBar.size.h }
		})
		sourceTitle:addAdaptedText(true, TB_MENU_LOCALIZED.LUAVIEWINGSORCE, nil, nil, FONTS.BIG, nil, 0.6)
		local listElements = {}
		for i, ln in pairs(info) do
			local textString = textAdapt(ln, 1, 1, listingHolder.size.w - 10, nil, true)
			for i = 1, #textString do
				local infoRow = UIElement:new({
					parent = listingHolder,
					pos = { 5, #listElements * elementHeight },
					size = { listingHolder.size.w - 10, elementHeight }
				})
				local string = textString[i]
				infoRow:addCustomDisplay(true, function()
						infoRow:uiText(string, nil, nil, 1, LEFT, 0.9)
					end)
				table.insert(listElements, infoRow)
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		local scriptDataScroll = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scriptDataScroll:makeScrollBar(listingHolder, listElements, toReload)
	end
	
	function Scripts:showScriptInfo(viewElement, file)
		local scriptName = UIElement:new({
			parent = viewElement,
			pos = { 10, 5 },
			size = { viewElement.size.w - 20, viewElement.size.h / 6 - 10 }
		})
		scriptName:addAdaptedText(true, file:gsub("^.*/", ""))
		
		local scriptFile = Files:new(file)
		local scriptSource = scriptFile:readAll()
		scriptFile:close()
		
		local vulnerabilityAlert = false
		local fileAccessAlert = false
		local loadScriptAlert = false
		
		for i, info in pairs(scriptSource) do
			if (info:find("tb_login")) then
				vulnerabilityAlert = true
			end
			if (info:find("io.[p]?open") or info:find("Files:new")) then
				fileAccessAlert = true
			end
			if (info:find("dofile") or info:find("require") or info:find("loadfile") or info:find("loadstring")) then
				loadScriptAlert = true
			end
		end
		
		if (vulnerabilityAlert or fileAccessAlert or loadScriptAlert) then
			local alertMessage = UIElement:new({
				parent = viewElement,
				pos = { 10, viewElement.size.h / 6 },
				size = { viewElement.size.w - 20, viewElement.size.h / 3 }
			})
			local alertMsg = ""
			if (vulnerabilityAlert) then
				alertMsg = TB_MENU_LOCALIZED.LUAMALICIOUSWARNING .. "\n"
				alertMessage:addAdaptedText(true, alertMsg, nil, nil, 4, nil, nil, nil, nil, 1.5, UICOLORRED, UICOLORWHITE)
			else
				if (fileAccessAlert) then
					alertMsg = alertMsg .. TB_MENU_LOCALIZED.LUAFILEACCESSWARNING .. "\n"
				end
				if (loadScriptAlert) then
					alertMsg = alertMsg .. TB_MENU_LOCALIZED.LUAOTHERSCRIPTSWARNING .. "\n"
				end
				alertMessage:addAdaptedText(true, alertMsg, nil, nil, 4)
			end
		end
		
		local viewSourceButton = UIElement:new({
			parent = viewElement,
			pos = { 10, viewElement.size.h / 6 * 4 },
			size = { viewElement.size.w - 10, viewElement.size.h / 8 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		viewSourceButton:addAdaptedText(false, TB_MENU_LOCALIZED.LUASHOWSOURCE)
		viewSourceButton:addMouseHandlers(nil, function()
				Scripts:showSource(scriptSource)
			end)
		local loadScriptButton = UIElement:new({
			parent = viewElement,
			pos = { 10, viewElement.size.h / 6 * 5 },
			size = { viewElement.size.w - 10, viewElement.size.h / 8 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
		})
		loadScriptButton:addAdaptedText(false, TB_MENU_LOCALIZED.LUALOADSCRIPT)
		loadScriptButton:addMouseHandlers(nil, function()
				UIElement:runCmd("loadscript2 " .. file)
				close_menu()
			end)
	end
	
	function Scripts:showRightView(viewElement, file)
		viewElement:kill(true)
		TBMenu:addBottomBloodSmudge(viewElement, 2)
		
		if (not file) then
			Scripts:showThirdPartyWarning(viewElement)
			return
		end
		Scripts:showScriptInfo(viewElement, file)
	end
	
	function Scripts:showMain()
		tbMenuCurrentSection:kill(true)
		local scriptFiles = Scripts:getScriptFiles()
		
		local rightView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { tbMenuCurrentSection.size.w * 0.7 + 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.3 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Scripts:showRightView(rightView)
		
		local mainList = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w * 0.7 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Scripts:showScriptsList(mainList, rightView, scriptFiles)		
	end
end
