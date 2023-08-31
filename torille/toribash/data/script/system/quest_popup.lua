dofile("system/quests_manager.lua")

local DELAY = 5
local QUEST_POPUP_CLAIM = false

local inputData = ARG1
local _, popups = inputData:gsub(" ", "")

local popupsRaw = { inputData:match(("([^ ]*) ?"):rep(popups + 1)) }
local popupsData = {}
for i,v in pairs(popupsRaw) do
	local data = { v:match(("([^:]*):?"):rep(2)) }
	for i,v in pairs(data) do
		data[i] = tonumber(data[i])
	end
	table.insert(popupsData, data)
end

local function showPopup(i)
	local quest = Quests:getQuestById(popupsData[i][1])
	if (not quest) then
		if (popupsData[i + 1]) then
			showPopup(i + 1)
		end
		return
	end
	local oldProgress = quest.progress
	Quests:setQuestProgress(quest, popupsData[i][2])
	if (oldProgress > quest.progress) then
		DELAY = 0
	end
	local questProgressNotificationHolder = UIElement:new({
		globalid = TB_MENU_HUB_GLOBALID,
		pos = { WIN_W, WIN_H - 140 },
		size = { 350, 80 },
		bgColor = cloneTable(TB_MENU_DEFAULT_BG_COLOR),
		shapeType = ROUNDED,
		rounded = 5,
		innerShadow = { 0, 5 },
		shadowColor = cloneTable(TB_MENU_DEFAULT_DARKER_COLOR)
	})
	local popupClose = UIElement:new({
		parent = questProgressNotificationHolder,
		pos = { -27, 2 },
		size = { 25, 25 },
		shapeType = questProgressNotificationHolder.shapeType,
		rounded = questProgressNotificationHolder.rounded,
		interactive = true,
		bgColor = TB_MENU_DEFAULT_DARKER_COLOR,
		hoverColor = TB_MENU_DEFAULT_DARKEST_COLOR,
		pressedColor = TB_MENU_DEFAULT_LIGHTER_COLOR
	})
	local popupCloseIcon = UIElement:new({
		parent = popupClose,
		pos = { 3, 3 },
		size = { popupClose.size.w - 6, popupClose.size.h - 6 },
		bgImage = "../textures/menu/general/buttons/crosswhite.tga"
	})
	local buttonClicked = false
	popupClose:addMouseHandlers(nil, function()
			buttonClicked = true
		end)
	local qType = (quest.type == 4 and quest.decap) and "decap" or quest.type
	local questIcon = UIElement:new({
		parent = questProgressNotificationHolder,
		pos = { 5, 5 },
		size = { questProgressNotificationHolder.size.h - 15, questProgressNotificationHolder.size.h - 15 },
		bgImage = "../textures/menu/general/quests/qtype" .. qType .. ".tga"
	})
	local questInfo = UIElement:new({
		parent = questProgressNotificationHolder,
		pos = { questProgressNotificationHolder.size.h, 5 },
		size = { questProgressNotificationHolder.size.w - questProgressNotificationHolder.size.h - 20, questProgressNotificationHolder.size.h - 15 }
	})
	local questName = UIElement:new({
		parent = questInfo,
		pos = { 0, 0 },
		size = { questInfo.size.w, questInfo.size.h / 3 }
	})
	questName:addAdaptedText(true, Quests:getQuestName(quest), nil, nil, nil, nil, nil, nil, nil, 1)
	local questProgressBar = UIElement:new({
		parent = questInfo,
		pos = { 10, questInfo.size.h / 2 },
		size = { questInfo.size.w - 20, questInfo.size.h / 5 * 2 },
		bgColor = cloneTable(TB_MENU_DEFAULT_DARKEST_COLOR),
		shapeType = ROUNDED,
		rounded = 3
	})
	local pSize = oldProgress == 0 and 1 or questProgressBar.size.w * (oldProgress / quest.requirement)
	local questProgress = UIElement:new({
		parent = questProgressBar,
		pos = { 0, 0 },
		size = { pSize, questProgressBar.size.h },
		bgColor = UICOLORWHITE,
		shapeType = questProgressBar.shapeType,
		rounded = questProgressBar.rounded
	})
	local questProgressText = UIElement:new({
		parent = questProgressBar,
		pos = { 0, 0 },
		size = { questProgressBar.size.w, questProgressBar.size.h }
	})
	
	local function showClaim()
		QUEST_POPUP_CLAIM = true
		local trans = 1
		local grow = 10
		local colorsDiff, shadowDiff, barDiff = {}, {}, {}
		for i,v in pairs(TB_MENU_DEFAULT_YELLOW) do
			colorsDiff[i] = (questProgressNotificationHolder.bgColor[i] - v) / 20
		end
		for i,v in pairs(TB_MENU_DEFAULT_ORANGE) do
			shadowDiff[i] = (questProgressNotificationHolder.shadowColor[1][i] - v) / 20
		end
		for i,v in pairs({ 0.594, 0.418, 0.14, 1 }) do
			barDiff[i] = (questProgressBar.bgColor[i] - v) / 20
		end
		questIcon:addCustomDisplay(false, function()
				set_color(1, 1, 1, trans)
				draw_disk(questIcon.pos.x + questIcon.size.w / 2, questIcon.pos.y + questIcon.size.h / 2, grow, grow + 10, 100, 1, 0, 360, 0)
				trans = trans - 0.025
				grow = grow + 0.5
				if (trans < 0) then
					questIcon:addCustomDisplay(false, function() end)
					questProgress:kill()
					popupClose:kill()
					questProgressNotificationHolder.interactive = true
					questProgressNotificationHolder.animateColor = cloneTable(questProgressNotificationHolder.bgColor)
					questProgressNotificationHolder.pressedColor = { 0.902, 0.738, 0.269, 1 }
					questProgressNotificationHolder.hoverColor = { 0.969, 0.781, 0.199, 1 }
					questProgressNotificationHolder:activate()
					questProgressNotificationHolder:addMouseHandlers(nil, function()
							claim_quest(quest.id)
							buttonClicked = true
						end)
				end
				if (trans <= 0.5) then
					set_color(unpack(questProgressNotificationHolder.bgColor))
					draw_quad(popupClose.pos.x, popupClose.pos.y, popupClose.size.w, popupClose.size.h)
					for i = 1, 3 do
						questProgressNotificationHolder.bgColor[i] = questProgressNotificationHolder.bgColor[i] - colorsDiff[i]
						questProgressNotificationHolder.shadowColor[1][i] = questProgressNotificationHolder.shadowColor[1][i] - shadowDiff[i]
						questProgressBar.bgColor[i] = questProgressBar.bgColor[i] - barDiff[i]
					end
					questProgress.size.w = questProgressBar.size.w * trans * 2
				end
				if (trans <= 0.25) then
					questProgressText.uiColor = { 1, 1, 1, 1 - trans * 4 }
					questProgressText.uiShadowColor = { 0, 0, 0, 1 - trans * 4 }
					questProgressText:addAdaptedText(true, TB_MENU_LOCALIZED.QUESTSCLAIMREWARD, nil, nil, nil, nil, nil, nil, nil, 1)
				elseif (trans <= 0.5) then
					questProgressText.uiColor = { 1, 1, 1, trans * 4 - 1 }
					questProgressText.uiShadowColor = { 0, 0, 0, trans * 4 - 1 }
					questProgressText:addAdaptedText(true, questProgressText.str, nil, nil, nil, nil, nil, nil, nil, 1)
				end
			end, true)
	end
	
	local barProgress = math.pi / 10
	local targetSize = questProgressBar.size.w * (quest.progress / quest.requirement)
	local sizeDifference = targetSize - questProgress.size.w
	local progress = math.pi / 10
	questProgressNotificationHolder:addCustomDisplay(false, function()
			if (questProgressNotificationHolder.pos.x > WIN_W - 340) then
				questProgressNotificationHolder:moveTo(-questProgressNotificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
				progress = progress + math.pi / 30
			else
				local clock = os.clock()
				questProgress:addCustomDisplay(false, function()
						if (questProgress.size.w < (questProgressBar.size.w * (quest.progress / quest.requirement))) then
							questProgress.size.w = questProgress.size.w + sizeDifference * 0.02 * math.sin(barProgress)
							local tSize = targetSize == 0 and 0 or (questProgress.size.w / targetSize)
							questProgressText:addAdaptedText(true, math.floor(tSize * quest.progress) .. " / " .. quest.requirement, nil, nil, nil, nil, nil, nil, nil, 1)
							barProgress = barProgress + math.pi / 100
						else
							if (quest.progress >= quest.requirement) then
								showClaim()
							end
							questProgress:addCustomDisplay(false, function() end)
						end
					end, true)
				questProgressNotificationHolder:addCustomDisplay(false, function()
						set_color(1, 1, 1, 1)
						draw_quad(questProgressNotificationHolder.pos.x, questProgressNotificationHolder.pos.y + questProgressNotificationHolder.size.h - 5, questProgressNotificationHolder.size.w * (os.clock() - clock) / DELAY, 5)
						if (clock + DELAY < os.clock() or buttonClicked) then
							local progress = math.pi / 10
							questProgressNotificationHolder:addCustomDisplay(false, function()
								set_color(1, 1, 1, 1)
								local size = questProgressNotificationHolder.size.w * (os.clock() - clock) / DELAY
								if (size > questProgressNotificationHolder.size.w) then
									size = questProgressNotificationHolder.size.w
								end
								draw_quad(questProgressNotificationHolder.pos.x, questProgressNotificationHolder.pos.y + questProgressNotificationHolder.size.h - 5, size, 5)
									if (questProgressNotificationHolder.pos.x < WIN_W) then
										questProgressNotificationHolder:moveTo(questProgressNotificationHolder.size.w * 0.07 * math.sin(progress), nil, true)
										progress = progress + math.pi / 30
									else
										questProgressNotificationHolder:kill()
										if (popupsData[i + 1]) then
											showPopup(i + 1)
										else
											download_quest(TB_MENU_PLAYER_INFO.username)
											local file = Files:new("../data/quest.txt")
											local questRefresh = UIElement:new({
												globalid = TB_MENU_HUB_GLOBALID,
												pos = { 0, 0 },
												size = { 0, 0 }
											})
											questRefresh:addCustomDisplay(false, function()
													if (not file:isDownloading()) then
														file:close()
														local oldQuests = cloneTable(QUESTS_DATA)
														QUESTS_DATA = Quests:getQuests()
														if (QUEST_POPUP_CLAIM and not TB_MENU_QUESTS_NEW) then
															TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT + 1
															TB_MENU_QUESTS_NEW = true
														end
														questRefresh:kill()
													end
												end)
										end
									end
								end)
						end
					end)
			end
		end)
end

showPopup(1)
