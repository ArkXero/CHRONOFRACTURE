extends Node2D
## The front of the game: the main menu with its options, admin and keybinds pages, then the opening cutscene that throws you into a run.
## Sound lives here too: the Music and SFX buses, their remembered volumes, the music itself and the menu's blips.

const Data := preload("res://data.gd")
const INK := Color("07030f") # the dark inside a rift
const DUSK := Color(0.06, 0.02, 0.12, 0.6) # dims the ballroom behind the menu
const LIT := Color("ffd24a")
const DIM := Color(1, 1, 1, 0.7)
const UP := {options = ["main", 1], keys = ["main", 2], admin = ["options", 2]} # each page's parent, and the row there that leads to it
const TOP := 9 # the most levels the admin panel hands out of one power

var page := "main" # main, options, admin, keys
var powers := [] # the admin page's grid: [upgrade name, column (its universe), row] for every upgrade
var pick := 0 # highlighted row of the current page
var volume := [0.6, 0.8] # per Data.BUSES, 0..1
var grab := -1 # volume slider the mouse is dragging, else -1
var clock := 0.0
var song := "" # the music track now playing
var panel := StyleBoxTexture.new()
var music := AudioStreamPlayer.new()
var blip := AudioStreamPlayer.new()

@onready var game = get_parent()
@onready var combat = $"../Combat"
@onready var button: Texture2D = load("res://gui/button.png") # 4 frames of 96x24: plain, lit, pressed, dim
@onready var bar: Texture2D = load("res://gui/bar.png")
@onready var header: Texture2D = load("res://gui/header.png")
@onready var font: Font = load(Data.FONT)
@onready var icons: Texture2D = load(Data.ICON_SHEET % [16, 16])


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	panel.texture = load("res://gui/panel.png")
	panel.set_texture_margin_all(24)
	var saved := ConfigFile.new()
	saved.load(Data.SETTINGS) # no file yet just leaves the defaults
	for i in Data.BUSES.size():
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, Data.BUSES[i])
		set_volume(i, saved.get_value("volume", Data.BUSES[i], volume[i]))
	for c in Data.UPGRADES.size():
		for j in Data.UPGRADES[c].size():
			powers.append([Data.UPGRADES[c][j][0], c, j])
	music.bus = Data.BUSES[0]
	blip.stream = tone()
	blip.bus = Data.BUSES[1]
	add_child(music)
	add_child(blip)


func _process(d: float) -> void:
	clock += d
	visible = game.phase in ["menu", "cine"]
	var want: String = Data.MUSIC if game.fronted() else combat.backdrop().get("music", game.uni().music)
	if want == song:
		music.volume_linear = move_toward(music.volume_linear, 1, 2 * d)
	else: # fade the old track out, then start the one this place calls for
		music.volume_linear = move_toward(music.volume_linear, 0, 2 * d)
		if music.volume_linear <= 0 or song == "":
			song = want
			music.stream = load(want)
			music.stream.loop = true
			music.play()
	queue_redraw()


func tone() -> AudioStreamWAV: # a short square-wave blip, made here because the project has no sound files yet
	var wav := AudioStreamWAV.new()
	var data := PackedByteArray()
	for i in 1800: # 8-bit mono at 22.05 kHz: about 80 ms of 440 Hz, fading out
		data.append(int((40 if i % 50 < 25 else -40) * (1 - i / 1800.0)) & 0xFF)
	wav.mix_rate = 22050
	wav.data = data
	return wav


func beep(pitch := 1.0) -> void:
	blip.pitch_scale = pitch
	blip.play()


func set_volume(i: int, v: float) -> void:
	volume[i] = clampf(v, 0, 1)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(Data.BUSES[i]), volume[i])


func save() -> void:
	var file := ConfigFile.new()
	for i in Data.BUSES.size():
		file.set_value("volume", Data.BUSES[i], volume[i])
	file.save(Data.SETTINGS)


func rows() -> int: # main: its buttons; options: a slider per bus, Admin Panel, Back; admin: every power, Clear All, Back; keys: just Back
	return {main = Data.MAIN.size(), options = Data.BUSES.size() + 2, admin = powers.size() + 2, keys = 1}[page]


func dial(i: int) -> bool: # row i is adjusted rather than pressed: a volume slider, or a power on the admin page
	return (page == "options" and i < Data.BUSES.size()) or (page == "admin" and i < powers.size())


func label(i: int) -> String: # what button row i says
	if page == "main":
		return Data.MAIN[i]
	if page == "options" and i == Data.BUSES.size():
		return "Admin Panel"
	if page == "admin" and i == powers.size():
		return "Clear All"
	return "Back"


func rect(i: int) -> Rect2: # where row i of the current page sits: a button, or a volume slider
	var mid := get_viewport_rect().size / 2
	if page == "main":
		return Rect2(mid.x - 144, mid.y - 54 + i * 78, 288, 72)
	if page == "options":
		return Rect2(mid.x - 100, mid.y - 116 + i * 84, 285, 51) if dial(i) else Rect2(mid.x - 144, mid.y + 56 + (i - Data.BUSES.size()) * 78, 288, 72)
	if page == "admin":
		return Rect2(mid.x - 414 + powers[i][1] * 280, mid.y - 196 + powers[i][2] * 34, 268, 32) if dial(i) else Rect2(mid.x - 300 + (i - powers.size()) * 312, mid.y + 160, 288, 72)
	return Rect2(mid.x - 144, mid.y + 128, 288, 72)


func open(to: String) -> void:
	if page == "options":
		save()
	pick = UP[page][1] if page in UP and UP[page][0] == to else 0
	page = to


func grant(i: int, by: int) -> void: # the admin page: one level more or less of power i, for every new run
	var gifts: Dictionary = game.admin
	var power: String = powers[i][0]
	var level: int = gifts.get(power, 0) + by
	if power in Data.MELEE and by > 0: # one weapon form at a time: the new one takes over the levels of the old, as it does in a run
		for form in Data.MELEE:
			if form != power:
				level += gifts.get(form, 0)
				gifts.erase(form)
	gifts[power] = clampi(level, 0, TOP)
	if gifts[power] == 0:
		gifts.erase(power)


func choose(i: int) -> void:
	if page == "main":
		match i:
			0:
				game.begin()
			1:
				open("options")
			2:
				open("keys")
			3:
				get_tree().quit()
	elif page == "admin" and dial(i):
		grant(i, 1)
	elif page == "admin" and i == powers.size():
		game.admin.clear()
	elif page == "options" and i == Data.BUSES.size():
		open("admin")
	elif i == rows() - 1: # Back
		open(UP[page][0])
	else:
		return
	beep(1.5)


func _input(ev: InputEvent) -> void:
	if game.phase != "menu":
		return
	if ev.is_action_pressed("ui_down") or ev.is_action_pressed("ui_up"):
		pick = (pick + (1 if ev.is_action_pressed("ui_down") else rows() - 1)) % rows()
		beep()
	elif dial(pick) and (ev.is_action_pressed("ui_left", true) or ev.is_action_pressed("ui_right", true)):
		var by := 1 if ev.is_action_pressed("ui_right", true) else -1
		if page == "admin":
			grant(pick, by)
		else:
			set_volume(pick, volume[pick] + 0.1 * by)
		beep()
	elif ev.is_action_pressed("ui_accept"):
		choose(pick)
	elif ev.is_action_pressed("ui_cancel") and page != "main":
		open(UP[page][0])
	elif ev is InputEventMouse:
		var mouse := get_global_mouse_position()
		var click: bool = ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT
		if click and not ev.pressed and grab >= 0: # let go of a slider: hear the new level
			grab = -1
			beep()
		for i in rows():
			if rect(i).has_point(mouse):
				pick = i
				if click and ev.pressed:
					if page == "options" and dial(i):
						grab = i
					else:
						choose(i)
				elif page == "admin" and dial(i) and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
					grant(i, -1)
					beep()
				break
		if grab >= 0:
			set_volume(grab, (mouse.x - rect(grab).position.x - 18) / 249)
	else:
		return
	get_viewport().set_input_as_handled() # so the press that starts the game does not also skip the opening


func _draw() -> void:
	var size := get_viewport_rect().size
	if game.phase == "menu":
		draw_ballroom(size)
		draw_rect(Rect2(Vector2.ZERO, size), DUSK)
		draw_menu(size)
	elif game.phase == "cine":
		draw_opening(size)


func draw_menu(size: Vector2) -> void:
	var mid := size / 2
	var left := HORIZONTAL_ALIGNMENT_LEFT
	var hint := "UP / DOWN or mouse  ·  ENTER select"
	if page == "main":
		draw_title(Vector2(mid.x, mid.y - 150), 1.0, 1.0)
		box(Rect2(mid.x - 192, mid.y - 92, 384, 380))
	elif page == "options":
		hint = "LEFT / RIGHT or drag to adjust  ·  ESC back"
		plate(Rect2(mid.x - 300, mid.y - 210, 600, 460), "OPTIONS")
		for i in Data.BUSES.size(): # a volume slider per bus, built from the health bar's frame
			var r := rect(i)
			var tone := Color.WHITE if pick == i else DIM
			text(Vector2(mid.x - 240, r.position.y + 36), Data.BUSES[i].to_upper(), left, -1, 20, tone)
			draw_rect(Rect2(r.position + Vector2(18, 21), Vector2(249, 15)), Color(0.08, 0.04, 0.12))
			draw_rect(Rect2(r.position + Vector2(18, 21), Vector2(249 * volume[i], 15)), LIT if pick == i else Color("c2185b"))
			draw_texture_rect(bar, r, false)
			text(Vector2(r.end.x + 14, r.position.y + 36), "%d%%" % roundi(volume[i] * 100), left, -1, 18, tone)
	elif page == "admin":
		hint = "click or ENTER: one more level  ·  right click or LEFT: one less  ·  every new run starts with these"
		plate(Rect2(mid.x - 440, mid.y - 290, 880, 550), "ADMIN PANEL")
		for c in Data.UPGRADES.size():
			text(Vector2(mid.x - 408 + c * 280, mid.y - 206), Data.UNIVERSES[c].name, left, -1, 13, DIM)
		for i in powers.size(): # every power in the game, a column per universe: lit with its level once granted
			var r := rect(i)
			var level: int = game.admin.get(powers[i][0], 0)
			if pick == i:
				draw_rect(r, Color(1, 1, 1, 0.14))
			draw_texture_rect_region(icons, Rect2(r.position, Vector2(32, 32)), Rect2(Vector2(Data.ICONS[powers[i][0]]) * 16, Vector2(16, 16)), Color.WHITE if level else Color(1, 1, 1, 0.45))
			text(r.position + Vector2(42, 22), powers[i][0], left, -1, 15, LIT if level else DIM)
			if level:
				text(r.position + Vector2(0, 22), "Lv %d" % level, HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 8, 15, LIT)
	else:
		hint = "ESC back"
		var r := Rect2(mid.x - 400, mid.y - 230, 800, 470)
		var y := mid.y - 100
		plate(r, "KEYBINDS")
		text(Vector2(r.position.x + 64, y - 38), "BASICS", left, -1, 13, DIM)
		text(Vector2(mid.x + 10, y - 38), "ABILITIES  ·  unlocked by upgrades", left, -1, 13, DIM)
		for i in Data.KEYS.size():
			text(Vector2(r.position.x + 64, y + i * 34), Data.KEYS[i][0], left, -1, 16, LIT)
			text(Vector2(r.position.x + 194, y + i * 34), Data.KEYS[i][1], left, -1, 16)
		for i in Data.ABILITIES.size():
			var a: Array = Data.ABILITIES[i]
			draw_texture_rect_region(icons, Rect2(mid.x + 10, y + i * 34 - 24, 32, 32), Rect2(Vector2(Data.ICONS[a[2]]) * 16, Vector2(16, 16)))
			text(Vector2(mid.x + 56, y + i * 34), a[1], left, -1, 16, LIT)
			text(Vector2(mid.x + 126, y + i * 34), a[2], left, -1, 16)
	for i in rows():
		if dial(i):
			continue
		var r := rect(i)
		draw_texture_rect_region(button, r, Rect2(96 if i == pick else 288, 0, 96, 24))
		text(Vector2(r.position.x, r.position.y + 43), label(i), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17, Color.WHITE if i == pick else DIM)
	text(Vector2(0, size.y - 12), hint, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, DIM)


func draw_opening(size: Vector2) -> void: # the cutscene, beat by beat (see Data.CINE)
	var t: float = game.cine
	var beat: Dictionary = Data.CINE
	var col: Color = Data.UNIVERSES[game.dest].col # the portal is lit by where it leads
	var full := Rect2(Vector2.ZERO, size)
	if t < beat.dark: # the ballroom
		var omen := clampf((t - beat.rip + 0.7) / 0.7, 0, 1) # the air starts to tear just before the portal opens
		var open := clampf((t - beat.rip) / 0.35, 0, 1) - 1 # -1 shut .. 0 burst open
		var pull := pow(clampf((t - beat.rip) / (beat.gone - beat.rip), 0, 1), 3) # 0 standing .. 1 swallowed: you resist, then go fast
		var swell := clampf((t - beat.gone) / (beat.dark - beat.gone), 0, 1) # then the portal grows to fill the screen
		var quake := (Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 8 * (open + 1)).snappedf(2)
		draw_set_transform(quake)
		var floor_y := draw_ballroom(size)
		draw_set_transform(Vector2.ZERO)
		var gate := Vector2(size.x * 0.68, floor_y - 170) + quake
		var stand := Vector2(size.x * lerpf(0.14, 0.42, minf(t / beat.walk, 1)), floor_y - combat.HALF) + quake
		for i in 14: # static: bands of the destination's colour tearing across the room
			var y := fposmod(sin(i * 91.7 + floorf(clock * 24) * 13.1) * 43758.5, 1.0) * size.y
			draw_rect(Rect2(0, floorf(y / 4) * 4, size.x, 4 + i % 3 * 4), Color(col, 0.3 * omen))
		if t < beat.rip: # a bright seam where it will open
			draw_rect(Rect2(gate.x - 6, gate.y - 70 * omen, 12, 140 * omen), Color(col, 0.5))
			draw_rect(Rect2(gate.x - 2, gate.y - 70 * omen, 4, 140 * omen), Color.WHITE)
		else:
			var r := 96 * (1 + 2.7 * open * open * open + 1.7 * open * open) + 6 * sin(clock * 9) + swell * swell * size.length() # pops open past its size, then settles
			for j in 14: # motes of the room pulled into it
				var near := fposmod(clock * 1.6 + j * 0.31, 1.0)
				draw_rect(Rect2((gate + Vector2.from_angle(j * 2.4 + clock) * (1 - near) * (r + 240)).snappedf(4), Vector2(4, 4)), Color(col, near))
			draw_circle(gate, r, INK)
			for i in 3: # the swirl inside
				draw_arc(gate, r * (0.8 - i * 0.25), clock * (4 + i * 2), clock * (4 + i * 2) + 4, 24, Color(col, 0.55 - i * 0.12), 4)
			rim(gate, r, col)
		draw_set_transform(Vector2(stand.x, floor_y + quake.y), 0, Vector2(1, 0.22)) # your shadow stays on the floor, thinning as you leave it
		draw_circle(Vector2.ZERO, 20, Color(0, 0, 0, 0.35 * (1 - pull)))
		draw_set_transform(Vector2.ZERO)
		if t < beat.rip:
			hero(t < beat.walk, t, stand)
		elif pull < 1: # torn off your feet, legs flailing, spinning and shrinking into the portal
			hero(true, t * 2, stand.lerp(gate, pull) + Vector2(randf_range(-2, 2), 0), 1 - pull, pull * TAU * 3)
		draw_rect(full, Color(1, 1, 1, -0.7 * open if t >= beat.rip else 0.0)) # the flash as it bursts open
		draw_rect(full, Color(DUSK, DUSK.a * (1 - t / 0.5))) # the menu's dusk lifts
	else: # the new world, drawn underneath by combat.gd
		var open := clampf((t - beat.dark) / (beat.land - beat.dark), 0, 1)
		if open < 1: # the rift irises open on where you land
			var eye := Vector2(combat.pos.x - combat.cam, combat.ground() - combat.HALF)
			var hole := open * open * size.length() * 0.75
			draw_arc(eye, hole + size.length(), 0, TAU, 96, INK, size.length() * 2)
			rim(eye, hole, col)
		if t >= beat.title: # the title pops in past full size and settles, then fades as the GUI arrives
			var pop := clampf((t - beat.title) / 0.4, 0, 1) - 1
			draw_rect(full, Color(1, 1, 1, -0.45 * pop))
			draw_title(Vector2(size.x / 2, size.y * 0.42), 1 + 2.7 * pop * pop * pop + 1.7 * pop * pop, 1 - game.gui)


func draw_ballroom(size: Vector2) -> float: # the hall, scaled to cover the screen above a polished floor; returns the floor's y
	var floor_y := roundf(size.y * 0.86)
	var hall: Texture2D = combat.art(Data.BALLROOM)
	var k := 1.03 * maxf(size.x / hall.get_width(), floor_y / (hall.get_height() * Data.BALLROOM_CUT)) # a little oversize, like the floor, so a shake never shows an edge
	draw_texture_rect(hall, Rect2((size.x - hall.get_width() * k) / 2, floor_y - hall.get_height() * Data.BALLROOM_CUT * k, hall.get_width() * k, hall.get_height() * k), false)
	draw_rect(Rect2(-16, floor_y, size.x + 32, size.y - floor_y + 16), Color("2b2338"))
	for i in range(-ceili(size.x / 140), ceili(size.x / 140) + 1): # floorboards running away from the middle
		draw_line(Vector2(size.x / 2 + i * 70, floor_y), Vector2(size.x / 2 + i * 150, size.y), Color(1, 0.8, 0.62, 0.12), 2)
	draw_rect(Rect2(-16, floor_y - 8, size.x + 32, 8), Color("6e4a3c")) # skirting board
	draw_rect(Rect2(-16, floor_y, size.x + 32, 4), Color("f2c9a0")) # the floor's lit edge
	return floor_y


func draw_title(at: Vector2, zoom: float, alpha: float) -> void: # the game's name with a dark outline
	var center := HORIZONTAL_ALIGNMENT_CENTER
	draw_set_transform(at, 0, Vector2(zoom, zoom))
	draw_string_outline(font, Vector2(-600, 0), Data.NAME, center, 1200, 88, 12, Color(INK, alpha))
	draw_string(font, Vector2(-600, 0), Data.NAME, center, 1200, 88, Color(1, 0.96, 0.84, alpha))
	draw_set_transform(Vector2.ZERO)


func rim(eye: Vector2, r: float, col: Color) -> void: # a rift's edge: broken arcs turning against each other, and shards flung off them
	for i in 3:
		for j in 6:
			var a := clock * 5 * (1 if i % 2 == 0 else -1) + j * TAU / 6 + i
			draw_arc(eye, r + 6 + i * 10, a, a + 0.7, 12, Color.WHITE if i == 0 else Color(col, 0.9 - i * 0.25), 6 - i)
	for j in 10:
		var a := j * TAU / 10 - clock * 3
		var far := r + 30 + fposmod(clock * 220 + j * 37, 90)
		draw_line(eye + Vector2.from_angle(a) * (r + 24), eye + Vector2.from_angle(a) * far, Color(col, 0.7), 4)


func hero(striding: bool, t: float, at: Vector2, zoom := 1.0, turn := 0.0) -> void: # you, facing right as combat.gd draws you (at = body centre), but free to spin and shrink
	var k: Dictionary = Data.SPRITES[Data.HERO]
	var col: int = [0, 1, 2, 1][int(t * 8) % 4] if striding else 1
	draw_set_transform(at, turn, Vector2.ONE * k.zoom * zoom)
	draw_texture_rect_region(combat.art(k.sheet), Rect2(-48, combat.HALF / k.zoom - k.feet, 96, 96), Rect2(col * 96, 192, 96, 96))
	draw_set_transform(Vector2.ZERO)


func plate(r: Rect2, title: String) -> void: # a panel with a named header plaque on its top edge
	box(r)
	draw_texture_rect(header, Rect2(r.get_center().x - 144, r.position.y - 26, 288, 96), false)
	text(Vector2(r.position.x, r.position.y + 30), title, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22)


func box(r: Rect2) -> void: # a nine-slice panel from the GUI pack, at 4x
	draw_set_transform(r.position, 0, Vector2(4, 4))
	draw_style_box(panel, Rect2(Vector2.ZERO, r.size / 4))
	draw_set_transform(Vector2.ZERO)


func text(at: Vector2, body: String, align: HorizontalAlignment, width: float, font_size: int, color := Color.WHITE) -> void: # outlined, so it reads over any backdrop
	draw_multiline_string_outline(font, at, body, align, width, font_size, -1, 6, Color(0, 0, 0, 0.85))
	draw_multiline_string(font, at, body, align, width, font_size, -1, color)
