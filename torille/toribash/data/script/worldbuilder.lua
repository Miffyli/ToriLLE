shapelist = {}
buttlist = { }
mouse = {x = 0, y = 0, down = 0, changex = 0, changey = 0, storex = 0, storey = 0, sens = 8}
currentshape = 1
change = { mode = "move", x = 0, y = 0, z = 0}
step = .25
timer = 0
finetune = 0
screen = { color = false, mass = false, flags = false, info = true, help = false }
adjust = { r = 0, g = 0, b = 0, a = 0, m = 0, f = 0 }
flag = { ig = 0, ng = 0, static = 0 }
shiftstate = 0
calledfunc = nil

okinput =    "abcdefghijklmnopqrstuvwxyz1234567890`-=[]\;,./"
shiftinput = "ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()~_+{}|:<>?"
input = ""
textbuffer = {  }
poop = io.open("help.wbt", "r")
line = poop:read("*l")
ln = 0
while line ~= nil do
	ln = ln + 1
	textbuffer[ln] = line
	line = poop:read("*l")
end	
poop:close()
filepos = 1

button = {
	xpos = 0,
	ypos = 0,
	width = 0,
	height = 0,
	color_r= 0,
	color_g= 0,
	color_b= 0,
	over_r = 0,
	over_g = 0,
	over_b = 0,
	over_a = .2,
	text_r = 0,
	text_g = 0,
	text_b = 0,
	text = "Button",
	status = 0,
	use3d = 1,
	func = nil
}

shape = {
	posx = 0, 
	posy = 0, 
	posz = 0,
	sizex = 1,
	sizey = 1,
	sizez = 1,
	colorr = 0,
	colorg = 0,
	colorb = 1,
	colora = 1,
	rotx = 0,
	roty = 0,
	rotz = 0,
	selected = 1,
	mass = .1,
	material = "steel",
	style = "box", --box, sphere, cylinder
	flags = 0
}

keylayout = { }
keylayout['primary'] = {
    index = 0,
	lessy = 264,
    morey = 258,
    lessx = 260,
    morex = 262,
    lessz = 263,
    morez = 257,
    group = 270,
  ungroup = 269,
   resize = 256,
   rotate = 266,
   delete = 127,
     dupe = 112,
     fine = 301,
    color =  99,
     mass = 109,
    flags = 102,
  keyswap = 107,
     info = 105,
    shape = 261,
      new = 268,
    cycle = 271,
     dump =  13,
	 load = 108,
	 help = 104
}
keylayout['alt'] = {
	index = 1,
    lessy = 119,
    morey = 120,
    lessx = 97,
    morex = 100,
    lessz = 113,
    morez = 122,
    group = 51,
  ungroup = 49,
   resize = 101,
   rotate = 114,
   delete = 127,
     dupe = 112,
     fine = 301,
    color =  99,
     mass = 109,
    flags = 102,
  keyswap = 107,
     info = 105,
    shape = 115,
      new = 96,
    cycle = 50,
     dump =  13,
	 load = 108,
	 help = 104
}
keyset = { }
keyset = keylayout.primary
movecmd = { x = 0, y = 0, z = 0 }

--################  BUTTON FUNCS  ########################
function button:draw()
	set_color(0,0,0,1)
	draw_quad(self.xpos, self.ypos, self.width, self.height)
	set_color(self.color_r, self.color_g, self.color_b, 1)
	draw_quad(self.xpos + 2, self.ypos + 2, self.width - 4, self.height - 4)
	if self.use3d == 1 and self.status ~= 2 then
		set_color(1,1,1,.5)
		draw_quad(self.xpos + 2, self.ypos + 2, self.width - 6, self.height - 6)
		set_color(0,0,0,.5)
		draw_quad(self.xpos + 4, self.ypos + 4, self.width - 6, self.height - 6)
	set_color(self.color_r, self.color_g, self.color_b, 1)
	draw_quad(self.xpos + 4, self.ypos + 4, self.width - 8, self.height - 8)
	end
	local texty = ((self.height/2) - 10 + self.ypos)
	local textx = (string.len(self.text) * 8)
	textx =  (self.width/2) - (textx / 2) + self.xpos 
	set_color(self.text_r, self.text_g, self.text_b, 1)
	draw_text(self.text,textx,texty,1)
end
function button:on_over(x, y)
	if inbetween(self.xpos , self.ypos, self.xpos + self.width, self.ypos + self.height, x, y) then
		if self.status == 0 then self.status = 1 end
		set_color(self.over_r,self.over_g,self.over_b,self.over_a)
		draw_quad(self.xpos, self.ypos, self.width, self.height)
	else
		self.status = 0
	end
	
end
function button:click()
	self.status = 2
	self.func()
end
function button:new(o)
  local obj = o or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function inbetween(lx, ly, rx, ry, px, py)
	local to_ret
	if px > lx and px < rx and py > ly and py < ry then to_ret = true else to_ret = false end
	return to_ret
end
function mousemove(x,y)
	mouse.changex = x - mouse.x
	mouse.changey = y - mouse.y
	mouse.x = x
	mouse.y = y
	if mouse.down == 1 then
		mouse.storex = mouse.changex + mouse.storex
		mouse.storey = mouse.changey + mouse.storey
	end
	
end
function mousedown(button,x,y)
	mouse.down = button
	
	for x = 1,#buttlist do 
		if buttlist[x].data.status == 1 then buttlist[x].data:click(); return 1 end
	end
	mouse.storex = 0
	mouse.storey = 0
	
	
end
function mouseup(button,x,y)
	mouse.down = 0

	for x = 1,#buttlist do buttlist[x].data.status = 0 end
	
	
end
function new_button( called, passfunc, args )
	number = #buttlist + 1
	buttlist[number] = { name = called, data = { } }
	buttlist[number].data = button:new(args)
	buttlist[number].data.func = passfunc
end
function removebuttonset(name)

	for x = #buttlist,1,-1 do
		if buttlist[x].name == name then table.remove(buttlist, x) end
	end

end
--################  BUTTON FUNCS  ########################

function shape:new(o)
  local obj = o or {}
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function shape:draw()

	if self.selected == 1 then alpha = self.colora else alpha = .5 end
	set_color(self.colorr, self.colorg, self.colorb, alpha)
	if self.style == "box" then
		draw_box(self.posx, self.posy, self.posz, self.sizex, self.sizey, self.sizez, self.rotx, self.roty, self.rotz)
		 
	end
	if self.style == "sphere" then
		draw_sphere(self.posx, self.posy, self.posz, self.sizex)
	end
	if self.style == "cylinder" then
		draw_capsule(self.posx, self.posy, self.posz, self.sizey, self.sizex, self.rotx, self.roty, self.rotz)
	end

end

function shape:translate()

	if self.selected == 1 then
		if change.mode == "move" then
			self.posx = self.posx + change.x
			self.posy = self.posy + change.y
			self.posz = self.posz + change.z
		end
		if change.mode == "size" then
			self.sizex = self.sizex + change.x
			self.sizey = self.sizey + change.y
			self.sizez = self.sizez + change.z
		end
		if change.mode == "rotate" then
			self.rotx = self.rotx + change.x
			self.roty = self.roty + change.y
			self.rotz = self.rotz + change.z
			if self.rotx >= 360 then self.rotx = self.rotx - 360 end
			if self.rotx <= -360 then self.rotx = self.rotx + 360 end
			if self.roty >= 360 then self.roty = self.roty - 360 end
			if self.roty <= -360 then self.roty = self.roty + 360 end
			if self.rotz >= 360 then self.rotz = self.rotz - 360 end
			if self.rotz <= -360 then self.rotz = self.rotz + 360 end
			
		end
	end
	
end

function highlight()

	px = shapelist[currentshape].data.posx
	py = shapelist[currentshape].data.posy
	pz = shapelist[currentshape].data.posz
	sx = shapelist[currentshape].data.sizex
	sy = shapelist[currentshape].data.sizey
	sz = shapelist[currentshape].data.sizez
	rx = shapelist[currentshape].data.rotx
	ry = shapelist[currentshape].data.roty
	rz = shapelist[currentshape].data.rotz
	set_color(1,1,1,timer / 10)
	if shapelist[currentshape].data.style == "box" then draw_box(px,py,pz,sx+.05,sy+.05,sz+.05,rx,ry,rz) end
	if shapelist[currentshape].data.style == "sphere" then draw_sphere(px,py,pz,sx+.05) end
	if shapelist[currentshape].data.style == "cylinder" then draw_capsule(px,py,pz,sy+.05,sx+.05,rx,ry,rz) end

end

function new_shape(args)

	numb = #shapelist + 1
	shapelist[numb] = { data = { } }
	shapelist[numb].data = shape:new(args)
	return numb
	
end

function remove_shape(arg)	table.remove(shapelist,arg) end

function copy_shape(tocopy)
	copyshape = { }
	for k,v in pairs(tocopy) do copyshape[k] = v end
	shapelist[currentshape].data.selected = 0
	currentshape = new_shape(copyshape)
	shapelist[currentshape].data.selected = 1
	
end

function input_to_real()

	local adjustby = step
	if change.mode == "rotate" then adjustby = 4 end
	if finetune == 1 then adjustby = adjustby / 4 end
	
	cam = get_camera_info()
	camangle = math.deg(math.atan2(cam.pos.y-cam.lookat.y,cam.pos.x-cam.lookat.x))

	if shiftstate == 0 then
		if mouse.storex > mouse.sens then movecmd.x = 1 end
		if mouse.storex < -mouse.sens then movecmd.x = -1 end
		if mouse.storey > mouse.sens then movecmd.y = 1 end
		if mouse.storey < -mouse.sens then movecmd.y = -1 end
	else
		if mouse.storey > mouse.sens then movecmd.z = 1 end
		if mouse.storey < -mouse.sens then movecmd.z = -1 end
	end
	
	if camangle >= -45 and camangle < 45 then 
		if movecmd.x == 1 then change.y = adjustby; mouse.storex = 0 end
		if movecmd.x == -1 then change.y = -adjustby; mouse.storex = 0 end
		if movecmd.y == 1 then change.x = adjustby; mouse.storey = 0 end
		if movecmd.y == -1 then change.x = -adjustby; mouse.storey = 0 end
	else
	if camangle >= 45 and camangle < 135 then 
		if movecmd.x == 1 then change.x = -adjustby; mouse.storex = 0 end
		if movecmd.x == -1 then change.x = adjustby; mouse.storex = 0 end
		if movecmd.y == 1 then change.y = adjustby; mouse.storey = 0 end
		if movecmd.y == -1 then change.y = -adjustby; mouse.storey = 0 end
	else
	if camangle >= -135 and camangle < -45 then 
		if movecmd.x == 1 then change.x = adjustby; mouse.storex = 0 end
		if movecmd.x == -1 then change.x = -adjustby; mouse.storex = 0 end
		if movecmd.y == 1 then change.y = -adjustby; mouse.storey = 0 end
		if movecmd.y == -1 then change.y = adjustby; mouse.storey = 0 end
	else
		if movecmd.x == 1 then change.y = -adjustby; mouse.storex = 0 end
		if movecmd.x == -1 then change.y = adjustby; mouse.storex = 0 end
		if movecmd.y == 1 then change.x = -adjustby; mouse.storey = 0 end
		if movecmd.y == -1 then change.x = adjustby; mouse.storey = 0 end
	end end end

		mouse.storex = 0
		if movecmd.z == 1 then change.z = -adjustby; mouse.storey = 0 end
		if movecmd.z == -1 then change.z = adjustby; mouse.storey = 0 end

end

function on3d()
	timer = timer + .25
	if timer == 6 then timer = 0 end
	
	input_to_real()
	for foo = 1,#shapelist do shapelist[foo].data:translate() end

	change.x, change.y, change.z, movecmd.x, movecmd.y, movecmd.z = 0,0,0,0,0,0

	for foo = 1,#shapelist do shapelist[foo].data:draw() end

	if #shapelist > 0 then 
		highlight(currentshape) 
		set_camera_lookat (shapelist[currentshape].data.posx,shapelist[currentshape].data.posy,shapelist[currentshape].data.posz)
	else
		set_camera_lookat(1,0,1)
	end

	set_color(1,1,1,.5)
	draw_box(0,0,0,1000,1000,.01,0,0,0)

end	

function on2d()
	if #shapelist > 0 and screen.info then
		local w, h  = get_window_size()
		
		set_color(1,1,1,.5)
		draw_quad(w-180,90,180,300)
		set_color(0,0,0,1)
		draw_right_text("OBJECT " .. currentshape ,10,100,1)
		draw_right_text("==================",10,120,1)
		draw_right_text("Object Shape: " .. shapelist[currentshape].data.style,10,140,1)
		draw_right_text("Position X: " .. shapelist[currentshape].data.posx,10,160,1)
		draw_right_text("Position Y: " .. shapelist[currentshape].data.posy,10,180,1)
		draw_right_text("Position Z: " .. shapelist[currentshape].data.posz,10,200,1)
		draw_right_text("Size X: " .. shapelist[currentshape].data.sizex,10,220,1)
		draw_right_text("Size Y: " .. shapelist[currentshape].data.sizey,10,240,1)
		draw_right_text("Size Z: " .. shapelist[currentshape].data.sizez,10,260,1)
		draw_right_text("Rotation X: " .. shapelist[currentshape].data.rotx,10,280,1)
		draw_right_text("Rotation Y: " .. shapelist[currentshape].data.roty,10,300,1)
		draw_right_text("Rotation Z: " .. shapelist[currentshape].data.rotz,10,320,1)
		draw_right_text("Mass: " .. shapelist[currentshape].data.mass,10,340,1)
		draw_right_text("Flags: " .. shapelist[currentshape].data.flags,10,360,1)
	end
	
	if screen.color then
		set_color(1,1,1,.5)
		draw_quad(20,90,105,100)
		set_color(adjust.r, adjust.g, adjust.b,adjust.a)
		draw_quad(95,100,20,80)
		for foo = 1,#shapelist do 
			if shapelist[foo].data.selected == 1 then
				shapelist[foo].data.colorr = adjust.r
				shapelist[foo].data.colorg = adjust.g
				shapelist[foo].data.colorb = adjust.b
				shapelist[foo].data.colora = adjust.a
			end
		end
	end

	if screen.mass then
		set_color(1,1,1,.5)
		draw_quad(20,200,105,100)
		set_color(0,0,0,1)
		draw_text("Mass:",52,205,1)
		draw_text(adjust.m,62,225,1)
		for foo = 1, #shapelist do 
			if shapelist[foo].data.selected == 1 then shapelist[foo].data.mass = adjust.m end 
		end
	end
	
	if screen.flags then
		set_color(1,1,1,.5)
		draw_quad(20,310,105,100)
		set_color(0,0,0,1)
		draw_text("Flags",50,310,1)
		draw_quad(25,335,95,1)
		draw_text("Static",46,340,1)
		draw_text("Instagib",32,360,1)
		draw_text("No Grab",30,380,1)
		for x = 1,#buttlist do 
			if buttlist[x].name == "flaga" then
				if flag.static ~= 0 then 
					buttlist[x].data.color_g = 1
					buttlist[x].data.color_r = 0
				else
					buttlist[x].data.color_g = 0
					buttlist[x].data.color_r = 1
				end
			end
			if buttlist[x].name == "flagb" then
				if flag.ig ~= 0 then 
					buttlist[x].data.color_g = 1
					buttlist[x].data.color_r = 0
				else
					buttlist[x].data.color_g = 0
					buttlist[x].data.color_r = 1
				end
			end
			if buttlist[x].name == "flagc" then
				if flag.ng ~= 0 then 
					buttlist[x].data.color_g = 1
					buttlist[x].data.color_r = 0
				else
					buttlist[x].data.color_g = 0
					buttlist[x].data.color_r = 1
				end
			end
		end
		
		adjust.f = flag.static + flag.ng + flag.ig
		for foo = 1, #shapelist do 
			if shapelist[foo].data.selected == 1 then shapelist[foo].data.flags = adjust.f end 
		end
		
	end
	
	for x = 1,#buttlist do buttlist[x].data:draw() end
	for x = 1,#buttlist do buttlist[x].data:on_over(mouse.x, mouse.y) end
	

	
end	

function screenprep(name)
	
	if name == "color" then
		screen.color = true
		if #shapelist > 0 then
			adjust.r = shapelist[currentshape].data.colorr
			adjust.g = shapelist[currentshape].data.colorg
			adjust.b = shapelist[currentshape].data.colorb
			adjust.a = shapelist[currentshape].data.colorb
			
		end
		new_button("color", function() if adjust.r > 0 then adjust.r = adjust.r - .1 end end, 
				  {xpos = 30, ypos = 100, width = 30, height = 20, color_r = 1,text = "-"} )
		new_button("color", function() if adjust.r < 1 then adjust.r = adjust.r + .1 end end, 
				  {xpos = 60, ypos = 100, width = 30, height = 20, color_r = 1,text = "+"} )
		new_button("color", function() if adjust.g > 0 then adjust.g = adjust.g - .1 end end, 
				  {xpos = 30, ypos = 120, width = 30, height = 20, color_g = 1,text = "-"} )
		new_button("color", function() if adjust.g < 1 then adjust.g = adjust.g + .1 end end, 
				  {xpos = 60, ypos = 120, width = 30, height = 20, color_g = 1,text = "+"} )
		new_button("color", function() if adjust.b > 0 then adjust.b = adjust.b - .1 end end, 
				  {xpos = 30, ypos = 140, width = 30, height = 20, color_b = 1,text = "-"} )
		new_button("color", function() if adjust.b < 1 then adjust.b = adjust.b + .1 end end, 
				  {xpos = 60, ypos = 140, width = 30, height = 20, color_b = 1,text = "+"} )
		new_button("color", function() if adjust.a > 0 then adjust.a = adjust.a - .1 end end, 
				  {xpos = 30, ypos = 160, width = 30, height = 20, color_r = 1, color_g = 1, color_b = 1,text = "-"} )
		new_button("color", function() if adjust.a < 1 then adjust.a = adjust.a + .1 end end, 
				  {xpos = 60, ypos = 160, width = 30, height = 20, color_r = 1, color_g = 1, color_b = 1,text = "+"} )
	end
	if  name == "mass" then
		screen.mass = true
		if #shapelist > 0 then adjust.m = shapelist[currentshape].data.mass else adjust.m = .1 end
		new_button("mass", function() if adjust.m > 0 then adjust.m = adjust.m - .1 end end, 
				  {xpos = 35, ypos = 250, width = 30, height = 20, color_r = .7, color_g = .7, color_b = .7,text = "-"} )
		new_button("mass", function() if adjust.m < 20 then adjust.m = adjust.m + .1 end end, 
				  {xpos = 80, ypos = 250, width = 30, height = 20, color_r = .7, color_g = .7, color_b = .7,text = "+"} )
		new_button("mass", function() removebuttonset("mass"); screen.mass = false end, 
				  {xpos = 35, ypos = 270, width = 75, height = 20, color_r = .7, color_g = .7, color_b = .7,text = "OK"} )
	end
	if name == "flags" then
		screen.flags = true
		if #shapelist > 0 then adjust.f = shapelist[currentshape].data.flags else adjust.f = 0 end
		
		if adjust.f >= 16 then adjust.f = adjust.f - 16; flag.ng = 16 else flag.ng = 0 end
		if adjust.f >= 8 then adjust.f = adjust.f - 8; flag.static = 8 else flag.static = 0 end
		if adjust.f >= 6 then adjust.f = adjust.f - 6; flag.ig = 6 else flag.ig = 0 end
		adjust.f = flag.static + flag.ig + flag.ng
		
		new_button("flaga", function() if flag.static == 0 then flag.static = 8 else flag.static = 0 end end, 
				  {xpos = 100, ypos = 342, width = 16, height = 16, use3d = 0, text = ""} )
		new_button("flagb", function() if flag.ig == 0 then flag.ig = 6 else flag.ig = 0 end end, 
				  {xpos = 100, ypos = 362, width = 16, height = 16, use3d = 0, text = ""} )
		new_button("flagc", function() if flag.ng == 0 then flag.ng = 16 else flag.ng = 0 end end, 
				  {xpos = 100, ypos = 382, width = 16, height = 16, use3d = 0, text = ""} )

	end

	if name == "help" then
	screen.help = true
		new_button("help", function() if filepos > 1 then filepos = filepos - 1 end end, 
				  {xpos = 750, ypos = 30, width = 20, height = 20, color_r = .7, color_g = .7, color_b = .7, use3d = 1, text = "-"} )
		new_button("help", function() if filepos < #textbuffer then filepos = filepos + 1 end end, 
				  {xpos = 750, ypos = 550, width = 20, height = 20, color_r = .7, color_g = .7, color_b = .7, use3d = 1, text = "+"} )
		
	end
	
end

function keydown(key)
	--echo("key>" .. key)
	for x = 1,6 do echo("  ") end
	local adjustby = step
	if finetune == 1 then adjustby = adjustby / 4 end
	if key == keyset.lessy then movecmd.y = -1 end
	if key == keyset.morey then movecmd.y = 1	end
	if key == keyset.morex then movecmd.x = 1 end
	if key == keyset.lessx then movecmd.x = -1 end
	if key == keyset.morez then movecmd.z = 1 end
	if key == keyset.lessz then movecmd.z = -1 end
	if key == keyset.group then shapelist[currentshape].data.selected = 1 end
	if key == keyset.ungroup then shapelist[currentshape].data.selected = 0 end
	if key == keyset.resize then change.mode = "size" end
	if key == keyset.rotate then change.mode = "rotate" end
	if key == keyset.fine then finetune = 1 end
	if key == keyset.mass then screenprep("mass") end
	
	if key == keyset.help then 
		if screen.help then 
			screen.help = false
			remove_hooks("help")
			removebuttonset("help")
		else
			loadhelp() 
		end
		
	end
	
	if key == keyset.keyswap then
		if keyset.index == 1 then keyset = keylayout.primary else keyset = keylayout.alt end 
	end
	if key == keyset.delete then
		remove_shape(currentshape)
--		echo(currentshape .. " " .. #shapelist)
		if currentshape > #shapelist then currentshape = #shapelist end
		if #shapelist < 1 then currentshape = 0 end
	end

	if key == keyset.color then 
		if screen.color then
			removebuttonset("color")
			screen.color = false
		else
			screenprep("color") 
		end
	end

	if key == keyset.flags then 
		if screen.flags then 
			removebuttonset("flaga")
			removebuttonset("flagb")
			removebuttonset("flagc")
			screen.flags = false
		else
			screenprep("flags") 
		end
	end
	
	if key == 303 or key == 304 then shiftstate = 1; return 1 end
	if key == keyset.info then if screen.info then screen.info = false else screen.info = true end end
	if key == keyset.shape then 

		if shapelist[currentshape].data.style == "box" then shapelist[currentshape].data.style = "sphere" else
		if shapelist[currentshape].data.style == "sphere" then shapelist[currentshape].data.style = "cylinder" else
		shapelist[currentshape].data.style = "box" end end
	
	end
	
	if key == keyset.new then 
		if #shapelist < 12 then currentshape = new_shape() end
	end

	if key == keyset.dupe then 
		if #shapelist < 12 then copy_shape(shapelist[currentshape].data) end
	end
		
	if key == keyset.cycle then
		currentshape = currentshape + 1
		if currentshape > #shapelist then currentshape = 1 end
--		echo(currentshape)
	end
	
	if key == keyset.dump then doinput("Filename to save: ", dumpmod) end
	if key == keyset.load then doinput("Filename to load: ", readmod) end

	for k,v in pairs(keyset) do if key == v then return 1 end end
end

function keyup(key)
--	echo("Keyup> " .. key)
	if key == keyset.fine then finetune = 0 end
	if key == 303 or key == 304 then shiftstate = 0; return 1 end
	if key == keyset.resize then change.mode = "move" end
	if key == keyset.rotate then change.mode = "move" end
	
	for k,v in pairs(keyset) do if key == v then return 1 end end
end

function dumpmod(input)

	modout = io.open(input,"w")
	modout:write("# Environment exported by WorldBuilder\n######################################" .. "\n\n")

	for x=1,#shapelist do
		modout:write("env_obj " .. x .. "\n")
		modout:write("    shape " .. shapelist[x].data.style .. "\n")
		modout:write("    pos " .. shapelist[x].data.posx .. " " .. shapelist[x].data.posy .. " " .. shapelist[x].data.posz .. "\n")
		modout:write("    color " .. shapelist[x].data.colorr .. " " .. shapelist[x].data.colorg .. " " .. shapelist[x].data.colorb .. " " .. shapelist[x].data.colora .. "\n")
		modout:write("    rot " .. shapelist[x].data.rotx .. " " .. shapelist[x].data.roty .. " " .. shapelist[x].data.rotz .. "\n")
		modout:write("    sides " .. shapelist[x].data.sizex .. " " .. shapelist[x].data.sizey .. " " .. shapelist[x].data.sizez .. "\n")
		modout:write("    material " .. shapelist[x].data.material .. "\n")
		modout:write("    mass " .. shapelist[x].data.mass .. "\n")
		modout:write("    flag " .. shapelist[x].data.flags .. "\n")
		modout:write("#END " .. x .. "\n\n")
	end
	
	modout:close()
	echo(input .. " written. " .. #shapelist .. " objects.")
end

function readmod(input)
	filename = input
	shapelist = {}
	stringlist = {}
	modin = io.open(filename, "r")
	line = modin:read("*l")
	while line ~= nil do
	
		result = string.find(line,"env_obj",1,true)
		if result ~= nil then
			stringlist[1] = line
			for x = 2,9 do
				line = modin:read("*l")
				stringlist[x] = line
			end
			--LOL OH GOD ITS A MESS
			number = new_shape()
			shapelist[number].data.style = string.sub(stringlist[2],11,#stringlist[2])
			result = string.find(stringlist[3]," ",9,true)
			result2 = string.find(stringlist[3]," ",result+1,true)
			shapelist[number].data.posx = tonumber(string.sub(stringlist[3],9,result))
			shapelist[number].data.posy = tonumber(string.sub(stringlist[3],result + 1,result2))
			shapelist[number].data.posz = tonumber(string.sub(stringlist[3],result2 + 1,#stringlist[3]))
			result = string.find(stringlist[4]," ",11,true)
			result2 = string.find(stringlist[4]," ",result+1,true)
			result3 = string.find(stringlist[4]," ",result2+1,true)
			shapelist[number].data.colorr = tonumber(string.sub(stringlist[4],11,result))
			shapelist[number].data.colorg = tonumber(string.sub(stringlist[4],result + 1,result2))
			shapelist[number].data.colorb = tonumber(string.sub(stringlist[4],result2 + 1,result3))
			shapelist[number].data.colora = tonumber(string.sub(stringlist[4],result3 + 1,#stringlist[4]))
			result = string.find(stringlist[5]," ",9,true)
			result2 = string.find(stringlist[5]," ",result+1,true)
			shapelist[number].data.rotx = tonumber(string.sub(stringlist[5],9,result))
			shapelist[number].data.roty = tonumber(string.sub(stringlist[5],result + 1,result2))
			shapelist[number].data.rotz = tonumber(string.sub(stringlist[5],result2 + 1,#stringlist[5]))
			result = string.find(stringlist[6]," ",11,true)
			result2 = string.find(stringlist[6]," ",result+1,true)
			shapelist[number].data.sizex = tonumber(string.sub(stringlist[6],11,result))
			shapelist[number].data.sizey = tonumber(string.sub(stringlist[6],result + 1,result2))
			shapelist[number].data.sizez = tonumber(string.sub(stringlist[6],result2 + 1,#stringlist[6]))
			shapelist[number].data.material = string.sub(stringlist[7],14,#stringlist[7])
			shapelist[number].data.mass = tonumber(string.sub(stringlist[8],10,#stringlist[8]))
			shapelist[number].data.flags = tonumber(string.sub(stringlist[9],10,#stringlist[9]))
		end

		line = modin:read("*l")
	end
	modin:close()
	echo("File loaded. " .. number .. " shapes read.")
	currentshape = number
end

function loadhelp()

	screenprep("help")
	add_hook("draw2d", "help", helpscreen)
--	add_hook("key_down", "help", helpkey)
end

function helpkey(key)
	--if key == 
	

end

function helpscreen()
		--Format for text formatting in read file is !<jrrggbbfs>
		--j = justification  l = left, c = centered, r = right
		--rrggbb = RGB hex value
		--f = font type (0, 1, or 2)
		--s = shadows (0 or 1)
	linecolor = "000000"
	set_color(1,1,1,.8)
	draw_quad(20,20,760,560)
	set_color(0,0,0,1)
	texttype = 1
	justification = "l"
	shadow = 0
	drawpos = 30
	rr, rg, rb = 0,0,0
	endln = filepos + 26
	if endln > #textbuffer then endln = #textbuffer end
	for x = filepos, endln do
				
		if string.sub(textbuffer[x],1,2) == "!<" then
			justification = string.sub(textbuffer[x],3,3)
			texttype = tonumber(string.sub(textbuffer[x],10,10))
			shadow = tonumber(string.sub(textbuffer[x],11,11))
			rr = hextodec(string.sub(textbuffer[x],4,5)) / 255
			rg = hextodec(string.sub(textbuffer[x],6,7)) / 255
			rb = hextodec(string.sub(textbuffer[x],8,9)) / 255
			set_color(rr,rg,rb,1)
			outp = string.sub(textbuffer[x],13,#textbuffer[x])
		else
			outp = textbuffer[x]
		end

		if texttype == 0 then offset = 55 end
		if texttype == 1 then offset = 18 end
		if texttype == 2 then offset = 28 end
		if drawpos + offset > 580 then break end
		if string.lower(justification) == "l" then 
			if shadow == 1 then 
				set_color(0,0,0,.8)
				draw_text(outp, 30 - (offset/10), drawpos+(offset/10),texttype) 
				set_color(rr,rg,rb,1)
			end
			draw_text(outp, 30, drawpos,texttype) 
		end
		if string.lower(justification) == "c" then 
			if shadow == 1 then 
				set_color(0,0,0,.8)
				draw_centered_text(outp .. " ",drawpos+(offset/10),texttype) 
				set_color(rr,rg,rb,1)
			end
			draw_centered_text(outp, drawpos,texttype) 
		end
		if string.lower(justification) == "r" then 
			if shadow == 1 then 
				set_color(0,0,0,.8)
				draw_right_text(outp, 60+(offset/10), drawpos+(offset/10),texttype) 
				set_color(rr,rg,rb,1)
			end
			draw_right_text(outp, 60, drawpos,texttype) 
		end
		
		drawpos = drawpos + offset

	end	
	
end

function hextodec(hexnum)
	local expcnt = 0
	local sum = 0
	for x = #hexnum, 1, -1 do
		local digit = string.lower(string.sub(hexnum,x,x))
		if string.byte(digit) >= 97 and string.byte(digit) <= 102 then
			digval = 9 + (string.byte(digit) - 96)
			--echo(digval)
		else
			digval = tonumber(digit)
		end
		sum = sum + ( digval * ( 16 ^ expcnt) )
		expcnt = expcnt + 1
	end
	return sum
end

--=================================================================================
function doinput(intext, callfunc)

	remove_hook("key_up","keypressup")
	remove_hook("key_down","keypressdown")


	add_hook("key_down", "input", inputkeydown)
	add_hook("key_up", "input", inputkeyup)
	add_hook("draw2d", "input", input2d)
	
	preload = intext
	calledfunc = callfunc
end

function inputkeyup(key)

	if key == 303 or key == 304 then shiftstate = 0 end
	return 1
end

function inputkeydown(key)
--	echo(key)     enter = 13  esc = 27
	if key == 303 or key == 304 then shiftstate = 1; return 1 end
	if key == 13 then 
		remove_hook("key_down", "input")
		remove_hook("key_up", "input")
		remove_hook("draw2d", "input")
		add_hook("key_up","keypressup",keyup)
		add_hook("key_down","keypressdown",keydown)
		calledfunc(input)
	end
	if key == 27 then
		remove_hook("key_down", "input")
		remove_hook("key_up", "input")
		remove_hook("draw2d", "input")
		add_hook("key_up","keypressup",keyup)
		add_hook("key_down","keypressdown",keydown)
	end
	if key == 8 then
		if #input <= 1 then input = "" end
		if #input > 1 then input = string.sub(input,1,#input - 1) end
		
		--echo(input)
		return 1 
	end
	
	local location = nil
	location = string.find(okinput,string.char(key),1,true)
	if location == nil then return 1 end

	if shiftstate == 0 then input = input .. string.sub(okinput,location,location)
	else input = input .. string.sub(shiftinput,location,location) end
	
	--echo(input)
	

	return 1
end

function input2d()
	set_color(1,1,1,.8)
	draw_quad(0,270,800,60)
	set_color(0,0,0,1)
	draw_text(preload .. input, 10,285,2)
end

--=================================================================================


add_hook("mouse_button_down","mouse", mousedown)
add_hook("mouse_button_up","mouse",mouseup)
add_hook("mouse_move","mouse",mousemove)
add_hook("draw2d","drawscreen", on2d)
add_hook("draw3d", "drawshapes", on3d)
add_hook("key_down", "keypressdown", keydown)
add_hook("key_up", "keypressup", keyup)

echo("World Builder v0.2 - by NewbLuck")
echo("For comments and suggestions please see:")
echo("http://forum.toribash.com/showthread.php?t=15622")
echo("Press 'h' for help.")