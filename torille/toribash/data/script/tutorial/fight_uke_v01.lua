local width, height = get_window_size()
local chosen_combo = 0
local move = 0
local hint = 0
local continue = 0
local modchoice = 0
local initchange = 0
local slide = 0
local cur_mod = math.random(1, 3) - 1
local win_count = 0
local uke_welcome = 0
local lose_count = 0
local modchange_trans = 0
local modchange_flag = 0
local name = get_master().master.nick
local change_mod_wait = 0
local mod_pending = 0

local BTN_UP = 1
local BTN_HOVER = 2
local BTN_DOWN = 3

local function unload_tutorial()
	remove_hooks("general")
	remove_hooks("fight uke")
	remove_hooks("redirect")
end

local buttons = {}
function load_buttons()
	buttons.arrow = { x = width,  y = height/2-40, state = BTN_UP }
	buttons.stay = { x = (width/2 - 235), y = (height - height/3 - 60), w = 145, h = 20, state = BTN_UP }
	buttons.gotomp = { x = (width/2 + 57), y = (height - height/3 - 60), w = 205, h = 20, state = BTN_UP }
	buttons.aikido = { x = width - 82, y = height/2 - 130, w = 70, h = 20, state = BTN_UP }
	buttons.judo = { x = width - 67, y = height/2 - 55, w = 52, h = 20, state = BTN_UP }
	buttons.wushu = { x = width - 82, y = height/2 + 20, w = 70, h = 20, state = BTN_UP }
	buttons.mod_proceed = { x = (width/2 - 205), y = (height/2 + height/16), w = 132, h = 20, state = BTN_UP }
	buttons.mod_decline = { x = (width/2 + 85), y = (height/2 + height/16), w = 75, h = 20, state = BTN_UP }
end

function load_icons()
	slidebutton = load_texture("/tutorial/slidebutton.tga")
	sliderbg = load_texture("/tutorial/sliderbg.tga")
	modchange = load_texture("/tutorial/try_modchange.tga")
end

function unload_icons()
	unload_texture(slidebutton)
	unload_texture(sliderbg)
	unload_texture(modchange)
end

local combo = {
	{
	{ grip = { 1, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },	-- aikido combo[1][1]
	{ grip = { 1, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 2, 1, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 0, 0 }, joint = { 3, 2, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3 } },
	},
	{
	{ grip = { 0, 1 }, joint = { 1, 1, 1, 2, 1, 3, 2, 2, 4, 4, 1, 4, 2, 2, 1, 2, 2, 3, 2, 2 } },	-- combo[2][1]
	{ grip = { 0, 1 }, joint = { 1, 1, 1, 3, 1, 3, 2, 2, 2, 1, 1, 1, 2, 2, 1, 2, 1, 3, 2, 2 } },
	{ grip = { 0, 1 }, joint = { 1, 4, 2, 1, 4, 1, 1, 4, 2, 1, 1, 1, 1, 2, 1, 2, 2, 1, 1, 4 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 4, 2, 2, 4, 4, 2, 2, 4, 4 } },	-- combo[3][1]
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 3, 4, 3, 3, 4, 3, 4, 3, 3, 2, 3, 4, 1, 3, 3, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 3, 1, 3, 2, 2, 3, 4, 3, 3, 2, 1, 2, 2, 1, 4, 3, 1 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 1, 2, 2, 2, 4, 3, 3, 1, 2, 2, 2, 1, 4, 3, 1 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 2, 2, 2, 2, 4, 3, 3, 2, 2, 1, 2, 4, 4, 2, 1 } },
	{ grip = { 1, 1 }, joint = { 3, 1, 2, 2, 1, 2, 1, 2, 2, 2, 2, 3, 1, 1, 2, 2, 2, 4, 2, 2 } },
	},
	{
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 3, 3, 1, 3, 3, 1, 3, 2, 2, 2, 1, 3, 2, 3, 3 } },	-- combo[4][1]
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 3, 3, 1, 3, 3, 1, 3, 2, 2, 2, 1, 3, 1, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 2, 3, 1, 3, 3, 1, 3, 1, 1, 2, 3, 3, 1, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 3, 2, 2, 3, 4, 3, 3, 1, 3, 1, 1, 2, 3, 3, 1, 3, 3 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 4, 4, 4, 2, 4, 4, 2, 4, 4, 4, 4, 2, 2, 4, 4, 2, 2, 4, 4 } },	-- combo[5][1]
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 3, 4, 3, 3, 4, 3, 3, 3, 3, 3, 3, 4, 1, 4, 3, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 2, 2, 3, 3, 1, 1, 3, 3, 3, 3, 3, 2, 1, 1, 4, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 2, 2, 3, 3, 1, 1, 3, 3, 3, 3, 3, 2, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 3, 1, 1, 2, 3, 1, 3, 3, 2, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 3, 1, 1, 2, 3, 1, 3, 3, 2, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 1, 3, 3, 2, 4, 1, 4, 2, 3 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 2, 2, 4, 2, 1, 4, 4, 4, 4, 4, 4, 2, 4, 2, 4, 4, 4, 4, 4 } },	-- combo[6][1]
	{ grip = { 1, 0 }, joint = { 4, 2, 2, 4, 2, 2, 4, 4, 4, 4, 4, 4, 2, 4, 2, 1, 4, 4, 4, 4 } },
	{ grip = { 1, 1 }, joint = { 4, 1, 2, 4, 1, 2, 4, 2, 2, 4, 4, 4, 1, 1, 1, 2, 1, 1, 4, 1 } },
	{ grip = { 1, 1 }, joint = { 4, 1, 2, 4, 1, 2, 4, 2, 2, 4, 4, 4, 1, 1, 1, 2, 1, 1, 4, 1 } },
	{ grip = { 1, 1 }, joint = { 4, 1, 1, 4, 1, 2, 4, 2, 1, 4, 4, 4, 2, 1, 1, 1, 1, 1, 4, 1 } },
	},
	{
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 2, 2, 3, 2, 1, 1, 2, 1, 1, 2, 2, 2, 1, 2, 2, 2, 2 } },	-- judo combo[7][1]
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 2, 1, 4, 1, 1, 2, 1, 2, 2, 2, 2, 1, 2, 1, 1, 1, 2 } },
	{ grip = { 1, 0 }, joint = { 3, 1, 2, 2, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 2 } },
	{ grip = { 1, 0 }, joint = { 3, 1, 2, 2, 1, 2, 1, 2, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 2 } },
	},
	{
	{ grip = { 1, 1 }, joint = { 3, 3, 3, 3, 2, 3, 1, 2, 3, 1, 1, 1, 2, 3, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 3, 3, 3, 2, 2, 1, 2, 2, 1, 1, 1, 2, 3, 3, 3, 3, 3, 3, 3 } },
	{ grip = { 1, 1 }, joint = { 3, 3, 3, 3, 2, 2, 1, 2, 2, 1, 1, 1, 2, 3, 2, 2, 3, 3, 3, 3 } },	-- combo[8][1]
	},
	{
	{ grip = { 1, 1 }, joint = { 3, 2, 3, 3, 2, 3, 2, 2, 3, 2, 3, 3, 2, 3, 3, 1, 3, 3, 3, 3 } },	-- combo[9][1]
	{ grip = { 1, 0 }, joint = { 3, 1, 1, 1, 2, 2, 1, 1, 2, 1, 3, 1, 1, 2, 2, 2, 1, 3, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 1, 1, 1, 1, 1, 1, 2, 2, 1, 3, 1, 1, 2, 1, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 2, 1, 1, 1, 2, 1, 2, 2, 1, 3, 1, 1, 2, 2, 2, 1, 1, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 3, 2, 2, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 3, 3 } },
	},
	{
	{ grip = { 1, 0 }, joint = { 3, 2, 2, 2, 2, 3, 2, 1, 3, 2, 3, 3, 2, 2, 3, 3, 3, 3, 3, 3 } },	-- combo[10][1]
	{ grip = { 1, 0 }, joint = { 3, 1, 2, 1, 1, 1, 1, 1, 3, 1, 1, 3, 1, 2, 4, 2, 2, 3, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 1, 2, 1, 2, 2, 1, 2, 3, 1, 1, 3, 1, 2, 3, 2, 1, 3, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 1, 1, 1, 2, 2, 1, 1, 3, 1, 1, 3, 2, 2, 3, 2, 1, 3, 3, 3 } },
	{ grip = { 1, 0 }, joint = { 3, 1, 1, 1, 3, 2, 1, 1, 2, 1, 1, 3, 2, 2, 3, 2, 1, 3, 3, 3 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 1, 1, 1, 1, 1, 2, 1, 1, 2, 2, 4, 2, 2, 2, 4, 2, 2, 4, 4 } },	-- wushu combo[11][1]
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 2, 2, 2, 1, 2, 2, 1, 1, 4, 1, 2, 2, 4, 1, 1, 4, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 2, 1, 2, 1, 1, 2, 1, 1, 4, 2, 2, 2, 2, 1, 1, 4, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 1, 2, 2, 2, 2, 1, 2, 4, 1, 1, 4, 2, 2, 4, 4, 1, 1, 4, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 1, 2, 1, 1, 2, 1, 1, 3, 1, 1, 1, 1, 2, 2, 2, 1, 1, 4, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 1, 2, 1, 1, 2, 1, 2, 2, 1, 1, 1, 1, 2, 2, 2, 1, 1, 4, 4 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 1, 4, 4, 1, 4, 4, 2, 1, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4 } },	-- combo[12][1]
	{ grip = { 0, 0 }, joint = { 4, 1, 4, 4, 2, 2, 4, 1, 2, 4, 4, 4, 2, 4, 2, 1, 4, 4, 2, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 4, 4, 1, 2, 1, 2, 2, 1, 4, 4, 1, 2, 2, 2, 4, 4, 2, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 1, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 1, 1, 2, 2, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 4, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 1, 2, 1, 1, 2, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 4, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 1, 1, 2, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 4, 1, 2, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 2, 2 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 3, 1, 3, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 3, 1, 1, 3, 2, 3, 3 } },	-- combo[13][1]
	{ grip = { 0, 0 }, joint = { 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 2, 2, 1, 3, 1, 3, 2 } },
	{ grip = { 0, 0 }, joint = { 3, 1, 1, 1, 2, 3, 3, 1, 3, 1, 3, 1, 2, 2, 2, 2, 4, 1, 3, 2 } },
	{ grip = { 0, 0 }, joint = { 3, 2, 2, 1, 2, 3, 3, 2, 2, 3, 3, 1, 1, 2, 2, 3, 1, 1, 1, 2 } },
	{ grip = { 0, 0 }, joint = { 3, 3, 3, 3, 1, 2, 1, 1, 2, 3, 3, 1, 2, 2, 2, 1, 1, 1, 1, 2 } },
	{ grip = { 0, 0 }, joint = { 3, 3, 3, 3, 1, 2, 1, 1, 2, 3, 3, 1, 2, 1, 2, 2, 1, 1, 1, 2 } },
	{ grip = { 0, 0 }, joint = { 3, 3, 3, 3, 1, 2, 1, 1, 2, 3, 3, 1, 2, 2, 2, 1, 1, 1, 1, 2 } },
	{ grip = { 0, 0 }, joint = { 3, 3, 3, 3, 1, 2, 1, 1, 2, 3, 3, 1, 2, 2, 2, 2, 1, 1, 1, 2 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 1, 4, 4, 1, 1, 4, 1, 1, 4, 4, 4, 4, 2, 4, 4, 2, 2, 4, 2 } },	-- combo[14][1]
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 4, 2, 2, 4, 1, 1, 4, 4, 4, 4, 1, 2, 4, 1, 1, 4, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 4, 1, 2, 1, 2, 2, 1, 1, 1, 2, 2, 2, 1, 1, 1, 4, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 1, 1, 2, 1, 2, 2, 1, 1, 1, 2, 2, 1, 2, 1, 1, 4, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 1, 2, 2, 2, 2, 1, 1, 4, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 1, 2, 2, 1, 2, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 4, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 1, 4, 2 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 1, 1, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 4, 2 } },
	},
	{
	{ grip = { 0, 0 }, joint = { 4, 1, 1, 2, 1, 1, 4, 2, 1, 4, 4, 4, 2, 3, 4, 2, 4, 4, 4, 4 } },	-- combo[15][1]
	{ grip = { 0, 0 }, joint = { 4, 2, 2, 2, 2, 2, 1, 1, 2, 1, 1, 4, 2, 2, 2, 1, 1, 1, 1, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 2, 2, 2, 2, 1, 1, 2, 1, 1, 4, 2, 2, 2, 1, 1, 1, 1, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 2, 2, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 1, 2, 1, 2, 1, 1, 2, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 2, 2, 2, 1, 2, 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 1, 2, 1, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 1, 2, 2, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 1, 2, 1, 1, 1, 4 } },
	{ grip = { 0, 0 }, joint = { 4, 1, 2, 2, 1, 2, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 1, 1, 1, 4 } },
	},
}

local advice = {
	{
		"A simple move taught to me by Gman80.",
		"I'm going to kick you out of the ring!",
	},
	{
		"FNugget's infamous Aikido Kick Lift!",
		"Lifting you with my left arm, I trip you with my right leg at the ^07same time.",
		"Enjoy the freefall!",
	},
	{
		"evilperson thought up this move.",
		"I'm going to throw you to the floor!",
	},
	{
		"A basic opener where I turn my body, grab you and prepare to kick.",
		"Kicking you lifts you off the ground. I can also raise my arm to ^07increase the momentum.",
		"Now I hold my hip so that my legs are stable for landing.",
		"Finally, I relax my left pec so that my arm swings down to form ^07another support for my body.",
		"This move was explained by Kyat!",
	},
	{
		"evilperson thought up this move.",
		"I'm going to push you to the floor!",
	},
	{
		"evilperson thought up this move.",
		"I'm going to push you out of the ring!",
	},
	{
		"This judo move is called \"Dragon Kick\".",
		"Its purpose is to deal damage with a heavy leg kick!",
	},
	{
		"This is a very basic move.",
		"It's called \"Noobclap\" and the only thing I'll do is grab you until ^07you fail.",
	},
	{
		"Judo fighting technique is very different from aikido.",
		"Sometimes it's more important to try to control your opponent ^07with grabs than to deal him lots of damage.",
		"Otherwise, you can easily get yourself dismembered and disqualified!",
	},
	{
		"The move I'm going to do is popular among intermediate judo players.",
		"I kick you with my leg while holding most joints and then try not ^07to DQ!",
	},
	{
		"This \"Heli\" type of moves is rather popular among wushu players.",
		"I jump to be upside down and then try to kick you with my legs!",
		"Are you dead yet?",
	},
	{
		"With opener looks quite peaceful, doesn't it?",
		"Ha, but this leg kick surely does not!",
		"And now I'll try not to fall down...",
	},
	{
		"In this move, I will first spin around",
		"And then attempt to kick you with my leg!",
	},
	{
		"I'm now getting ready to push myself forwards",
		"And try to perform a leg kick!",
		"If I miss, I can still attack you with my hands!",
	},
	{
		"This is one of \"Heli\" move variations.",
		"I push myself with my hands and attempt to kick you with my legs!",
	},
}


function do_combo_move()
	move = move + 1
	if (combo[chosen_combo][move] ~= nil) then
		for i, v in ipairs(combo[chosen_combo][move].grip) do
			set_grip_info(1, i+10, v)
		end
		for i, v in ipairs(combo[chosen_combo][move].joint) do
			set_joint_state(1, i-1, v)
		end
	end
end
function redo_combo_move()
	if (combo[chosen_combo][move] ~= nil) then
		for i, v in ipairs(combo[chosen_combo][move].grip) do
			set_grip_info(1, i+10, v)
		end
		for i, v in ipairs(combo[chosen_combo][move].joint) do
			set_joint_state(1, i-1, v)
		end
	end
end
function speak()
	hint = hint + 1
	if (advice[chosen_combo][hint] ~= nil) then
		echo("^07<^05Uke^07> " .. advice[chosen_combo][hint])
	end
end

function change_mod(modpick)
	cur_mod = modpick
	activate_uke()
	modchange_flag = 1000
	load_icons()
end

local MOUSE_UP = 0
local MOUSE_DOWN = 1
local mouse_state = MOUSE_UP

function mouse_down(mouse_btn, x, y)
	mouse_state = MOUSE_DOWN
	if (get_world_state().selected_player == 1) then select_player(0) end
	
	if (modchoice == 0 and initchange == 0) then
	if (x > buttons.arrow.x - 10 and x < buttons.arrow.x and y > buttons.arrow.y - 10 and y < buttons.arrow.y + 10) then
		buttons.arrow.state = BTN_DOWN
	end
	elseif (modchoice == 1 and initchange == 0) then
	if (x > buttons.arrow.x - 110 and x < buttons.arrow.x - 100 and y > buttons.arrow.y - 10 and y < buttons.arrow.y + 10) then
		buttons.arrow.state = BTN_DOWN
	end
	if (x > buttons.aikido.x and x < (buttons.aikido.x + buttons.aikido.w) and y > buttons.aikido.y and y < (buttons.aikido.y + buttons.aikido.h)) then
		buttons.aikido.state = BTN_DOWN
	end
	if (x > buttons.judo.x and x < (buttons.judo.x + buttons.judo.w) and y > buttons.judo.y and y < (buttons.judo.y + buttons.judo.h)) then
		buttons.judo.state = BTN_DOWN
	end
	if (x > buttons.wushu.x and x < (buttons.wushu.x + buttons.wushu.w) and y > buttons.wushu.y and y < (buttons.wushu.y + buttons.wushu.h)) then
		buttons.wushu.state = BTN_DOWN
	end
	end
	
	if (change_mod_wait == 1) then
		if (x > buttons.mod_proceed.x and x < (buttons.mod_proceed.x + buttons.mod_proceed.w) and y > buttons.mod_proceed.y and y < (buttons.mod_proceed.y + buttons.mod_proceed.h)) then
			buttons.mod_proceed.state = BTN_DOWN
		end
		if (x > buttons.mod_decline.x and x < (buttons.mod_decline.x + buttons.mod_decline.w) and y > buttons.mod_decline.y and y < (buttons.mod_decline.y + buttons.mod_decline.h)) then
			buttons.mod_decline.state = BTN_DOWN
		end
	end
	
	if (continue == 1) then
		if (x > buttons.stay.x and x < (buttons.stay.x + buttons.stay.w) and y > buttons.stay.y and y < (buttons.stay.y + buttons.stay.h)) then
			buttons.stay.state = BTN_DOWN
		end
		if (x > buttons.gotomp.x and x < (buttons.gotomp.x + buttons.gotomp.w) and y > buttons.gotomp.y and y < (buttons.gotomp.y + buttons.gotomp.h)) then
			buttons.gotomp.state = BTN_DOWN
		end
	end
end
function mouse_up(mouse_btn, x, y)
	mouse_state = MOUSE_UP
	if (get_world_state().selected_player == 1) then select_player(0) end
	
	if (modchoice == 0 and initchange == 0) then
	if (x > buttons.arrow.x - 10 and x < buttons.arrow.x and y > buttons.arrow.y - 10 and y < buttons.arrow.y + 10) then
		buttons.arrow.state = BTN_HOVER
		initchange = 1
	end
	elseif (modchoice == 1 and initchange == 0) then
	if (x > buttons.arrow.x - 110 and x < buttons.arrow.x - 100 and y > buttons.arrow.y - 10 and y < buttons.arrow.y + 10) then
		buttons.arrow.state = BTN_HOVER
		initchange = 1
	end
	if (x > buttons.aikido.x and x < (buttons.aikido.x + buttons.aikido.w) and y > buttons.aikido.y and y < (buttons.aikido.y + buttons.aikido.h)) then
		buttons.aikido.state = BTN_HOVER
		if ((cur_mod == 0 or get_world_state().match_turn ~= 0) and win_count > 0 and win_count < 3 and continue ~= 2) then 
			change_mod_wait = 1
			mod_pending = 0
		else
			remove_hook("new_game", "redirect")
			change_mod(0)
			add_hook("new_game", "redirect", unload_tutorial)
		end
	end
	if (x > buttons.judo.x and x < (buttons.judo.x + buttons.judo.w) and y > buttons.judo.y and y < (buttons.judo.y + buttons.judo.h)) then
		buttons.judo.state = BTN_HOVER
		if ((cur_mod == 1 or get_world_state().match_turn ~= 0) and win_count > 0 and win_count < 3 and continue ~= 2) then
			change_mod_wait = 1
			mod_pending = 1
		else
			remove_hook("new_game", "redirect")
			change_mod(1)
			add_hook("new_game", "redirect", unload_tutorial)
		end
	end
	if (x > buttons.wushu.x and x < (buttons.wushu.x + buttons.wushu.w) and y > buttons.wushu.y and y < (buttons.wushu.y + buttons.wushu.h)) then
		buttons.wushu.state = BTN_HOVER
		if ((cur_mod == 2 or get_world_state().match_turn ~= 0) and win_count > 0 and win_count < 3 and continue ~= 2) then
			change_mod_wait = 1
			mod_pending = 2
		else
			remove_hook("new_game", "redirect")
			change_mod(2)
			add_hook("new_game", "redirect", unload_tutorial)
		end
	end
	end
	
	if (change_mod_wait == 1) then
		if (x > buttons.mod_proceed.x and x < (buttons.mod_proceed.x + buttons.mod_proceed.w) and y > buttons.mod_proceed.y and y < (buttons.mod_proceed.y + buttons.mod_proceed.h)) then
			buttons.mod_proceed.state = BTN_HOVER
			change_mod_wait = 0
			win_count = 0
			change_mod(mod_pending)
		end
		if (x > buttons.mod_decline.x and x < (buttons.mod_decline.x + buttons.mod_decline.w) and y > buttons.mod_decline.y and y < (buttons.mod_decline.y + buttons.mod_decline.h)) then
			buttons.mod_decline.state = BTN_HOVER
			change_mod_wait = 0
		end
	end
	
	if (continue == 1) then
		if (x > buttons.stay.x and x < (buttons.stay.x + buttons.stay.w) and y > buttons.stay.y and y < (buttons.stay.y + buttons.stay.h)) then
			buttons.stay.state = BTN_HOVER
			continue = 2
			activate_uke()
		end
	
		if (x > buttons.gotomp.x and x < (buttons.gotomp.x + buttons.gotomp.w) and y > buttons.gotomp.y and y < (buttons.gotomp.y + buttons.gotomp.h)) then
			buttons.gotomp.state = BTN_HOVER
			continue = 2
			unload_icons()
			unload_tutorial()
			run_cmd("option beginner 5")
			run_cmd("connect 144.76.163.135 22005")
			echo(" ")
			echo(" ")
			echo(" ")
			echo(" ")
			echo("^07<^05Uke^07> You won... Now you shall face hell!")
			return 1
		end
	end
end

function mouse_move(x, y)	

	if (modchoice == 0 and initchange == 0) then
	if (x > buttons.arrow.x - 10 and x < buttons.arrow.x and y > buttons.arrow.y - 10 and y < buttons.arrow.y + 10) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.arrow.state = BTN_DOWN
		else
			buttons.arrow.state = BTN_HOVER
		end
	else
		buttons.arrow.state = BTN_UP
	end
	elseif (modchoice == 1 and initchange == 0) then
	if (x > buttons.arrow.x - 110 and x < buttons.arrow.x - 100 and y > buttons.arrow.y - 10 and y < buttons.arrow.y + 10) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.arrow.state = BTN_DOWN
		else
			buttons.arrow.state = BTN_HOVER
		end
	else
		buttons.arrow.state = BTN_UP
	end
	if (x > buttons.aikido.x and x < (buttons.aikido.x + buttons.aikido.w) and y > buttons.aikido.y and y < (buttons.aikido.y + buttons.aikido.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.aikido.state = BTN_DOWN
		else
			buttons.aikido.state = BTN_HOVER
		end
	else
		buttons.aikido.state = BTN_UP
	end
	if (x > buttons.judo.x and x < (buttons.judo.x + buttons.judo.w) and y > buttons.judo.y and y < (buttons.judo.y + buttons.judo.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.judo.state = BTN_DOWN
		else
			buttons.judo.state = BTN_HOVER
		end
	else
		buttons.judo.state = BTN_UP
	end
	if (x > buttons.wushu.x and x < (buttons.wushu.x + buttons.wushu.w) and y > buttons.wushu.y and y < (buttons.wushu.y + buttons.wushu.h)) then
		if (mouse_state == MOUSE_DOWN) then
			buttons.wushu.state = BTN_DOWN
		else
			buttons.wushu.state = BTN_HOVER
		end
	else
		buttons.wushu.state = BTN_UP
	end
	end	
	
	if (change_mod_wait == 1) then
		if (x > buttons.mod_proceed.x and x < (buttons.mod_proceed.x + buttons.mod_proceed.w) and y > buttons.mod_proceed.y and y < (buttons.mod_proceed.y + buttons.mod_proceed.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.mod_proceed.state = BTN_DOWN
			else
				buttons.mod_proceed.state = BTN_HOVER
			end
		else
			buttons.mod_proceed.state = BTN_UP
		end
	
		if (x > buttons.mod_decline.x and x < (buttons.mod_decline.x + buttons.mod_decline.w) and y > buttons.mod_decline.y and y < (buttons.mod_decline.y + buttons.mod_decline.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.mod_decline.state = BTN_DOWN
			else
				buttons.mod_decline.state = BTN_HOVER
			end
		else
			buttons.mod_decline.state = BTN_UP
		end
	end
	
	if (continue == 1) then
		if (x > buttons.stay.x and x < (buttons.stay.x + buttons.stay.w) and y > buttons.stay.y and y < (buttons.stay.y + buttons.stay.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.stay.state = BTN_DOWN
			else
				buttons.stay.state = BTN_HOVER
			end
		else
			buttons.stay.state = BTN_UP
		end
	
		if (x > buttons.gotomp.x and x < (buttons.gotomp.x + buttons.gotomp.w) and y > buttons.gotomp.y and y < (buttons.gotomp.y + buttons.gotomp.h)) then
			if (mouse_state == MOUSE_DOWN) then
				buttons.gotomp.state = BTN_DOWN
			else
				buttons.gotomp.state = BTN_HOVER
			end
		else
			buttons.gotomp.state = BTN_UP
		end
	end
end

function select_color_links(state, color)
	if (state == BTN_UP and color == "white") then
		set_color(1, 1, 1, 1)
	elseif (state == BTN_UP and color == "black") then
		set_color(0, 0, 0, 1)
	elseif (state == BTN_DOWN) then
		set_color(0.16, 0.66, 0.86, 1)
	else
		set_color(0.82, 0.39, 0.39, 1)
	end
end

function overlay()
	if (modchoice == 0) then
		if (initchange == 0) then
			set_color(1, 1, 1, 1)
			draw_quad(width-20, height/2-102, 128, 128, slidebutton)
			set_color(1, 1, 1, 1)
			if (buttons.arrow.state == BTN_UP) then draw_disk(width, height/2-40, 0, 14, 3, 1, 270, 360, 0)
				elseif (buttons.arrow.state == BTN_DOWN) then draw_disk(width, height/2-40, 0, 10, 3, 1, 270, 360, 0)
				else draw_disk(width, height/2-40, 0, 16, 3, 1, 270, 360, 0)
			end
		end
		if (initchange == 1 and slide ~= 100) then
			buttons.arrow.state = BTN_UP
			set_color(1, 1, 1, 1)
			draw_quad(width-20-slide, height/2-102, 128, 128, slidebutton)
			set_color(1, 1, 1, 1)
			if (buttons.arrow.state == BTN_UP) then draw_disk(width-slide, height/2-40, 0, 14, 3, 1, 270, 360, 0)
				elseif (buttons.arrow.state == BTN_DOWN) then draw_disk(width-slide, height/2-40, 0, 10, 3, 1, 270, 360, 0)
				else draw_disk(width-slide, height/2-40, 0, 16, 3, 1, 270, 360, 0)
			end
			set_color(1, 1, 1, 1)
			draw_quad(width-slide, height/2-161, 256, 256, sliderbg)
			set_color(1, 1, 1, slide/100)
			draw_text("aikido", buttons.aikido.x + 100 - slide, buttons.aikido.y, FONTS.MEDIUM)
			draw_text("judo", buttons.judo.x + 100 - slide, buttons.judo.y, FONTS.MEDIUM)
			draw_text("wushu", buttons.wushu.x + 100 - slide, buttons.wushu.y, FONTS.MEDIUM)
			slide = slide + 5
		end
		if (slide == 100) then
			initchange = 0
			modchoice = 1
		end
	elseif (modchoice == 1) then
		if (initchange == 0) then
			set_color(1, 1, 1, 1)
			draw_quad(width-120, height/2-102, 128, 128, slidebutton)
			set_color(1, 1, 1, 1)
			if (buttons.arrow.state == BTN_UP) then draw_disk(width-100, height/2-40, 0, 14, 3, 1, 270, 360, 0)
				elseif (buttons.arrow.state == BTN_DOWN) then draw_disk(width-100, height/2-40, 0, 10, 3, 1, 270, 360, 0)
				else draw_disk(width-100, height/2-40, 0, 16, 3, 1, 270, 360, 0)
			end
			set_color(1, 1, 1, 1)
			draw_quad(width-100, height/2-161, 256, 256, sliderbg)
			select_color_links(buttons.aikido.state, "white")
			draw_text("aikido", buttons.aikido.x, buttons.aikido.y, FONTS.MEDIUM)
			select_color_links(buttons.judo.state, "white")
			draw_text("judo", buttons.judo.x, buttons.judo.y, FONTS.MEDIUM)
			select_color_links(buttons.wushu.state, "white")
			draw_text("wushu", buttons.wushu.x, buttons.wushu.y, FONTS.MEDIUM)
		end
		if (initchange == 1 and slide ~= 0) then
			buttons.arrow.state = BTN_UP
			set_color(1, 1, 1, 1)
			draw_quad(width-20-slide, height/2-102, 128, 128, slidebutton)
			set_color(1, 1, 1, 1)
			if (buttons.arrow.state == BTN_UP) then draw_disk(width-slide, height/2-40, 0, 14, 3, 1, 270, 360, 0)
				elseif (buttons.arrow.state == BTN_DOWN) then draw_disk(width-slide, height/2-40, 0, 10, 3, 1, 270, 360, 0)
				else draw_disk(width-slide, height/2-40, 0, 16, 3, 1, 270, 360, 0)
			end
			set_color(1, 1, 1, 1)
			draw_quad(width-slide, height/2-161, 256, 256, sliderbg)
			set_color(1, 1, 1, slide/100)
			draw_text("aikido", buttons.aikido.x + 100 - slide, buttons.aikido.y, FONTS.MEDIUM)
			draw_text("judo", buttons.judo.x + 100 - slide, buttons.judo.y, FONTS.MEDIUM)
			draw_text("wushu", buttons.wushu.x + 100 - slide, buttons.wushu.y, FONTS.MEDIUM)
			slide = slide - 5
		end
		if (slide == 0) then
			initchange = 0
			modchoice = 0
		end
	end
	
	if (lose_count > 4) then
		if (width > 1040) then
			if (modchange_trans < 100 and modchange_flag < 100) then
				modchange_trans = modchange_trans + 1
				modchange_flag = modchange_flag + 1
			elseif (modchange_flag == 600 or (modchange_trans > 0 and modchange_flag == 1000)) then
				modchange_trans = modchange_trans - 1
			elseif (modchange_trans == 100) then
				modchange_flag = modchange_flag + 1
			end 
			set_color(1, 1, 1, .9)
			draw_quad(0, height - modchange_trans/2, width, 60) 
			set_color(0, 0, 0, .4)
			draw_quad(0, height - modchange_trans/2, width, 1)
			set_color(0, 0, 0, modchange_trans/2)
			draw_centered_text("Feeling Uke too tough to beat in this mod? Try picking another one in the menu on the right!", height - modchange_trans/2.8, FONTS.MEDIUM)
		end
	end
	
	if (change_mod_wait == 1 and win_count > 0 and win_count < 3) then
		set_color(1, 1, 1, .8)
		draw_quad(width/4, height/2 - height/8, width/2, height/4)
		set_color(0, 0, 0, 1)
		draw_quad(width/4, height/2 - height/8, 1, height/4)
		draw_quad(width/4, height/2 + height/8, width/2, 1)
		draw_quad(width - width/4, height/2 - height/8, 1, height/4)
		draw_quad(width/4, height/2 - height/8, width/2, 1)
		draw_centered_text("Do you want to change the mod?", height/3+50, FONTS.MEDIUM)
		draw_centered_text("This will change your current win count to 0", height/3+80, FONTS.MEDIUM)
		select_color_links(buttons.mod_proceed.state, "black")
		draw_text("CHANGE MOD", buttons.mod_proceed.x, buttons.mod_proceed.y, FONTS.MEDIUM)
		select_color_links(buttons.mod_decline.state, "black")
		draw_text("CANCEL", buttons.mod_decline.x, buttons.mod_decline.y, FONTS.MEDIUM)
	end
	
	if (continue == 1) then
		set_color(1, 1, 1, .8)
		draw_quad(width/4, height/3, width/2, height/3)
		set_color(0, 0, 0, 1)
		draw_quad(width/4, height/3, 1, height/3)
		draw_quad(width/4, height/3, width/2, 1)
		draw_quad(width - width/4, height/3, 1, height/3)
		draw_quad(width/4, height - height/3, width/2, 1)
		draw_centered_text("Congratulations!", height/3+15, FONTS.BIG)
		draw_centered_text("Congratulations!", height/3+15, FONTS.BIG)
		draw_centered_text("Do you want to continue fighting Uke", height/3+80, FONTS.MEDIUM)
		draw_centered_text("or are you ready to try your skills in Multiplayer?", height/3+105, FONTS.MEDIUM)
		select_color_links(buttons.stay.state, "black")
		draw_text("STAY WITH UKE", buttons.stay.x, buttons.stay.y, FONTS.MEDIUM)
		select_color_links(buttons.gotomp.state, "black")
		draw_text("GO KICK SOME BUTTS", buttons.gotomp.x, buttons.gotomp.y, FONTS.MEDIUM)
	end
end	

function check_victory()
	remove_hooks("fight uke")

	local winner = get_world_state().winner
	local frames = get_world_state().match_frame

	local redirect = function()
		remove_hooks("redirect")
		if (winner == 0) then	-- tori won
			win_count = win_count + 1
			if (continue == 0 and win_count == 3) then 
				continue = 1
			else 
				activate_uke()
			end
		elseif (winner == 1) then	-- uke won
			win_count = 0
			lose_count = lose_count + 1
			activate_uke()
		elseif ((frames > 499 and (cur_mod == 1 or cur_mod == 2)) or (frames > 349 and cur_mod == 0)) then
			activate_uke()
		else
			run_cmd("lm classic.tbm")
			run_cmd("clear")
			echo("^07<^05Uke^07> If that's all you've got, then run away! *evil laughter*")
			echo(" ")
			echo("Finding Uke too tough to beat?")
			echo("Visit the link below for tips and tricks!")
			echo("http://forum.toribash.com/forumdisplay.php?f=364")
			unload_tutorial()
			unload_icons()
		end
		refresh_chat_cache()
	end
	add_hook("new_game", "redirect", redirect)
end


function choose_combo()
	if (cur_mod == 0) then chosen_combo = math.random(1, 6)
	elseif (cur_mod == 1) then chosen_combo = math.random(1, 4) + 6
	elseif (cur_mod == 2) then chosen_combo = math.random(1, 5) + 10
	end

	do_combo_move()
end

function activate_uke()
	reset_camera(1)

	local options = {"text", "uke", "hint", "name", "score", "timer", "feedback"}
	for i = 1, 7 do
		set_option(options[i], 1) end
		
	load_buttons()
	load_icons()

	set_gameover_timelimit(4)

	start_new_game()	-- This clears the settings for the previous replay
	if (cur_mod == 0) then run_cmd("lm aikido.tbm")
	elseif (cur_mod == 1) then run_cmd("lm judo.tbm") run_cmd("set matchframes 500") run_cmd("rt")
	elseif (cur_mod == 2) then run_cmd("lm wushu.tbm")
	end
	run_cmd("clear")

	add_hook("draw2d", "general", overlay)
	add_hook("mouse_button_down", "general", mouse_down)
	add_hook("mouse_button_up", "general", mouse_up)
	add_hook("mouse_move", "general", mouse_move)
	add_hook("enter_freeze", "fight uke", do_combo_move)
	add_hook("exit_freeze", "fight uke", function() redo_combo_move(); speak(); end)
	add_hook("end_game", "fight uke", function() check_victory() end)
	add_hook("new_game", "redirect", unload_tutorial)
	add_hook("new_mp_game", "redirect", unload_tutorial)


	echo(" ")		-- to hide "clear" echo message
	echo(" ")
	echo(" ")
	echo(" ")
	
	if (continue == 0) then
	if (win_count == 0) then 
		if (uke_welcome == 0) then
			echo("^07<^05Uke^07> It's payback time!")
			echo("^07<^05Uke^07> This won't stop until you win thrice in a row or run away!")
		else 
			uke_welcome = math.random(1,3)
			if (uke_welcome == 1) then
				echo("^07<^05Uke^07> Aaand I win again!")
				echo("^07<^05Uke^07> You will never defeat me if you fight like this!")
			elseif (uke_welcome == 2) then
				echo("^07<^05Uke^07> Yeeah, le goût de la victoire!")
				echo("^07<^05Uke^07> If only you knew how much fun beating you is!")
			else
				echo("^07<^05Uke^07> Oops, looks like I won again!")
				echo("^07<^05Uke^07> Sorry, won't happen again! Ha-ha, joking.")
			end
		end
	elseif (win_count == 1) then
		uke_welcome = math.random(1,3)
		if (uke_welcome == 1) then
			echo("^07<^05Uke^07> Do you think that this random win will stop me?")
			echo("^07<^05Uke^07> Two more wins to get past me! TWO IN A ROW!")
		elseif (uke_welcome == 2) then
			echo("^07<^05Uke^07> Oh, looks like you aren't that bad at fighting?")
			echo("^07<^05Uke^07> Let's try again, two more wins to defeat me!")	
		else
			echo("^07<^05Uke^07> ...are you playing already?")
			echo("^07<^05Uke^07> Eh, sorry, I kinda fell asleep. Well, you won't beat me any more ^07times anyway.")
		end
		
	elseif (win_count == 2) then
		uke_welcome = math.random(1,3)
		if (uke_welcome == 1) then
			echo("^07<^05Uke^07> THAT WAS YOUR LUCK! I MISCLICKED!")
			echo("^07<^05Uke^07> YOU'LL NEVER WIN ME!!!")
		elseif (uke_welcome == 2) then
			echo("^07<^05Uke^07> Is this really the first time you play Toribash?")
			echo("^07<^05Uke^07> I can't believe you just beat me twice!")
		else
			echo("^07<^05Uke^07> That was intense, good game!")
			echo("^07<^05Uke^07> Win one more game and you're ready to face real players!")
		end
	end
	elseif (continue == 2) then
		if (win_count == 0) then
			echo("^07<^05Uke^07> We all make mistakes, my friend!")
			echo("^07<^05Uke^07> Let's fight again and see who wins!")
		else
			echo("^07<^05Uke^07> You're going to be a great fighter, "..name.."!")
			echo("^07<^05Uke^07> It would be an honour to continue sparring with you!")
		end
	end
	
	chosen_combo = 0
	move = 0
	hint = 0

	choose_combo()
end

activate_uke()