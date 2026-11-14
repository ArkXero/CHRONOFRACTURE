extends Node2D
## Everything drawn over the stage: health bar, ability panes, Loki's health, upgrade picks, pause menu and ending screens.

const Data := preload("res://data.gd")
const SLOT := 64.0 # ability pane size on screen (32px art at 2x)
const HORN := ["..##....", ".##.....", "##......", "##......", "###.....", ".####...", "..######"] # one of Loki's horns, as pixels
const GOLD := Color("e8b923")
const NAME := ["#.....###..#...#.#####", "#....#...#.#..#....#..", "#....#...#.###.....#..", "#....#...#.#..#....#..", "#####.###..#...#.#####"] # LOKI, as pixels

var panel := StyleBoxTexture.new()
var lag := 1.0 # Loki's health as shown a moment ago: the pale sliver that drains after a hit

@onready var game = get_parent()
@onready var combat = $"../Combat"
@onready var slot: Texture2D = load("res://gui/slot.png") # 5 frames of 32x32: plain, orange, yellow, red, dim
@onready var button: Texture2D = load("res://gui/button.png") # 4 frames of 96x24: plain, lit, pressed, dim
@onready var bar: Texture2D = load("res://gui/bar.png")
@onready var header: Texture2D = load("res://gui/header.png")
@onready var font: Font = load(Data.FONT)
@onready var icons := {16: load(Data.ICON_SHEET % [16, 16]), 32: load(Data.ICON_SHEET % [32, 32])}


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	panel.texture = load("res://gui/panel.png")
	panel.set_texture_margin_all(24)


func _process(d: float) -> void:
	queue_redraw()
	modulate.a = game.gui
	var loki = boss()
	lag = 1.0 if loki == null else maxf(loki.hp / loki.max, lag - 0.25 * d)


func boss(): # Loki while he is on stage, else null
	for e in combat.enemies:
		if e.boss:
			return e
	return null


func menu_rect(i: int) -> Rect2: # where pause menu entry i sits; game.gd uses this for mouse picking
	var size := get_viewport_rect().size
	return Rect2(size.x / 2 - 144, size.y / 2 - 110 + i * 80, 288, 72)


func _draw() -> void:
	var size := get_viewport_rect().size
	var center := HORIZONTAL_ALIGNMENT_CENTER
	if game.gui <= 0: # the main menu and the opening: no run to report on yet
		return
	if game.phase in Data.SCREENS:
		text(Vector2(0, size.y * 0.25), Data.SCREENS[game.phase] + "\n\nESC: menu", center, size.x, 22)
	else:
		draw_health(size)
		draw_abilities(size)
		var loki = boss()
		if loki != null:
			draw_loki_bar(size, clampf(loki.hp / loki.max, 0, 1))
		if game.phase == "pick":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.75))
			var offer := "WAVE %d CLEARED: choose one %s upgrade" % [game.waves, game.uni().name]
			text(Vector2(0, size.y * 0.22), offer, center, size.x, 22)
			for i in 3: # one row per choice: icon in a pane, then name and what it does
				var up: Array = game.choices[i]
				var lvl: int = game.loadout.get(up[0], 0)
				var at := Vector2(size.x / 2 - 330, size.y * 0.22 + 44 + i * 100)
				draw_texture_rect_region(slot, Rect2(at, Vector2(80, 80)), Rect2(32, 0, 32, 32))
				icon(up[0], at + Vector2(8, 8), 32, 2)
				text(at + Vector2(100, 32), "[%d]  %s  (%s)" % [i + 1, up[0], "Lv %d > %d" % [lvl, lvl + 1] if lvl else "new"], HORIZONTAL_ALIGNMENT_LEFT, 560, 22, Color.GOLD)
				text(at + Vector2(100, 58), up[1], HORIZONTAL_ALIGNMENT_LEFT, 560, 16)
		if game.toast_t > 0:
			text(Vector2(0, size.y * 0.31), game.toast, center, size.x, 20, Color.GOLD)
		if game.phase == "shift":
			draw_shift(size)
	if game.paused:
		draw_menu(size)


func draw_health(size: Vector2) -> void: # top middle, with the round counter under it
	var at := Vector2(roundf(size.x / 2 - 142), 6)
	draw_rect(Rect2(at + Vector2(18, 21), Vector2(249, 15)), Color(0.08, 0.04, 0.12))
	draw_rect(Rect2(at + Vector2(18, 21), Vector2(249 * clampf(combat.hp / combat.stats.maxhp, 0, 1), 15)), Color.CRIMSON)
	draw_texture_rect(bar, Rect2(at, Vector2(285, 51)), false)
	text(at + Vector2(0, 68), "FINAL ROUND" if game.boss else "ROUND %d / 10" % mini(game.waves + 1, 10), HORIZONTAL_ALIGNMENT_CENTER, 285, 14)


func draw_abilities(size: Vector2) -> void: # top left: one pane per ability, with a bar through it while it cools down
	var stats: Dictionary = combat.stats
	for i in Data.ABILITIES.size():
		var a: Array = Data.ABILITIES[i]
		var at := Vector2(16 + i * (SLOT + 4), 12)
		var owned: bool = stats[a[0]] > 0
		var left: float = maxf(combat.cd.get(a[0], 0.0), 0) / combat.cdmax.get(a[0], 1.0) if owned else 0.0 # share of the cooldown still to run
		var live: bool = (a[0] == "chrono" and combat.slowmo()) or (a[0] == "gauntlet" and combat.charge > 0)
		draw_texture_rect_region(slot, Rect2(at, Vector2(SLOT, SLOT)), Rect2((2 if live else 0 if owned else 4) * 32, 0, 32, 32))
		if owned:
			icon(a[2], at + Vector2(8, 8), 16, 3, Color(1, 1, 1, 0.35 if left > 0 else 1.0))
		if left > 0: # cooldown bar, shrinking to nothing
			draw_rect(Rect2(at + Vector2(4, 26), Vector2(SLOT - 8, 12)), Color(0, 0, 0, 0.75))
			draw_rect(Rect2(at + Vector2(6, 28), Vector2((SLOT - 12) * minf(left, 1), 8)), a[3])
		elif a[0] == "gauntlet" and combat.charge > 0: # the Spell Book has no cooldown: its bar shows the charge instead
			draw_rect(Rect2(at + Vector2(4, 26), Vector2(SLOT - 8, 12)), Color(0, 0, 0, 0.75))
			draw_rect(Rect2(at + Vector2(6, 28), Vector2((SLOT - 12) * combat.charge / 1.5, 8)), combat.beam_tint())
		text(at + Vector2(-8, SLOT + 16), a[1], HORIZONTAL_ALIGNMENT_CENTER, SLOT + 16, 13, Color.WHITE if owned else Color(1, 1, 1, 0.4))


func draw_loki_bar(size: Vector2, part: float) -> void: # hand-drawn on a 4px grid: gold frame, horns, emerald health in ten cells
	var p := 4.0
	var w := floorf(size.x * 0.5 / p) * p
	var at := Vector2(roundf((size.x - w) / 2), 138) # top middle, below your own health and the round counter
	draw_rect(Rect2(at - Vector2(3, 3) * p, Vector2(w, 0) + Vector2(6, 10) * p), Color("120a1c"))
	draw_rect(Rect2(at - Vector2(2, 2) * p, Vector2(w, 0) + Vector2(4, 8) * p), GOLD)
	draw_rect(Rect2(at - Vector2(2, -5) * p, Vector2(w, 0) + Vector2(4, 1) * p), Color("9c6b12")) # shaded lower edge
	draw_rect(Rect2(at - Vector2(1, 1) * p, Vector2(w, 0) + Vector2(2, 6) * p), Color("120a1c"))
	draw_rect(Rect2(at, Vector2(w, 4 * p)), Color("0b2a1a"))
	var low := part < 0.3 and int(Time.get_ticks_msec() / 150) % 2 == 0 # flickers red when nearly beaten
	draw_rect(Rect2(at, Vector2(floorf(w * lag / p) * p, 4 * p)), Color("f4f1c9"))
	draw_rect(Rect2(at, Vector2(floorf(w * part / p) * p, 4 * p)), Color("c8323c") if low else Color("1fae4f"))
	draw_rect(Rect2(at, Vector2(floorf(w * part / p) * p, p)), Color("ff8a80") if low else Color("7dffa0")) # highlight row
	draw_rect(Rect2(at + Vector2(0, 3 * p), Vector2(floorf(w * part / p) * p, p)), Color("7a1620") if low else Color("0f7a3a")) # shadow row
	for i in range(1, 10):
		draw_rect(Rect2(at + Vector2(floorf(w * i / 10 / p) * p, 0), Vector2(p, 4 * p)), Color("120a1c"))
	for side in [-1.0, 1.0]: # a horn curling up from each end
		var root := at + Vector2(-3 * p if side < 0 else w + 3 * p, 5 * p)
		for y in HORN.size():
			for x in 8:
				if HORN[y][x] == "#":
					var cell := Vector2(root.x + (x - 8) * p if side < 0 else root.x + (7 - x) * p, root.y + (y - 7) * p)
					draw_rect(Rect2(cell + Vector2(0, p), Vector2(p, p)), Color("120a1c"))
					draw_rect(Rect2(cell, Vector2(p, p)), GOLD if y > 1 else Color("fff3b0"))
	draw_rect(Rect2(at + Vector2(w / 2 - 3 * p, -3 * p), Vector2(6, 3) * p), Color("120a1c")) # centre gem
	draw_rect(Rect2(at + Vector2(w / 2 - 2 * p, -3 * p), Vector2(4, 2) * p), Color("1fae4f"))
	draw_rect(Rect2(at + Vector2(w / 2 - 2 * p, -3 * p), Vector2(2, 1) * p), Color("7dffa0"))


	var face: Texture2D = combat.art(Data.LOKI) # his head from the front-facing frame, then his name in pixels
	var left := roundf(size.x / 2 - (48 + 12 + NAME[0].length() * p) / 2)
	draw_texture_rect_region(face, Rect2(left, at.y - 54, 48, 42), Rect2(120, 6, 48, 42))
	for y in NAME.size():
		for x in NAME[y].length():
			if NAME[y][x] == "#":
				var cell := Vector2(left + 60 + x * p, at.y - 36 + y * p)
				draw_rect(Rect2(cell + Vector2(p, p), Vector2(p, p)), Color("0f7a3a")) # emerald drop shadow
				draw_rect(Rect2(cell, Vector2(p, p)), Color("fff3b0") if y == 0 else GOLD if y < 4 else Color("9c6b12"))


func draw_shift(size: Vector2) -> void: # a rift irises shut on the player, the destination is named in the dark, then it opens on the new world
	var closed := 1 - absf(game.shift - Data.SHIFT) / Data.SHIFT # 0 open .. 1 shut .. 0 open
	var hole := (1 - ease(closed, 0.5)) * size.length() * 0.6
	var eye: Vector2 = combat.pos - Vector2(combat.cam, 0)
	var to: Dictionary = Data.UNIVERSES[3 if game.dest < 0 else game.dest]
	var spin: float = game.shift * 5
	for i in 14: # static: bands of the destination's colour tearing across the screen
		var y := fposmod(sin(i * 91.7 + floorf(game.shift * 24) * 13.1) * 43758.5, 1.0) * size.y
		draw_rect(Rect2(0, floorf(y / 4) * 4, size.x, 4 + i % 3 * 4), Color(to.col, 0.35 * closed))
	draw_arc(eye, hole + size.length(), 0, TAU, 96, Color("07030f"), size.length() * 2) # everything outside the hole
	for i in 3: # the rift's rim: broken arcs turning against each other
		var r := hole + 6 + i * 10
		for j in 6:
			var a: float = spin * (1 if i % 2 == 0 else -1) + j * TAU / 6 + i
			draw_arc(eye, r, a, a + 0.7, 12, Color.WHITE if i == 0 else Color(to.col, 0.9 - i * 0.25), 6 - i)
	for j in 10: # shards flung off the rim
		var a: float = j * TAU / 10 - spin * 0.6
		var far: float = hole + 30 + fposmod(game.shift * 220 + j * 37, 90)
		draw_line(eye + Vector2.from_angle(a) * (hole + 24), eye + Vector2.from_angle(a) * far, Color(to.col, 0.7), 4)
	if closed > 0.55:
		var fade := clampf((closed - 0.55) / 0.2, 0, 1)
		text(Vector2(0, size.y / 2 - 30), "THE TIMELINE COLLAPSES" if game.dest < 0 else "REBIRTH", HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(1, 1, 1, fade * 0.8))
		text(Vector2(0, size.y / 2 + 24), to.name, HORIZONTAL_ALIGNMENT_CENTER, size.x, 48, Color(to.col, fade))


func icon(upgrade: String, at: Vector2, px: int, zoom: int, tone := Color.WHITE) -> void: # an upgrade's icon from the 16px or 32px sheet
	draw_texture_rect_region(icons[px], Rect2(at, Vector2(px, px) * zoom), Rect2(Vector2(Data.ICONS[upgrade]) * px, Vector2(px, px)), tone)


func draw_menu(size: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7))
	var top := menu_rect(0).position
	box(Rect2(top.x - 48, top.y - 96, 384, 96 + Data.MENU.size() * 80 + 64), 4.0)
	draw_texture_rect(header, Rect2(size.x / 2 - 144, top.y - 122, 288, 96), false)
	text(Vector2(0, top.y - 66), "PAUSED", HORIZONTAL_ALIGNMENT_CENTER, size.x, 22)
	for i in Data.MENU.size():
		var r := menu_rect(i)
		draw_texture_rect_region(button, r, Rect2(96 if i == game.menu else 288, 0, 96, 24))
		text(Vector2(r.position.x, r.position.y + 43), Data.MENU[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 17, Color.WHITE if i == game.menu else Color(1, 1, 1, 0.75))
	text(Vector2(0, top.y + Data.MENU.size() * 80 + 22), "A/D move  ·  W/SPACE jump  ·  mouse aim  ·  click shoot  ·  ESC resume", HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Color(1, 1, 1, 0.7))


func box(r: Rect2, zoom := 3.0) -> void: # a nine-slice panel from the GUI pack
	draw_set_transform(r.position, 0, Vector2(zoom, zoom))
	draw_style_box(panel, Rect2(Vector2.ZERO, r.size / zoom))
	draw_set_transform(Vector2.ZERO)


func text(at: Vector2, body: String, align: HorizontalAlignment, width: float, font_size: int, color := Color.WHITE) -> void: # outlined, so it reads over any backdrop
	draw_multiline_string_outline(font, at, body, align, width, font_size, -1, 6, Color(0, 0, 0, 0.85))
	draw_multiline_string(font, at, body, align, width, font_size, -1, color)
