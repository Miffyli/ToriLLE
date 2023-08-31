-- Events manager class

do
	Events = {}
	Events.__index = Events
	local cln = {}
	setmetatable(cln, Events)
	
	function Events:quit()
		tbMenuCurrentSection:kill(true)
		tbMenuNavigationBar:kill(true)
		TBMenu:showNavigationBar()
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 0
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Events:getEvents()
		return {
			{
				accentColor = { 1, 1, 1, 1 },
				uiColor = { 0.05, 0.44, 0.57, 1 },
				name = "Head Texture of the Month: Ocean",
				image = "../textures/menu/promo/events/htotmocean.tga",
				forumlink = "http://forum.toribash.com/showthread.php?t=623552",
				data = {
					{
						title = "Description",
						desc = "May it be the friendly fish near the surface or the mysterious horrors of the abyss, the Ocean has many interesting creatures dwelling within. Show us your favorite - as the theme for this month's HTOTM is Ocean!"
					},
					{
						title = "Rules",
						desc = "- No plagiarism, this isn't tolerated at all and is severely punishable\n- Do not submit old or pre-made textures\n- A rough sketch or WIP is required to prove that it is a head in progress and not a pre-made head that you are reposting\n- Collaborations are allowed, however in this scenario prizes will be split\n- Only one submission is allowed, which also means no alts used to submit two different heads (if you're collaborating with another artist, you can only submit that head)\n- Submissions must be in 512x512 resolution or higher\n- Post watermarked flats in this thread with spherical previews. It would be much appreciated if you used Toribash Textures for 3D previews\n- If you aren't using Toribash Textures, ensure to make your previews clear, show all aspects of your head and attempt to keep watermarks somewhat non-intrusive while still being effective"
					},
					{
						title = "Deadline",
						desc = "We will stop accepting new entries on February 6th, 20:00 (GMT +0)"
					},
				},
				prizes = {
					{
						info = "Best work",
						tc = 100000,
						st = 5,
						itemids = { 2888 }
					},
					{
						info = "Honorable mentions",
						tc = 30000,
						st = 3
					},
				}
			}
		}
	end
	
	function Events:showEventDescription(viewElement, event)
		local elementHeight = 41
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 55, elementHeight + 5, 20, event.accentColor)
		listingView.bgColor = cloneTable(event.accentColor)
		listingView.bgColor[4] = 0.7
		
		local listElements = {}
		for i, info in pairs(event.data) do
			if (info.imagetitle) then
				local imageScale = elementHeight * 8 > listingHolder.size.w - 20 and (listingHolder.size.w - 20) / 8 or elementHeight
				local infoTitle = UIElement:new({
					parent = listingHolder,
					pos = { listingHolder.size.w / 2 - imageScale * 4, #listElements * elementHeight },
					size = { imageScale * 8, imageScale },
					bgImage = info.imagetitle
				})
				table.insert(listElements, infoTitle)
			elseif (info.title) then
				local infoTitle = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				infoTitle:addAdaptedText(true, info.title, nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
				table.insert(listElements, infoTitle)
			end
			if (info.desc) then
				if (i == 2) then
					DEBUGGING_ACTIVE = true
				end
				local textString = textAdapt(info.desc, 4, 0.9, listingHolder.size.w - 80)
				DEBUGGING_ACTIVE = false
				local rows = math.ceil(#textString / 2)
				for i = 1, rows do
					local infoRow = UIElement:new({
						parent = listingHolder,
						pos = { 50, #listElements * elementHeight },
						size = { listingHolder.size.w - 80, elementHeight }
					})
					infoRow:addCustomDisplay(true, function()
							infoRow:uiText(textString[i * 2 - 1], nil, nil, 4, CENTER, 0.85)
							if (textString[i * 2]) then
								infoRow:uiText(textString[i * 2], nil, nil, 4, CENTERBOT, 0.85)
							end
						end)
					table.insert(listElements, infoRow)
				end
			end
			if (i ~= #event.data) then
				local emptyRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				table.insert(listElements, emptyRow)
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		scrollBar.bgColor = { 0, 0, 0, 0 }
		scrollBar.hoverColor = { 0, 0, 0, 0 }
		scrollBar.pressedColor = { 0, 0, 0, 0 }
		listingScrollBG.bgColor = { 0, 0, 0, 0 }
		
		return topBar, botBar
	end
	
	function Events:showPrizeInfo(prize, listingHolder, elements, elementHeight)
		local rewardView = UIElement:new({
			parent = listingHolder,
			pos = { 10, elements * elementHeight },
			size = { listingHolder.size.w - 20, elementHeight }
		})
		local rewardBulletpoint = UIElement:new({
			parent = rewardView,
			pos = { 0, rewardView.size.h / 2 - 3 },
			size = { 6, 6 },
			bgColor = rewardView.uiColor,
			shapeType = ROUNDED,
			rounded = rewardView.size.h
		})
		local itemIcon = UIElement:new({
			parent = rewardView,
			pos = { rewardBulletpoint.size.w + 5, 2 },
			size = { rewardView.size.h - 4, rewardView.size.h - 4 },
			bgImage = prize.icon or Torishop:getItemIcon(prize.itemid)
		})
		local itemName = UIElement:new({
			parent = rewardView,
			pos = { rewardBulletpoint.size.w + itemIcon.size.w + 10, 0 },
			size = { rewardView.size.w - (rewardBulletpoint.size.w + itemIcon.size.w + 10), rewardView.size.h }
		})
		itemName:addAdaptedText(true, prize.itemname, nil, nil, nil, LEFTMID)
		return rewardView
	end
	
	function Events:showEventPrizes(viewElement, event)
		local elementHeight = 41
		local toReload, topBar, botBar, listingView, listingHolder, listingScrollBG = TBMenu:prepareScrollableList(viewElement, 55, elementHeight + 5, 20, event.accentColor)
		listingView.bgColor = cloneTable(event.accentColor)
		listingView.bgColor[4] = 0.7
		
		local listElements = {}
		if (event.imagetitle) then
			local imageScale = elementHeight * 8 > listingHolder.size.w - 20 and (listingHolder.size.w - 20) / 8 or elementHeight
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { listingHolder.size.w / 2 - imageScale * 4, #listElements * elementHeight },
				size = { imageScale * 8, imageScale },
				bgImage = event.imagetitle
			})
			table.insert(listElements, infoTitle)
		else
			local infoTitle = UIElement:new({
				parent = listingHolder,
				pos = { 10, #listElements * elementHeight },
				size = { listingHolder.size.w - 20, elementHeight }
			})
			infoTitle:addAdaptedText(true, "Prizes", nil, nil, FONTS.BIG, nil, nil, nil, 0.5)
			table.insert(listElements, infoTitle)
		end
		
		for i, prize in pairs(event.prizes) do
			if (prize.info) then
				local infoRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				infoRow:addAdaptedText(true, prize.info)
				table.insert(listElements, infoRow)
			end
			if (prize.tc) then
				local itemShopInfo = { itemname = prize.tc .. " Toricredits", icon = "../textures/store/toricredit.tga" }
				local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
				table.insert(listElements, itemRewardView)
			end
			if (prize.st) then
				local itemShopInfo = { itemname = prize.st .. (prize.st > 1 and " Shiai Tokens" or " Shiai Token"), icon = "../textures/store/shiaitoken.tga" }
				local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
				table.insert(listElements, itemRewardView)
			end
			if (prize.itemids) then
				for i, id in pairs(prize.itemids) do
					local itemShopInfo = Torishop:getItemInfo(id)
					local itemRewardView = Events:showPrizeInfo(itemShopInfo, listingHolder, #listElements, elementHeight)
					table.insert(listElements, itemRewardView)
				end
			end
			if (i ~= #event.prizes) then
				local emptyRow = UIElement:new({
					parent = listingHolder,
					pos = { 10, #listElements * elementHeight },
					size = { listingHolder.size.w - 20, elementHeight }
				})
				table.insert(listElements, emptyRow)
			end
		end
		for i,v in pairs(listElements) do
			v:hide()
		end
		
		local scrollBar = TBMenu:spawnScrollBar(listingHolder, #listElements, elementHeight)
		scrollBar:makeScrollBar(listingHolder, listElements, toReload)
		scrollBar.bgColor = { 0, 0, 0, 0 }
		scrollBar.hoverColor = { 0, 0, 0, 0 }
		scrollBar.pressedColor = { 0, 0, 0, 0 }
		listingScrollBG.bgColor = { 0, 0, 0, 0 }
		
		return topBar, botBar
	end
	
	function Events:getEventInfo(id)
		local events = Events:getEvents()
		
		events[id].accentColor = events[id].accentColor or TB_MENU_DEFAULT_BG_COLOR
		return events[id]
	end
	
	function Events:showEventInfo(id)
		if (not TB_STORE_DATA.ready) then
			TBMenu:showDataError("Please wait until Torishop data is ready")
			return false
		end
		local event = Events:getEventInfo(1)
		local overlay = TBMenu:spawnWindowOverlay()
		UIScrollbarIgnore = false
		local viewElement = UIElement:new({
			parent = overlay,
			pos = { WIN_W / 10, 100 },
			size = { WIN_W * 0.8, WIN_H - 200 },
			bgColor = event.accentColor,
			uiColor = event.uiColor
		})
		overlay:addMouseHandlers(nil, function()
				overlay:kill()
			end)
		local scale = viewElement.size.h * 2 - 200 < viewElement.size.w and viewElement.size.h - 100 or viewElement.size.w / 2
		local backgroundImage = UIElement:new({
			parent = viewElement,
			pos = { viewElement.size.w / 2 - scale, (viewElement.size.h - scale) / 2 },
			size = { scale * 2, scale },
			bgImage = event.image
		})
		
		local descriptionView = UIElement:new({
			parent = viewElement,
			pos = { 0, 0 },
			size = { viewElement.size.w * 0.6, viewElement.size.h }
		})
		local dtopBar, dbotBar = Events:showEventDescription(descriptionView, event)
		local prizesView = UIElement:new({
			parent = viewElement,
			pos = { descriptionView.size.w, 0 },
			size = { viewElement.size.w - descriptionView.size.w, viewElement.size.h }
		})
		local ptopBar, pbotBar = Events:showEventPrizes(prizesView, event)
		
		local eventName = UIElement:new({
			parent = dtopBar,
			pos = { 10, 0 },
			size = { viewElement.size.w - (dtopBar.size.h - 30), dtopBar.size.h },
			bgColor = event.accentColor
		})
		table.insert(ptopBar.child, eventName)
		eventName:addAdaptedText(false, event.name, nil, nil, FONTS.BIG)
		
		local eventForumLinkHolder = UIElement:new({
			parent = dbotBar,
			pos = { 0, 0 },
			size = { viewElement.size.w, dbotBar.size.h },
			bgColor = event.accentColor,
			uiColor = event.accentColor
		})
		local buttonHColor, buttonPColor = cloneTable(viewElement.uiColor), cloneTable(viewElement.uiColor)
		local delta = buttonHColor[1] + buttonHColor[2] + buttonHColor[3]
		if (delta > 1.5) then
			buttonHColor[2] = (buttonHColor[2] - math.abs(0.8 - buttonHColor[2]))
			buttonHColor[3] = (buttonHColor[3] - math.abs(0.8 - buttonHColor[3]))
			buttonPColor[2] = (buttonPColor[2] - math.abs(0.85 - buttonPColor[2]))
			buttonPColor[3] = (buttonPColor[3] - math.abs(0.85 - buttonPColor[3]))
		else
			buttonHColor[1] = (buttonHColor[1] + math.abs(0.6 - buttonHColor[1]))
			buttonPColor[1] = (buttonPColor[1] + math.abs(0.7 - buttonPColor[1]))
		end
		
		local eventForumLink = UIElement:new({
			parent = eventForumLinkHolder,
			pos = { viewElement.size.w / 4, 5 },
			size = { viewElement.size.w / 2, eventForumLinkHolder.size.h - 10 },
			interactive = true,
			bgColor = viewElement.uiColor,
			hoverColor = buttonHColor,
			pressedColor = buttonPColor,
			shapeType = ROUNDED,
			rounded = 3
		})
		table.insert(pbotBar.child, eventForumLink)
		TBMenu:showTextExternal(eventForumLink, "View event on forums")
		eventForumLink:addMouseHandlers(nil, function()
				open_url(event.forumlink)
			end)
		
		local closeButton = UIElement:new({
			parent = ptopBar,
			pos = { -(ptopBar.size.h - 10), 10 },
			size = { ptopBar.size.h - 20, ptopBar.size.h - 20 },
			bgColor = viewElement.uiColor,
			hoverColor = buttonHColor,
			pressedColor = buttonPColor,
			rounded = 3,
			shapeType = ROUNDED,
			interactive = true
		})
		local closeTexture = "../textures/menu/general/buttons/crosswhite.tga"
		if (delta > 1.5) then
			closeTexture = "../textures/menu/general/buttons/crossblack.tga"
		end
		local closeImage = UIElement:new({
			parent = closeButton,
			pos = { 5, 5 },
			size = { closeButton.size.w - 10, closeButton.size.h - 10 },
			bgImage = closeTexture
		})
		table.insert(dtopBar.child, closeButton)
		closeButton:addMouseHandlers(nil, function()
				overlay:kill()
			end)
	end
end
