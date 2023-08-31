-- daily login manager class

TC = 0
ITEM = 1

if (not Torishop) then
	dofile("system/store_manager.lua")
end

do
	Rewards = {}
	Rewards.__index = Rewards
	local cln = {}
	setmetatable(cln, Rewards)

	RewardData = {}
	
	function Rewards:getRewardData()
		local data_types = { "reward_type", "tc", "item" }
		local file = io.open("system/loginrewards.txt")
		if (file == nil) then
			return false
		end
		
		for ln in file:lines() do
			if string.match(ln, "^REWARD") then
				local segments = 5
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				local days = tonumber(data_stream[2])
				RewardData[days - 1] = {}
				
				for i, v in ipairs(data_types) do
					if (i < 3) then
						RewardData[days - 1][v] = tonumber(data_stream[i + 2])
					else 
						RewardData[days - 1][v] = data_stream[i + 2]
					end
				end
				if (RewardData[days - 1].item ~= '0') then
					RewardData[days - 1].item = Torishop:getItemInfo(tonumber(RewardData[days - 1].item))
				end
			end
		end
		
		file:close()
		return true
	end
	
	function Rewards:quit()
		if (get_option("newmenu") == 0 or TB_MENU_MAIN_ISOPEN == 0) then
			tbMenuMain:kill()
			TB_MENU_SPECIAL_SCREEN_ISOPEN = 4
			remove_hooks("tbMainMenuVisual")
			return
		end
		tbMenuCurrentSection:kill(true) 
		tbMenuNavigationBar:kill(true)
		TB_MENU_SPECIAL_SCREEN_ISOPEN = 4
		TBMenu:showNavigationBar()
		TBMenu:openMenu(TB_LAST_MENU_SCREEN_OPEN)
	end
	
	function Rewards:getNavigationButtons()
		local buttonText = (get_option("newmenu") == 0 or TB_MENU_MAIN_ISOPEN == 0) and TB_MENU_LOCALIZED.NAVBUTTONEXIT or TB_MENU_LOCALIZED.NAVBUTTONTOMAIN
		local buttonsData = {
			{ 
				text = buttonText, 
				action = function() Rewards:quit() end
			}
		}
		return buttonsData
	end
	
	function Rewards:showMain(viewElement, rewardData)
		viewElement:kill(true)
		if (rewardData.days > 6) then
			rewardData.days = rewardData.days % 7
		end
		
		local loginView = UIElement:new({	
			parent = viewElement,
			pos = { 5, 0 },
			size = { viewElement.size.w - 10, viewElement.size.h },
			bgColor = TB_MENU_DEFAULT_BG_COLOR
		})
		local bloodSmudge = TBMenu:addBottomBloodSmudge(loginView, 1)
		local loginViewTitle = UIElement:new({
			parent = loginView,
			pos = { 0, 0 },
			size = { loginView.size.w, loginView.size.h / 8 }
		})
		loginViewTitle:addCustomDisplay(false, function()
			loginViewTitle:uiText(TB_MENU_LOCALIZED.REWARDSDAILYTITLE, nil, nil, FONTS.BIG, CENTERMID, 0.8, nil, nil, nil, nil, 0.5)
		end)
		local dayRewardsView = UIElement:new({
			parent = loginView,
			pos = { 20, loginViewTitle.size.h },
			size = { loginView.size.w - 40, loginView.size.h * 0.62 }
		})
		local dayRewardWidth = dayRewardsView.size.w / 7
		local dayReward = {}
		
		for i = 0, 6 do
			local bgImg = RewardData[i].item ~= '0' and "../textures/store/items/" .. RewardData[i].item.itemid .. "_big.tga" or "../textures/store/toricredit.tga"
			local iconSize = dayRewardWidth - 40 > dayRewardsView.size.h / 2 and dayRewardsView.size.h / 2 - 20 or dayRewardWidth - 60
			
			dayReward[i] = {}
			dayReward[i].main = UIElement:new({
				parent = dayRewardsView,
				pos = { 0 + i * dayRewardWidth, 0 },
				size = { dayRewardWidth - 20, dayRewardsView.size.h },
				bgColor = i == rewardData.days and { 0, 0, 0, 0.5 } or { 0, 0, 0, 0.3 }
			})
			dayReward[i].day = UIElement:new({
				parent = dayReward[i].main,
				pos = { 5, 0 },
				size = { dayReward[i].main.size.w - 10, dayReward[i].main.size.h / 7 }
			})
			dayReward[i].day:addAdaptedText(true, rewardData.days == i and "Today" or TB_MENU_LOCALIZED.REWARDSTIMEDAY .. " " .. i + 1, nil, nil, FONTS.BIG, nil, 0.55, nil, 0.2)
			if (iconSize > 32) then
				iconSize = i == rewardData.days and iconSize + 20 or iconSize
				dayReward[i].icon = UIElement:new({
					parent = dayReward[i].main,
					pos = { (dayReward[i].main.size.w - iconSize) / 2, (dayReward[i].main.size.h - iconSize) / 2 - 10 },
					size = { iconSize, iconSize },
					bgImage = bgImg
				})
			end
			dayReward[i].title = UIElement:new({
				parent = dayReward[i].main,
				pos = { 5, -dayReward[i].main.size.h / 4 },
				size = { dayReward[i].main.size.w - 10, dayReward[i].main.size.h / 5 }
			})
			local rewardStr = RewardData[i].item.itemid ~= 0 and RewardData[i].item.itemname or RewardData[i].tc .. " TC"
			local textScaleModifier = 0
			if (rewardData.days == i) then
				dayReward[i].title:addAdaptedText(true, rewardStr, nil, nil, FONTS.BIG)
			else
				dayReward[i].title:addAdaptedText(true, rewardStr)
			end
		end
		local rewardNextTime = UIElement:new( {
			parent = loginView,
			pos = { 0, -loginView.size.h / 6 - loginView.size.h / 12 },
			size = { loginView.size.w, loginView.size.h / 12 }
		})
		rewardNextTime:addCustomDisplay(false, function()
			rewardNextTime:uiText(Rewards:getTime(rewardData.timeLeft - math.ceil(os.clock()), rewardData.available))
		end)
		local rewardClaim = UIElement:new({
			parent = loginView,
			pos = { loginView.size.w / 6, -loginView.size.h / 6 },
			size = { loginView.size.w / 6 * 4, loginView.size.h / 7 },
			interactive = rewardData.available,
			bgColor = { 0, 0, 0, 0.3 },
			hoverColor = { 0, 0, 0, 0.5 },
			pressedColor = { 1, 0, 0, 0.2 },
			downSound = 31
		})
		local rewardClaimString = TB_MENU_LOCALIZED.REWARDSCLAIM
		local rewardClaimInProgress = false
		local rewardClaimProgressTime = nil
		local textSizeModifier = 0.55
		local tcUpdate = false
		if (rewardData.available) then
			rewardClaim:addCustomDisplay(false, function()
				if (rewardClaimInProgress == true and PlayerInfo:getLoginRewardStatus() == -1 and os.time() - rewardClaimProgressTime > 5) then
					rewardClaimString = TB_MENU_LOCALIZED.REWARDSCLAIMNETWORKERROR
					rewardClaimInProgress = false
					rewardClaim:deactivate()
				elseif (rewardClaimInProgress == true and PlayerInfo:getLoginRewardStatus() == -1) then
					rewardClaimString = TB_MENU_LOCALIZED.REWARDSCLAIMINPROGRESS .. string.rep(".", (os.time() - rewardClaimProgressTime) % 4)
				elseif (rewardClaimInProgress == true) then
					rewardClaim:deactivate()
					if (PlayerInfo:getLoginRewardStatus() == 0) then
						rewardClaimString = TB_MENU_LOCALIZED.REWARDSCLAIMSUCCESS
						update_tc_balance()
						TB_MENU_NOTIFICATIONS_COUNT = TB_MENU_NOTIFICATIONS_COUNT - 1
						TB_MENU_DOWNLOAD_INACTION = true
						tcUpdate = true
					else
						local error = PlayerInfo:getLoginRewardError()
						if (error == 0) then
							rewardClaimString = TB_MENU_LOCALIZED.REWARDSCLAIMNOREWARD
						elseif (error == 1) then
							rewardClaimString = TB_MENU_LOCALIZED.REWARDSCLAIMTIMEOUT
						else
							rewardClaimString = TB_MENU_LOCALIZED.REWARDSCLAIMERROROTHER
						end
					end
					rewardClaimInProgress = false
				end
				if (tcUpdate) then
					local tempData = PlayerInfo:getUserData(TB_MENU_PLAYER_INFO.username)
					if (TB_MENU_PLAYER_INFO.data.tc ~= tempData.tc or TB_MENU_PLAYER_INFO.data.st ~= tempData.st) then
						TB_MENU_PLAYER_INFO.data = PlayerInfo:getUserData(TB_MENU_PLAYER_INFO.username)
						tcUpdate = false
					end
				end
				while (not rewardClaim:uiText(rewardClaimString, nil, nil, FONTS.BIG, LEFT, textSizeModifier, nil, nil, nil, nil, nil, true)) do
					textSizeModifier = textSizeModifier - 0.05
				end
				rewardClaim:uiText(rewardClaimString, nil, nil, FONTS.BIG, nil, textSizeModifier)
			end)
			rewardClaim:addMouseHandlers(function() end, function()
					claim_reward()
					rewardClaimProgressTime = os.time()
					rewardClaimInProgress = true
				end, function() end)
		else
			rewardClaim:addAdaptedText(false, TB_MENU_LOCALIZED.REWARDSNOAVAILABLE, nil, nil, FONTS.BIG, nil, 0.6, nil, 0.6)
		end
	end
	
	function Rewards:getTime(timetonext, isClaimed)
		if (timetonext <= 0 and not isClaimed) then
			return TB_MENU_LOCALIZED.REWARDSAVAILABLERESTART
		elseif (timetonext <= 0 and isClaimed) then
			return TB_MENU_LOCALIZED.REWARDSEXPIRED
		end
		
		local returnval = TBMenu:getTime(timetonext)
		
		if (not isClaimed) then
			return TB_MENU_LOCALIZED.REWARDSNEXTREWARD .. " " .. returnval
		end
		return returnval .. " " .. TB_MENU_LOCALIZED.REWARDSTIMELEFT
	end
end
