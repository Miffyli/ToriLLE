-- clan data manager class

DEAD = 0
ALIVE = 1
ACTIVE = 2

CLANLOGODEFAULT = "../textures/clans/default.tga"
LOGOCACHE = LOGOCACHE or {}
AVATARCACHE = AVATARCACHE or {}

DEFCOLOR = {0.7, 0.1, 0.1, 1}
DEFHOVCOLOR = {0.8,0.07,0.07,1}

CLANLISTSHIFT = CLANLISTSHIFT or { 0 }
CLANSEARCHFILTERS = CLANSEARCHFILTERS or nil

do
	Clans = {}
	Clans.__index = Clans
	local cln = {}
	setmetatable(cln, Clans)
	
	ClanData = ClanData or {}
	ClanLevelData = ClanLevelData or {}
	ClanAchievementData = ClanAchievementData or {}
		
	-- Populates clan data table
	-- clans/clan.txt is fetched from server
	function Clans:getClanData(reload)
		if (not reload and #ClanData > 1) then
			return true
		end
		
		local data_types = { "id", "name", "tag", "isofficial", "rank", "level", "xp", "memberstotal", "isfreeforall", "topach", "isactive", "members", "leaders", "bgcolor", "leaderscustom", "memberscustom" }
		local file = Files:new("clans/clans.txt")
		if (not file.data) then
			return false
		end
		
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^CLAN") then
				local _, segments = ln:gsub("\t", "")
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				if (not data_stream[3]:match("^#") and not (data_stream[5] == "0" and data_stream[12] == "0")) then -- Ignore unofficial dead clans
					data_stream[2] = tonumber(data_stream[2])
					for i = 5, 12 do 
						data_stream[i] = tonumber(data_stream[i])
					end
					for i = 15, 17 do
						data_stream[i] = data_stream[i] ~= "" and data_stream[i] or false
					end
					
					local clanid = data_stream[2]
					ClanData[clanid] = {}
					for i = 1, #data_types do
						ClanData[clanid][data_types[i]] = data_stream[i + 1]
					end
					local members, leaders = data_stream[13], data_stream[14]
					ClanData[clanid].members, ClanData[clanid].leaders = {}, {}
					for word in members:gmatch("%S+") do table.insert(ClanData[clanid].members, word) end
					for word in leaders:gmatch("%S+") do table.insert(ClanData[clanid].leaders, word) end
					local bgColorHex = data_stream[15]
					if (bgColorHex) then
						ClanData[clanid].bgcolor = {}
						for col in bgColorHex:gmatch("%w%w") do table.insert(ClanData[clanid].bgcolor, tonumber(col, 16) / 256) end
						ClanData[clanid].bgcolor[4] = 1
						ClanData[clanid].xpbarbgcolor, ClanData[clanid].xpbarcolor, ClanData[clanid].xpbaraccenttopcolor, ClanData[clanid].xpbaraccentbotcolor = cloneTable(ClanData[clanid].bgcolor), cloneTable(ClanData[clanid].bgcolor), cloneTable(ClanData[clanid].bgcolor), cloneTable(ClanData[clanid].bgcolor)
						local colSum = 0
						for i = 1, 3 do
							ClanData[clanid].xpbarbgcolor[i] = ClanData[clanid].xpbarbgcolor[i] + 0.05
							ClanData[clanid].xpbarcolor[i] = ClanData[clanid].xpbarcolor[i] - 0.1
							ClanData[clanid].xpbaraccenttopcolor[i] = ClanData[clanid].xpbaraccenttopcolor[i] + 0.1
							ClanData[clanid].xpbaraccentbotcolor[i] = ClanData[clanid].xpbaraccentbotcolor[i] - 0.2
							colSum = colSum + ClanData[clanid].bgcolor[i]
						end
						if (colSum > 2) then
							ClanData[clanid].colorNegative = true
						end
					end
				end
			end
		end
		file:close()
		return true
	end
	
	function Clans:getLevelData(reload)
		if (not reload and #ClanLevelData > 1) then
			return true
		end
		
		local data_types = { "minxp", "maxmembers", "officialonly" }
		local file = Files:new("clans/clanlevels.txt")
		if (not file.data) then
			return false
		end
		
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^LEVEL") then
				local segments = 5
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local level = tonumber(data_stream[2])
				ClanLevelData[level] = {}
				
				for i, v in ipairs(data_types) do
					ClanLevelData[level][v] = tonumber(data_stream[i + 2])
				end
			end
		end
		
		file:close()
		return true
	end
	
	function Clans:getAchievementData(reload)
		if (not reload and #ClanAchievementData > 1) then
			return true
		end
		
		local data_types = { "achname", "achdesc" }
		local file = Files:new("clans/clanachievements.txt")
		if (not file.data) then
			return false
		end
		
		for i, ln in pairs(file:readAll()) do
			if string.match(ln, "^ACHIEVEMENT") then
				local segments = 4
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local level = tonumber(data_stream[2])
				ClanAchievementData[level] = {}
				
				for i, v in ipairs(data_types) do
					ClanAchievementData[level][v] = data_stream[i + 2]
				end
			end
		end
		
		file:close()
		return true
	end
	
	function Clans:quit()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		if (get_option("newmenu") == 0) then
			tbMenuMain:kill()
			remove_hooks("tbMainMenuVisual")
			return
		end
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
		
	function Clans:getNavigationButtons(showBack)
		local buttonText = get_option("newmenu") == 0 and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local buttonsData = {
			{ 
				text = buttonText, 
				action = function() TB_MENU_CLANS_OPENCLANID = 0 Clans:quit() end, 
				width = get_string_length(buttonText, FONTS.BIG) * 0.65 + 30
			}
		}
		if (showBack) then
			local backButton = {
				text = TB_MENU_LOCALIZED.NAVBUTTONBACK,
				action = function() TB_MENU_CLANS_OPENCLANID = 0 Clans:showMain(tbMenuCurrentSection) end,
				width = get_string_length(TB_MENU_LOCALIZED.NAVBUTTONBACK, FONTS.BIG) * 0.65 + 30
			}
			table.insert(buttonsData, backButton)
		end
		return buttonsData
	end
	
	function Clans:isBeginnerClan(clanid)
		if (clanid == 2193 or clanid == 2194) then
			return true
		end
		return false
	end
	
	function Clans:showMain(viewElement, clantag)
		if (clantag) then
			local clanid
			for i,v in pairs(ClanData) do
				if (v.tag == clantag) then
					clanid = v.id
					break
				end
			end
			Clans:showClan(viewElement, clanid)
			return
		end
		viewElement:kill(true)
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 3
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Clans:getNavigationButtons(), true)
		local clanListSettings = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.3 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showUserClan(clanListSettings)
		local clanView = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w * 0.3 + 5, 0 },
			size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanList(clanView)
	end
	
	function Clans:showUserClan(viewElement)
		local clanUserBotSmudge = TBMenu:addBottomBloodSmudge(viewElement, 1)
		local clanid = TB_MENU_PLAYER_INFO.clan.id
		if (clanid ~= 0) then
			local userClanTitle = UIElement:new({
				parent = viewElement,
				pos = { 0, 0 },
				size = { viewElement.size.w, viewElement.size.h / 8 }
			})
			userClanTitle:addCustomDisplay(true, function()
					userClanTitle:uiText(TB_MENU_LOCALIZED.CLANSMYCLAN, nil, nil, FONTS.BIG, nil, 0.7, nil, nil, nil, nil, 0.2)
				end)
			local buttonHeight = viewElement.size.h / 6
			local clanView = UIElement:new({
				parent = viewElement,
				pos = { 0, viewElement.size.h / 7 },
				size = { viewElement.size.w, viewElement.size.h / 3 * 2 }
			})
			local heightMod = 0
			if (clanView.size.h / 3 * 2 > 60) then
				local iconSize = clanView.size.h / 3 * 2 > 256 and 256 or math.floor(clanView.size.h / 3 * 2)
				local clanLogo = UIElement:new({
					parent = clanView,
					pos = { (clanView.size.w - iconSize) / 2, 0 },
					size = { iconSize, iconSize },
					bgImage =  { "../textures/clans/"..clanid..".tga", CLANLOGODEFAULT }
				})
				heightMod = iconSize
				Clans:loadClanLogo(clanid, clanLogo)
			end
			local clanInfo = UIElement:new({
				parent = clanView,
				pos = { clanView.size.w / 10, clanView.size.h / 3 * 2 },
				size = { clanView.size.w / 10 * 8, clanView.size.h / 3 }
			})
			local clanName = UIElement:new({
				parent = clanInfo,
				pos = { 0, 0 },
				size = { clanInfo.size.w, clanInfo.size.h / 2 }
			})
			local clanNameSize = 0.8
			while (not clanName:uiText(TB_MENU_PLAYER_INFO.clan.name, nil, nil, FONTS.BIG, LEFT, clanNameSize, nil, nil, nil, nil, nil, true)) do
				clanNameSize = clanNameSize - 0.05
			end
			clanName:addCustomDisplay(true, function()
					clanName:uiText(TB_MENU_PLAYER_INFO.clan.name, nil, nil, FONTS.BIG, nil, clanNameSize)
				end)
			local memberStatus = UIElement:new({
				parent = clanInfo,
				pos = { 0, clanInfo.size.h / 2 },
				size = { clanInfo.size.w, clanInfo.size.h / 4 },
			})
			if (TB_MENU_PLAYER_INFO.clan.isleader) then
				local memberStatusSize = 1
				while (not memberStatus:uiText(TB_MENU_LOCALIZED.CLANSCLANLEADER, nil, nil, 4, LEFT, memberStatusSize, nil, nil, nil, nil, nil, true)) do
					memberStatusSize = memberStatusSize - 0.05
				end
				memberStatus:addCustomDisplay(true, function()
						memberStatus:uiText(TB_MENU_LOCALIZED.CLANSCLANLEADER, nil, nil, 4, CENTERMID, memberStatusSize)
					end)
				local otherMembers = UIElement:new({
					parent = clanInfo,
					pos = { 0, clanInfo.size.h / 4 * 3 },
					size = { clanInfo.size.w, clanInfo.size.h / 4 }
				})
				if (#ClanData[clanid].leaders > 1) then
					local leader1 = math.random(1, #ClanData[clanid].leaders)
					while (ClanData[clanid].leaders[leader1]:lower() == TB_MENU_PLAYER_INFO.username:lower()) do
						leader1 = math.random(1, #ClanData[clanid].leaders)
					end
					local otherMembersStr = TB_MENU_LOCALIZED.CLANSTOGETHERWITH .. " " .. ClanData[clanid].leaders[leader1]
					if (#ClanData[clanid].leaders > 2) then
						local leader2 = math.random(1, #ClanData[clanid].leaders)
						while (ClanData[clanid].leaders[leader2]:lower() == TB_MENU_PLAYER_INFO.username:lower() or leader2 == leader1) do
							leader2 = math.random(1, #ClanData[clanid].leaders)
						end
						if (otherMembers:uiText(otherMembersStr .. " " .. TB_MENU_LOCALIZED.GENERALSTRINGAND .. " " .. ClanData[clanid].leaders[leader2], nil, nil, 4, LEFT, 0.5, nil, nil, nil, nil, nil, true)) then
							otherMembersStr = otherMembersStr .. " " .. TB_MENU_LOCALIZED.GENERALSTRINGAND .. " " .. ClanData[clanid].leaders[leader2]
						end
					end
					local otherMembersSize = memberStatusSize - 0.2
					while (not otherMembers:uiText(otherMembersStr, nil, nil, 4, LEFT, otherMembersSize, nil, nil, nil, nil, nil, true)) do
						otherMembersSize = otherMembersSize - 0.05
					end					
					otherMembers:addCustomDisplay(true, function()
							otherMembers:uiText(otherMembersStr, nil, nil, 4, CENTER, otherMembersSize)
						end)
				end
			else 
				local memberStatusSize = 1
				while (not memberStatus:uiText(TB_MENU_LOCALIZED.CLANSCLANMEMBER, nil, nil, 4, LEFT, memberStatusSize, nil, nil, nil, nil, nil, true)) do
					memberStatusSize = memberStatusSize - 0.05
				end
				memberStatus:addCustomDisplay(true, function()
						memberStatus:uiText(TB_MENU_LOCALIZED.CLANSCLANMEMBER, nil, nil, 4, CENTERMID, memberStatusSize)
					end)
				local otherMembers = UIElement:new({
					parent = clanInfo,
					pos = { 0, clanInfo.size.h / 4 * 3 },
					size = { clanInfo.size.w, clanInfo.size.h / 4 }
				})
				if (#ClanData[clanid].members > 1) then
					local member1 = math.random(1, #ClanData[clanid].members)
					while (ClanData[clanid].members[member1]:lower() == TB_MENU_PLAYER_INFO.username:lower()) do
						member1 = math.random(1, #ClanData[clanid].members)
					end
					local otherMembersStr = TB_MENU_LOCALIZED.CLANSTOGETHERWITH .. " " .. ClanData[clanid].members[member1]
					if (#ClanData[clanid].members > 2) then
						local member2 = math.random(1, #ClanData[clanid].members)
						while (ClanData[clanid].members[member2]:lower() == TB_MENU_PLAYER_INFO.username:lower() or member2 == member1) do
							member2 = math.random(1, #ClanData[clanid].members)
						end
						if (otherMembers:uiText(otherMembersStr .. " " .. TB_MENU_LOCALIZED.GENERALSTRINGAND .. " " .. ClanData[clanid].members[member2], nil, nil, 4, LEFT, 0.5, nil, nil, nil, nil, nil, true)) then
							otherMembersStr = otherMembersStr .. " " .. TB_MENU_LOCALIZED.GENERALSTRINGAND .. " " .. ClanData[clanid].members[member2]
						end
					end
					local otherMembersSize = memberStatusSize - 0.2
					while (not otherMembers:uiText(otherMembersStr, nil, nil, 4, LEFT, otherMembersSize, nil, nil, nil, nil, nil, true)) do
						otherMembersSize = otherMembersSize - 0.05
					end				
					otherMembers:addCustomDisplay(true, function()
							otherMembers:uiText(otherMembersStr, nil, nil, 4, CENTER, otherMembersSize)
						end)
				end
			end
			local clanButton = UIElement:new({
				parent = viewElement,
				pos = { 10, -buttonHeight },
				size = { viewElement.size.w - 20, buttonHeight - 20 },
				interactive = true,
				bgColor = { 0, 0, 0, 0.1 },
				hoverColor = { 0, 0, 0, 0.3 },
				pressedColor = { 1, 0, 0, 0.1 }
			})
			clanButton:addCustomDisplay(false, function()
					clanButton:uiText(TB_MENU_LOCALIZED.CLANSVIEWCLAN)
				end)
			clanButton:addMouseHandlers(nil, function()
					Clans:showClan(viewElement.parent, TB_MENU_PLAYER_INFO.clan.id)
				end)
		else
			local noClanHeader = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 10, viewElement.size.h / 8 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 4 }
			})
			local noClanHeaderSize = 1
			while (not noClanHeader:uiText(TB_MENU_LOCALIZED.CLANSPLAYERCLANLESS, nil, nil, FONTS.BIG, LEFT, noClanHeaderSize, nil, nil, nil, nil, nil, true)) do
				noClanHeaderSize = noClanHeaderSize - 0.05
			end
			noClanHeader:addCustomDisplay(true, function()
					noClanHeader:uiText(TB_MENU_LOCALIZED.CLANSPLAYERCLANLESS, nil, nil, FONTS.BIG, nil, noClanHeaderSize)
				end)
			local noClanDesc = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 10, viewElement.size.h / 5 * 2 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 4 }
			})
			local noClanDescSize = 1
			while (not noClanDesc:uiText(TB_MENU_LOCALIZED.CLANSPLAYERCLANLESSINFOMSG, nil, nil, nil, LEFT, noClanDescSize, nil, nil, nil, nil, nil, true)) do
				noClanDescSize = noClanDescSize - 0.05
			end
			noClanDesc:addCustomDisplay(true, function()
					noClanDesc:uiText(TB_MENU_LOCALIZED.CLANSPLAYERCLANLESSINFOMSG, nil, nil, nil, nil, noClanDescSize)
				end)
			local makeNewClan = UIElement:new({
				parent = viewElement,
				pos = { viewElement.size.w / 10, -viewElement.size.h / 4 },
				size = { viewElement.size.w / 10 * 8, viewElement.size.h / 5 },
				bgColor = { 0, 0, 0, 0.3 },
				hoverColor = { 0, 0, 0, 0.5 },
				pressedColor = { 1, 0, 0, 0.1 },
				interactive = true,
				hoverSound = 31
			})
			makeNewClan:addCustomDisplay(false, function()
					makeNewClan:uiText(TB_MENU_LOCALIZED.CLANSCREATENEWCLAN)
				end)
			makeNewClan:addMouseHandlers(nil, function()
					open_url("http://forum.toribash.com/clan_register.php")
				end)
		end
	end
	
	function Clans:getDefaultFilters()
		return {
			isactive = { strict = true, val = 2 },
			isfreeforall = { strict = false, val = 0 },
			isofficial = { strict = false, val = 0 },
			sortby = "rank",
			desc = false
		}
	end
	
	function Clans:populateClanList(opt)
		local list = {}
		local options = Clans:getDefaultFilters()
		if (opt) then
			for i,v in pairs(opt) do
				if (i ~= "sortby" and i ~= "desc") then
					options[i].val = v
				else 
					options[i] = v
				end
			end
		end
		for i,v in pairs(ClanData) do
			local check = true
			for j,z in pairs(options) do
				if (type(z) == "table" and ((z.strict and z.val ~= v[j]) or (not z.strict and z.val > v[j]))) then
					check = false
					break
				end
			end
			if (check) then
				table.insert(list, v)
			end
		end
		return UIElement:qsort(list, options.sortby, options.desc)
	end
	
	function Clans:showClanListFilters(viewElement, opt)
		viewElement:kill(true)
		local options = {}
		if (opt) then
			options = opt
		else
			local opts = Clans:getDefaultFilters()
			options = {
				isactive = opts.isactive.val,
				isfreeforall = opts.isfreeforall.val,
				isofficial = opts.isofficial.val,
				sortby = opts.sortby,
				desc = opts.desc
			}
		end
		
		options.isactive = options.isactive + 1
		options.desc = options.desc and 2 or 1
		
		local sortOptions = {
			rank = { name = TB_MENU_LOCALIZED.CLANFILTERSRANK },
			name = { name = TB_MENU_LOCALIZED.CLANFILTERSCLANNAME },
			tag = { name = TB_MENU_LOCALIZED.CLANFILTERSCLANTAG },
			id = { name = TB_MENU_LOCALIZED.CLANFILTERSCLANID },
			isofficial = { name = TB_MENU_LOCALIZED.CLANFILTERSOFFICIALSTATUS },
			isfreeforall = { name = TB_MENU_LOCALIZED.CLANFILTERSJOINMODE }
		}
		local activityOptions = { 
			{ name = TB_MENU_LOCALIZED.CLANFILTERSDEAD },
			{ name = TB_MENU_LOCALIZED.CLANFILTERSINACTIVE },
			{ name = TB_MENU_LOCALIZED.CLANFILTERSACTIVE }
		}
		local sortOrder = {
			{ name = TB_MENU_LOCALIZED.SORTORDERASCENDING },
			{ name = TB_MENU_LOCALIZED.SORTORDERDESCENDING }
		}
		local optData = {
			--{ opt = "isactive", name = TB_MENU_LOCALIZED.CLANFILTERSACTIVITYSTATE, desc = TB_MENU_LOCALIZED.CLANFILTERSACTIVITYSTATEDESC, customSelection = activityOptions },
			{ opt = "isfreeforall", name = TB_MENU_LOCALIZED.CLANFILTERSFFAONLY, desc = TB_MENU_LOCALIZED.CLANFILTERSFFAONLYDESC, },
			{ opt = "isofficial", name = TB_MENU_LOCALIZED.CLANFILTERSOFFICIALONLY, desc = TB_MENU_LOCALIZED.CLANFILTERSOFFICIALONLYDESC, },
			{ opt = "sortby", name = TB_MENU_LOCALIZED.SORTBYNAME, customSelection = sortOptions },
			{ opt = "desc", name = TB_MENU_LOCALIZED.SORTORDERNAME, customSelection = sortOrder }
		}
		
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local filtersTopBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		local filtersBotBar = UIElement:new({
			parent = toReload,
			pos = { 0, -50 },
			size = { viewElement.size.w, 50 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		local filtersTitle = UIElement:new({
			parent = filtersTopBar,
			pos = { 0, 0 },
			size = { filtersTopBar.size.w - filtersTopBar.size.h, filtersTopBar.size.h }
		})
		filtersTitle:addCustomDisplay(true, function()
				filtersTitle:uiText(TB_MENU_LOCALIZED.CLANSSEARCHFILTERS, nil, nil, FONTS.BIG, CENTERMID, 0.7, nil, nil, nil, nil, 0.2)
			end)
		local clanListFilters = TBMenu:createImageButtons(filtersTopBar, filtersTitle.size.w, 0, filtersTitle.size.h, filtersTitle.size.h, TB_MENU_CLANFILTERS_BUTTON, TB_MENU_CLANFILTERS_BUTTON_HOVER, TB_MENU_CLANFILTERS_BUTTON_PRESS)
		clanListFilters:addMouseHandlers(nil, function()
				if (options) then
					options.isactive = options.isactive - 1
					options.desc = options.desc % 2 == 0 and true or false
				end
				Clans:showClanList(viewElement, options)
			end, nil)
		
		local filtersMain = UIElement:new({
			parent = viewElement,
			pos = { 0, filtersTopBar.size.h },
			size = { filtersTopBar.size.w, viewElement.size.h - filtersTopBar.size.h - filtersBotBar.size.h }
		})
		local filtersView = UIElement:new({
			parent = filtersMain,
			pos = { 0, 0 },
			size = { filtersMain.size.w - 20, filtersMain.size.h }
		})
		local listFilters = {}
		for i,v in pairs(optData) do
			local listFilterElement = UIElement:new({
				parent = filtersView,
				pos = { 0, #listFilters * 50 },
				size = { filtersView.size.w, 50 }
			})
			table.insert(listFilters, listFilterElement)
			local filterName = UIElement:new({
				parent = listFilterElement,
				pos = { 20, 10 },
				size = { (listFilterElement.size.w - 40) / 2, listFilterElement.size.h - 20 }
			})
			filterName:addCustomDisplay(true, function()
					filterName:uiText(optData[i].name, nil, nil, nil, LEFTMID)
				end)
			if (optData[i].desc) then
				local listFilterElement = UIElement:new({
					parent = filtersView,
					pos = { 0, #listFilters * 50 },
					size = { filtersView.size.w, 50 }
				})
				table.insert(listFilters, listFilterElement)
				local filterDesc = UIElement:new({
					parent = listFilterElement,
					pos = { 20, 10 },
					size = { listFilterElement.size.w - 40, listFilterElement.size.h - 20 }
				})
				filterDesc:addCustomDisplay(true, function()
						filterDesc:uiText(optData[i].desc, nil, nil, 4, LEFT, 0.6)
					end)
				if (i ~= #optData) then
					local separator = UIElement:new({
						parent = listFilterElement,
						pos = { 0, -1 },
						size = { listFilterElement.size.w, 1 },
						bgColor = { 0, 0, 0, 0.2 }
					})
				end
				listFilterElement:hide()
			elseif (i ~= #optData) then
				local separator = UIElement:new({
					parent = listFilterElement,
					pos = { 0, -1 },
					size = { listFilterElement.size.w, 1 },
					bgColor = { 0, 0, 0, 0.2 }
				})
			end
			local opts = optData[i].opt
			if (optData[i].customSelection) then
				local optTotal = 0
				for j, k in pairs(optData[i].customSelection) do
					optTotal = optTotal + 1
				end
				local filterOption = UIElement:new({
					parent = listFilterElement,
					pos = { listFilterElement.size.w / 2, 5 },
					size = { (listFilterElement.size.w - 40) / 2, listFilters[i].size.h - 10 },
					bgColor = { 0, 0, 0, 0.3 },
					hoverColor = { 0, 0, 0, 0.5 },
					pressedColor = { 1, 0, 0, 0.1 },
					interactive = true
				})
				local filterSelection = UIElement:new({
					parent = filtersView,
					pos = { filterOption.pos.x - filtersView.pos.x, filterOption.pos.y - filtersView.pos.y },
					size = { filterOption.size.w, filterOption.size.h * optTotal / 3 * 2 },
					bgColor = TB_MENU_DEFAULT_DARKER_COLOR
				})
				filterSelection:addCustomDisplay(false, function()
						if (filterSelection.pos.y < filtersMain.pos.y or filterSelection.pos.y + filterSelection.size.h > filtersMain.pos.y + filtersMain.size.h) then
							filterSelection:moveTo(filterOption.pos.x - filtersView.pos.x, filterOption.pos.y - filtersView.pos.y)
							filterSelection:hide()
						end
					end)
				local count = 0
				for j,k in pairs(optData[i].customSelection) do
					local filterSelectionOption = UIElement:new({
						parent = filterSelection,
						pos = { 0, count * filterOption.size.h / 3 * 2 },
						size = { filterOption.size.w, filterOption.size.h / 3 * 2 },
						interactive = true,
						bgColor = { 0, 0, 0, 0 },
						hoverColor = { 0, 0, 0, 0.2 },
						pressedColor = { 1, 0, 0, 0.1 }
					})
					filterSelectionOption:addCustomDisplay(false, function()
							filterSelectionOption:uiText(k.name, nil, nil, 4, CENTERMID, 0.7)
						end)
					filterSelectionOption:addMouseHandlers(nil, function()
							filterSelection:moveTo(nil, filterOption.pos.y - filtersView.pos.y)
							options[opts] = j
							filterSelection:hide()
						end, nil)
					count = count + 1
				end
				filterOption:addCustomDisplay(false, function()
						filterOption:uiText(optData[i].customSelection[options[opts]].name, nil, nil, nil, CENTERMID, nil, nil, nil, nil, nil, 0.2)
					end)
				filterOption:addMouseHandlers(function()
						if (filterSelection.pos.y + filterSelection.size.h > filtersBotBar.pos.y) then
							local lPos = filtersView:getLocalPos(0, filtersBotBar.pos.y).y
							if (lPos < 0) then
								lPos = lPos - filtersView.size.h
							end
							filterSelection:moveTo(nil, lPos - filterSelection.size.h)
						elseif (filterSelection.pos.y < filtersTopBar.pos.y + filtersTopBar.size.h) then
							local lPos = filtersView:getLocalPos(0, filtersTopBar.pos.y + filtersTopBar.size.h).y
							if (lPos < 0) then
								lPos = lPos - filtersView.size.h
							end
							filterSelection:moveTo(nil, lPos)
						end
						filterSelection:show()
					end, nil, nil)
				filterSelection:hide()
			else
				local filterCheckbox = UIElement:new({
					parent = listFilterElement,
					pos = { -60, 5 },
					size = { listFilterElement.size.h - 10, listFilterElement.size.h - 10 },
					bgColor = { 0, 0, 0, 0.3 },
					hoverColor = { 0, 0, 0, 0.5 },
					pressedColor = { 1, 0, 0, 0.1 },
					interactive = true					
				})
				local filterCheckboxIcon = UIElement:new({
					parent = filterCheckbox,
					pos = { 0, 0 },
					size = { filterCheckbox.size.w, filterCheckbox.size.h },
					bgImage = "../textures/menu/general/buttons/checkmark.tga"
				})
				if (options[opts] == 0 or options[opts] == false) then
					filterCheckboxIcon:hide(true)
				end
				filterCheckbox:addMouseHandlers(nil, function()
						if (type(options[opts]) == "boolean") then
							options[opts] = not options[opts]
						else
							options[opts] = 1 - options[opts]
						end
						if (options[opts] == 1 or options[opts] == true) then
							filterCheckboxIcon:show(true)
						else
							filterCheckboxIcon:hide(true)
						end
					end, nil)
			end
		end
			
		for i,v in pairs(listFilters) do
			v:hide()
		end
		
		local filtersScrollBar = TBMenu:spawnScrollBar(filtersView, #listFilters, 50)
		filtersScrollBar:makeScrollBar(filtersView, listFilters, toReload)
				
		local clanFiltersBotSmudge = TBMenu:addBottomBloodSmudge(filtersBotBar, 2)
		local filterSearchButton = UIElement:new({
			parent = filtersBotBar,
			pos = { filtersBotBar.size.w / 6, 5 },
			size = { filtersBotBar.size.w / 6 * 4, filtersBotBar.size.h - 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 },
			hoverSound = 31
		})
		filterSearchButton:addCustomDisplay(false, function()
				filterSearchButton:uiText(TB_MENU_LOCALIZED.CLANSSEARCH, nil, nil, FONTS.BIG, CENTERMID, 0.5)
			end)
		filterSearchButton:addMouseHandlers(nil, function()
				options.isactive = options.isactive - 1
				options.desc = options.desc % 2 == 0 and true or false
				CLANLISTSHIFT[1] = 0
				Clans:showClanList(viewElement, options)
			end, nil)
	end
	
	function Clans:showClanList(viewElement, options)
		viewElement:kill(true)
		if (CLANSEARCHFILTERS and type(CLANSEARCHFILTERS.desc) ~= "boolean") then
			CLANSEARCHFILTERS.isactive = CLANSEARCHFILTERS.isactive - 1
			CLANSEARCHFILTERS.desc = CLANSEARCHFILTERS.desc % 2 == 0 and true or false
		end
		local options = options or CLANSEARCHFILTERS
		local clanList = Clans:populateClanList(options)
		CLANSEARCHFILTERS = options
		local clanEntryHeight = 45
		-- Parent Object to hold all elements that require reloading when scrolling
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		
		-- Top and Bottom bars, keep interactive to prevent clicking through
		local clanListTopBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, 80 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			interactive = true
		})
		local clanListTopBarTitle = UIElement:new({
			parent = clanListTopBar,
			pos = { 0, 0 },
			size = { clanListTopBar.size.w - 50, 50 }
		})
		clanListTopBarTitle:addCustomDisplay(true, function()
				clanListTopBarTitle:uiText(TB_MENU_LOCALIZED.CLANSCLANLIST, nil, nil, FONTS.BIG, CENTERMID, 0.7, nil, nil, nil, nil, 0.2)
			end)
		local clanListFilters = TBMenu:createImageButtons(clanListTopBar, clanListTopBarTitle.size.w, 0, clanListTopBarTitle.size.h, clanListTopBarTitle.size.h, TB_MENU_CLANFILTERS_BUTTON, TB_MENU_CLANFILTERS_BUTTON_HOVER, TB_MENU_CLANFILTERS_BUTTON_PRESS)
		clanListFilters:addMouseHandlers(nil, function()
				Clans:showClanListFilters(viewElement, options)
			end, nil)
			
		local clanListLegendRankWidth = 60
		local clanListLegendNameWidth = (clanListTopBar.size.w - clanListLegendRankWidth - 30) / 5 * 3
		local clanListLegendOfficialWidth = (clanListTopBar.size.w - clanListLegendRankWidth - 30) / 5
		local clanListLegendJoinModeWidth = (clanListTopBar.size.w - clanListLegendRankWidth - 30) / 5
		
		local clanListTopBarLegend = UIElement:new({
			parent = clanListTopBar,
			pos = { 0, clanListTopBarTitle.size.h },
			size = { clanListTopBar.size.w, clanListTopBar.size.h - clanListTopBarTitle.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		local clanListLegendRank = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { 0, 0 },
			size = { clanListLegendRankWidth, clanListTopBarLegend.size.h },
			bgColor = { 0, 0, 0, 0.05 }
		})
		clanListLegendRank:addCustomDisplay(false, function()
				clanListLegendRank:uiText(TB_MENU_LOCALIZED.CLANSLEGENDRANK, nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListLegendName = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { clanListLegendRankWidth, 0 },
			size = { clanListLegendNameWidth, clanListTopBarLegend.size.h }
		})
		clanListLegendName:addCustomDisplay(true, function()
				clanListLegendName:uiText(TB_MENU_LOCALIZED.CLANSLEGENDTAGNAME, nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListLegendOfficial = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { clanListLegendRankWidth + clanListLegendNameWidth, 0 },
			size = { clanListLegendOfficialWidth, clanListTopBarLegend.size.h },
			bgColor = { 0, 0, 0, 0.05 }
		})
		clanListLegendOfficial:addCustomDisplay(false, function()
				clanListLegendOfficial:uiText(TB_MENU_LOCALIZED.CLANSLEGENDSTATUS, nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListLegendJoinMode = UIElement:new({
			parent = clanListTopBarLegend,
			pos = { clanListLegendRankWidth + clanListLegendNameWidth + clanListLegendOfficialWidth, 0 },
			size = { clanListLegendJoinModeWidth, clanListTopBarLegend.size.h }
		})
		clanListLegendJoinMode:addCustomDisplay(true, function()
				clanListLegendJoinMode:uiText(TB_MENU_LOCALIZED.CLANSLEGENDJOINMODE, nil, nil, 4, CENTERMID, 0.7)
			end)
		local clanListBotBar = UIElement:new({
			parent = toReload,
			pos = { 0, -30 },
			size = { viewElement.size.w, 30 },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			interactive = true
		})
		local clanListBotSmudge = TBMenu:addBottomBloodSmudge(clanListBotBar, 2)
		
		-- Main View for Clan List
		local clanListView = UIElement:new({
			parent = viewElement,
			pos = { 0, clanListTopBar.size.h },
			size = { viewElement.size.w, viewElement.size.h - clanListTopBar.size.h - clanListBotBar.size.h }
		})
		
		-- Clan Holder Object, used to create scrollable list
		local clanListHolder = UIElement:new({
			parent = clanListView,
			pos = { 0, 0 },
			size = { clanListView.size.w - 20, clanListView.size.h }
		})
				
		if (#clanList > 0) then
			local clanListClans = {}
			for i, v in pairs(clanList) do
			 	clanListClans[i] = UIElement:new({
					parent = clanListHolder,
					pos = { 0, (i - 1) * clanEntryHeight },
					size = { clanListHolder.size.w, clanEntryHeight },
					interactive = true,
					bgColor = { 0, 0, 0, i % 2 == 0 and 0 or 0.1 },
					hoverColor = { 0, 0, 0, 0.3 },
					pressedColor = { 0, 0, 0, 0.4 },
					hoverSound = 31
				})
				clanListClans[i]:addMouseHandlers(nil, function()
						Clans:showClan(viewElement.parent, clanList[i].id)
					end, nil)
				local clanListClanRank = UIElement:new({
					parent = clanListClans[i],
					pos = { 0, 0 },
					size = { clanListLegendRankWidth, clanListClans[i].size.h },
					bgColor = { 0, 0, 0, 0.05 }
				})
				local clanRank = clanList[i].rank == 0 and "-" or clanList[i].rank
				clanListClanRank:addCustomDisplay(false, function()
						clanListClanRank:uiText(clanRank, nil, nil, 4, CENTERMID, 0.7)
					end)
				local clanListClanNameView = UIElement:new({
					parent = clanListClans[i],
					pos = { clanListLegendRankWidth, 0 },
					size = { clanListLegendNameWidth, clanListClans[i].size.h }
				})
				local clanListClanTag = UIElement:new({
					parent = clanListClanNameView,
					pos = { 0, 0 },
					size = { clanListClanNameView.size.w / 3 - 5, clanListClanNameView.size.h } 
				})
				local clanListClanName = UIElement:new({
					parent = clanListClanNameView,
					pos = { clanListClanNameView.size.w / 3 + 5, 0 },
					size = { clanListClanNameView.size.w / 3 * 2 - 5, clanListClanNameView.size.h } 
				})
				local clanListClanNameSeparator = UIElement:new({
					parent = clanListClanNameView,
					pos = { clanListClanNameView.size.w / 3 - 5, 0 },
					size = { 10, clanListClanNameView.size.h }
				})
				clanListClanNameSeparator:addCustomDisplay(true, function()
						clanListClanNameSeparator:uiText("|", nil, nil, 4, CENTERMID, 0.7)
					end)
				clanListClanTag:addCustomDisplay(true, function()
						clanListClanTag:uiText(clanList[i].tag, nil, nil, 4, RIGHTMID, 0.7)
					end)
				clanListClanName:addCustomDisplay(true, function()
						clanListClanName:uiText(clanList[i].name, nil, nil, 4, LEFTMID, 0.7)
					end)
				local clanListClanOfficial = UIElement:new({
					parent = clanListClans[i],
					pos = { clanListLegendRankWidth + clanListLegendNameWidth, 0 },
					size = { clanListLegendOfficialWidth, clanListClans[i].size.h },
					bgColor = { 0, 0, 0, 0.05 }
				})
				local officialStatus = clanList[i].isofficial == 1 and TB_MENU_LOCALIZED.CLANSTATEOFFICIAL or TB_MENU_LOCALIZED.CLANSTATEUNOFFICIAL
				clanListClanOfficial:addCustomDisplay(false, function()
						clanListClanOfficial:uiText(officialStatus, nil, nil, 4, CENTERMID, 0.7)
					end)
				local clanListClanJoinMode = UIElement:new({
					parent = clanListClans[i],
					pos = { clanListLegendRankWidth + clanListLegendNameWidth + clanListLegendOfficialWidth, 0 },
					size = { clanListLegendJoinModeWidth, clanListClans[i].size.h }
				})
				local joinModeStatus = clanList[i].isfreeforall == 1 and TB_MENU_LOCALIZED.CLANSTATEFREEFORALL or TB_MENU_LOCALIZED.CLANSTATEINVITEONLY
				clanListClanJoinMode:addCustomDisplay(true, function()
						clanListClanJoinMode:uiText(joinModeStatus, nil, nil, 4, CENTERMID, 0.7)
					end)
				clanListClans[i]:hide()
			end
			
			local clanListScrollBG = UIElement:new({
				parent = clanListView,
				pos = { -(clanListView.size.w - clanListHolder.size.w), 0 },
				size = { clanListView.size.w - clanListHolder.size.w, clanListHolder.size.h },
				bgColor = TB_MENU_DEFAULT_DARKER_COLOR
			})
			local clanListScrollBar = TBMenu:spawnScrollBar(clanListHolder, #clanListClans, clanEntryHeight)
			clanListScrollBar:makeScrollBar(clanListHolder, clanListClans, toReload, CLANLISTSHIFT)
		else 
			clanListHolder:addCustomDisplay(true, function()
				clanListHolder:uiText(TB_MENU_LOCALIZED.CLANSLISTEMPTYMSG, nil, nil, 4)
			end)
		end
	end
	
	function Clans:showClanInfoLeft(viewElement, clanid)
		if (not ClanData[clanid].bgcolor) then
			TBMenu:addBottomBloodSmudge(viewElement, 2)
		end
		local clanName = UIElement:new({
			parent = viewElement,
			pos = { 10, 10 },
			size = { viewElement.size.w - 20, 60 }
		})
		local clanTag = ClanData[clanid].isofficial == 1 and "[" .. ClanData[clanid].tag .. "]" or "(" .. ClanData[clanid].tag .. ")"
		clanName:addAdaptedText(true, clanTag .. " " .. ClanData[clanid].name, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.2)
		local joinInteractive = false
		if (ClanData[clanid].isfreeforall == 1 and TB_MENU_PLAYER_INFO.clan.id == 0 and (ClanData[clanid].memberstotal < ClanLevelData[ClanData[clanid].level + 1].maxmembers or Clans:isBeginnerClan(clanid))) then
			joinInteractive = true
		end
		local clanJoin = UIElement:new({
			parent = viewElement,
			pos = { 10, -80 },
			size = { viewElement.size.w - 20, 70 },
			interactive = joinInteractive,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 }
		})
		if (joinInteractive) then
			clanJoin:addAdaptedText(false, TB_MENU_LOCALIZED.CLANSJOINCLAN)
			clanJoin:addMouseHandlers(nil, function()
					open_url("http://forum.toribash.com/clan.php?clanid=" .. clanid .. "&join=1")
				end)
		elseif (ClanData[clanid].isfreeforall == 1) then
			clanJoin:addAdaptedText(false, TB_MENU_LOCALIZED.CLANSTATEFREEFORALL, nil, nil, nil, nil, nil, nil, 0.2)
		else
			clanJoin:addAdaptedText(false, TB_MENU_LOCALIZED.CLANSTATEINVITEONLY, nil, nil, nil, nil, nil, nil, 0.2)
		end
		
		local freeSpace = viewElement.size.h - clanName.shift.y - clanName.size.h - clanJoin.size.h - 30
		local logoScale = 256 > freeSpace and freeSpace or 256
		local clanLogo = UIElement:new({
			parent = viewElement,
			pos = { (viewElement.size.w - logoScale) / 2, clanName.size.h + clanName.shift.y + 10 + (freeSpace - logoScale) / 2 },
			size = { logoScale, logoScale },
			bgImage =  { "../textures/clans/"..clanid..".tga", CLANLOGODEFAULT }
		})
		Clans:loadClanLogo(clanid, clanLogo)
		local logoReload = UIElement:new({
			parent = clanLogo,
			pos = { 0, 0 },
			size = { clanLogo.size.w, clanLogo.size.h },
			interactive = true,
			bgColor = { 0, 0, 0, 0 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 }
		})
		logoReload:addCustomDisplay(true, function()
				local color = logoReload:getButtonColor()
				set_color(unpack(color))
				draw_quad(logoReload.pos.x, logoReload.pos.y, logoReload.size.w, logoReload.size.h)
				logoReload:uiText(TB_MENU_LOCALIZED.CLANSRELOADLOGO, nil, nil, nil, nil, nil, nil, nil, {1, 1, 1, color[4] * 2} )
			end)
		logoReload:addMouseHandlers(nil, function()
				Clans:loadClanLogo(clanid, clanLogo, true)
			end, nil)
	end
	
	function Clans:showClanInfoMid(viewElement, clanid)
		local clanLevelValue = ClanData[clanid].level
		local clanTopAch = ClanData[clanid].topach
		local xpBarProgress = 0
		if (clanLevelValue < #ClanLevelData) then
			xpBarProgress = (ClanData[clanid].xp - ClanLevelData[clanLevelValue].minxp) / (ClanLevelData[clanLevelValue + 1].minxp - ClanLevelData[clanLevelValue].minxp)
			if (xpBarProgress > 1) then
				xpBarProgress = 1
			end
		else 
			xpBarProgress = 1
		end
		
		if (not ClanData[clanid].bgcolor) then
			TBMenu:addBottomBloodSmudge(viewElement, 1)
		end
		local clanRank = UIElement:new( {
			parent = viewElement,
			pos = { 40, 10 },
			size = { (viewElement.size.w - 80) / 2, 35 }
		})
		local clanRankText = TB_MENU_LOCALIZED.CLANSLEGENDRANK .. " "..ClanData[clanid].rank
		if (ClanData[clanid].rank < 1) then
			clanRankText = TB_MENU_LOCALIZED.CLANSTATEUNRANKED
		end
		clanRank:addAdaptedText(true, clanRankText, nil, nil, FONTS.BIG, LEFTMID, nil, nil, 0.2)
		local clanLevel = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 2, 10 },
			size = { (viewElement.size.w - 80) / 2, 35}
		})
		clanLevel:addAdaptedText(false, TB_MENU_LOCALIZED.CLANSLEGENDLEVEL .. " " .. clanLevelValue, nil, nil, FONTS.BIG, RIGHTMID, nil, nil, 0.2)
		local clanXpBarOutline = UIElement:new( {
			parent = viewElement,
			pos = { 30, 50 },
			size = { viewElement.size.w - 60, 60 },
			bgColor = { 0.1, 0.1, 0.1, 0.5 },
			shapeType = ROUNDED,
			rounded = 10
		})
		local clanXpBar = UIElement:new({
			parent = clanXpBarOutline,
			pos = { 2, 2 },
			size = { clanXpBarOutline.size.w - 4, clanXpBarOutline.size.h - 4 },
			bgColor = ClanData[clanid].xpbarbgcolor or { 0.5, 0.1, 0.1, 1 },
			shapeType = clanXpBarOutline.shapeType,
			rounded = clanXpBarOutline.rounded / 5 * 4 })
		if (xpBarProgress > 0) then
			clanXpBarProgress = UIElement:new({
				parent = clanXpBar,
				pos = { 0, 0 },
				size = { clanXpBar.size.w * xpBarProgress, clanXpBar.size.h },
				bgColor = ClanData[clanid].xpbarcolor or { 0.78, 0.05, 0.08, 1 },
				shapeType = clanXpBar.shapeType,
				rounded = clanXpBar.rounded,
				innerShadow = { 4, 4 },
				shadowColor = { ClanData[clanid].xpbaraccenttopcolor or { 0.91, 0.34, 0.24, 1 }, ClanData[clanid].xpbaraccentbotcolor or { 0.33, 0, 0, 1 } }
			})
		end
		
		local clanXp = UIElement:new( {
			parent = clanXpBar,
			pos = { 0, 0 },
			size = { clanXpBar.size.w, clanXpBar.size.h } } )
		local clanXpStr = ClanData[clanid].xp
		if (clanLevelValue < #ClanLevelData) then
			clanXpStr = clanXpStr .. " / " .. ClanLevelData[clanLevelValue + 1].minxp .. " " .. TB_MENU_LOCALIZED.CLANSLEGENDXP
		else 
			clanXpStr = clanXpStr .. " " .. TB_MENU_LOCALIZED.CLANSLEGENDXP
		end
		clanXp:addAdaptedText(false, clanXpStr, nil, nil, FONTS.BIG, nil, 0.65, nil, nil, 1)
		local clanWars = UIElement:new({
			parent = viewElement,
			pos = { 30, 120 },
			size = { viewElement.size.w - 60, (viewElement.size.h - 140) / 2 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.1 },
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.1 }
		})
		clanWars:addAdaptedText(false, TB_MENU_LOCALIZED.CLANSVIEWWARSFORUM, nil, nil, FONTS.BIG, nil, 0.8, nil, 0.6)
		clanWars:addMouseHandlers(true, function()
				open_url("http://forum.toribash.com/clan_war.php?clanid=" .. clanid)
			end, nil)
		local clanTopAchievement = UIElement:new({
			parent = viewElement,
			pos = { 30, -(viewElement.size.h - 120) / 2 },
			size = { viewElement.size.w - 60, (viewElement.size.h - 140) / 2 }
		})
		if (clanTopAch ~= 0) then
			iconScale = clanTopAchievement.size.h >= 110 and 100 or clanTopAchievement.size.h - 10
			local clanTopAchIcon = UIElement:new({
				parent = clanTopAchievement,
				pos = { 10, (clanTopAchievement.size.h - iconScale) / 2 },
				size = { iconScale, iconScale },
				bgImage = "../textures/clans/achievements/" .. clanTopAch .. ".tga"
			})
			local clanTopAchName = UIElement:new({
				parent = clanTopAchievement,
				pos = { iconScale + 10, 0 },
				size = { clanTopAchievement.size.w - iconScale - 20, clanTopAchievement.size.h / 2 - 5 }
			})
			clanTopAchName:addCustomDisplay(false, function()
				clanTopAchName:uiText(ClanAchievementData[clanTopAch].achname, nil, nil, nil, CENTERBOT)
			end)
			local clanTopAchDesc = UIElement:new({
				parent = clanTopAchievement,
				pos = { iconScale + 30, clanTopAchievement.size.h / 2 + 5 },
				size = { clanTopAchievement.size.w - iconScale - 60, clanTopAchievement.size.h / 2 - 5 },
			})
			clanTopAchDesc:addCustomDisplay(false, function()
				clanTopAchDesc:uiText(ClanAchievementData[clanTopAch].achdesc, nil, nil, 4, CENTER, 0.7)
			end)
		else
			local clanTopAchDesc = UIElement:new({
				parent = clanTopAchievement,
				pos = { 10, 0 },
				size = { clanTopAchievement.size.w - 20, clanTopAchievement.size.h }
			})
			clanTopAchDesc:addCustomDisplay(false, function()
					clanTopAchDesc:uiText(TB_MENU_LOCALIZED.CLANSTOPACHMISSING, nil, nil, 4, nil, 0.7)
				end)
		end
	end
	
	function Clans:downloadHead(reloader, avatars, id)
		local downloads = get_downloads()
		if (table.getn(downloads) == 0) then
			if (PlayerInfo:getItems(avatars[id].player).textures.head.equipped) then
				avatars[id]:updateImage("../../custom/" .. avatars[id].player:lower() .. "/head.tga", nil, true)
			end
			if (id < #avatars) then
				id = id + 1
				download_head(avatars[id].player)
				TB_MENU_DOWNLOAD_INACTION = true
				reloader:addCustomDisplay(false, function() Clans:downloadHead(reloader, avatars, id) end)
			else 
				reloader:kill()
			end
		end
	end
	
	function Clans:reloadHeadAvatars(avatars)
		for i = #avatars, 1, -1 do
			if (avatars[i].player == TB_MENU_PLAYER_INFO.username) then
				table.remove(avatars, i)
				break
			end
		end
		if (avatars[1].player) then
			download_head(avatars[1].player)
		end
		TB_MENU_DOWNLOAD_INACTION = true
		local reloader = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 0, 0 },
			size = { 1, 1 }
		})
		reloader:addCustomDisplay(false, function() Clans:downloadHead(reloader, avatars, 1) end)
	end
	
	function Clans:showClanMemberlist(viewElement, clanid)
		local shaders = get_option("shaders")
		local avatarWidth = shaders * 40
		local rosterEntryHeight = 40
		
		
		local toReload, rosterTop, rosterBottom, rosterView, rosterMemberHolder, rosterScrollBG = TBMenu:prepareScrollableList(viewElement, 50, rosterEntryHeight, 15, ClanData[clanid].bgcolor)
		local rosterTitle = UIElement:new({
			parent = rosterTop,
			pos = { avatarWidth, 0 },
			size = { rosterTop.size.w - avatarWidth * 2, rosterTop.size.h }
		})
		local rosterStr = TB_MENU_LOCALIZED.CLANSLEGENDROSTER .. (Clans:isBeginnerClan(clanid) and (" (" .. ClanData[clanid].memberstotal .. ")") or (" (" .. ClanData[clanid].memberstotal .. "/" .. ClanLevelData[ClanData[clanid].level].maxmembers .. ")"))
		rosterTitle:addAdaptedText(true, rosterStr, nil, nil, FONTS.BIG, nil, nil, nil, 0)
		if (shaders == 1) then
			local viewportTopReplacer = UIElement:new({
				parent = rosterTop,
				pos = { 0, 0 },
				size = { avatarWidth, rosterTop.size.h },
				bgColor = ClanData[clanid].bgcolor or TB_MENU_DEFAULT_DARKER_COLOR,
				viewport = true
			})
			viewportTopReplacer:addCustomDisplay(false, function()
					set_color(unpack(viewportTopReplacer.bgColor))
					draw_box(0, 0, 10, 2, 2, 2, 0, 0, 0)
				end)
			local viewportBotReplacer = UIElement:new({
				parent = rosterBottom,
				pos = { 0, 0 },
				size = { avatarWidth, avatarWidth },
				bgColor = ClanData[clanid].bgcolor or TB_MENU_DEFAULT_DARKER_COLOR,
				viewport = true
			})
			viewportBotReplacer:addCustomDisplay(false, function()
					set_color(unpack(viewportBotReplacer.bgColor))
					draw_box(0, 0, 10, 2, 2, 2, 0, 0, 0)
				end)
		end
		if (not ClanData[clanid].bgcolor) then
			TBMenu:addBottomBloodSmudge(rosterBottom, 3)
		end
		
		local rosterMembers = {}
		local headAvatars = {}
		local rosterPos = 0
		if (#ClanData[clanid].leaders > 0) then
			local leadersTitle = UIElement:new({
				parent = rosterMemberHolder,
				pos = { 0, rosterPos },
				size = { rosterMemberHolder.size.w, rosterEntryHeight }
			})
			table.insert(rosterMembers, leadersTitle)
			rosterPos = rosterPos + rosterEntryHeight
			local leaderStr = ClanData[clanid].leaderscustom or (#ClanData[clanid].leaders > 1 and TB_MENU_LOCALIZED.CLANLEADERS or TB_MENU_LOCALIZED.CLANLEADER)
			leadersTitle:addAdaptedText(true, leaderStr, nil, nil, nil, nil, nil, nil, 0.2)
			for i,v in pairs(ClanData[clanid].leaders) do
				local leader = UIElement:new({
					parent = rosterMemberHolder,
					pos = { 0, rosterPos },
					size = { rosterMemberHolder.size.w, rosterEntryHeight },
					bgColor = rosterPos % (rosterEntryHeight * 2 ) == 0 and { 0, 0, 0, 0.1 } or { 0, 0, 0, 0 }
				})
				if (shaders == 1) then
					local avatarViewport = UIElement:new( {
						parent = leader,
						pos = { 0, 0 },
						size = { avatarWidth, avatarWidth },
						viewport = true
					})
					local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
					local player = PlayerInfo:getItems(v)
					if (player.textures.head.equipped) then
						headTexture[1] = "../../custom/" .. v .. "/head.tga"
					end
					local avatar = UIElement:new({
						parent = avatarViewport,
						pos = { 0, 0, 10 },
						rot = { 0, 0, 0 },
						radius = 1,
						bgColor = { 1, 1, 1, 1 },
						bgImage = headTexture
					})
					avatar.player = v
					table.insert(headAvatars, avatar)
				end
				local leaderText = UIElement:new({
					parent = leader,
					pos = { avatarWidth + 5, 0 },
					size = { leader.size.w - avatarWidth - 10, leader.size.h }
				})
				leaderText:addCustomDisplay(true, function()
						leaderText:uiText(v, nil, nil, 4, LEFTMID, 0.7)
					end)
				table.insert(rosterMembers, leader)
				rosterPos = rosterPos + rosterEntryHeight
			end
		end
		if (#ClanData[clanid].members > 0) then
			local membersTitle = UIElement:new({
				parent = rosterMemberHolder,
				pos = { 0, rosterPos },
				size = { rosterMemberHolder.size.w, rosterEntryHeight }
			})
			table.insert(rosterMembers, membersTitle)
			rosterPos = rosterPos + rosterEntryHeight
			local memberStr = ClanData[clanid].memberscustom or (#ClanData[clanid].members > 1 and TB_MENU_LOCALIZED.CLANMEMBERS or TB_MENU_LOCALIZED.CLANMEMBER)
			membersTitle:addAdaptedText(true, memberStr, nil, nil, nil, nil, nil, nil, 0.2)
			for i,v in pairs(ClanData[clanid].members) do
				local member = UIElement:new({
					parent = rosterMemberHolder,
					pos = { 0, rosterPos },
					size = { rosterMemberHolder.size.w, rosterEntryHeight },
					bgColor = rosterPos % (rosterEntryHeight * 2 ) == 0 and { 0, 0, 0, 0.05 } or { 0, 0, 0, 0 }
				})
				if (shaders == 1) then	
					local avatarViewport = UIElement:new( {
						parent = member,
						pos = { 0, 0 },
						size = { avatarWidth, member.size.h },
						viewport = true
					})
					local headTexture = { "../../custom/tori/head.tga", "../../custom/tori/head.tga" }
					local player = PlayerInfo:getItems(v)
					if (player.textures.head.equipped) then
						headTexture[1] = "../../custom/" .. v .. "/head.tga"
					end
					local avatar = UIElement:new({
						parent = avatarViewport,
						pos = { 0, 0, 10 },
						rot = { 0, 0, 0 },
						radius = 1,
						bgColor = { 1, 1, 1, 1 },
						bgImage = headTexture
					})
					avatar.player = v
					table.insert(headAvatars, avatar)
				end
				local memberText = UIElement:new({
					parent = member,
					pos = { avatarWidth + 5, 0 },
					size = { member.size.w - avatarWidth - 10, member.size.h }
				})
				memberText:addCustomDisplay(true, function()
						memberText:uiText(v, nil, nil, 4, LEFTMID, 0.7)
					end)
				table.insert(rosterMembers, member)
				rosterPos = rosterPos + rosterEntryHeight
			end
		end
		
		if (#rosterMembers > 0) then
			if (shaders == 1) then
				Clans:reloadHeadAvatars(headAvatars)
			end
			
			for i,v in pairs(rosterMembers) do
				v:hide()
			end
			
			local rosterScrollBar = TBMenu:spawnScrollBar(rosterMemberHolder, #rosterMembers, rosterEntryHeight)
			rosterScrollBar:makeScrollBar(rosterMemberHolder, rosterMembers, toReload)
		else 
			local clanMembersEmpty = UIElement:new({
				parent = rosterView,
				pos = { 0, 0 },
				size = { rosterView.size.w, rosterView.size.h }
			})
			clanMembersEmpty:addCustomDisplay(true, function()
					clanMembersEmpty:uiText(TB_MENU_LOCALIZED.CLANSMEMBERSEMPTY)
				end)
		end
	end
	
	function Clans:showClan(viewElement, clanid)
		TB_MENU_CLANS_OPENCLANID = clanid
		viewElement:kill(true)
		TBMenu:clearNavSection()
		TBMenu:showNavigationBar(Clans:getNavigationButtons(true), true)
				
		local clanView = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h + (ClanData[clanid].bgcolor and 25 or 0) },
			uiColor = ClanData[clanid].colorNegative and UICOLORBLACK,
			uiShadowColor = ClanData[clanid].colorNegative and UICOLORWHITE,
		})
		local clanInfoLeftView = UIElement:new({
			parent = clanView,
			pos = { 5, 0 },
			size = { 276, clanView.size.h },
			bgColor = ClanData[clanid].bgcolor or TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanInfoLeft(clanInfoLeftView, clanid)
		local memberlistWidth = (clanView.size.w - clanInfoLeftView.size.w - 30) / 3 * 2 < 200 and 200 or (clanView.size.w - clanInfoLeftView.size.w - 30) / 3
		memberlistWidth = memberlistWidth > 276 and 276 or memberlistWidth
		local clanInfoMemberlistView = UIElement:new({
			parent = clanView,
			pos = { -memberlistWidth - 5, 0 },
			size = { memberlistWidth, clanView.size.h },
			bgColor = ClanData[clanid].bgcolor or TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanMemberlist(clanInfoMemberlistView, clanid)
		local clanInfoMidView = UIElement:new({
			parent = clanView,
			pos = { clanInfoLeftView.size.w + clanInfoLeftView.shift.x + 10, 0 },
			size = { clanView.size.w - clanInfoLeftView.size.w - clanInfoMemberlistView.size.w - 30, clanView.size.h },
			bgColor = ClanData[clanid].bgcolor or TB_MENU_DEFAULT_BG_COLOR
		})
		Clans:showClanInfoMid(clanInfoMidView, clanid)
	end
	
	function Clans:loadClanLogo(clanid, viewElement, reload)
		for i = #LOGOCACHE, 1, -1 do
			if (LOGOCACHE[i] == clanid) then
				if (reload) then
					table.remove(LOGOCACHE, i)
					break
				else
					return
				end
			end
		end
		
		download_clan_logo(clanid)
		TB_MENU_DOWNLOAD_INACTION = true
		local rotation = 0
		local scale = 0
		local transparency = { 0.8 }
		local loadView = UIElement:new({
			parent = viewElement,
			pos = { 0, -30 },
			size = { viewElement.size.w, 30 }
		})
		loadView:addCustomDisplay(true, function()
				set_color(0, 0, 0, transparency[1] / 2)
				draw_quad(loadView.pos.x, loadView.pos.y, loadView.size.w, loadView.size.h)
			end)
		local loadIndicatorDisk = UIElement:new({
			parent = loadView,
			pos = { 0, 0 },
			size = { loadView.size.h,  loadView.size.h }
		})
		local loadIndicator = UIElement:new({
			parent = loadView,
			pos = { loadView.size.h, 0 },
			size = { loadView.size.w - loadView.size.h, loadView.size.h }
		})
		loadIndicatorDisk:addCustomDisplay(true, function()
				set_color(1,1,1,transparency[1])
				draw_disk(loadIndicatorDisk.pos.x + loadIndicatorDisk.size.w / 2, loadIndicatorDisk.pos.y + loadIndicatorDisk.size.h / 2, 6, 12, 200, 1, rotation, scale, 0)
				rotation = rotation + 2.5
				scale = scale + 5
				if (scale > 360) then
					scale = -360
				end
			end)
		local updateTextScale = 1
		while (not loadIndicator:uiText(TB_MENU_LOCALIZED.CLANSUPDATINGLOGO, nil, nil, nil, LEFT, updateTextScale, nil, nil, nil, nil, nil, true)) do
			updateTextScale = updateTextScale - 0.05
		end
		local downloadInProgress = true
		loadIndicator:addCustomDisplay(true, function()
				local downloads = get_downloads()
				if (table.getn(downloads) == 0) then
					downloadInProgress = false
				end
				if (not downloadInProgress) then
					if (transparency[1] == 0.8) then
						viewElement:updateImage("../textures/clans/"..clanid..".tga", CLANLOGODEFAULT, true)
					end
					transparency[1] = transparency[1] - 0.05
					if (transparency[1] <= 0) then
						table.insert(LOGOCACHE, clanid)
						loadView:kill()
					end
				end
				loadIndicator:uiText(TB_MENU_LOCALIZED.CLANSUPDATINGLOGO, nil, nil, nil, nil, updateTextScale, nil, nil, { 1, 1, 1, transparency[1] })
			end)
	end
end
