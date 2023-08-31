-- Bounty manager class

if (download_fetch_bounties) then
	TB_BOUNTIES_DEFINED = true
end

do
	Bounty = {}
	Bounty.__index = Bounty
	local cln = {}
	setmetatable(cln, Bounty)

	PlayerBounties = {}
	
	function Bounty:getBountyData(data)
		local onlinePlayers = FriendsList:updateOnline()
		local data_types = { "userid", "player", "tc", "claimed", "claimedby", "decap" }
		
		for i,ln in pairs(data) do
			if (not ln:find("^USERID")) then
				local data_stream = { ln:match(("([^\t]*)\t"):rep(#data_types)) }
				local online = false
				for i,v in pairs(onlinePlayers) do
					if (PlayerInfo:getUser(v.player):lower() == data_stream[2]:lower()) then
						online = v.room
					end
				end
				
				table.insert(PlayerBounties, {
					player = data_stream[2],
					reward = data_stream[3] + 0,
					claimed = data_stream[4] + 0,
					claimedby = data_stream[5],
					decap = data_stream[6] + 0,
					room = online
				})
			end
		end
	end
	
	function Bounty:quit()
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
	
	function Bounty:getNavigationButtons()
		local buttonText = (get_option("newmenu") == 0 or TB_MENU_MAIN_ISOPEN == 0) and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local buttonsData = {
			{ 
				text = buttonText, 
				action = function() Bounty:quit() end, 
				width = get_string_length(buttonText, FONTS.BIG) * 0.65 + 30 
			}
		}
		return buttonsData
	end
	
	function Bounty:showCurrentTarget(objectiveView, target)
		if (not target) then
			local noActiveBountiesMessage = UIElement:new({
				parent = objectiveView,
				pos = { 0, 0 },
				size = { objectiveView.size.w, objectiveView.size.h }
			})
			noActiveBountiesMessage:addAdaptedText(true, "No bounties currently active, check again later!")
			return
		end
		download_head(target.player)
		
		local bgSize = objectiveView.size.h > 1024 and 1024 or objectiveView.size.h
		bgSize = objectiveView.size.w < objectiveView.size.h * 1.6 and objectiveView.size.w / 1.6 or bgSize
		
		local wantedBackground = UIElement:new({
			parent = objectiveView,
			pos = { -objectiveView.size.w - bgSize / 8, (objectiveView.size.h - bgSize) / 2 },
			size = { bgSize, bgSize },
			bgImage = "../textures/menu/general/bounty_wanted.tga"
		})
		local objectiveViewport = UIElement:new({
			parent = objectiveView,
			pos = { bgSize / 10, (objectiveView.size.h - bgSize / 2) / 2 },
			size = { bgSize / 2, bgSize / 2 },
			viewport = true
		})
		local objectiveHead = UIElement:new({
			parent = objectiveViewport,
			pos = { 0, 0, 10 },
			rot = { 0, 0, -10 },
			radius = 0.9,
			bgColor = { 1, 1, 1, 1 },
			bgImage = { "../../custom/" .. target.player .. "/head.tga", "../../custom/tori/head.tga" }
		})
		objectiveHead:addCustomDisplay(false, function()
				if (#get_downloads() == 0) then
					objectiveHead:updateImage("../../custom/" .. target.player .. "/head.tga", "../../custom/tori/head.tga")
					objectiveHead:addCustomDisplay(false, function() end)
				end
			end)
		local objectiveTitle = UIElement:new({
			parent = objectiveView,
			pos = { bgSize * 0.8, 0 },
			size = { objectiveView.size.w - bgSize * 0.9, objectiveView.size.h / 7 }
		})
		objectiveTitle:addAdaptedText(true, "Current target", nil, nil, FONTS.BIG, LEFTBOT, 0.65)
		local playerName = UIElement:new({
			parent = objectiveView,
			pos = { objectiveTitle.shift.x, objectiveTitle.shift.y + objectiveTitle.size.h * 7 / 6 },
			size = { objectiveTitle.size.w, objectiveTitle.size.h }
		})
		playerName:addAdaptedText(true, "Player: " .. target.player, nil, nil, nil, LEFTBOT)
		local objectiveSpecifics = UIElement:new({
			parent = objectiveView,
			pos = { objectiveTitle.shift.x, playerName.shift.y + playerName.size.h * 7 / 6 },
			size = { objectiveTitle.size.w, objectiveTitle.size.h }
		})
		objectiveSpecifics:addAdaptedText(true, "Objective: " .. (target.decap == 0 and "defeat in fight" or "Decapitate and win"), nil, nil, nil, LEFTMID)
		local bountyReward = UIElement:new({
			parent = objectiveView,
			pos = { objectiveTitle.shift.x, objectiveSpecifics.shift.y + objectiveSpecifics.size.h * 7 / 6 },
			size = { objectiveTitle.size.w, objectiveTitle.size.h }
		})
		bountyReward:addAdaptedText(true, "Reward: " .. target.reward .. " TC", nil, nil, nil, LEFT)
		local bountyRoom = UIElement:new({
			parent = objectiveView,
			pos = { objectiveTitle.shift.x, bountyReward.shift.y + bountyReward.size.h * 7 / 6 },
			size = { objectiveTitle.size.w, objectiveTitle.size.h },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			shapeType = ROUNDED,
			rounded = 20
		})
		if (target.room) then
			local sign = UIElement:new({
				parent = bountyRoom,
				pos = { 10, bountyRoom.size.h / 2 - 10 },
				size = { 20, 20 },
				bgColor = UICOLORGREEN,
				shapeType = ROUNDED,
				rounded = 20
			})
			bountyRoom:addAdaptedText(false, "Online in " .. target.room, 40, nil, nil, LEFTMID)
			local joinButton = UIElement:new({
				parent = bountyRoom,
				pos = { -bountyRoom.size.w / 3, 10 },
				size = { bountyRoom.size.w / 3 - 10, bountyRoom.size.h - 20 },
				shapeType = ROUNDED,
				rounded = 20,
				interactive = true,
				bgColor = TB_MENU_DEFAULT_BG_COLOR,
				hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
				pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR
			})
			joinButton:addAdaptedText(false, "Join room", nil, nil, nil, nil, 0.8)
			joinButton:addMouseHandlers(nil, function()
					UIElement:runCmd("jo " .. target.room)
					close_menu()
				end)
		else
			local sign = UIElement:new({
				parent = bountyRoom,
				pos = { 10, bountyRoom.size.h / 2 - 10 },
				size = { 20, 20 },
				bgColor = UICOLORRED,
				shapeType = ROUNDED,
				rounded = 20
			})
			bountyRoom:addAdaptedText(false, "Offline", 40, nil, nil, LEFTMID)
		end	
		local aboutEvent = UIElement:new({
			parent = objectiveView,
			pos = { objectiveTitle.shift.x, bountyRoom.shift.y + bountyRoom.size.h * 7 / 6 },
			size = { objectiveTitle.size.w, objectiveTitle.size.h },
			interactive = true,
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
			hoverColor = TB_MENU_DEFAULT_LIGHTER_COLOR,
			pressedColor = TB_MENU_DEFAULT_DARKEST_COLOR,
			shapeType = ROUNDED,
			rounded = 20
		})
		aboutEvent:addAdaptedText(false, "About Toribash's Most Wanted")
		aboutEvent:addMouseHandlers(nil, function()
				Bounty:showAboutEvent(objectiveHead)
			end)
	end
	
	function Bounty:getEventInfo()
		local function getRandom(list)
			local seed = math.random(1, #list)
			return list[seed]
		end
		
		local season = {
			{
				titleimg = "../textures/menu/promo/halloween/description.tga",
				desc = "Halloween is upon us, and trouble is brewing on the streets. The Police has compiled a list of bloodthirsty maniacs and merciless criminals. Bounties have been places on their heads. It's time to hunt!\nEvery hour, there will be a new bounty placed on a randomly selected player and it will be up to you to find them and defeat them. In addition to that, there will be special bounties with higher rewards, which will be placed on carefully selected people within the community. You will be rewarded if you can claim the bounty that has been put on someone's head.",
			},
			{
				titleimg = "../textures/menu/promo/halloween/rules.tga",
				desc = "- Rigging matches to receive bounty rewards is prohibited.\n- Do not request for prizes won on one account to be sent to another account. You will receive all the items you won on the account you participated on."
			},
			{
				titleimg = "../textures/menu/promo/halloween/prizes.tga",
				prizes = {
					{
						title = "Best bounty hunter:",
						prizes = {
							items = { { itemid = getRandom({ 2031, 1997, 2030, 2029, 2028, 2188, 2281, 2674, 2741, 2743, 2742, 2784, 2783, 2785 }), name = "Random Halloween 3D Item" } },
							tc = 100000,
							st = 8
						}
					},
					{
						title = "Claim at least 2 bounties:",
						prizes = {
							items = { { itemid = getRandom({ 2031, 1997, 2030, 2029, 2028, 2188, 2281, 2674, 2741, 2743, 2742, 2784, 2783, 2785 }), name = "Random Halloween 3D Item" } },
							st = 2
						}
					},
				}
			}
		}
		return season
	end
	
	function Bounty:showAboutEvent(headObject, bountyList)
		headObject:hide()
		bountiesScrollBar:deactivate()
		
		local eventOverlay = TBMenu:spawnWindowOverlay()
		local eventViewHeight = eventOverlay.size.h / 2 > 532 and 532 or eventOverlay.size.h / 5 * 3
		if (eventViewHeight > eventOverlay.size.w / 8 * 3) then
			eventViewHeight = eventOverlay.size.w / 8 * 2
		end
		local eventViewBackground = UIElement:new({
			parent = eventOverlay,
			pos = { eventOverlay.size.w / 8, eventOverlay.size.h / 2 - eventViewHeight / 2 },
			size = { eventOverlay.size.w / 8 * 6, eventViewHeight },
			bgColor = TB_MENU_DEFAULT_DARKER_COLOR
		})
		local eventViewImage = UIElement:new({
			parent = eventViewBackground,
			pos = { 10, 10 },
			size = { eventViewHeight - 20, eventViewHeight - 20 },
			bgImage = "../textures/menu/promo/halloweenblock.tga"
		})
		local eventView = UIElement:new({
			parent = eventViewBackground,
			pos = { eventViewHeight, 0 },
			size = { eventViewBackground.size.w - eventViewHeight, eventViewBackground.size.h }
		})
		
		local eventInfo = Bounty:getEventInfo()
		
		local elementHeight = 33.8
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(eventView, 40, 45, 20)
		
		local eventTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 0 },
			size = { topBar.size.w - 20, topBar.size.h }
		})
		eventTitle:addAdaptedText(true, "Toribash's Most Wanted", nil, nil, FONTS.BIG)
		
		local backButton = UIElement:new({
			parent = botBar,
			pos = { -botBar.size.w / 3, 5 },
			size = { botBar.size.w / 3 - 20, botBar.size.h - 10 },
			interactive = true,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 1, 1, 0.2 }
		})
		backButton:addAdaptedText(false, TB_MENU_LOCALIZED.NAVBUTTONBACK)
		backButton:addMouseHandlers(nil, function()
				eventOverlay:kill()
				headObject:show()
				bountiesScrollBar:activate()
			end)
			
		local listElements = {}
		local count = 0
		for i, info in pairs(eventInfo) do
			count = count + 1
			if (info.titleimg) then
				local titleImageSize = listingHolder.size.w >= elementHeight * 8 and elementHeight * 8 or listingHolder.size.w
				local infoTitle = UIElement:new({
					parent = listingHolder,
					pos = { (listingHolder.size.w - titleImageSize) / 2, #listElements * elementHeight },
					size = { titleImageSize, titleImageSize / 8 },
					bgImage = info.titleimg
				})
				table.insert(listElements, infoTitle)
			end
			if (info.desc) then
				local textString = textAdapt(info.desc, 4, 0.7, listingHolder.size.w - 30)
				local rows = math.ceil(#textString / 2)
				for i = 1, rows do
					local infoRow = UIElement:new({
						parent = listingHolder,
						pos = { 10, #listElements * elementHeight },
						size = { listingHolder.size.w - 20, elementHeight }
					})
					local string = textString[i * 2] and textString[i * 2 - 1] .. textString[i * 2] or textString[i * 2 - 1]
					infoRow:addCustomDisplay(true, function()
							infoRow:uiText(string, nil, nil, 4, LEFT, 0.7)
						end)
					table.insert(listElements, infoRow)
				end
			end
			if (info.prizes) then
				for k, prize in pairs(info.prizes) do
					local prizeTitleHolder = UIElement:new({
						parent = listingHolder,
						pos = { 0, #listElements * elementHeight },
						size = { listingHolder.size.w, elementHeight }
					})
					local prizeListSign = UIElement:new({
						parent = prizeTitleHolder,
						pos = { elementHeight / 3, elementHeight / 3 },
						size = { elementHeight / 3, elementHeight / 3 },
						shapeType = ROUNDED,
						rounded = elementHeight / 6,
						bgColor = UICOLORBLACK
					})
					local prizeTitle = UIElement:new({
						parent = prizeTitleHolder,
						pos = { elementHeight, 0 },
						size = { prizeTitleHolder.size.w - elementHeight, elementHeight }
					})
					prizeTitle:addAdaptedText(true, prize.title, nil, nil, nil, LEFTMID)
					table.insert(listElements, prizeTitleHolder)
					if (prize.prizes.items) then
						local count = 0
						local itemsRow = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, itemsRow)
						local currentRow = itemsRow
						for j, item in pairs(prize.prizes.items) do
							count = count + 1
							if (count * (elementHeight + 10) > listingHolder.size.w - 20) then
								local itemsRowNew = UIElement:new({
									parent = listingHolder,
									pos = { 40, #listingHolder * elementHeight },
									size = { listingHolder.size.w - 50, elementHeight }
								})
								table.insert(listElements, itemsRowNew)
								count = 1
								currentRow = itemsRowNew
							end
							local itemDisplay = UIElement:new({
								parent = currentRow,
								pos = { (count - 1) * (elementHeight + 10), 0 },
								size = { elementHeight, elementHeight },
								interactive = true,
								bgImage = item.customicon and "../textures/store/" .. item.customicon ..".tga" or "../textures/store/items/" .. item.itemid .. ".tga"
							})
							local itemInfo = UIElement:new({
								parent = itemDisplay,
								pos = { 5, 5 },
								size = { 250, 84 },
								bgColor = { 1, 1, 1, 0.85 },
								shapeType = ROUNDED,
								rounded = 5
							})
							local itemTexture = UIElement:new({
								parent = itemInfo,
								pos = { 10, 10 },
								size = { 64, 64 },
								bgImage = item.customicon and "../textures/store/" .. item.customicon ..".tga" or "../textures/store/items/" .. item.itemid .. ".tga"
							})
							local itemDescription = UIElement:new({
								parent = itemInfo,
								pos = { 84, 10 },
								size = { itemInfo.size.w - 94, itemInfo.size.h - 20 }
							})
							itemDescription:addAdaptedText(false, item.name, nil, nil, 4, nil, 0.7, nil, nil, nil, UICOLORBLACK)
							itemDisplay:addCustomDisplay(false, function()
									if (itemDisplay.hoverState) then
										itemInfo:show()
									else
										itemInfo:hide()
									end
								end)
						end
					end
					if (prize.prizes.tc) then
						local tcPrizeHolder = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, tcPrizeHolder)
						local tcSign = UIElement:new({
							parent = tcPrizeHolder,
							pos = { 0, 5 },
							size = { elementHeight - 10, elementHeight - 10 },
							bgImage = "../textures/store/toricredit_tiny.tga"
						})
						local tcPrize = UIElement:new({
							parent = tcPrizeHolder,
							pos = { elementHeight, 0 },
							size = { tcPrizeHolder.size.w - elementHeight, elementHeight }
						})
						tcPrize:addAdaptedText(true, prize.prizes.tc .. " Toricredits", nil, nil, nil, LEFTMID, 0.8)
					end
					if (prize.prizes.st) then
						local stPrizeHolder = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, stPrizeHolder)
						local stSign = UIElement:new({
							parent = stPrizeHolder,
							pos = { 0, 5 },
							size = { elementHeight - 10, elementHeight - 10 },
							bgImage = "../textures/store/shiaitoken_tiny.tga"
						})
						local stPrize = UIElement:new({
							parent = stPrizeHolder,
							pos = { elementHeight, 0 },
							size = { stPrizeHolder.size.w - elementHeight, elementHeight }
						})
						stPrize:addAdaptedText(true, prize.prizes.st .. " Shiai Tokens", nil, nil, nil, LEFTMID, 0.8)
					end
					if (prize.prizes.misc) then
						local miscPrize = UIElement:new({
							parent = listingHolder,
							pos = { 40, #listElements * elementHeight },
							size = { listingHolder.size.w - 50, elementHeight }
						})
						table.insert(listElements, miscPrize)
						miscPrize:addAdaptedText(true, "+ " .. prize.prizes.misc, nil, nil, nil, LEFTMID, 0.9)
					end
				end
			end
			if (count < #eventInfo) then
				local separator = UIElement:new({
					parent = listingHolder,
					pos = { 0, #listElements * elementHeight },
					size = { listingHolder.size.w, elementHeight }
				})
				local separatorLine = UIElement:new({
					parent = separator,
					pos = { 10, separator.size.h / 2 - 0.5 },
					size = { separator.size.w - 20, 1 },
					bgColor = { 1, 1, 1, 0.2 }
				})
				table.insert(listElements, separator)
			end
		end
		
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local eventInfoScrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		eventInfoScrollBar:makeScrollBar(listingHolder, listElements, toReload)
	end
	
	function Bounty:showBountyList(viewElement)
		local elementHeight = 35
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 50, elementHeight, 20)
		TBMenu:addBottomBloodSmudge(botBar, 2)
		local bountyListTitle = UIElement:new({
			parent = topBar,
			pos = { 10, 5 },
			size = { topBar.size.w - 20, topBar.size.h - 10 }
		})
		bountyListTitle:addAdaptedText(true, "Latest bounties", nil, nil, FONTS.BIG, nil, 0.65)
		local listEntries = {}
		for i,v in pairs(PlayerBounties) do
			local playerName = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listEntries * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listEntries, playerName)
			playerName:addAdaptedText(false, "Target: " .. v.player, 10, nil, nil, LEFTBOT)
			local bountyInfo = UIElement:new({
				parent = listingHolder,
				pos = { 0, #listEntries * elementHeight },
				size = { listingHolder.size.w, elementHeight }
			})
			table.insert(listEntries, bountyInfo)
			local infoString = 	"Bounty: " .. v.reward .. " TC\n" ..
								(v.claimedby == "" and (v.room == false and "Offline" or "Online in " .. v.room) or "Claimed by " .. v.claimedby .. " in " .. TBMenu:getTime(v.claimed) .. "\n")
			bountyInfo:addAdaptedText(false, infoString, 10, nil, 4, LEFT, 0.6)
			if (i ~= 1) then
				local separator = UIElement:new({
					parent = playerName,
					pos = { 10, 0 },
					size = { playerName.size.w - 20, 1 },
					bgColor = { 1, 1, 1, 0.3 }
				})
			end
		end
		for i,v in pairs(listEntries) do
			v:hide()
		end
		
		bountiesScrollBar = TBMenu:spawnScrollBar(listingHolder, #listEntries, elementHeight)
		bountiesScrollBar:makeScrollBar(listingHolder, listEntries, toReload)
	end
	
	function Bounty:showBounties()
		add_hook("console", "tbMenuBountiesChatIgnore", function(s,i)
				if (s:find("Download complete")) then
					remove_hooks("tbMenuBountiesChatIgnore")
					return 1
				end
			end)
		tbMenuCurrentSection:kill(true)
		local objectiveView = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w / 3 * 2 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(objectiveView, 1)
		
		local bountyList = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { objectiveView.size.w + 15, 0 },
			size = { tbMenuCurrentSection.size.w / 3 - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		Bounty:showBountyList(bountyList)
		
		Bounty:showCurrentTarget(objectiveView, Bounty:getTarget())
	end
	
	function Bounty:getTarget()
		local bounties = {}
		for i,v in pairs(PlayerBounties) do
			if (v.claimedby == "") then
				table.insert(bounties, v)
			end
		end
		
		if (#bounties > 0) then
			bounties = UIElement:qsort(bounties, "reward", 1)
			for i,v in pairs(bounties) do
				if (v.room) then
					return v
				end
			end
			return bounties[1]
		else
			return false
		end
	end
	
	function Bounty:prepare()
		tbMenuCurrentSection:kill(true)
		UIElement:runCmd("refresh")
		download_fetch_bounties()
		local loadOverlay = UIElement:new({
			parent = tbMenuCurrentSection,
			pos = { 5, 0 },
			size = { tbMenuCurrentSection.size.w - 10, tbMenuCurrentSection.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		TBMenu:addBottomBloodSmudge(loadOverlay, 1)
		TBMenu:displayLoadingMark(loadOverlay, "Updating...")
		local bountyFile = Files:new("../data/bounties.txt")
		loadOverlay:addCustomDisplay(false, function()
				if (not bountyFile:isDownloading()) then
					bountyFile:reopen()
					Bounty:getBountyData(bountyFile:readAll())
					Bounty:showBounties()
				end
			end)
	end
	
end