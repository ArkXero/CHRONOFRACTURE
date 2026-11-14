extends SceneTree
## Run: Godot --headless --path . --script tests/main_menu.gd

const Data := preload("res://data.gd")

var game
var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)


func action(name: String) -> void:
	var event := InputEventAction.new()
	event.action = name
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	for node in [game, game.get_node("Combat"), game.get_node("Hud"), game.get_node("Title")]:
		node.set_process(false)
	var combat = game.get_node("Combat")
	var title = game.get_node("Title")
	var hud = game.get_node("Hud")
	var entry := Data.MENU.find("Main Menu")
	check(entry >= 0, "pause menu offers Main Menu")
	if entry >= 0:
		for phase in ["play", "pick", "shift", "over", "unbroken", "guardian"]:
			game.new_run(false, 0)
			game.start_wave()
			game.phase = phase
			game.gui = 1.0
			game.paused = true
			game.menu = entry
			combat.charge = 1.0
			combat.pickups.append({pos = Vector2.ZERO, vy = 0.0, t = 5.0})
			action("ui_accept")
			check(game.phase == "menu" and not game.paused, "Main Menu returns from %s without leaking Enter into New Game" % phase)
			check(game.gui == 0.0 and combat.enemies.is_empty() and combat.pickups.is_empty() and combat.charge == 0.0, "returning from %s clears the run's visible effects" % phase)
			title._process(0.1)
			hud._process(0.1)
			check(title.visible and hud.modulate.a == 0.0 and title.page == "main", "title is visible and HUD is hidden after leaving %s" % phase)
		game.begin()
		game._process(9.1)
		check(game.phase == "play" and not game.boss and not combat.enemies.is_empty(), "New Game works after returning to the menu")

	for phase in ["over", "unbroken", "guardian"]:
		game.new_run(false, 0)
		game.phase = phase
		game.gui = 1.0
		check(hud.has_method("main_rect"), "ending %s has a Main Menu button" % phase)
		if hud.has_method("main_rect"):
			var button: Rect2 = hud.call("main_rect")
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.position = root.get_final_transform() * button.get_center()
			Input.parse_input_event(click)
			Input.flush_buffered_events()
			check(game.phase == "menu", "clicking Main Menu on %s returns instead of restarting" % phase)

	if entry >= 0:
		root.size = Vector2i(960, 540)
		for i in Data.MENU.size():
			var button: Rect2 = hud.menu_rect(i)
			check(button.position.y >= 0 and button.end.y <= 540, "pause button %d stays inside the viewport" % i)

	print("%d checks, %d failures" % [checks, failures])
	game.free()
	quit(1 if failures else 0)
