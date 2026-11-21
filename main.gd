extends Node2D
## One-room prototype to isolate and compare game-feel effects.
## No external sprites, plugins, or addons required.

const MOVE_SPEED := 145.0
const ACCELERATION := 1150.0
const FRICTION := 1400.0
const GRAVITY := 800.0
const JUMP_SPEED := -302.0
const HIT_DISTANCE := 48.0

var effects := {
	"flash": true,
	"squash": true,
	"hitstop": true,
	"shake": true,
	"particles": true,
	"sfx": true,
}
var player: CharacterBody2D
var player_visual: Node2D
var player_sprite: Sprite2D
var dummy: StaticBody2D
var dummy_visual: Node2D
var dummy_sprite: Sprite2D
var camera: Camera2D
var effects_label: Label
var counter_label: Label
var message_label: Label
var hit_count := 0
var face := 1
var last_attack_ms := -10000
var shake_left := 0.0
var shake_duration := 0.12
var shake_strength := 2.9
var tween_squash: Tween
var tween_dummy: Tween
var hitstop_running := false
var time_since_start := 0.0
var audio_nodes := {}
var idle_frames: Array[Texture2D] = []
var walk_frames: Array[Texture2D] = []
var animation_clock: float = 0.0
var alien_clock: float = 0.0
var current_animation: String = "idle"

func _ready() -> void:
	randomize()
	setup_input()
	build_stage()
	build_animation_frames()
	build_characters()
	build_camera()
	build_audio()
	build_ui()
	update_hud()

func setup_input() -> void:
	bind_keys("move_left", [KEY_A, KEY_LEFT])
	bind_keys("move_right", [KEY_D, KEY_RIGHT])
	bind_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	bind_keys("attack", [KEY_J, KEY_K])
	var mouse_attack := InputEventMouseButton.new()
	mouse_attack.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mouse_attack)

func bind_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key_code in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key_code
		InputMap.action_add_event(action, ev)

func build_stage() -> void:
	var platform := StaticBody2D.new()
	platform.position = Vector2(240, 255)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(480, 30)
	collision.shape = shape
	platform.add_child(collision)
	add_child(platform)

func build_characters() -> void:
	player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(132, 220)
	var player_collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 28)
	player_collision.shape = shape
	player.add_child(player_collision)
	add_child(player)
	player_visual = Node2D.new()
	player_visual.name = "VisualOnly_DoNotScaleCollision"
	player.add_child(player_visual)
	player_sprite = Sprite2D.new()
	player_sprite.texture = idle_frames[0]
	# The physical collider keeps its old dimensions; only the art is scaled.
	# Each 48 px atlas cell has a fixed foot baseline at y≈46.
	player_sprite.scale = Vector2(0.82, 0.82)
	player_sprite.offset = Vector2(0.0, -5.0)
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_visual.add_child(player_sprite)

	dummy = StaticBody2D.new()
	dummy.name = "TrainingDummy"
	dummy.position = Vector2(344, 220)
	var dummy_collision := CollisionShape2D.new()
	var dummy_shape := RectangleShape2D.new()
	dummy_shape.size = Vector2(20, 28)
	dummy_collision.shape = dummy_shape
	dummy.add_child(dummy_collision)
	add_child(dummy)
	dummy_visual = Node2D.new()
	dummy_visual.name = "FlashAndKnockbackVisual"
	dummy.add_child(dummy_visual)
	dummy_sprite = Sprite2D.new()
	dummy_sprite.texture = create_dummy_texture()
	dummy_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec4 col = texture(TEXTURE, UV) * COLOR;
    COLOR = vec4(mix(col.rgb, vec3(1.0), flash_strength), col.a);
}
"""
	mat.shader = shader
	dummy_sprite.material = mat
	dummy_visual.add_child(dummy_sprite)

func build_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(240, 135)
	add_child(camera)
	camera.make_current()

func build_audio() -> void:
	var audio := {
		"jump": "res://audio/jump.wav",
		"attack": "res://audio/attack.wav",
		"hit": "res://audio/hit.wav",
		"land": "res://audio/land.wav",
	}
	for kind in audio:
		var player_audio := AudioStreamPlayer.new()
		player_audio.stream = load(audio[kind])
		player_audio.volume_db = -7.0 if kind == "hit" else -12.0
		add_child(player_audio)
		audio_nodes[kind] = player_audio

func play_sfx(kind: String) -> void:
	if effects["sfx"] and audio_nodes.has(kind):
		var node: AudioStreamPlayer = audio_nodes[kind]
		node.stop()
		node.play()

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var title := make_label("GAME FEEL LAB  •  Alien Forest", Vector2(12, 9), 12, Color("#f5e9ad"))
	layer.add_child(title)
	var controls := make_label("A / D: mover   ESPAÇO: pular   J / clique: atacar", Vector2(12, 28), 9, Color("#d9e0f4"))
	layer.add_child(controls)
	var tip := make_label("Acerte o boneco à direita e ligue/desligue os efeitos.", Vector2(12, 42), 9, Color("#9fadc5"))
	layer.add_child(tip)
	effects_label = make_label("", Vector2(341, 74), 10, Color("#ffffff"))
	layer.add_child(effects_label)
	counter_label = make_label("", Vector2(12, 248), 10, Color("#f5e9ad"))
	layer.add_child(counter_label)
	message_label = make_label("", Vector2(110, 72), 11, Color("#f5e9ad"))
	layer.add_child(message_label)

func make_label(content: String, pos: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.text = content
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("#070e1d"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func update_hud() -> void:
	var lines := ["TESTES (ligar/desligar)"]
	for row in [["1", "flash", "White flash"], ["2", "squash", "Squash/stretch"], ["3", "hitstop", "Hitstop"], ["4", "shake", "Camera shake"], ["5", "particles", "Partículas"], ["6", "sfx", "Sons"]]:
		lines.append("%s  %s: %s" % [row[0], row[2], "ON" if effects[row[1]] else "OFF"])
	effects_label.text = "\n".join(lines)
	counter_label.text = "ACERTOS: %d    |    R: reiniciar" % hit_count

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var keys := {
		KEY_1: "flash", KEY_2: "squash", KEY_3: "hitstop",
		KEY_4: "shake", KEY_5: "particles", KEY_6: "sfx",
	}
	if keys.has(key_event.physical_keycode):
		var effect: String = keys[key_event.physical_keycode]
		effects[effect] = not effects[effect]
		if effect == "flash" and not effects[effect]:
			dummy_sprite.material.set_shader_parameter("flash_strength", 0.0)
		update_hud()
	elif key_event.physical_keycode == KEY_R:
		Engine.time_scale = 1.0
		player.position = Vector2(132, 220)
		player.velocity = Vector2.ZERO
		player_visual.scale = Vector2.ONE
		dummy_visual.position = Vector2.ZERO
		dummy_visual.scale = Vector2.ONE
		dummy_sprite.material.set_shader_parameter("flash_strength", 0.0)
		hit_count = 0
		update_hud()

func _physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0:
		face = 1 if axis > 0 else -1
		player_sprite.flip_h = face < 0
		player.velocity.x = move_toward(player.velocity.x, axis * MOVE_SPEED, ACCELERATION * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, FRICTION * delta)
	var was_on_floor := player.is_on_floor()
	if not was_on_floor:
		player.velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and was_on_floor:
		player.velocity.y = JUMP_SPEED
		apply_squash(Vector2(0.74, 1.24), 0.22)
		play_sfx("jump")
	player.move_and_slide()
	player.position.x = clampf(player.position.x, 12.0, 468.0)
	if not was_on_floor and player.is_on_floor():
		apply_squash(Vector2(1.27, 0.73), 0.28)
		if effects["particles"]:
			burst(player.position + Vector2(0, 14), 6, Color("#d8cbaa"), 0.65)
		play_sfx("land")
	if Input.is_action_just_pressed("attack"):
		attack()

func _process(delta: float) -> void:
	time_since_start += delta
	animation_clock += delta
	alien_clock += delta
	if player_sprite != null:
		var moving: bool = absf(player.velocity.x) > 8.0 and player.is_on_floor()
		var state: String = "walk" if moving else "idle"
		if state != current_animation:
			current_animation = state
			animation_clock = 0.0
		var frames: Array[Texture2D] = walk_frames if moving else idle_frames
		var fps: float = 10.0 if moving else 4.0
		var index: int = int(floor(animation_clock * fps)) % frames.size()
		player_sprite.texture = frames[index]
	queue_redraw()
	if shake_left > 0:
		shake_left -= delta
		var intensity: float = shake_strength * maxf(shake_left / shake_duration, 0.0)
		camera.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	else:
		camera.offset = Vector2.ZERO

func apply_squash(target: Vector2, duration: float) -> void:
	if not effects["squash"]:
		return
	if tween_squash != null and tween_squash.is_running():
		tween_squash.kill()
	player_visual.scale = target
	tween_squash = create_tween()
	tween_squash.set_trans(Tween.TRANS_BACK)
	tween_squash.set_ease(Tween.EASE_OUT)
	tween_squash.tween_property(player_visual, "scale", Vector2.ONE, duration)

func attack() -> void:
	var now := Time.get_ticks_msec()
	if now - last_attack_ms < 190:
		return
	last_attack_ms = now
	play_sfx("attack")
	apply_squash(Vector2(1.18, 0.86), 0.14)
	spawn_slash()
	var dx := dummy.position.x - player.position.x
	var dy : float = abs(dummy.position.y - player.position.y)
	if dx * face > 0 and dx * face <= HIT_DISTANCE and dy < 29:
		register_hit()

func spawn_slash() -> void:
	var slash := Line2D.new()
	slash.name = "SlashVisual"
	slash.width = 3.5
	slash.default_color = Color("#c3f8ff")
	slash.antialiased = false
	slash.points = PackedVector2Array([
		Vector2(9, -19), Vector2(21, -16), Vector2(31, -8),
		Vector2(36, 2), Vector2(32, 12), Vector2(23, 18),
	])
	slash.position = player.position
	slash.scale.x = face
	add_child(slash)
	var t := create_tween()
	t.tween_property(slash, "modulate:a", 0.0, 0.10)
	t.tween_callback(slash.queue_free)

func register_hit() -> void:
	hit_count += 1
	update_hud()
	play_sfx("hit")
	if effects["flash"]:
		var mat: ShaderMaterial = dummy_sprite.material
		mat.set_shader_parameter("flash_strength", 1.0)
		var flash_tween := create_tween()
		flash_tween.tween_method(func(v: float): mat.set_shader_parameter("flash_strength", v), 1.0, 0.0, 0.14)
	if tween_dummy != null and tween_dummy.is_running():
		tween_dummy.kill()
	dummy_visual.position = Vector2(face * 5, -1)
	dummy_visual.scale = Vector2(1.22, 0.82) if effects["squash"] else Vector2.ONE
	tween_dummy = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween_dummy.set_parallel(true)
	tween_dummy.tween_property(dummy_visual, "position", Vector2.ZERO, 0.24)
	tween_dummy.tween_property(dummy_visual, "scale", Vector2.ONE, 0.24)
	if effects["hitstop"]:
		activate_hitstop()
	if effects["shake"]:
		shake_left = shake_duration
	if effects["particles"]:
		burst(dummy.position + Vector2(-face * 12, 0), 12, Color("#ffe6a3"), 1.4)
	floating_damage(dummy.position + Vector2(0, -18))

func activate_hitstop() -> void:
	if hitstop_running:
		return
	hitstop_running = true
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.055, true, false, true).timeout
	Engine.time_scale = 1.0
	hitstop_running = false

func burst(at: Vector2, amount: int, color: Color, force: float) -> void:
	for i in amount:
		var px := ColorRect.new()
		var s: float = float(randi_range(2, 4))
		px.size = Vector2(s, s)
		px.position = at
		px.color = color.lerp(Color("#ffffff"), randf_range(0, 0.5))
		px.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(px)
		var move := Vector2(randf_range(-25, 25), randf_range(-33, 6)) * force
		var t := create_tween()
		t.set_parallel(true)
		t.tween_property(px, "position", at + move, randf_range(0.20, 0.36))
		t.tween_property(px, "modulate:a", 0.0, 0.36)
		t.set_parallel(false)
		t.tween_callback(px.queue_free)

func floating_damage(at: Vector2) -> void:
	var label := make_label("12", at, 13, Color("#fff2b7"))
	add_child(label)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(label, "position", at + Vector2(0, -22), 0.38)
	t.tween_property(label, "modulate:a", 0.0, 0.38)
	t.set_parallel(false)
	t.tween_callback(label.queue_free)

# Pixel-art traveler frames are cropped directly from a real transparent PNG.
# Grid: 5 columns × 2 rows, 48×48 pixels per cell. No runtime resizing of cells.
const TRAVELER_FRAME: int = 48
const TRAVELER_FRAMES_PER_ROW: int = 5

func build_animation_frames() -> void:
	var sheet: Texture2D = load("res://assets/traveler_sheet.png") as Texture2D
	if sheet == null:
		push_error("Traveler PNG not found: res://assets/traveler_sheet.png")
		return
	for frame in range(TRAVELER_FRAMES_PER_ROW):
		idle_frames.append(make_sprite_frame(sheet, frame, 0))
		walk_frames.append(make_sprite_frame(sheet, frame, 1))

func make_sprite_frame(sheet: Texture2D, column: int, row: int) -> Texture2D:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = sheet
	atlas_texture.region = Rect2(
		column * TRAVELER_FRAME, row * TRAVELER_FRAME,
		TRAVELER_FRAME, TRAVELER_FRAME
	)
	return atlas_texture

func create_dummy_texture() -> Texture2D:
	var im := Image.create(24, 32, false, Image.FORMAT_RGBA8)
	im.fill(Color.TRANSPARENT)
	block(im, 10, 18, 4, 14, "#6d4b37")
	block(im, 4, 13, 16, 6, "#7d5236")
	block(im, 8, 3, 9, 19, "#a67b4e")
	block(im, 6, 7, 13, 11, "#d1a86e")
	block(im, 2, 11, 20, 3, "#785338")
	block(im, 10, 10, 4, 4, "#763f33")
	block(im, 9, 11, 6, 2, "#763f33")
	block(im, 3, 29, 18, 3, "#53372d")
	return ImageTexture.create_from_image(im)

func block(img: Image, x: int, y: int, w: int, h: int, hex: String) -> void:
	img.fill_rect(Rect2i(x, y, w, h), Color(hex))

# Alien forest: deterministic pixel layers, designed for future parallax extraction.
func _draw() -> void:
	draw_rect(Rect2(0, 0, 480, 270), Color("#141d39"))
	# Nebula gradient bands.
	for band in range(15):
		var tint: Color = Color("#27365c").lerp(Color("#74518a"), float(band) / 15.0)
		draw_rect(Rect2(0, band * 8, 480, 8), tint)
	# Huge ringed planet and a second moon.
	draw_arc(Vector2(393, 65), 71.0, -0.45, 2.7, 96, Color("#d8a8d6"), 5.0)
	draw_arc(Vector2(393, 65), 75.0, -0.45, 2.7, 96, Color("#916db8"), 2.0)
	draw_circle(Vector2(393, 65), 55.0, Color("#aa82be"))
	draw_circle(Vector2(377, 44), 32.0, Color("#c29bc8"))
	draw_circle(Vector2(271, 65), 18.0, Color("#6073a8"))
	for i in range(47):
		var sx: float = float((i * 97 + 27) % 480)
		var sy: float = float((i * 47 + 17) % 132)
		draw_rect(Rect2(sx, sy, 1, 1), Color("#c6dbed"))
	# Far-away silhouettes: layered canopy, giant stalks and vegetation.
	for i in range(18):
		var fx: float = float(i * 32 - 10)
		var h: float = float(22 + (i * 13) % 29)
		draw_rect(Rect2(fx + 13, 185 - h, 7, h + 52), Color("#293a58"))
		draw_circle(Vector2(fx + 16, 179 - h), 20.0, Color("#38496b"))
		draw_circle(Vector2(fx + 4, 181 - h), 12.0, Color("#455679"))
	# Front foliage: overgrown platform, luminous spores, mushrooms.
	draw_rect(Rect2(0, 238, 480, 32), Color("#283d41"))
	draw_rect(Rect2(0, 238, 480, 4), Color("#56866e"))
	for i in range(36):
		var px: float = float((i * 71 + 17) % 480)
		var py: float = float(243 + (i * 13) % 24)
		draw_rect(Rect2(px, py, 9, 3), Color("#345c56"))
	for i in range(12):
		var x: float = float((i * 103 + 36) % 480)
		var height: float = float(7 + (i % 3) * 4)
		draw_line(Vector2(x, 238), Vector2(x - 2, 238 - height), Color("#477d72"), 2.0)
		draw_circle(Vector2(x - 2, 238 - height), 3.0, Color("#53d6ba"))
	# Bioluminescent insect-flowers.
	for i in range(8):
		var px: float = float((i * 89 + 55) % 480)
		var py: float = float(213 + (i % 3) * 7)
		draw_line(Vector2(px, 238), Vector2(px, py), Color("#587f69"), 2.0)
		draw_circle(Vector2(px, py), 4.0, Color("#4ce7e3"))
		draw_circle(Vector2(px - 5, py + 2), 3.0, Color("#8964ba"))
		draw_circle(Vector2(px + 5, py + 2), 3.0, Color("#8964ba"))
	# Creature silhouettes in the background: dragonfly-insects.
	for i in range(3):
		var ix: float = 71.0 + float(i * 146)
		var iy: float = 148.0 + float(i % 2) * 21.0 + sin(alien_clock * 2.0 + i) * 3.0
		draw_circle(Vector2(ix, iy), 4.0, Color("#263448"))
		draw_line(Vector2(ix - 2, iy), Vector2(ix - 11, iy - 5), Color("#67b7b1"), 2.0)
		draw_line(Vector2(ix + 2, iy), Vector2(ix + 11, iy - 5), Color("#67b7b1"), 2.0)
