extends Node2D
## The side-scrolling stage: player, enemies, shots and blasts as dictionaries, simulated in _process and drawn in _draw.
## Positions are body centres in stage coordinates; the camera only slides along x.

const Data := preload("res://data.gd")
const WORLD := 3600.0 # stage width
const GRAVITY := 1900.0
const JUMP := 760.0
const HALF := 30.0 # the player's centre above their feet

var stats := {}
var hp := 0.0
var pos := Vector2.ZERO
var vel_y := 0.0
var face := 1.0
var walking := false
var cam := 0.0
var variant := 0 # which backdrop of the current universe
var clock := 0.0
var charge := 0.0
var cd := {fire = 0.0, hurt = 0.0, melee = 0.0, nova = 0.0, cannon = 0.0, blink = 0.0, chrono = 0.0, grenade = 0.0, hack = 0.0}
var enemies := []
var corpses := []
var shots := []
var blasts := []
var bursts := [] # explosion animations playing out
var pickups := [] # health packs lying on the stage
var beams := [] # Spell Book beams: fixed far end, near end follows the book
var cdmax := {} # full length of each running cooldown, for the HUD
var textures := {}

@onready var game = get_parent()
@onready var font: Font = load(Data.FONT)


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST # crisp pixel art


func reset() -> void: # fresh run: base stats, every upgrade stat at 0
	stats = {maxhp = 100.0, dmg = 1.0, rate = 1.0, speed = 1.0, shots = 1, form = ""}
	for pool in Data.UPGRADES:
		for up in pool:
			if not stats.has(up[2]):
				stats[up[2]] = 0
	for k in cd:
		cd[k] = 0.0


func arrive() -> void: # entering a universe: a random one of its places, starting mid-stage
	variant = randi()
	pickups.clear()
	pos = Vector2(WORLD / 2, ground() - HALF)
	vel_y = 0.0
	cam = pos.x - get_viewport_rect().size.x / 2


func clear() -> void: # empty the stage of everything but the player
	enemies.clear()
	corpses.clear()
	shots.clear()
	blasts.clear()
	bursts.clear()
	beams.clear()


func spawn() -> void: # the next wave, or Loki
	clear()
	cd.hurt = 1.0
	var size := get_viewport_rect().size
	var u: Dictionary = game.uni()
	var boss: bool = game.boss
	var w: int = game.waves + 1
	var wave_k := 1 + 0.12 * w # difficulty layer A: global wave
	var para_k: float = 1 + 0.2 * game.paradox # difficulty layer B: Paradox
	for i in 1 if boss else 4 + w:
		var kind := "" if boss else pick_foe(u.foes)
		var k: Dictionary = Data.SPRITES.get(kind, {}) # this enemy type's own twists on the universe's stats
		var r: float = 44.0 if boss else k.get("r", 28.0)
		var side := 1.0 if i % 2 == 0 else -1.0 # they close in from just off both edges of the screen
		var x := clampf(pos.x + side * size.x * randf_range(0.55, 1.0), -80, WORLD + 80)
		var e := {pos = Vector2(x, ground() - r), vy = 0.0, off = randf_range(-26, 26), kind = kind, hp = 30 * u.hp * k.get("hp", 1.0) * wave_k * para_k,
			dmg = 8 * (1 + 0.08 * w) * para_k, spd = 85 * u.spd * k.get("spd", 1.0) * (1 + 0.03 * w) * (1 + 0.05 * game.paradox),
			r = r, rng = k.get("rng", u.rng), weave = k.get("weave", u.weave), rate = u.rate / (1 + 0.1 * game.paradox),
			t = randf() * 2, n = 0, bane = "", boss = boss, slow = 0.0, burn = 0.0, hack = 0.0, tox = 0,
			face = -side, moving = false, flinch = 0.0, atk = 0.0}
		e.max = e.hp
		if not boss and randf() < 0.05 + 0.2 * game.paradox:
			e.bane = Data.BANES.keys().pick_random()
		enemies.append(e)


func pick_foe(foes: Dictionary) -> String: # weighted pick of an enemy type
	var roll: int = randi() % foes.values().reduce(func(a, b): return a + b)
	for kind in foes:
		roll -= foes[kind]
		if roll < 0:
			return kind
	return ""


func _process(d: float) -> void:
	queue_redraw()
	if game.paused:
		return
	clock += d
	for b in bursts.duplicate():
		b.t += d
		if b.t > 0.5:
			bursts.erase(b)
	for c in corpses.duplicate():
		c.t += d
		if c.t > 0.9:
			corpses.erase(c)
	if game.phase in Data.SCREENS:
		cam += 40 * d # ending screens drift past the scenery
	if game.phase != "play":
		return
	var size := get_viewport_rect().size
	var floor_y := ground()
	var mouse := aim_point()
	var aim := pos.angle_to_point(mouse)
	var power: float = stats.dmg * pow(Data.MASTERY, game.local)
	for k in cd:
		cd[k] -= d

	var run := float(int(held(KEY_D)) - int(held(KEY_A)))
	walking = run != 0
	face = 1.0 if mouse.x >= pos.x else -1.0
	pos.x = clampf(pos.x + run * 260 * stats.speed * d, 30, WORLD - 30)
	if pos.y >= floor_y - HALF - 1 and (held(KEY_W) or held(KEY_SPACE)):
		vel_y = -JUMP
	vel_y += GRAVITY * d
	pos.y += vel_y * d
	if pos.y >= floor_y - HALF:
		pos.y = floor_y - HALF
		vel_y = 0.0
	cam = lerpf(cam, clampf(pos.x - size.x / 2, 0, WORLD - size.x), minf(1, 8 * d))

	var bow: int = stats.crossbow
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and cd.fire <= 0: # full auto: holding the button keeps firing
		cd.fire = (0.75 if bow else 0.3) / stats.rate
		for i in stats.shots:
			fire(aim + (i - (stats.shots - 1) / 2.0) * 0.15, (30 + 8 * bow if bow else 12) * power, stats.pierce, 5, 60 if bow >= 3 else 0)
	if stats.melee > 0 and cd.melee <= 0:
		var m: Array = Data.MELEE[stats.form]
		for e in enemies:
			if pos.distance_to(e.pos) < m[0] + e.r and absf(angle_difference(aim, pos.angle_to_point(e.pos))) <= m[1]:
				hit(e, m[3] * (0.5 + 0.5 * stats.melee) * power)
				cd.melee = m[2]
	if cast("cannon", KEY_R, 2.0):
		fire(aim, 30 * stats.cannon * power, 0, 8, 80, 400)
	if stats.gauntlet > 0:
		if held(KEY_F) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			charge = minf(charge + d, 1.5)
		elif charge > 0:
			beams.append({end = mouse, dmg = 80 * charge * stats.gauntlet * power, w = 14 + 16 * charge, life = 0.5 + 0.5 * charge, t = 0.0, hit = []})
			charge = 0.0
	for b in beams.duplicate(): # each beam strikes every enemy it sweeps across once
		var from := book(b.end)
		for e in enemies:
			if not b.hit.has(e) and Geometry2D.get_closest_point_to_segment(e.pos, from, b.end).distance_to(e.pos) < b.w + e.r:
				hit(e, b.dmg)
				b.hit.append(e)
		b.t += d
		if b.t > b.life:
			beams.erase(b)
	if stats.nova > 0 and cd.nova <= 0:
		cd.nova = 3.0
		boom(pos, 130, 30 * stats.nova * power, 0.15)
	for i in stats.blades:
		zap(blade(i), 12, 90 * power * d)
	if cast("blink", KEY_C, 4.0 / maxi(stats.blink, 1)):
		pos = Vector2(clampf(mouse.x, 30, WORLD - 30), minf(mouse.y, floor_y - HALF))
		vel_y = 0.0
		cd.hurt = 0.4
	if cast("grenade", KEY_Q, 4.0):
		boom(Vector2(mouse.x, minf(mouse.y, floor_y)), 100, 80 * stats.grenade * power, 0.6)
	if cast("hack", KEY_E, 6.0) and enemies:
		var target: Dictionary = nearest(mouse)
		target["slow" if target.boss else "hack"] = 3.0 + stats.hack
	cast("chrono", KEY_SHIFT, 12.0)
	var ed := d * (0.3 if slowmo() else 1.0) # enemy time

	var view := Rect2(cam, 0, size.x, size.y).grow(60)
	for s in shots.duplicate():
		if s.foe:
			if s.pos.distance_to(pos) < 22 and hurt(s.dmg):
				shots.erase(s)
		else:
			if stats.homing > 0 and enemies:
				s.vel = s.vel.lerp(s.pos.direction_to(nearest(s.pos).pos) * 520, minf(1, 4 * stats.homing * d)).normalized() * 520
			for e in enemies:
				if s.pierce >= 0 and s.pos.distance_to(e.pos) < e.r + s.r and not s.hit.has(e):
					hit(e, s.dmg)
					s.hit.append(e)
					s.pierce -= 1
					if s.boom > 0:
						boom(s.pos, s.boom, s.dmg, 0.05)
					if bow >= 2 and s.r == 5: # crossbow bolts split into two smaller ones
						for a in [-0.6, 0.6]:
							fire(s.vel.angle() + a, s.dmg * 0.5, 0, 4, 0).merge({pos = e.pos, hit = [e]}, true)
			if s.pierce < 0:
				shots.erase(s)
		s.pos += s.vel * (ed if s.foe else d)
		if not view.has_point(s.pos) or s.pos.y > floor_y + 6: # left the screen or buried in the ground
			shots.erase(s)

	for e in enemies:
		var k: float = ed * (0.4 if e.slow > 0 else 1.0)
		var prey = nearest(e.pos, e) if e.hack > 0 else null # hacked enemies hunt their allies
		var goal: Vector2 = pos if prey == null else prey.pos
		var dist: float = e.pos.distance_to(goal)
		var keep: float = e.rng if prey == null else 0.0 # ranged enemies hold their distance
		var gap: float = goal.x - e.pos.x + (e.off if keep == 0 else 0.0) # melee ones spread out a little instead of stacking
		var step := 0.0 if absf(absf(gap) - keep) < 6 else signf(absf(gap) - keep) * signf(gap)
		e.pos.x += step * e.spd * k
		e.moving = step != 0
		if absf(goal.x - e.pos.x) > 4:
			e.face = signf(goal.x - e.pos.x)
		var rest: float = floor_y - e.r
		if e.weave > 0 and e.pos.y >= rest and sin(e.t * 3) > 0.95: # weavers come at you in hops
			e.vy = -JUMP * 0.75 * e.weave
		e.vy += GRAVITY * k
		e.pos.y += e.vy * k
		if e.pos.y >= rest:
			e.pos.y = rest
			e.vy = 0.0
		e.t += k
		e.slow -= d
		e.hack -= d
		e.burn -= d
		e.flinch -= d
		e.atk -= d
		if e.burn > 0:
			e.hp -= 10 * stats.fire * power * d
		if prey != null:
			if dist < e.r + prey.r:
				prey.hp -= e.dmg * 4 * d
				e.atk = 0.2
		elif dist < e.r + 16 and hurt(e.dmg):
			e.atk = 0.4
			if e.bane == "vampiric":
				e.hp = e.max
		if e.t > e.rate and prey == null:
			e.t = 0.0
			e.atk = 0.4
			var at: float = e.pos.angle_to_point(pos)
			if e.boss:
				loki(e, at)
			else:
				shoot(e, at)

	for b in blasts.duplicate():
		b.t -= d if b.mine else ed
		if b.t <= 0:
			blasts.erase(b)
			bursts.append({pos = b.pos, r = b.r, t = 0.0})
			if b.mine:
				zap(b.pos, b.r, b.dmg)
			elif b.pos.distance_to(pos) < b.r:
				hurt(b.dmg)

	for e in enemies.filter(func(x): return x.hp <= 0):
		enemies.erase(e)
		corpses.append({pos = e.pos, r = e.r, face = e.face, boss = e.boss, kind = e.kind, t = 0.0})
		hp = minf(hp + stats.leech, stats.maxhp)
		if not e.boss and randf() < Data.DROP:
			pickups.append({pos = e.pos, vy = -300.0, t = Data.PACK_LIFE})
		if e.bane == "volatile":
			boom(e.pos, 80, e.dmg * 1.5, 0.7, false)
		for o in enemies:
			if o.bane == "berserker":
				o.spd *= 1.2

	for p in pickups.duplicate(): # health packs pop up, settle on the ground, and wait until you can use them
		p.vy += GRAVITY * d
		p.pos.y = minf(p.pos.y + p.vy * d, floor_y - 18)
		p.t -= d
		if hp < stats.maxhp and p.pos.distance_to(pos) < 44:
			hp = minf(hp + stats.maxhp * Data.HEAL, stats.maxhp)
			pickups.erase(p)
		elif p.t <= 0:
			pickups.erase(p)

	if hp <= 0: # death is resolved once, and always before a wave can be awarded
		game.die()
	elif enemies.is_empty():
		game.clear_wave()


func loki(e: Dictionary, aim: float) -> void:
	var ring: int = 14 + 4 * game.paradox
	e.n += 1
	match e.n % 3:
		0: # dome of bolts over his head, denser with Paradox
			for i in ring:
				shoot(e, PI + i * PI / (ring - 1)) # the two flat ones must be jumped
		1: # aimed fan
			for i in range(-2, 3):
				shoot(e, aim + i * 0.2)
		2: # rift under the player, then Loki blinks away
			boom(pos, 110, e.dmg * 2, 0.8, false)
			e.pos.x = clampf(pos.x + randf_range(250, 500) * [-1, 1].pick_random(), 80, WORLD - 80)


func shoot(e: Dictionary, angle: float) -> void:
	shots.append({pos = e.pos, vel = Vector2.from_angle(angle) * 240, dmg = e.dmg, r = 5.0, foe = true})


func fire(angle: float, dmg: float, pierce: int, r: float, blast: float, speed := 520.0) -> Dictionary:
	shots.append({pos = pos, vel = Vector2.from_angle(angle) * speed, dmg = dmg, pierce = pierce, r = r, boom = blast, hit = [], foe = false})
	return shots.back()


func boom(p: Vector2, r: float, dmg: float, fuse: float, mine := true) -> void: # delayed blast: yours hits enemies, theirs hits you
	blasts.append({pos = p, r = r, dmg = dmg, t = fuse, mine = mine})


func hit(e: Dictionary, dmg: float) -> void: # a weapon hit, carrying your imbued elements
	e.hp -= dmg * (1 + 0.15 * e.tox)
	e.flinch = 0.2
	e.tox = mini(e.tox + stats.toxin, 10)
	e.slow = maxf(e.slow, stats.frost)
	if stats.fire > 0:
		e.burn = 3.0
	if stats.shock > 0:
		zap(e.pos, 70, dmg * 0.3 * stats.shock)


func zap(p: Vector2, r: float, dmg: float) -> void: # plain area damage
	for e in enemies:
		if e.pos.distance_to(p) < e.r + r:
			e.hp -= dmg


func nearest(p: Vector2, skip = null): # closest enemy to p, or null
	var best = null
	for e in enemies:
		if not is_same(e, skip) and (best == null or p.distance_squared_to(e.pos) < p.distance_squared_to(best.pos)):
			best = e
	return best


func hurt(dmg: float) -> bool:
	if cd.hurt > 0:
		return false
	hp -= dmg * pow(0.8, stats.armor)
	cd.hurt = 0.5
	return true


func cast(ability: String, key: Key, cooldown: float) -> bool: # owned, key held and off cooldown
	if stats[ability] > 0 and held(key) and cd[ability] <= 0:
		cd[ability] = cooldown
		cdmax[ability] = cooldown
		return true
	return false


func held(key: Key) -> bool:
	return Input.is_physical_key_pressed(key)


func slowmo() -> bool:
	return cd.chrono > 10.0 - stats.get("chrono", 0)


func tint() -> Color: # colour of your first imbued element
	for k in Data.ELEMENTS:
		if stats[k] > 0:
			return Data.ELEMENTS[k]
	return Color.WHITE


func beam_tint() -> Color:
	for k in Data.BEAM:
		if stats[k] > 0:
			return Data.BEAM[k]
	return Data.BEAM_PLAIN


func book(target: Vector2) -> Vector2: # where the Spell Book is held: just ahead of the player, toward the target
	return pos + pos.direction_to(target) * 34


func blade(i: int) -> Vector2:
	return pos + Vector2.from_angle(Time.get_ticks_msec() / 250.0 + i * TAU / stats.blades) * 60


func backdrop() -> Dictionary:
	var places: Array = Data.BACKDROPS[3 if game.boss else game.universe]
	return places[variant % places.size()]


func ground() -> float: # screen y of the line everyone stands on
	return get_viewport_rect().size.y * backdrop().ground


func aim_point() -> Vector2: # the cursor, in stage coordinates
	return get_global_mouse_position() + Vector2(cam, 0)


func art(path: String) -> Texture2D:
	if not textures.has(path):
		textures[path] = load(path)
	return textures[path]


func _draw() -> void:
	var size := get_viewport_rect().size
	var u: Dictionary = game.uni()
	var floor_y := ground()
	if game.fronted(): # title.gd fills the screen
		return
	draw_backdrop(size, u, floor_y)
	if game.phase in Data.SCREENS:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.65))
		return
	var aim := pos.angle_to_point(aim_point())
	if slowmo():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 1, 0.7, 0.1))
	to_stage()
	for b in blasts:
		if not b.mine: # enemy blasts warn you: sparks racing round the edge of where it will hit
			for j in 18:
				var a := j * TAU / 18 + clock * 2.5
				draw_rect(Rect2((b.pos + Vector2.from_angle(a) * b.r).snappedf(4), Vector2(4, 4)), Color(1, 0.5 + 0.4 * sin(clock * 20 + j), 0.1))
		elif b.t > 0.1: # your grenade drops in before it bursts
			draw_texture_rect_region(art(Data.ICON_SHEET % [32, 32]), Rect2(b.pos + Vector2(-16, -16 - b.t * 420), Vector2(32, 32)), Rect2(Vector2(Data.ICONS.Grenades) * 32, Vector2(32, 32)))
	for b in bursts: # 9 frames over half a second, scaled to the blast's reach
		draw_sprite(art(Data.EXPLOSION), Rect2(mini(int(b.t * 18), 8) * 112, 0, 112, 128), b.pos, Vector2(56, 70), b.r / 44.0, 1.0, Color.WHITE)
	for c in corpses:
		if not c.boss:
			if Data.SPRITES[c.kind].has("boom"):
				draw_sprite(art(Data.EXPLOSION), Rect2(mini(int(c.t * 10), 8) * 112, 0, 112, 128), c.pos, Vector2(56, 64), 2.0, 1.0, Color.WHITE)
			else:
				draw_actor(c.kind, "Death", c.t, c.pos + Vector2(0, c.r), c.face, Color(1, 1, 1, minf(1, (0.9 - c.t) * 4)), false)
	for e in enemies:
		var feet: Vector2 = e.pos + Vector2(0, e.r)
		var mod := Color.SKY_BLUE if e.slow > 0 else Color.WHITE
		draw_shadow(feet.x, floor_y, e.r * 0.8)
		if e.hack > 0 or e.bane:
			draw_aura(feet, e.r, Data.BANES.get(e.bane, Color.CYAN) if e.hack <= 0 else Color.CYAN, e.pos.x)
		if e.boss:
			var col: int = int(e.t * 6) % 3 if e.moving else 1
			var surge: float = clampf((e.t / e.rate - 0.5) / 0.5, 0, 1) # he gathers power through the second half of each wind-up
			for j in 10: # motes of light pulled into him, quicker and brighter as the attack nears
				var pull := fposmod(clock * (1.5 + 2 * surge) + j * 0.31, 1.0)
				var mote: Vector2 = e.pos + Vector2.from_angle(j * 2.4 + clock) * (1 - pull) * (e.r + 60)
				draw_rect(Rect2(mote.snappedf(4), Vector2(4, 4)), Color(0.6, 1, 0.65, surge * pull))
			var glow := mod.lerp(Color(0.45, 1, 0.55), surge * (0.55 + 0.45 * sin(clock * 34))) # flickers emerald
			var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 3 * surge * surge # and trembles just before release
			draw_sprite(art(Data.LOKI), Rect2(col * 96, 96 if e.face < 0 else 192, 96, 96), feet + shake, Vector2(48, 90), 1.5, 1.0, glow)
		elif e.flinch > 0:
			draw_actor(e.kind, "Hurt", (0.2 - e.flinch) * 2, feet, e.face, mod, false)
		elif e.atk > 0:
			draw_actor(e.kind, "Attack", (0.4 - e.atk) * 1.5, feet, e.face, mod, false)
		else:
			draw_actor(e.kind, "Walk" if e.moving else "Idle", e.t, feet, e.face, mod)
		if e.hp < e.max and not e.boss:
			draw_rect(Rect2(e.pos.x - 21, e.pos.y - e.r - 15, 42, 6), Color(0, 0, 0, 0.7))
			draw_rect(Rect2(e.pos.x - 20, e.pos.y - e.r - 14, 40 * clampf(e.hp / e.max, 0, 1), 4), Color.CRIMSON)
		var label: String = "hacked" if e.hack > 0 else e.bane
		if label:
			var c: Color = Data.BANES.get(label, Color.CYAN)
			draw_string_outline(font, e.pos + Vector2(-40, -e.r - 20), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 12, 4, Color.BLACK)
			draw_string(font, e.pos + Vector2(-40, -e.r - 20), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 12, c)
	for p in pickups:
		if p.t < 2 and int(p.t * (6 if p.t > 1 else 12)) % 2 == 0: # blinks in its last two seconds, faster in the last one
			continue
		var at: Vector2 = p.pos + Vector2(0, sin(clock * 4 + p.pos.x) * 4)
		draw_circle(at, 20, Color(1, 0.3, 0.3, 0.25 + 0.1 * sin(clock * 6)))
		draw_texture_rect_region(art(Data.ICON_SHEET % [32, 32]), Rect2(at - Vector2(16, 16), Vector2(32, 32)), Rect2(Vector2(Data.HEART) * 32, Vector2(32, 32)))
	for s in shots:
		var c: Color = Color.ORANGE_RED if s.foe else tint()
		if not s.foe and stats.crossbow > 0 and s.r <= 5: # crossbow bolts are arrows
			draw_set_transform(s.pos - Vector2(roundf(cam), 0), s.vel.angle(), Vector2(2.5, 2.5))
			draw_texture(art(Data.ARROW), Vector2(-16, -16), c)
			to_stage()
		else: # everything else is a glowing bolt with a short trail
			draw_line(s.pos - s.vel.normalized() * s.r * 4, s.pos, Color(c, 0.45), s.r * 1.2)
			draw_circle(s.pos, s.r + 3, Color(c, 0.3))
			draw_circle(s.pos, s.r, c)
	for i in stats.blades:
		var turn: float = Time.get_ticks_msec() / 250.0 + i * TAU / stats.blades
		for ghost in [[0.5, 0.2], [0.25, 0.4], [0.0, 1.0]]: # two fading after-images, then the sword itself, point leading
			var a: float = turn - ghost[0]
			draw_set_transform(pos + Vector2.from_angle(a) * 60 - Vector2(roundf(cam), 0), a + PI * 0.75, Vector2(1.5, 1.5))
			draw_texture_rect_region(art(Data.ICON_SHEET % [32, 32]), Rect2(-16, -16, 32, 32), Rect2(Vector2(Data.ICONS.Sword) * 32, Vector2(32, 32)), Color(1, 1, 1, ghost[1]))
		to_stage()

	var sole := pos + Vector2(0, HALF)
	var tone := Color.WHITE if cd.hurt <= 0 else Color(1, 1, 1, 0.45)
	draw_shadow(pos.x, floor_y, 20)
	if stats.melee > 0 and cd.melee > 0: # swing, with a fading slash
		var m: Array = Data.MELEE[stats.form]
		draw_actor("Soldier", "Attack", (1 - cd.melee / m[2]) * 0.8, sole, face, tone, false)
		draw_arc(pos, m[0], aim - m[1], aim + m[1], 24, Color(tint(), cd.melee / m[2]), 5)
	elif pos.y < floor_y - HALF - 1:
		draw_actor("Soldier", "Jump", remap(vel_y, -JUMP, JUMP, 0.0, 0.59), sole, face, tone, false) # rising frames, then falling ones
	elif walking:
		draw_actor("Soldier", "Walk", clock * 1.2, sole, face, tone)
	else:
		draw_actor("Soldier", "Idle", clock, sole, face, tone)
	if charge > 0:
		draw_circle(pos + Vector2.from_angle(aim) * 34, 8 + 12 * charge, Color(beam_tint(), 0.4))
		draw_circle(pos + Vector2.from_angle(aim) * 34, 4 + 10 * charge, Color.WHITE)
	for b in beams:
		draw_beam(b)
	if game.phase != "cine":
		draw_line(pos + Vector2.from_angle(aim) * 40, pos + Vector2.from_angle(aim) * 52, Color(1, 1, 1, 0.7), 3) # aim tick
	draw_set_transform(Vector2.ZERO)


func draw_backdrop(size: Vector2, u: Dictionary, floor_y: float) -> void: # parallax layers, each tiled across the screen
	var b: Dictionary = backdrop()
	var layers: Array = b.get("layers", Data.NASHA)
	draw_rect(Rect2(Vector2.ZERO, size), u.bg)
	for i in layers.size():
		var file: String = layers[i][0]
		if i == 2 and b.has("anim"): # 9-frame animated layer (the waterfall)
			file = b.anim % (Time.get_ticks_msec() / 120 % 9 + 1)
		var tex := art(b.dir + file)
		var w := roundf(tex.get_width() * size.y / tex.get_height())
		var x := -fposmod(roundf(cam * layers[i][1]), w)
		while x < size.x:
			draw_texture_rect(tex, Rect2(x, 0, w, size.y), false)
			x += w
	var k := size.y / 160
	for p in b.get("props", []): # loose planets and asteroids drifting by
		var tex := art(b.dir + p[0])
		var span := size.x + 400
		draw_texture_rect(tex, Rect2(fposmod(p[1] * span - cam * p[3], span) - 200, p[2] * size.y, tex.get_width() * k, tex.get_height() * k), false)
	if b.has("floor"): # places with no ground of their own get a glowing walkway
		draw_rect(Rect2(0, floor_y, size.x, size.y - floor_y), Color(0.02, 0.03, 0.06, 0.92))
		var x := -fposmod(cam, 96)
		while x < size.x:
			draw_line(Vector2(x, floor_y), Vector2(x - 24, size.y), Color(u.col, 0.18), 2)
			x += 96
		draw_line(Vector2(0, floor_y), Vector2(size.x, floor_y), Color(u.col, 0.3), 9)
		draw_line(Vector2(0, floor_y), Vector2(size.x, floor_y), u.col, 3)


func draw_beam(b: Dictionary) -> void: # 9 frames of 131x30, 20 a second: a tapered start, then a body that tiles out to the far end
	var from := book(b.end)
	var frame := int(b.t * 20)
	if frame > 8:
		frame = 3 + (frame - 3) % 6 # hold on the steady frames once the opening burst has played
	var fade := clampf((b.life - b.t) / 0.15, 0, 1) # thins out as it ends
	var zoom: float = b.w / 5
	var length := from.distance_to(b.end) / zoom
	var col := beam_tint()
	draw_circle(b.end, b.w * (1.3 + 0.3 * sin(clock * 40)) * fade, Color(col, 0.45))
	for layer in [["res://fx/beam_glow.png", col, 1.0], ["res://fx/beam_core.png", Color.WHITE, 0.5]]: # tinted glow under a thinner white core
		draw_set_transform(from - Vector2(roundf(cam), 0), from.angle_to_point(b.end), Vector2(zoom, zoom * fade * layer[2]))
		var tex := art(layer[0])
		var x := 0.0
		while x < length:
			var from_x := 0.0 if x == 0 else 40.0 # later tiles skip the tapered start
			var w := minf(131 - from_x, length - x)
			draw_texture_rect_region(tex, Rect2(x, -15, w, 30), Rect2(from_x, frame * 30, w, 30), layer[1])
			x += w
	to_stage()
	draw_circle(b.end, b.w * 0.7 * fade, Color.WHITE)


func draw_aura(feet: Vector2, r: float, col: Color, seed: float) -> void: # flames licking up behind an enemy, on a 4px grid
	var count := 11
	for i in count:
		var side := i / (count - 1.0) * 2 - 1 # -1 left edge .. 1 right edge
		var flick := 0.5 + 0.5 * sin(clock * 9 + i * 2.3 + seed) # each tongue flickers on its own beat
		var tall := r * (2.5 + 1.3 * flick) * (1 - 0.5 * side * side) # tallest behind the middle
		var x := snappedf(feet.x + side * (r + 18) + sin(clock * 5 + i) * 2, 4)
		draw_rect(Rect2(x - 6, feet.y - snappedf(tall * 0.55, 4), 12, snappedf(tall * 0.55, 4)), Color(col, 0.35)) # wide dim base
		draw_rect(Rect2(x - 4, feet.y - snappedf(tall * 0.8, 4), 8, snappedf(tall * 0.8, 4)), Color(col, 0.55))
		draw_rect(Rect2(x - 2, feet.y - snappedf(tall, 4), 4, snappedf(tall, 4)), Color(col.lightened(0.4), 0.75)) # bright thin tip
	for j in 7: # embers drifting up and fading
		var rise := fposmod(clock * 0.8 + j * 0.37 + seed * 0.01, 1.0)
		var ember := Vector2(feet.x + sin(j * 12.9 + seed) * (r + 6) + sin(clock * 3 + j) * 4, feet.y - rise * (r * 3.5 + 50))
		draw_rect(Rect2(ember.snappedf(4), Vector2(4, 4)), Color(col.lightened(0.5), 1 - rise))


func to_stage() -> void: # draw in stage coordinates from here on
	draw_set_transform(Vector2(-roundf(cam), 0))


func draw_sprite(tex: Texture2D, src: Rect2, feet: Vector2, anchor: Vector2, zoom: float, flip: float, mod: Color) -> void:
	draw_set_transform(feet - Vector2(roundf(cam), 0), 0, Vector2(zoom * flip, zoom))
	draw_texture_rect_region(tex, Rect2(-anchor, src.size), src, mod)
	to_stage()


func draw_actor(kind: String, anim: String, t: float, feet: Vector2, flip: float, mod: Color, loop := true) -> void: # 10 frames a second
	var k: Dictionary = Data.SPRITES[kind]
	if anim == "Hurt" and not k.anims.has(anim):
		mod *= Color(1, 0.45, 0.45) # no flinch frames: flash red instead
	var a: Array = k.anims.get(anim, k.anims.Walk)
	var tex := art(k.path + a[0])
	var n: int = tex.get_width() / a[1]
	var f := int(t * 10) % n if loop else clampi(int(t * 10), 0, n - 1)
	draw_sprite(tex, Rect2(f * a[1], 0, a[1], tex.get_height()), feet, Vector2(a[2], k.feet), k.zoom, flip, mod)


func draw_shadow(x: float, floor_y: float, w: float) -> void:
	draw_set_transform(Vector2(x - roundf(cam), floor_y), 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, w, Color(0, 0, 0, 0.35))
	to_stage()
