-- Friends List manager

do
	FriendsList = {}
	FriendsList.__index = FriendsList
	local cln = {}
	setmetatable(cln, FriendsList)
	
	function FriendsList:quit()
		if (get_option("newmenu") == 0) then
			FRIENDSLIST_OPEN = false
			tbMenuMain:kill()
			remove_hooks("tbMainMenuVisual")
			return
		end
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function FriendsList:getNavigationButtons()
		local buttonText = get_option("newmenu") == 0 and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local navigation = {
			{ 
				text = buttonText, 
				action = function() FriendsList:quit() end, 
				width = get_string_length(buttonText, FONTS.BIG) * 0.65 + 30 
			}
		}
		return navigation
	end
	
	-- Run /sa * command to fetch all online players
	function FriendsList:updateOnline()
		local playersOnline = {}
		add_hook("console", "friendsListConsoleIgnore", function(s, i)
			-- Ignore the info message and lobbies
			if (s:match("Searching for") or s:match("Players:%d")) then 
				return 1
			end
			
			local data = { s:match(("([^ ]+) *"):rep(2)) }
			table.insert(playersOnline, { room = data[1]:lower(), player = data[2]:lower() })
			return 1
		end)
		UIElement:runCmd("sa *", false, true)
		remove_hooks("friendsListConsoleIgnore")
		-- Remove the command echo
		table.remove(playersOnline)
		return playersOnline
	end
	
	function FriendsList:getOnline(viewElement, noWait)
		FRIENDSLIST_IS_REFRESHED = false
		add_hook("console", "friendsListConsoleIgnore", function(s, i) if (s == "refreshing server list") then return 1 end end)
		UIElement:runCmd("refresh")
		remove_hooks("friendsListConsoleIgnore")
		
		local waitBlock = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h }
		})
		local waitBlockStartTime = os.clock()
		waitBlock:addCustomDisplay(true, function()
				local timediff = os.clock() - waitBlockStartTime
				-- Wait animation
				set_color(1, 1, 1, 0.8)
				draw_disk(waitBlock.pos.x + waitBlock.size.w / 2, waitBlock.pos.y + waitBlock.size.h / 2, waitBlock.size.h / 30, waitBlock.size.h / 15, 500, 1, timediff * 180, timediff * 360, 0)
				
				if (timediff >= 1 or noWait) then
					FRIENDSLIST_PLAYERS_ONLINE = FriendsList:updateOnline()
					FRIENDSLIST_IS_REFRESHED = true
					FRIENDSLIST_REFRESH_TIME = os.clock()
					local clanFriends = {}
					
					for i,v in pairs(FRIENDSLIST_FRIENDS) do
						for k,n in pairs(FRIENDSLIST_PLAYERS_ONLINE) do
							if (PlayerInfo:getUser(n.player) == v.username) then
								v.online = true
								v.room = n.room
								break
							end
							if (v.username:match("%b()") or v.username:match("%b[]") or v.username:match("%b{}")) then
								if (PlayerInfo:getClanTag(n.player) == v.username:gsub("%W", "")) then
									table.insert(clanFriends, { username = n.player, online = true, room = n.room })
								end
							end
						end
					end
					
					-- Remove duplicate entries when one of friends is also found during clan friends search
					for i,v in pairs(FRIENDSLIST_FRIENDS) do
						for n = #clanFriends, 1, -1 do
							if (v.username == PlayerInfo:getUser(clanFriends[n].username)) then
								table.remove(clanFriends, n)
							end
						end
					end
					for i,v in pairs(clanFriends) do
						table.insert(FRIENDSLIST_FRIENDS, v)
					end
					waitBlock:kill()
					FriendsList:showFriends(viewElement)
				end
			end)
	end
	
	function FriendsList:getFriends()
		local file = Files:new("../data/buddies.txt")
		if (not file.data) then
			UIElement:runCmd("ab testuser")
			file:reopen()
			if (not file.data) then
				return false
			end
			UIElement:runCmd("rb testuser")
		end
		FRIENDSLIST_FRIENDS = {}
		
		for i, ln in pairs(file:readAll()) do
			local segments = 3
			local data_stream = { ln:match(("([^ ]+) *"):rep(segments)) }
			table.insert(FRIENDSLIST_FRIENDS, { username = data_stream[1], online = false, room = false })
		end
		
		file:close()
		return true
	end
	
	function FriendsList:addFriend(player)
		local friend = { username = player:lower() }
		for i,v in pairs(FRIENDSLIST_PLAYERS_ONLINE) do
			if (v.player == friend.username) then
				friend.online = true
				friend.room = v.room
				break
			end
		end
		table.insert(FRIENDSLIST_FRIENDS, friend)
		UIElement:runCmd("addbuddy " .. player:lower())
	end
	
	function FriendsList:removeFriend(player)
		for i,v in pairs (FRIENDSLIST_FRIENDS) do
			if (v.username == player) then
				table.remove(FRIENDSLIST_FRIENDS, i)
				break
			end
		end
		UIElement:runCmd("removebuddy " .. player)
		--FriendsList:updateDataFile()
	end
	
	function FriendsList:showFriendsList(viewElement)
		local entryHeight = 35
		
		local toReload = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h}
		})
		
		local friendsTopBar = UIElement:new({
			parent = toReload,
			pos = { 0, 0 },
			size = { viewElement.size.w, entryHeight },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		local friendsBotBar = UIElement:new({
			parent = toReload,
			pos = { 0, -entryHeight },
			size = { viewElement.size.w, entryHeight },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		})
		TBMenu:addBottomBloodSmudge(friendsBotBar, 1)
		
		local friendsMain = UIElement:new({
			parent = viewElement,
			pos = { 0, friendsTopBar.size.h },
			size = { friendsTopBar.size.w, viewElement.size.h - friendsTopBar.size.h - friendsBotBar.size.h }
		})
		local friendsView = UIElement:new({
			parent = friendsMain,
			pos = { 0, 0 },
			size = { friendsMain.size.w - 20, friendsMain.size.h }
		})
		
		local friendsElements = {}
		for i,v in pairs(UIElement:qsort(FRIENDSLIST_FRIENDS, "online", true)) do
			local friendElement = UIElement:new({
				parent = friendsView,
				pos = { 0, (i - 1) * entryHeight },
				size = { friendsView.size.w, entryHeight },
				bgColor = i % 2 == 1 and TB_MENU_DEFAULT_BG_COLOR or TB_MENU_DEFAULT_DARKER_COLOR
			})
			table.insert(friendsElements, friendElement)
			local friendOnlineMarker = UIElement:new({
				parent = friendElement,
				pos = { friendElement.size.w / 40, friendElement.size.h / 3 },
				size = { friendElement.size.h / 3, friendElement.size.h / 3 },
				bgColor = v.online and UICOLORGREEN or { 0.8, 0.8, 0.8, 1},
				shapeType = ROUNDED,
				rounded = friendElement.size.h
			})
			local friendName = UIElement:new({
				parent = friendElement,
				pos = { friendOnlineMarker.shift.x + friendElement.size.h / 3 * 2, 0 },
				size = { friendElement.size.w / 3, friendElement.size.h }
			})
			friendName:addCustomDisplay(true, function()
					friendName:uiText(v.username, nil, nil, nil, LEFTMID)
				end)
			if (v.online) then
				local friendRoomLocation = UIElement:new({
					parent = friendElement,
					pos = { friendName.shift.x + friendName.size.w, 0 },
					size = { (friendElement.size.w - friendName.shift.x - friendName.size.w) / 2, friendElement.size.h }
				})
				friendRoomLocation:addCustomDisplay(false, function()
						friendRoomLocation:uiText(v.room, nil, nil, 4, nil, 0.75)
					end)
				local friendRoomJoinButton = UIElement:new({
					parent = friendElement,
					pos = { friendElement.size.w - friendRoomLocation.size.w, 5 },
					size = { friendRoomLocation.size.w - friendElement.size.h, friendElement.size.h - 10 },
					interactive = true,
					bgColor = { 0, 0, 0, 0.1 },
					hoverColor = { 0, 0, 0, 0.3 },
					pressedColor = { 1, 0, 0, 0.2 }
				})
				friendRoomJoinButton:addCustomDisplay(false, function()
						friendRoomJoinButton:uiText(TB_MENU_LOCALIZED.FRIENDSLISTJOINROOM, nil, nil, nil, nil, 0.8)
					end)
				friendRoomJoinButton:addMouseHandlers(nil, function()
						UIElement:runCmd("jo " .. v.room)
						close_menu()
					end)
			end
			if (not v.username:match("[)%]}].+")) then
				local friendRemoveButton = UIElement:new({
					parent = friendElement,
					pos = { friendElement.size.w - friendElement.size.h + 5, 5 },
					size = { friendElement.size.h - 10, friendElement.size.h - 10 },
					interactive = true,
					bgColor = { 0, 0, 0, 0.1 },
					hoverColor = { 1, 0, 0, 0.3 },
					pressedColor = { 1, 0, 0, 0.5 },
					bgImage = "../textures/menu/general/buttons/crosswhite.tga"
				})
				friendRemoveButton:addMouseHandlers(nil, function()
					FriendsList:removeFriend(v.username)
					FriendsList:showFriends(viewElement.parent)
				end)
			end
		end
		if (#friendsElements == 0) then
			local friendsMessageTop = UIElement:new({
				parent = friendsView,
				pos = { 10, 0 },
				size = { friendsView.size.w - 20, friendsView.size.h / 2 - 5 }
			})
			friendsMessageTop:addAdaptedText(true, TB_MENU_LOCALIZED.FRIENDSLISTEMPTY .. " :(", nil, nil, FONTS.BIG, CENTERBOT)
			local friendsMessageBot = UIElement:new({
				parent = friendsView,
				pos = { 10, friendsView.size.h / 2 + 5 },
				size = { friendsView.size.w - 20, friendsView.size.h / 2 - 5 }
			})
			friendsMessageBot:addAdaptedText(true, TB_MENU_LOCALIZED.FRIENDSLISTEMPTYINFO, nil, nil, nil, CENTER)
		end
			
		for i,v in pairs(friendsElements) do
			v:hide()
		end
		
		local friendsScrollBG = UIElement:new({
			parent = friendsMain,
			pos = { -(friendsMain.size.w - friendsView.size.w), 0 },
			size = { friendsMain.size.w - friendsView.size.w, friendsView.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		
		local friendsScrollBar = TBMenu:spawnScrollBar(friendsView, #friendsElements, entryHeight)
		friendsScrollBar:makeScrollBar(friendsView, friendsElements, toReload)
		
		local legendInfo = {
			{ name = "", width = friendsView.size.w / 40 + entryHeight},
			{ name = TB_MENU_LOCALIZED.FRIENDSLISTLEGENDPLAYER, width = friendsView.size.w / 3 },
			{ name = TB_MENU_LOCALIZED.FRIENDSLISTLEGENDROOM, width = (friendsView.size.w * 2 / 3 - friendsView.size.w / 40 - entryHeight * 2 + 10) / 2 }
		}
		local legendShiftX = 0
		for i = 1, #legendInfo do
			local legendElement = UIElement:new({
				parent = friendsTopBar,
				pos = { legendShiftX, 0 },
				size = { legendInfo[i].width, friendsTopBar.size.h }
			})
			legendShiftX = legendShiftX + legendElement.size.w
			legendElement:addCustomDisplay(true, function()
					legendElement:uiText(legendInfo[i].name, nil, nil, 4, nil, 0.6)
				end)
		end
		local friendsRefresh = UIElement:new({
			parent = friendsBotBar,
			pos = { friendsBotBar.size.w / 4, 5 },
			size = { friendsBotBar.size.w / 2, friendsBotBar.size.h - 5 },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_BG_COLOR,
			hoverColor = { 0, 0, 0, 0.3 },
			pressedColor = { 1, 0, 0, 0.2 }
		})
		friendsRefresh:addCustomDisplay(false, function()
				friendsRefresh:uiText(TB_MENU_LOCALIZED.FRIENDSLISTREFRESH)
			end)
		friendsRefresh:addMouseHandlers(nil, function()
				local friendsView = viewElement.parent
				viewElement:kill()
				if (FriendsList:getFriends()) then
					FriendsList:getOnline(friendsView)
				end
			end)
	end
	
	function FriendsList:showFriends(viewElement)
		viewElement:kill(true)
		local headerTitle = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, 50 }
		})
		local titleTextScale = 0.7
		while (not headerTitle:uiText(TB_MENU_LOCALIZED.FRIENDSLISTTITLE, nil, nil, FONTS.BIG, 0, titleTextScale, nil, nil, nil, nil, nil, true)) do
			titleTextScale = titleTextScale - 0.05
		end
		headerTitle:addCustomDisplay(true, function()
				headerTitle:uiText(TB_MENU_LOCALIZED.FRIENDSLISTTITLE, nil, nil, FONTS.BIG, nil, titleTextScale)
			end)
		
		local friendsView = UIElement:new({
			parent = viewElement,
			pos = { 0, headerTitle.size.h },
			size = { viewElement.size.w, viewElement.size.h - headerTitle.size.h }
		})
		FriendsList:showFriendsList(friendsView)
	end
	
	function FriendsList:showMenu(viewElement)
		local friendAddView = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w, viewElement.size.h / 4 }
		})
		local imageSize = viewElement.size.w / 4 * 5 < viewElement.size.h / 7 * 5 and viewElement.size.w / 4 * 5 or viewElement.size.h / 7 * 5
		local friendImage = UIElement:new({
			parent = viewElement,
			pos = { imageSize > viewElement.size.w and -viewElement.size.w - (imageSize - viewElement.size.w) / 2 or (viewElement.size.w - imageSize) / 2, viewElement.size.h / 3 + (viewElement.size.h / 7 * 4 - imageSize) / 2 },
			size = { imageSize, imageSize },
			bgImage = "../textures/menu/friendslist.tga"
		})
		local friendAddTitle = UIElement:new({
			parent = friendAddView,
			pos = { 0, 0 },
			size = { friendAddView.size.w, friendAddView.size.h / 2 }
		})
		friendAddTitle:addCustomDisplay(true, function()
				friendAddTitle:uiText(TB_MENU_LOCALIZED.FRIENDSLISTADDFRIEND)
			end)
		local elementHeight = friendAddView.size.h / 2 > 30 and 30 or friendAddView.size.h / 2
		local friendAddInputBG = UIElement:new({
			parent = friendAddView,
			pos = { elementHeight / 2, friendAddView.size.h / 2 },
			size = { friendAddView.size.w - elementHeight, elementHeight },
			shapeType = ROUNDED,
			rounded = 3
		})
		friendAddInputBG:addCustomDisplay(true, function() end)
		local friendAddInputField = TBMenu:spawnTextField(friendAddInputBG, nil, nil, friendAddInputBG.size.w - elementHeight - 5, nil, nil, nil, nil, 0.7, UICOLORWHITE, TB_MENU_LOCALIZED.FRIENDSLISTSEARCHDEFAULT)
		friendAddInputField:addEnterAction(function()
				FriendsList:addFriend(friendAddInputField.textfieldstr[1])
				FriendsList:showMain(viewElement.parent, true)
			end)
		local addFriendButton = UIElement:new({
			parent = friendAddInputBG,
			pos = { -elementHeight, 0 },
			size = { elementHeight, elementHeight },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.6 },
			pressedColor = { 0, 1, 0, 0.6 },
			shapeType = ROUNDED,
			rounded = 3
		})
		addFriendButton:addCustomDisplay(false, function()
				set_color(1, 1, 1, 1)
				draw_quad(	addFriendButton.pos.x + addFriendButton.size.w / 2 - 1,
							addFriendButton.pos.y + addFriendButton.size.h / 6,
							2,
							addFriendButton.size.h / 6 * 4	)
				draw_quad(	addFriendButton.pos.x + addFriendButton.size.w / 6,
							addFriendButton.pos.y + addFriendButton.size.h / 2 - 1,
							addFriendButton.size.w / 6 * 4,
							2	)
			end)
		addFriendButton:addMouseHandlers(nil, function()
				FriendsList:addFriend(friendAddInputField.textfieldstr[1])
				FriendsList:showMain(viewElement.parent, true)
			end)
	end
	
	function FriendsList:showMain(viewElement, noWait)
		viewElement:kill(true)
		local friendsView = UIElement:new({
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w * 0.7 - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(friendsView, 1)
		if (FriendsList:getFriends()) then
			FriendsList:getOnline(friendsView, noWait)
		end
		
		local friendsMenu = UIElement:new({
			parent = viewElement,
			pos = { friendsView.size.w + 15, 0 },
			size = { viewElement.size.w - friendsView.size.w - 20, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(friendsMenu, 2)
		FriendsList:showMenu(friendsMenu)
	end
end
