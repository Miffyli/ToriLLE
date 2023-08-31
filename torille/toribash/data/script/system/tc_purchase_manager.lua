-- tc purchase manager class

do
	TCPurchase = {}
    TCPurchase.__index = TCPurchase
    
    function TCPurchase:create()
		TC_PURCHASE_ISOPEN = 1
		local cln = {}
		setmetatable(cln, TCPurchase)
    end
	
	function TCPurchase:getData()
        local TCPurchaseData = {}
		
		local file = io.open("torishop/torishop.txt")
		if (file == nil) then
			return
		end
		
		for ln in file:lines() do
			if string.match(ln, "^PRODUCT") then
				local segments = 19
				local data_stream = { ln:match(("([^\t]*)\t"):rep(segments)) }
				if (data_stream[2] == '45' and data_stream[18] == '0' and data_stream[19] == '0') then
					table.insert(TCPurchaseData, { itemid = data_stream[4], name = data_stream[5], price = data_stream[8] })
				end
			end
		end
		file:close()
		
		-- rearrange entries
		for i, v in pairs(TCPurchaseData) do
			for k, x in pairs(TCPurchaseData) do
				if (k > i) then
					n1 = v.name:gsub("%s%a*", "")
					n2 = x.name:gsub("%s%a*", "")
					if (tonumber(n1) > tonumber(n2)) then
						local r1, r2, r3 = v.itemid, v.name, v.price
						TCPurchaseData[i].itemid, TCPurchaseData[i].name, TCPurchaseData[i].price = x.itemid, x.name, x.price
						TCPurchaseData[k].itemid, TCPurchaseData[k].name, TCPurchaseData[k].price = r1, r2, r3
					end
				end
			end
		end
		return TCPurchaseData
	end
	
    function TCPurchase:showMain(tcPriceData)
        tcPurchaseViewBG = UIElement:new( {	pos = { 20, 20 },
        									size = {500, 500},
        									shapeType = ROUNDED,
        									rounded = 20,
        									bgColor = {0,0,0,0.95} } )
        local tcPurchaseView = UIElement:new( {	parent = tcPurchaseViewBG,
												pos = { 2, 2 },
												size = { tcPurchaseViewBG.size.w - 4, tcPurchaseViewBG.size.h - 4 },
												shapeType = tcPurchaseViewBG.shapeType,
												rounded = tcPurchaseViewBG.rounded - 2.5,
												bgColor = {0.6,0,0,1},
												innerShadow = {0, 15},
												shadowColor = { {0,0,0,0}, {0.5,0,0,1} } } )
		local tcPurchaseTitle = UIElement:new( {	parent = tcPurchaseView,
													pos = { 0, 0 },
													size = { tcPurchaseView.size.w, 50 } } )
		tcPurchaseTitle:addCustomDisplay(false, function()
				tcPurchaseTitle:uiText("Purchase Toricredits", 20, tcPurchaseTitle.pos.y +0, FONTS.BIG, LEFT, 0.75, nil, 2) 
			end)
		local quitButton = UIElement:new( {	parent = tcPurchaseTitle,
											pos = { -50, 5 },
											size = { 40, 40 },
											bgColor = { 0,0,0,0.7 },
											shapeType = ROUNDED,
											rounded = 17,
											interactive = true,
											hoverColor = { 0.2,0,0,0.7},
											pressedColor = { 1,0,0,0.5} } )
		quitButton:addCustomDisplay(false, function()
				local indent = 12
				local weight = 5
				set_color(1,1,1,1)
				draw_line(quitButton.pos.x + indent, quitButton.pos.y + indent, quitButton.pos.x + quitButton.size.w - indent, quitButton.pos.y + quitButton.size.h - indent, weight)
				draw_line(quitButton.pos.x + quitButton.size.w - indent, quitButton.pos.y + indent, quitButton.pos.x + indent, quitButton.pos.y + quitButton.size.h - indent, weight)
			end)
		quitButton:addMouseHandlers(function() end, function()
				remove_hooks("tcPurchaseVisual")
				tcPurchaseViewBG:kill()
				TC_PURCHASE_ISOPEN = 0
			end, function() end)
		local tcEntry = {}
		local tcIcon = load_texture("../textures/store/toricredit.tga")
		for i, v in pairs(tcPriceData) do
			tcEntry[i] = UIElement:new( {	parent = tcPurchaseView,
											pos = { 20, i * 70 },
											size = { 456, 64 },
											bgColor = {0.5, 0, 0, 1},
										 	interactive = true,
											shapeType = ROUNDED,
											rounded = 50,
											hoverColor = {0.65, 0, 0, 1},
											pressedColor = {0.4, 0, 0, 1} } )
			tcEntry[i]:addCustomDisplay(false, function()
					draw_quad(tcEntry[i].pos.x, tcEntry[i].pos.y, 64, 64, tcIcon)
					tcEntry[i]:uiText(v.name, 100, 2, nil, LEFT, nil, nil, 1)
					tcEntry[i]:uiText(v.price .. " USD", 100, 24, FONTS.BIG, LEFT, 0.6, nil, 1.5)
					local priceCents = v.price:gsub("%.", "")
					local noDiscountVal = tonumber(priceCents) / 100 * 1000
					local discountVal = v.name:gsub("%s%a*", "")
					discountVal = tonumber(discountVal)
					local percentFree = math.floor((1 - (noDiscountVal/discountVal)) * 100)
					if (percentFree > 0) then
						tcEntry[i]:uiText(percentFree .. "% cheaper", -20, 45, nil, RIGHT, 0.8, -22, 0.5, {1, 0.8, 0, 1})
					end
				end)
			tcEntry[i]:addMouseHandlers(function() end, function()
					UIElement:runCmd("steam purchase " .. v.itemid, true)
				end, function() end)
		end
		
		local torishopButtonBG = UIElement:new( {	parent = tcPurchaseView,
													pos = { 75, -75 },
													size = { 346, 54 },
												 	bgColor = {0, 0, 0, 0.95},
												 	shapeType = ROUNDED,
													rounded = 10 } )
		local torishopButton = UIElement:new( {	parent = torishopButtonBG,
												pos = { 2, 2 },
												size = { 342, 50 },
												bgColor = {0.5, 0, 0, 1},
												shapeType = ROUNDED,
												rounded = 8,
												interactive = true,
												hoverColor = {0.7, 0, 0, 1},
												pressedColor = {0.4, 0, 0, 1} } )
		torishopButton:addCustomDisplay(false, function()
				torishopButton:uiText("Go to Torishop", nil, nil, FONTS.BIG, nil, 0.63, nil, 1.5)
			end)
		torishopButton:addMouseHandlers(function() end, function()
				remove_hooks("tcPurchaseVisual")	
				tcPurchaseViewBG:kill()
				TC_PURCHASE_ISOPEN = 0			
				open_menu(12)
			end, function() end)
    end
	
	function TCPurchase:drawVisuals()
		for i, v in pairs(UIElementManager) do
			v:updatePos()
		end
		for i, v in pairs(UIVisualManager) do
			v:display()
		end
	end
	
end
