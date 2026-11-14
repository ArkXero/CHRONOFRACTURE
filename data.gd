## Content tables: universes, upgrades, weapon forms, text. Tune the game here.

const UNIVERSES := [ # enemy flavour: who appears (name = how often), hp/speed multipliers, preferred range (0 = melee), weave, seconds per shot
	{name = "MEDIEVAL", foes = {Orc = 3, Slime = 2}, flyer = "Skull", bg = Color("2b2118"), col = Color("c9b38a"), hp = 1.6, spd = 0.8, rng = 0.0, weave = 0.0, rate = INF, music = "res://music/medieval.mp3"},
	{name = "CYBERPUNK", foes = {Marine = 4, Walker = 2, Mech = 1}, flyer = "JetMarine", bg = Color("120a2a"), col = Color("ff3df0"), hp = 0.9, spd = 1.0, rng = 260.0, weave = 0.0, rate = 3.0, music = "res://music/cyberpunk.mp3"},
	{name = "ARCANE", foes = {Demon = 3, Blood = 2}, flyer = "Specter", bg = Color("0c2a2a"), col = Color("7df9c0"), hp = 0.7, spd = 1.3, rng = 0.0, weave = 0.9, rate = INF, music = "res://music/medieval.mp3"},
	{name = "THE END OF TIME", foes = {}, flyer = "RiftEye", bg = Color("050505"), col = Color("6dff5a"), hp = 60.0, spd = 0.6, rng = 220.0, weave = 0.0, rate = 1.8, music = "res://music/boss.mp3"},
]
const UPGRADES := [ # per universe: [name, description, stat, amount]. Picking one again adds another level.
	[["Sword", "auto-slash toward the cursor; later picks offer other weapon forms", "melee", 1],
		["Spear", "melee form: long, narrow thrust", "melee", 1], ["Axe", "melee form: wide, heavy cleave", "melee", 1],
		["Flail", "melee form: hits all around you", "melee", 1], ["Daggers", "melee form: short and very fast", "melee", 1],
		["Crossbow", "slow, heavy bolts  ·  Lv2 split on impact  ·  Lv3 explode", "crossbow", 1],
		["Orbiting Blade", "+1 sword circling you", "blades", 1], ["Tower Shield", "+40 max health and a full heal", "maxhp", 40.0],
		["Plate Armor", "-20% damage taken", "armor", 1], ["Whetstone", "+35% damage", "dmg", 0.35]],
	[["Twin Blaster", "+1 bolt per shot", "shots", 1], ["Overclock", "+30% fire rate", "rate", 0.3],
		["Thrusters", "+20% move speed", "speed", 0.2], ["Rail Rounds", "bolts pierce +1 enemy", "pierce", 1],
		["Chrono Implant", "SHIFT slows time, longer per level", "chrono", 1], ["Arm Cannon", "R fires an explosive rocket at the cursor", "cannon", 1],
		["Grenades", "Q lobs a grenade at the cursor", "grenade", 1], ["Neural Hack", "E turns the enemy at the cursor on its allies (slows Loki)", "hack", 1]],
	[["Blink", "C teleports you to the cursor", "blink", 1], ["Nova", "periodic blast around you", "nova", 1],
		["Seeker Bolts", "bolts home in on enemies", "homing", 1], ["Soul Leech", "+3 health per kill", "leech", 3.0],
		["Spell Book", "hold F or right mouse to charge, release a piercing beam", "gauntlet", 1],
		["Frost Imbue", "weapon hits slow enemies", "frost", 1], ["Fire Imbue", "weapon hits set enemies burning", "fire", 1],
		["Shock Imbue", "weapon hits arc to nearby enemies", "shock", 1], ["Toxin Imbue", "weapon hits make enemies take more damage", "toxin", 1]],
]

# Art. Characters are strips of 100x100 frames named <path>_<Anim>.png, facing right, feet at (50, 57).
const TINY1 := "res://Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc/Characters(100x100 split)/"
const TINY2 := "res://Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/"
const PACK3 := "res://FreeCharactersAnimationsAssetPack/SpriteSheets(96x96)/"
const SCIFI := "res://enemies/" # ansimuz's CC0 sideview sci-fi sprites
const RAVEN := "res://Free - Raven Fantasy Icons/Free - Raven Fantasy Icons/Full Spritesheet/"
# Characters. anims: name = [file suffix, frame width, x of the body's centre in a frame]; all face right; anchor.y = feet.
# Missing Idle/Attack fall back to Walk, a missing Hurt tints red, and boom = true dies in an explosion instead of a Death strip.
# Enemies may also scale the universe's hp and spd, and override r (size), rng (preferred range) and weave (hopping).
const SPRITES := {
	Soldier = {path = PACK3 + "Human_Soldier_Sword_Shield/No_Shadows/Human_Soldier_Sword_Shield_", feet = 57, zoom = 4.0, anims = {
		Idle = ["Idle-Sheet.png", 96, 46], Walk = ["Walk-Sheet.png", 96, 46], Attack = ["Attack1-Sheet.png", 96, 46], Jump = ["Jump_Fall-Sheet.png", 96, 46], Hurt = ["Hurt-Sheet.png", 96, 46]}},
	Orc = {path = TINY1 + "Orc/Orc/Orc_", feet = 57, zoom = 4.0, anims = {
		Idle = ["Idle.png", 100, 50], Walk = ["Walk.png", 100, 50], Attack = ["Attack01.png", 100, 50], Hurt = ["Hurt.png", 100, 50], Death = ["Death.png", 100, 50]}},
	Slime = {path = PACK3 + "Monster_Slime/No_Shadows/Monster_Slime_", feet = 57, zoom = 4.0, hp = 0.6, spd = 1.1, r = 20.0, weave = 0.6, anims = {
		Idle = ["Idle-Sheet.png", 96, 47], Walk = ["Walk-Sheet.png", 96, 47], Attack = ["Attack1-Sheet.png", 96, 47], Hurt = ["Hurt-Sheet.png", 96, 47], Death = ["Death-Sheet.png", 96, 47]}},
	Demon = {path = TINY2 + "Demon_A/Demon_A/Demon_A_", feet = 57, zoom = 4.0, anims = {
		Idle = ["Idle.png", 100, 50], Walk = ["Walk.png", 100, 50], Attack = ["Attack01.png", 100, 50], Hurt = ["Hurt.png", 100, 50], Death = ["Death.png", 100, 50]}},
	Blood = {path = TINY2 + "Blood Monster_A/Blood Monster_A/Blood Monster_A_", feet = 57, zoom = 4.0, hp = 1.6, spd = 0.75, weave = 0.0, anims = {
		Idle = ["Idle.png", 100, 50], Walk = ["Walk.png", 100, 50], Attack = ["Attack01.png", 100, 50], Hurt = ["Hurt.png", 100, 50], Death = ["Death.png", 100, 50]}},
	Marine = {path = SCIFI + "space-marine-", feet = 48, zoom = 2.0, anims = {
		Idle = ["idle.png", 48, 16], Walk = ["run.png", 48, 16], Attack = ["shoot.png", 64, 22], Death = ["die.png", 80, 50]}},
	Walker = {path = SCIFI, feet = 63, zoom = 2.0, hp = 1.8, spd = 0.7, r = 44.0, boom = true, anims = {Walk = ["bipedal-unit.png", 80, 38]}},
	Mech = {path = SCIFI, feet = 79, zoom = 2.0, hp = 2.4, spd = 0.8, r = 52.0, rng = 0.0, boom = true, anims = {Walk = ["mech-unit.png", 96, 48]}},
	Skull = {path = RAVEN + "32x32.png", region = Rect2(416, 1696, 32, 32), feet = 24, zoom = 3.0,
		fly = true, hover = 0.0, hp = 0.55, spd = 1.5, r = 24.0, rng = 0.0, rate = INF},
	JetMarine = {path = SCIFI + "space-marine-", feet = 48, zoom = 2.0, fly = true, hover = 80.0,
		hp = 0.75, spd = 1.3, r = 24.0, rng = 230.0, rate = 2.4, boom = true, jets = true, anims = {
		Idle = ["idle.png", 48, 16], Walk = ["run.png", 48, 16], Attack = ["shoot.png", 64, 22]}},
	Specter = {path = RAVEN + "32x32.png", region = Rect2(256, 2080, 32, 32), feet = 24, zoom = 3.0,
		fly = true, hover = 70.0, hp = 0.8, spd = 1.15, r = 24.0, rng = 150.0, rate = 2.8},
	RiftEye = {path = RAVEN + "32x32.png", region = Rect2(448, 1408, 32, 32), feet = 22, zoom = 3.0,
		fly = true, hover = 90.0, hp = 1.2, spd = 1.3, r = 22.0, rng = 190.0, rate = 2.0},
}
const BALLROOM := "res://startingscene.png" # behind the main menu, and where the opening cutscene begins
const BALLROOM_CUT := 0.935 # how far down that image its wall ends: the floor is drawn from there
const EXPLOSION := "res://enemies/explosion-animation.png" # 9 frames of 112x128
const ARROW := "res://Tiny RPG Character Asset Pack 01 v2.0 -Free Soldier&Orc/Arrow(Projectile)/Arrow01(32x32).png"
const LOKI := "res://png/48x48/lokihelmet.png" # 3x4 sheet of 96x96 frames; rows: down, left, right, up
const CASTLE := "res://nashas_parallax_worlds_free_castle_town_and_dungeon_gate_v1.0/"
const NEON := "res://nashas_parallax_worlds_free_neon_downtown_and_rooftops_v1.0/"
const JUNGLE := "res://nashas_parallax_worlds_free_jungle_temple_and_waterfall_v1.0/"
const NASHA := [["layer_1_sky.png", 0.1], ["layer_2_mountains.png", 0.25], ["layer_3_hills.png", 0.5],
	["layer_4_forest.png", 1.0], ["layer_5_foreground.png", 1.0]] # default parallax layers: [file, scroll speed]
const BACKDROPS := [ # per universe: the places it can look like. ground = where feet stand, as a fraction of screen height
	[{dir = CASTLE + "castle_town/320x180/", ground = 0.82}, {dir = CASTLE + "dungeon_gate/320x180/", ground = 0.9}],
	[{dir = NEON + "neon_downtown/320x180/", ground = 0.93}, {dir = NEON + "neon_rooftops/320x180/", ground = 0.94}],
	[{dir = JUNGLE + "jungle_temple/320x180/", ground = 0.87},
		{dir = JUNGLE + "jungle_waterfall/320x180/", ground = 0.9, anim = "animated_waterfall/layer_3_hills_%d.png"},
		{dir = "res://Underwater_Parallax/", ground = 0.89, music = "res://music/underwater.mp3", layers = [["Sinky_Sub_BG.png", 0.0], ["Sinky_Sub_Ruins_Whale.png", 0.2],
			["Sinky_Sub_Cliffs.png", 0.3], ["Sinky_Sub_GodRays.png", 0.5], ["Sinky_Sub_CloseRockKelp.png", 0.8], ["Sinky_Sub_Floor.png", 1.0]]}],
	[{dir = "res://space_background_pack/Assets/Blue Version/layered/", ground = 0.88, floor = true,
		layers = [["blue-back.png", 0.05], ["blue-stars.png", 0.15]], # props: [file, x, y (screen fractions), scroll speed]
		props = [["prop-planet-big.png", 0.7, 0.18, 0.2], ["prop-planet-small.png", 0.2, 0.3, 0.12],
			["asteroid-1.png", 0.45, 0.5, 0.35], ["asteroid-2.png", 0.9, 0.62, 0.45], ["asteroid-2.png", 0.1, 0.12, 0.3]]}],
]
# [stage x, height above the floor, width]. Each 100px step is within the base jump's 152px reach.
const LEDGES := [Vector3(240, 100, 240), Vector3(540, 200, 240), Vector3(840, 100, 240),
	Vector3(1140, 200, 240), Vector3(1440, 100, 240), Vector3(1940, 100, 240),
	Vector3(2240, 200, 240), Vector3(2540, 100, 240), Vector3(2840, 200, 240), Vector3(3140, 100, 240)]
const PLATFORMS := [ # existing art, cropped to a stone cornice, roof, mossy ledge, or asteroid
	{path = "res://Pixel-Art-Battlegrounds/PNG/Battleground2/Bright/floor.png", region = Rect2(120, 512, 480, 96), edge = Color("d2c494")},
	{path = "res://cyberpunk-street-files/Assets/Version 2/Layers/foreground.png", region = Rect2(488, 24, 62, 16), edge = Color("ff3df0")},
	{path = "res://Pixel-Art-Battlegrounds/PNG/Battleground3/Bright/grass&road.png", region = Rect2(200, 530, 480, 96), edge = Color("7fb66b")},
	{path = "res://space_background_pack/Assets/Blue Version/layered/asteroid-1.png", region = Rect2(0, 0, 32, 27), edge = Color("6dff5a")},
]
const MELEE := { # form: [reach, half-arc in radians, seconds per swing, damage]
	Sword = [70.0, 0.9, 0.5, 40.0], Spear = [140.0, 0.25, 0.5, 50.0], Axe = [80.0, 1.6, 0.9, 85.0],
	Flail = [100.0, PI, 1.0, 55.0], Daggers = [50.0, 0.8, 0.2, 20.0]}
const ELEMENTS := {frost = Color.SKY_BLUE, fire = Color.ORANGE, shock = Color.YELLOW, toxin = Color.LIME_GREEN}
const ABILITIES := [ # the HUD's ability panes: [stat, key, upgrade name (for its icon), cooldown bar colour]
	["blink", "C", "Blink", Color("7df9c0")], ["chrono", "SHIFT", "Chrono Implant", Color("ffd24a")], ["grenade", "Q", "Grenades", Color("ff7a3d")],
	["hack", "E", "Neural Hack", Color("ff3df0")], ["cannon", "R", "Arm Cannon", Color("ff9a3d")], ["gauntlet", "F", "Spell Book", Color("66e0ff")]]
const BEAM := {frost = Color.WHITE, fire = Color.ORANGE, shock = Color.YELLOW, toxin = Color.LIME_GREEN} # Spell Book beam colour per imbued element
const BEAM_PLAIN := Color("66e0ff")
const FONT := "res://gui/PixelifySans.ttf"
const NAME := "CHRONOFRACTURE"
const MAIN := ["New Game", "Options", "Keybinds", "Quit"] # main menu
const KEYS := [["A / D", "move"], ["W / SPACE", "jump"], ["MOUSE", "aim"], ["LEFT CLICK", "shoot"], ["1  2  3", "choose an upgrade"], ["ESC", "pause"]] # the keybinds page; abilities are added from ABILITIES
const BUSES := ["Music", "SFX"] # audio buses, each with a volume slider on the options page
const MUSIC := "res://cyberpunk-street-files/Assets/music/cyberpunk-street.ogg" # main menu and ballroom; each universe names its own track, and a backdrop may override it
const SETTINGS := "user://settings.cfg" # where the volumes are remembered
# The opening cutscene, as seconds from New Game: you walk into the ballroom until walk, a portal tears open at rip and has swallowed you by gone,
# it fills the screen by dark (the run is set up behind it), you have dropped into a universe by land, the title pops at title,
# and from fade to end it fades out while the in-game GUI fades in.
const CINE := {walk = 1.6, rip = 2.6, gone = 4.1, dark = 4.8, land = 5.6, title = 5.8, fade = 7.8, end = 9.0}
const ICON_SHEET := RAVEN + "%dx%d.png" # 16 icons a row, in 16px and 32px versions
const ICONS := { # upgrade name -> (column, row) on the icon sheet
	"Sword": Vector2i(7, 90), "Spear": Vector2i(4, 91), "Axe": Vector2i(9, 91), "Flail": Vector2i(1, 92), "Daggers": Vector2i(3, 90),
	"Crossbow": Vector2i(8, 92), "Orbiting Blade": Vector2i(15, 93), "Tower Shield": Vector2i(6, 134), "Plate Armor": Vector2i(0, 120),
	"Whetstone": Vector2i(15, 41), "Twin Blaster": Vector2i(4, 61), "Overclock": Vector2i(0, 64), "Thrusters": Vector2i(10, 55),
	"Rail Rounds": Vector2i(9, 64), "Chrono Implant": Vector2i(12, 20), "Arm Cannon": Vector2i(8, 62), "Grenades": Vector2i(11, 47),
	"Neural Hack": Vector2i(9, 67), "Blink": Vector2i(12, 41), "Nova": Vector2i(6, 65), "Seeker Bolts": Vector2i(5, 61),
	"Soul Leech": Vector2i(2, 41), "Spell Book": Vector2i(3, 18), "Frost Imbue": Vector2i(13, 63), "Fire Imbue": Vector2i(13, 62),
	"Shock Imbue": Vector2i(13, 64), "Toxin Imbue": Vector2i(1, 45)}
const MENU := ["Resume", "Jump to Loki (testing)", "Restart run", "Quit"] # pause menu
const BANES := {volatile = Color.ORANGE, vampiric = Color.RED, berserker = Color.YELLOW}
const DROP := 0.05 # chance an enemy drops a health pack
const HEAL := 0.1 # share of max health a pack restores
const PACK_LIFE := 5.0 # seconds a pack lasts on the ground
const HEART := Vector2i(2, 41) # the health pack's icon on the 32px sheet
const SHIFT := 0.8 # seconds a dimension shift takes to close, and again to open
const MASTERY := 1.08 # damage multiplier compounding per wave cleared in the current universe
const SCREENS := {
	over = "GAME OVER\n\nThe timeline rejected you.\n\nYour abilities survive, knocked back to level 1.\n\nENTER or click for a new run",
	unbroken = "THE UNBROKEN TIMELINE\n\nYou never died. With the fracture no worse than you found it,\nyou close the multiverse and restore one unified timeline.\n\nENTER or click for a new run",
	guardian = "GUARDIAN OF THE MULTIVERSE\n\nLoki falls, but the realities you crossed still need a keeper.\nYou take his place at the End of Time.\n\nENTER or click for a new run",
}
