-- modern tc purchase UI

TC_PURCHASE_ISOPEN = TC_PURCHASE_ISOPEN or 0
if (TC_PURCHASE_ISOPEN == 1) then
	remove_hooks("tcPurchaseVisual")
	tcPurchaseViewBG:kill()
	TC_PURCHASE_ISOPEN = 0
	return
end

dofile("system/tc_purchase_manager.lua")
dofile("toriui/uielement.lua")

TCPurchase:create()
tcPriceData = TCPurchase:getData()
TCPurchase:showMain(tcPriceData)

add_hook("mouse_button_down", "uiMouseHandler", function(s, x, y) UIElement:handleMouseDn(s, x, y) end)
add_hook("mouse_button_up", "uiMouseHandler", function(s, x, y) UIElement:handleMouseUp(s, x, y) end)
add_hook("mouse_move", "uiMouseHandler", function(x, y) UIElement:handleMouseHover(x, y) end)
add_hook("draw2d", "tcPurchaseVisual", function() TCPurchase:drawVisuals() end)