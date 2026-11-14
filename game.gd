extends Node2D
## The rules of a run: global waves, fracture, rebirth, Paradox, upgrade picks, endings.

const Data := preload("res://data.gd")

var phase := "menu" # menu, cine, play, pick, shift, taunt, finale, fallen, over, unbroken, guardian
var scene := 0.0 # seconds into the current pick, taunt (Loki speaks), finale (Loki dies) or fallen (he beat you) phase
var cine := 0.0 # seconds into the opening cutscene (phase "cine"); its beats are Data.CINE
var gui := 0.0 # how solid the in-game GUI is: it fades in as the opening ends
var waves := 0 # completed global waves
var universe := 0
var local := 0 # waves cleared since entering this universe: fracture counter and mastery level
var paradox := 0 # successful rebirths
var boss := false
var loadout := {} # upgrade name -> level
var admin := {} # upgrade name -> levels handed to every new run by the admin panel on the options page
var choices := []
var toast := ""
var toast_t := 0.0
var shift := 0.0 # seconds into a dimension shift (phase "shift"): the rift closes for SHIFT, swaps worlds, then opens
var dest := 0 # where the shift leads: a universe, or -1 for the End of Time
var paused := false
var menu := 0 # highlighted pause menu entry

@onready var combat = $Combat
@onready var hud = $Hud


func begin() -> void: # New Game on the main menu: play the opening, which drops you into a fresh run
	dest = randi() % 3
	cine = 0.0
	phase = "cine"


func fronted() -> bool: # the main menu or the ballroom fills the screen: there is no run to show yet
	return phase == "menu" or (phase == "cine" and cine < Data.CINE.dark)


func new_run(keep := false, to := randi() % 3) -> void: # keep: carry the last run's upgrades over, each knocked back to level 1
	var kept: Array = loadout.keys() if keep else []
	waves = 0
	paradox = 0
	boss = false
	loadout.clear()
	combat.reset()
	for pool in Data.UPGRADES:
		for up in pool:
			if up[0] in kept:
				combat.stats[up[2]] += up[3]
				loadout[up[0]] = 1
				if up[0] in Data.MELEE:
					combat.stats.form = up[0]
			for n in admin.get(up[0], 0):
				gain(up)
	enter(to)


func enter(u: int) -> void:
	universe = u
	local = 0
	combat.hp = combat.stats.maxhp
	combat.arrive()


func warp(to: int) -> void: # begin a dimension shift
	dest = to
	shift = 0.0
	phase = "shift"


func start_wave() -> void:
	if waves == 10 and not boss: # Loki waits in another dimension
		warp(-1)
		return
	boss = waves == 10
	phase = "play"
	if boss:
		say("THE END OF TIME: Loki permits no rebirth. Death here is final.")
	combat.spawn()


func clear_wave() -> void:
	if boss:
		phase = "unbroken" if paradox == 0 else "guardian"
		return
	waves += 1
	local += 1
	if local == 2:
		say("STABILIZED: death here now means rebirth, not the end")
	if waves % 2 == 0:
		phase = "pick" # the Sword comes first; other melee forms are only offered once you have one
		scene = 0.0
		var armed: bool = combat.stats.melee > 0
		choices = Data.UPGRADES[universe].filter(func(up): return not up[0] in Data.MELEE or (up[0] == "Sword") != armed)
		choices.shuffle()
		choices.resize(3)
	else:
		start_wave()


func die() -> void:
	if boss or local < 2:
		phase = "fallen" if boss else "over" # Loki's own game over only leads back to the main menu
		scene = 0.0
		return
	paradox += 1
	warp((universe + randi_range(1, 2)) % 3) # a random *other* universe


func taunt() -> void: # the fight holds still while Loki speaks
	phase = "taunt"
	scene = 0.0


func finale() -> void: # Loki is beaten: his death plays out before the ending
	phase = "finale"
	scene = 0.0


func take(up: Array) -> void: # an upgrade picked between waves
	gain(up)
	start_wave()


func gain(up: Array) -> void: # one more level of an upgrade
	var stats: Dictionary = combat.stats
	stats[up[2]] += up[3]
	if up[0] in Data.MELEE: # a new form replaces the old one and keeps its level
		loadout.erase(stats.form)
		stats.form = up[0]
		loadout[up[0]] = stats.melee
	else:
		loadout[up[0]] = loadout.get(up[0], 0) + 1
	if up[2] == "maxhp":
		combat.hp = stats.maxhp


func uni() -> Dictionary:
	return Data.UNIVERSES[3 if boss else universe]


func say(text: String) -> void:
	toast = text
	toast_t = 4.0


func main_menu() -> void:
	phase = "menu"
	gui = 0.0
	paused = false
	toast_t = 0.0
	combat.clear()
	combat.pickups.clear()
	combat.charge = 0.0
	$Title.page = "main"
	$Title.pick = 0
	$Title.grab = -1


func choose(i: int) -> void: # a pause menu entry
	paused = false
	match i:
		1: # testing shortcut: straight to the boss with whatever loadout you have
			if phase in Data.SCREENS:
				new_run()
			waves = 10
			start_wave()
		2:
			new_run()
			start_wave()
		3:
			main_menu()
		4:
			get_tree().quit()


func _process(d: float) -> void:
	if paused:
		return
	toast_t -= d
	if phase in ["pick", "taunt", "finale", "fallen"]:
		var before := scene
		scene += d
		if phase == "taunt" and scene >= Data.TAUNT_TIME:
			phase = "play"
		elif phase == "finale":
			if before < Data.FINALE.burst and scene >= Data.FINALE.burst: # hidden in the flash: only his crown is left
				combat.vanish()
			if scene >= Data.FINALE.end:
				clear_wave()
	if phase == "cine":
		var beat: Dictionary = Data.CINE
		var before := cine
		cine += d
		if before < beat.dark and cine >= beat.dark: # hidden inside the portal: set up the run where it spits you out
			new_run(false, dest)
		if cine >= beat.dark: # you drop out of the sky into the new world
			var fall := clampf((cine - beat.dark) / (beat.land - beat.dark), 0, 1)
			combat.pos.y = combat.ground() - combat.HALF - 420 * (1 - fall * fall)
			combat.vel_y = combat.JUMP if fall < 1 else 0.0
		gui = clampf((cine - beat.fade) / (beat.end - beat.fade), 0, 1)
		if cine >= beat.end:
			start_wave()
	if phase == "shift":
		var before := shift
		shift += d
		if before < Data.SHIFT and shift >= Data.SHIFT: # hidden behind the closed rift: swap worlds
			combat.clear()
			combat.pickups.clear()
			if dest < 0:
				boss = true
			else:
				universe = dest
				local = 0
				combat.hp = combat.stats.maxhp
				combat.arrive()
		elif shift >= Data.SHIFT * 2:
			if dest >= 0:
				say("REBIRTH into %s   ·   Paradox %d: enemies grow stronger   ·   mastery lost" % [uni().name, paradox])
			start_wave()


func _input(ev: InputEvent) -> void:
	if phase == "menu": # title.gd runs the main menu
		return
	if phase == "cine": # ENTER or ESC skips the opening
		if ev.is_action_pressed("ui_accept") or ev.is_action_pressed("ui_cancel"):
			if cine < Data.CINE.dark:
				new_run(false, dest)
			cine = Data.CINE.end
		return
	if phase == "fallen": # beaten by Loki: the only way on is back to the main menu
		var click: bool = ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and hud.main_rect().has_point(ev.position)
		if scene > 1.0 and (click or ev.is_action_pressed("ui_accept")):
			main_menu()
			get_viewport().set_input_as_handled()
		return
	if ev.is_action_pressed("ui_cancel"):
		paused = not paused
		menu = 0
		return
	if paused:
		var count := Data.MENU.size()
		if ev.is_action_pressed("ui_down"):
			menu = (menu + 1) % count
		elif ev.is_action_pressed("ui_up"):
			menu = (menu + count - 1) % count
		elif ev.is_action_pressed("ui_accept"):
			choose(menu)
		elif ev is InputEventMouse:
			for i in count:
				if hud.menu_rect(i).has_point(hud.get_global_mouse_position()):
					menu = i
					if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
						choose(i)
		get_viewport().set_input_as_handled()
		return
	if phase in Data.SCREENS and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and hud.main_rect().has_point(ev.position):
		main_menu()
		get_viewport().set_input_as_handled()
		return
	if phase in Data.SCREENS and (ev.is_action_pressed("ui_accept") or (ev is InputEventMouseButton and ev.pressed)):
		new_run(phase == "over") # after a death, abilities come back at level 1
		start_wave()
	elif phase == "pick" and ev is InputEventKey and ev.pressed and ev.physical_keycode in [KEY_1, KEY_2, KEY_3]:
		take(choices[ev.physical_keycode - KEY_1])
	elif phase == "pick" and scene > 0.4 and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: # the short wait keeps a click meant for the fight from choosing
		for i in 3:
			if hud.pick_rect(i).has_point(ev.position):
				take(choices[i])
				break
	elif phase == "taunt" and ev is InputEventKey and ev.pressed and ev.physical_keycode == KEY_ENTER: # ENTER cuts Loki short
		phase = "play"
