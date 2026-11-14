extends SceneTree
## Run: Godot --headless --path . --script tests/platforms_flying.gd

const Data := preload("res://data.gd")

var game
var combat
var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func stage(u := 0) -> void:
	game.boss = false
	game.new_run(false, u)
	game.start_wave()
	game.gui = 1.0
	combat.hp = 100000.0
	# Keep a real spawned enemy alive far away so physics checks cannot clear a wave.
	combat.enemies.resize(1)
	combat.enemies[0].pos = Vector2(3400, combat.ground() - 28)
	combat.enemies[0].spd = 0.0
	combat.enemies[0].rate = INF
	combat.enemies[0]["fly"] = false


func press(key: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = down
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for node in [game, game.get_node("Combat"), game.get_node("Hud"), game.get_node("Title")]:
		node.set_process(false)
	combat = game.get_node("Combat")
	seed(73)

	stage()
	var floor_y: float = combat.ground()
	combat.pos = Vector2(340, floor_y - 170)
	combat.vel_y = 400.0
	combat._process(0.1)
	check(is_equal_approx(combat.pos.y + 30, floor_y - 100), "falling player lands on the first raised platform")
	check(combat.vel_y == 0.0, "landing stops downward velocity")
	combat._process(0.05)
	check(is_equal_approx(combat.pos.y + 30, floor_y - 100), "player stays supported on a platform")

	stage()
	floor_y = combat.ground()
	combat.pos = Vector2(340, floor_y - 120)
	combat.vel_y = -500.0
	combat._process(0.1)
	check(combat.pos.y + 30 < floor_y - 100 and combat.vel_y < 0, "jump passes through the underside of a platform")

	stage()
	floor_y = combat.ground()
	combat.pos = Vector2(340, floor_y - 130)
	press(KEY_SPACE, true)
	combat._process(0.05)
	check(combat.vel_y < 0, "jump works while standing on a raised platform")
	press(KEY_SPACE, false)
	combat.pos = Vector2(510, floor_y - 130)
	combat.vel_y = 0.0
	combat._process(0.1)
	check(combat.pos.y + 30 > floor_y - 100, "walking off a ledge starts a fall")
	combat.vel_y = 1600.0
	combat._process(0.2)
	check(is_equal_approx(combat.pos.y + 30, floor_y), "player lands on the floor after leaving a ledge")

	# Exercise full trajectories with real input, not only hand-positioned landing checks.
	stage()
	floor_y = combat.ground()
	combat.pos = Vector2(220, floor_y - 30)
	press(KEY_D, true)
	press(KEY_SPACE, true)
	combat._process(0.016)
	press(KEY_SPACE, false)
	for i in 44:
		combat._process(0.016)
	press(KEY_D, false)
	check(is_equal_approx(combat.pos.y + 30, floor_y - 100), "base jump reaches a lower platform from the floor")
	combat.pos = Vector2(460, floor_y - 130)
	press(KEY_D, true)
	press(KEY_SPACE, true)
	combat._process(0.016)
	press(KEY_SPACE, false)
	for i in 44:
		combat._process(0.016)
	press(KEY_D, false)
	check(is_equal_approx(combat.pos.y + 30, floor_y - 200), "base jump crosses the gap from a lower platform to an upper one")
	combat.pos = Vector2(340, floor_y - 280)
	combat.vel_y = 1400.0
	combat._process(0.2)
	check(is_equal_approx(combat.pos.y + 30, floor_y - 100), "fast falls cannot tunnel through a platform")

	stage()
	floor_y = combat.ground()
	combat.pos.x = 1000
	combat.pickups.append({pos = Vector2(340, floor_y - 140), vy = 400.0, t = 5.0})
	combat._process(0.1)
	check(is_equal_approx(combat.pickups[0].pos.y + 18, floor_y - 100), "health drops land on platforms")

	for u in 4:
		stage(mini(u, 2))
		if u == 3:
			game.waves = 10
			game.start_wave()
			game._process(0.81)
			game._process(0.81)
		else:
			game.start_wave()
		var flyers: Array = combat.enemies.filter(func(e): return e.get("fly", false))
		check(combat.art(Data.PLATFORMS[u].path) != null, "dimension %d loads its platform art from the root project" % u)
		check(not flyers.is_empty(), "dimension %d spawns a flying enemy" % u)
		check(combat.has_method("platforms"), "dimension %d supplies raised platforms" % u)
		if combat.has_method("platforms"):
			var ledges: Array = combat.call("platforms")
			check(ledges.size() >= 4, "dimension %d has multiple raised platforms" % u)
			for p in ledges:
				check(p.position.y > 60 and p.position.y < combat.ground(), "platform stays visible above the floor")
		if flyers.is_empty():
			continue
		var foe: Dictionary = flyers[0]
		var sprite: Dictionary = Data.SPRITES[foe.kind]
		var path: String = sprite.path if sprite.has("region") else sprite.path + sprite.anims.Walk[0]
		check(combat.art(path) != null, "dimension %d loads its flying sprite" % u)
		combat.pos = Vector2(foe.pos.x + 80, combat.ground() - 260)
		foe.pos.y = combat.ground() - 90
		var before: float = foe.pos.y
		combat._process(0.1)
		check(foe.pos.y < before, "flyer pursues a player above it in dimension %d" % u)
		if u == 1:
			foe.pos.y = combat.ground() - 90
			foe.slow = 0.0
			combat._process(0.1)
			var normal: float = combat.ground() - 90 - foe.pos.y
			foe.pos.y = combat.ground() - 90
			foe.slow = 3.0
			combat._process(0.1)
			check(is_equal_approx(combat.ground() - 90 - foe.pos.y, normal * 0.4), "frost slows flying movement")
			foe.pos.y = combat.ground() - 90
			foe.slow = 0.0
			combat.stats.chrono = 1
			combat.cd.chrono = 12.0
			combat._process(0.1)
			check(is_equal_approx(combat.ground() - 90 - foe.pos.y, normal * 0.3), "Chrono Implant slows flying movement")
			var frozen: Vector2 = foe.pos
			game.paused = true
			combat._process(1.0)
			check(foe.pos == frozen, "pause freezes flying movement")
			game.paused = false
			combat.pos.x = 30
			foe.pos.x = -70
			combat._process(0.1)
			check(foe.pos.x >= foe.r, "ranged flyers cannot retreat beyond the left stage edge")
			combat.pos.x = 3570
			foe.pos.x = 3670
			combat._process(0.1)
			check(foe.pos.x <= 3600 - foe.r, "ranged flyers cannot retreat beyond the right stage edge")
		combat.hit(foe, 1000000.0)
		combat._process(0.02)
		check(not combat.enemies.has(foe), "flying enemies can be killed in dimension %d" % u)

	# Boss helpers must not prevent the ending once Loki dies.
	var chief = combat.enemies.filter(func(e): return e.boss)
	if not chief.is_empty():
		chief[0].hp = 0
		combat._process(0.02)
		check(game.phase == "unbroken", "defeating Loki finishes the run even with flyers alive")
	game.new_run(false, 0)
	check(not game.boss, "restarting after Loki returns to a regular dimension")

	# Rebirth changes the platform theme and enemy pool while keeping the global wave.
	stage()
	game.waves = 3
	game.warp(1)
	game._process(0.81)
	game._process(0.81)
	check(game.universe == 1 and game.waves == 3 and game.phase == "play", "rebirth rebuilds the destination stage and resumes the wave")
	check(combat.enemies.any(func(e): return e.get("fly", false)), "rebirth spawns the destination's flying enemies")
	root.size = Vector2i(960, 540)
	var ledges: Array = combat.call("platforms")
	check(is_equal_approx(ledges[0].position.y, combat.ground() - 100), "platforms follow the floor when the viewport resizes")

	print("%d checks, %d failures" % [checks, failures])
	game.free()
	quit(1 if failures else 0)
