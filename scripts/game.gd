extends Node3D
## BLOB — hyper-casual 3D mass runner. World, UI and audio are all built in code.

const TRACK_WIDTH := 8.0
const LANE_X := [-2.0, 2.0]
const BASE_MASS := 20.0
const MASS_MIN := 4.0
const SPEED_BASE := 13.5
const LEVEL_LEN := 170.0
const ROAD_TOP := 0.57
const GATE_STEP := 60.0
const GATE_COLORS := [
	Color("#35E6FF"), Color("#9B6BFF"), Color("#4FD1C5"),
	Color("#FFB020"), Color("#FF7AC6"), Color("#5B8CFF"),
]
const BLOB_SHADER := preload("res://shaders/blob.gdshader")
const SPEED_FX := preload("res://shaders/speed_fx.gdshader")

const BIOMES := [
	{
		"name": "ROOFTOPS", "decor": "city",
		"sky_top": Color("#082353"), "sky_horizon": Color("#6FB3E8"),
		"ground": Color("#3E7E52"), "track": Color("#7C8FB8"), "fog": Color("#6FA4D6"),
		"ambient": Color(0.72, 0.80, 0.98),
	},
	{
		"name": "GROVE", "decor": "trees",
		"sky_top": Color("#063127"), "sky_horizon": Color("#84D6A2"),
		"ground": Color("#1E5B39"), "track": Color("#A7BC8C"), "fog": Color("#7FBF95"),
		"ambient": Color(0.80, 0.95, 0.85),
	},
	{
		"name": "CANYON", "decor": "rocks",
		"sky_top": Color("#2C0A28"), "sky_horizon": Color("#E08A4E"),
		"ground": Color("#6B2F19"), "track": Color("#C79A72"), "fog": Color("#C98A5E"),
		"ambient": Color(1.0, 0.86, 0.74),
	},
	{
		"name": "ABYSS", "decor": "coral",
		"sky_top": Color("#040515"), "sky_horizon": Color("#2C2E74"),
		"ground": Color("#0E2440"), "track": Color("#3E7E92"), "fog": Color("#2A4272"),
		"ambient": Color(0.66, 0.78, 1.0),
	},
]

# ---- run state
var state := "menu"
var level := 1
var mass := BASE_MASS
var goal := 90.0
var z := 0.0
var prev_z := 0.0
var blob_x := -2.0
var lane := 0
var radius := 1.0
var level_len := LEVEL_LEN
var unit := 90.0
var force_short := false
var shield_left := 0
var invuln := 0.0
var hitstop := 0.0
var shake := 0.0
var clock := 0.0
var run_time := 0.0
var bad_hits := 0
var eaten := 0
var coins_run := 0
var boss_active := false
var boss_mass := 0.0
var won_boss := false
var squash := 0.0
var pop_t := 0.0

# ---- debug / capture
var autoplay := false
var forced_lane := -1
var invincible := false
var trace := false
var want_shot := false
var spike_demo := false
var _last_back_ms := 0
var autonext := false
var autorevive := false
var nearmiss_demo := false
var steam_demo := false
var shot_delay := 6.0
var shot_taken := false
var screen_arg := ""

# ---- nodes
var world: Node3D
var blob: MeshInstance3D
var blob_mat: ShaderMaterial
var trail: CPUParticles3D
var coin_shown := 0.0
var landed := false
var fx_mat: ShaderMaterial
var fx_strength := 0.0
var fov_punch := 0.0
var near_t := 0.0
var revives := 0
var death_tw: Tween
var daily_mode := false
var daily_seed := 0
var combo := 0
var magnet_t := 0.0
var double_t := 0.0
var lbl_combo: Label
var lbl_buffs: Label
var pickup_arg := ""
var daily_arg := false
var tut_layer: Control
var tut_label: Label
var tut_hand: Panel
var tut_step := 0
var tut_gates := 0
var _burst_mesh_cache: SphereMesh
var _water_mesh_cache: SphereMesh
var _halo_tex: GradientTexture2D
var blob_halo: MeshInstance3D
var blob_shadow: MeshInstance3D
var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D

var ui_root: Control
var hud: Control
var menu: MenuUI
var panel_layer: Control

var lbl_level: Label
var lbl_biome: Label
var lbl_mass: Label
var lbl_goal: Label
var goal_bar: GoalBar
var lbl_coins: Label
var shield_row: HBoxContainer
var boss_box: Control
var boss_bar: GoalBar
var lbl_boss: Label
var lbl_hint: Label

var gates: Array = []
var enemies: Array = []
var pickups: Array = []
var hazards: Array = []
var boss_node: MeshInstance3D
var boss_lbl: Label3D
var boss_br := 1.5

var sfx := {}
var music: AudioStreamPlayer


# =============================================================== boot
func _ready() -> void:
	_build_env()
	_build_blob()
	_build_audio()
	_build_ui()
	_handle_args()


func _build_env() -> void:
	world = Node3D.new()
	world.name = "World"
	add_child(world)

	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color("#0B2F72")
	psm.sky_horizon_color = Color("#8FD0FF")
	psm.ground_bottom_color = Color("#243B55")
	psm.ground_horizon_color = Color("#8FD0FF")
	psm.sun_angle_max = 24.0
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.80, 0.98)
	env.ambient_light_energy = 0.24
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.97
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_strength = 1.0
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.set_glow_level(2, 0.7)
	env.set_glow_level(3, 0.6)
	env.set_glow_level(4, 0.45)
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.30
	env.adjustment_contrast = 1.16
	env.fog_enabled = true
	env.fog_light_color = Color("#9CC7F0")
	env.fog_density = 0.0032
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, 38, 0)
	sun.light_energy = 0.72
	sun.light_color = Color("#FFF4DA")
	sun.shadow_enabled = true
	add_child(sun)


func _build_blob() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 48
	mesh.rings = 28
	blob = MeshInstance3D.new()
	blob.mesh = mesh
	blob_mat = ShaderMaterial.new()
	blob_mat.shader = BLOB_SHADER
	blob.material_override = blob_mat
	blob.position = Vector3(LANE_X[0], 1.0, 0.0)
	add_child(blob)
	blob_halo = _halo(Color("#7BE8FF"), 1.0, Vector3.ZERO, 0.26, self)
	blob_shadow = _contact_shadow()
	_apply_skin()
	_build_trail()

	cam = Camera3D.new()
	cam.fov = 62.0
	cam.position = Vector3(0, 5.6, 9.4)
	add_child(cam)
	cam.current = true


func _halo_texture() -> GradientTexture2D:
	if _halo_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.45))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 128
		t.height = 128
		_halo_tex = t
	return _halo_tex


func _halo(col: Color, size: float, pos: Vector3, alpha := 0.35, parent: Node = null, additive := true) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _halo_texture()
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.disable_receive_shadows = true
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var host: Node = parent if parent != null else world
	host.add_child(mi)
	return mi


func _contact_shadow() -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _halo_texture()
	m.albedo_color = Color(0.02, 0.05, 0.09, 0.42)
	m.disable_receive_shadows = true
	mi.material_override = m
	mi.rotation_degrees = Vector3(-90, 0, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


func _particle_mesh() -> SphereMesh:
	if _burst_mesh_cache == null:
		var m := SphereMesh.new()
		m.radius = 0.5
		m.height = 1.0
		m.radial_segments = 8
		m.rings = 4
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.disable_receive_shadows = true
		m.surface_set_material(0, mat)
		_burst_mesh_cache = m
	return _burst_mesh_cache


func _water_mesh() -> SphereMesh:
	if _water_mesh_cache == null:
		var m := SphereMesh.new()
		m.radius = 0.5
		m.height = 1.0
		m.radial_segments = 10
		m.rings = 6
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.vertex_color_use_as_albedo = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
		m.surface_set_material(0, mat)
		_water_mesh_cache = m
	return _water_mesh_cache


func _build_trail() -> void:
	# water droplets flicked off the drop, not smoke: they arc backwards and fall
	trail = CPUParticles3D.new()
	trail.mesh = _water_mesh()
	trail.amount = 28
	trail.lifetime = 0.52
	trail.local_coords = false
	trail.emitting = true
	trail.direction = Vector3(0, 0.45, 1)
	trail.spread = 24.0
	trail.gravity = Vector3(0, -11.0, 0)
	trail.initial_velocity_min = 1.2
	trail.initial_velocity_max = 3.4
	trail.scale_amount_min = 0.09
	trail.scale_amount_max = 0.20
	trail.damping_min = 0.4
	trail.damping_max = 1.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.90))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.55, Color(1, 1, 1, 0.55))
	trail.color_ramp = ramp
	trail.color = Color(0.66, 0.94, 1.0, 0.9)
	add_child(trail)


func _steam(pos: Vector3, lost: float) -> void:
	if world == null:
		return
	var amount := clampi(int(lost * 1.6) + 22, 22, 60)
	var size := clampf(0.75 + lost * 0.012, 0.75, 1.45)
	var p := CPUParticles3D.new()
	p.mesh = _water_mesh()
	p.amount = amount
	p.lifetime = 1.05
	p.one_shot = true
	p.explosiveness = 0.85
	p.direction = Vector3(0, 1, 0.2)
	p.spread = 38.0
	p.gravity = Vector3(0, 2.2, 0)
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 3.4
	p.scale_amount_min = 0.26 * size
	p.scale_amount_max = 0.72 * size
	p.damping_min = 0.6
	p.damping_max = 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.86, 0.91, 0.98, 0.66))
	ramp.set_color(1, Color(0.92, 0.97, 1.0, 0.0))
	ramp.add_point(0.45, Color(0.92, 0.95, 1.0, 0.34))
	p.color_ramp = ramp
	p.color = Color(0.90, 0.94, 1.0, 0.72)
	p.position = pos
	world.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)


func _burst(pos: Vector3, col: Color, amount := 14, speed := 7.0, size := 1.0) -> void:
	if world == null:
		return
	var p := CPUParticles3D.new()
	p.mesh = _particle_mesh()
	p.amount = amount
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.gravity = Vector3(0, -16, 0)
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.scale_amount_min = 0.10 * size
	p.scale_amount_max = 0.30 * size
	var ramp := Gradient.new()
	ramp.set_color(0, col)
	ramp.set_color(1, Color(col.r, col.g, col.b, 0.0))
	p.color_ramp = ramp
	p.color = col
	p.position = pos
	world.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.1).timeout.connect(p.queue_free)


func _build_audio() -> void:
	for n in ["pop", "eat", "hurt", "win", "click", "star", "buy", "lose", "boss", "steam"]:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/sfx/%s.wav" % n)
		p.volume_db = -4.0
		add_child(p)
		sfx[n] = p
	music = AudioStreamPlayer.new()
	var stream: AudioStream = load("res://assets/sfx/music.ogg")
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	music.stream = stream
	music.volume_db = -15.0
	add_child(music)
	_apply_music()


func _apply_music() -> void:
	if Profile.music_on:
		if not music.playing:
			music.play()
	else:
		music.stop()


func _play(n: String, pitch := 1.0, vol := 0.0) -> void:
	if not Profile.sfx_on:
		return
	var p: AudioStreamPlayer = sfx.get(n)
	if p == null:
		return
	p.pitch_scale = clampf(pitch, 0.6, 1.8)
	p.volume_db = -4.0 + vol
	p.play()


func _buzz(ms: int) -> void:
	if Profile.haptics_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


# =============================================================== UI shell
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_root)

	var fx := ColorRect.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_mat = ShaderMaterial.new()
	fx_mat.shader = SPEED_FX
	fx.material = fx_mat
	ui_root.add_child(fx)

	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	ui_root.add_child(hud)
	_build_hud()

	panel_layer = Control.new()
	panel_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(panel_layer)

	menu = MenuUI.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(menu)
	menu.play_pressed.connect(_on_play)
	menu.daily_pressed.connect(_on_daily)
	menu.level_selected.connect(_on_level_selected)
	menu.sfx_requested.connect(_on_menu_sfx)


func _build_hud() -> void:
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 20
	top.offset_right = -20
	top.offset_top = 20
	top.custom_minimum_size = Vector2(0, 74)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 12)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	hud.add_child(top)

	var level_pill := Panel.new()
	level_pill.custom_minimum_size = Vector2(196, 74)
	level_pill.size = Vector2(196, 74)
	level_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_pill.add_theme_stylebox_override("panel", UIKit.panel_style(24, Color(0.04, 0.07, 0.16, 0.68), UIKit.C_ACCENT.darkened(0.35), 1, 14, 0.5))
	top.add_child(level_pill)
	var lv := VBoxContainer.new()
	lv.position = Vector2(18, 8)
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv.add_theme_constant_override("separation", -4)
	level_pill.add_child(lv)
	lbl_level = UIKit.label("LEVEL 1", 27, UIKit.C_TEXT, 600)
	lbl_level.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv.add_child(lbl_level)
	lbl_biome = UIKit.label("ROOFTOPS", 13, UIKit.C_ACCENT, 800, false)
	lbl_biome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv.add_child(lbl_biome)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)

	# PanelContainer sizes itself from its contents: the icon and the number can
	# never spill outside the rounded chip, whatever the coin count is.
	var coin_pill := PanelContainer.new()
	coin_pill.add_theme_stylebox_override("panel", UIKit.panel_style(24, Color(0.04, 0.07, 0.16, 0.68), UIKit.C_GOLD.darkened(0.45), 1, 12, 0.45))
	coin_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 14)
	cm.add_theme_constant_override("margin_right", 16)
	cm.add_theme_constant_override("margin_top", 8)
	cm.add_theme_constant_override("margin_bottom", 8)
	cm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coin_pill.add_child(cm)
	var ch := HBoxContainer.new()
	ch.add_theme_constant_override("separation", 8)
	ch.alignment = BoxContainer.ALIGNMENT_CENTER
	ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cm.add_child(ch)
	var ic := UIKit.coin_icon(24)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ch.add_child(ic)
	lbl_coins = UIKit.label("0", 24, UIKit.C_GOLD, 700, false)
	lbl_coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ch.add_child(lbl_coins)
	top.add_child(coin_pill)

	var pause := UIKit.icon_button("II", 62)
	pause.custom_minimum_size = Vector2(62, 62)
	pause.pressed.connect(_toggle_pause)
	top.add_child(pause)

	var block := Panel.new()
	block.set_anchors_preset(Control.PRESET_CENTER_TOP)
	block.offset_left = -158
	block.offset_right = 158
	block.offset_top = 94
	block.offset_bottom = 268
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_theme_stylebox_override("panel", UIKit.panel_style(30, Color(0.03, 0.05, 0.13, 0.68), Color(1, 1, 1, 0.13), 1, 16, 0.5))
	hud.add_child(block)
	var bv := VBoxContainer.new()
	bv.set_anchors_preset(Control.PRESET_FULL_RECT)
	bv.offset_top = 12
	bv.offset_bottom = -12
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bv.add_theme_constant_override("separation", 1)
	block.add_child(bv)
	var cap := UIKit.label("MASS", 13, UIKit.C_ACCENT, 800, false)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(cap)
	lbl_mass = UIKit.title("20", 66, UIKit.C_TEXT, 700, 12, Color(0.02, 0.04, 0.10, 0.92))
	lbl_mass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(lbl_mass)
	goal_bar = GoalBar.new()
	goal_bar.custom_minimum_size = Vector2(240, 17)
	goal_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bv.add_child(goal_bar)
	lbl_goal = UIKit.label("GOAL 90", 14, UIKit.C_MUTED, 700, false)
	lbl_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(lbl_goal)
	lbl_combo = UIKit.label("", 17, UIKit.C_GOLD, 800, false)
	lbl_combo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(lbl_combo)
	lbl_buffs = UIKit.label("", 13, UIKit.C_ACCENT, 700, false)
	lbl_buffs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bv.add_child(lbl_buffs)

	shield_row = HBoxContainer.new()
	shield_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	shield_row.offset_left = 24
	shield_row.offset_top = 112
	shield_row.add_theme_constant_override("separation", 5)
	shield_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(shield_row)

	boss_box = Control.new()
	boss_box.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_box.offset_top = 286
	boss_box.offset_left = 60
	boss_box.offset_right = -60
	boss_box.custom_minimum_size = Vector2(0, 54)
	boss_box.visible = false
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(boss_box)
	var bb := VBoxContainer.new()
	bb.set_anchors_preset(Control.PRESET_FULL_RECT)
	bb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bb.add_theme_constant_override("separation", 3)
	boss_box.add_child(bb)
	lbl_boss = UIKit.label("RIVAL  0", 13, UIKit.C_PINK, 700, false)
	lbl_boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bb.add_child(lbl_boss)
	boss_bar = GoalBar.new()
	boss_bar.custom_minimum_size = Vector2(0, 10)
	boss_bar.fill_a = UIKit.C_PINK
	boss_bar.fill_b = UIKit.C_PINK
	boss_bar.bg_color = Color(0.35, 0.05, 0.12, 0.55)
	bb.add_child(boss_bar)

	lbl_hint = UIKit.label("TAP LEFT / RIGHT TO SWITCH LANES", 13, Color(1, 1, 1, 0.78), 700, false)
	lbl_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	lbl_hint.offset_left = -320
	lbl_hint.offset_right = 320
	lbl_hint.offset_top = -72
	lbl_hint.offset_bottom = -40
	lbl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(lbl_hint)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		var now := Time.get_ticks_msec()
		if now - _last_back_ms < 400:
			return
		_last_back_ms = now
		_on_back_pressed()


func _on_back_pressed() -> void:
	if panel_layer.get_child_count() > 0:
		if state == "paused":
			_toggle_pause()
		else:
			_show_menu()
		return
	if state == "play" or state == "paused":
		_toggle_pause()
		return
	if menu.visible and menu.screen != "menu":
		menu.show_screen("menu")
		return
	get_tree().quit()


func _debug_click_next() -> void:
	await get_tree().create_timer(1.8).timeout
	for b in _all_buttons(panel_layer):
		if b is Button and String(b.text).begins_with("NEXT"):
			print("AUTONEXT press ", b.text, " state=", state)
			b.pressed.emit()
			return
	print("AUTONEXT no button found")


func _debug_click_revive() -> void:
	await get_tree().create_timer(1.4).timeout
	for b in _all_buttons(panel_layer):
		if b is Button and (String(b.text).begins_with("REVIVE") or String(b.text).begins_with("CONTINUE")):
			print("AUTOREVIVE press ", b.text, " coins_before=", Profile.coins)
			b.pressed.emit()
			return
	print("AUTOREVIVE no button")


func _all_buttons(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_all_buttons(c))
	return out


func _show_menu() -> void:
	state = "menu"
	hud.visible = false
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.visible = true
	menu.show_screen("menu")
	_clear_panel()


func _on_menu_sfx(n: String) -> void:
	if n == "music_toggle":
		_apply_music()
		return
	_play(n)


# =============================================================== capture args
func _handle_args() -> void:
	var args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for a in args:
		if a == "--autoplay":
			autoplay = true
		elif a == "--invincible":
			invincible = true
		elif a == "--trace":
			trace = true
		elif a == "--short":
			force_short = true
		elif a == "--shot":
			want_shot = true
		elif a == "--spike":
			spike_demo = true
		elif a == "--autonext":
			autonext = true
		elif a == "--autorevive":
			autorevive = true
		elif a == "--nearmiss":
			nearmiss_demo = true
		elif a == "--steam":
			steam_demo = true
		elif a == "--daily":
			daily_arg = true
		elif a.begins_with("--pickup="):
			pickup_arg = a.split("=")[1]
		elif a == "--unlockall":
			Profile.unlocked = 24
		elif a.begins_with("--lane="):
			forced_lane = int(a.split("=")[1])
		elif a.begins_with("--shot-delay="):
			shot_delay = float(a.split("=")[1])
		elif a.begins_with("--screen="):
			screen_arg = a.split("=")[1]
		elif a.begins_with("--level="):
			level = int(a.split("=")[1])

	if screen_arg == "daily":
		_on_daily()
		return
	match screen_arg:
		"levels", "shop", "skins":
			_show_menu()
			menu.show_screen(screen_arg)
		"settings":
			_show_menu()
			menu._open_settings()
		"play", "boss", "win", "lose", "pause":
			if daily_arg:
				_on_daily()
			else:
				_start_run(10 if screen_arg == "boss" else level)
			if pickup_arg != "":
				var prng := RandomNumberGenerator.new()
				prng.seed = 11
				_spawn_pickup(-16.0, prng, pickup_arg)
				if not pickups.is_empty():
					var lp: Dictionary = pickups[pickups.size() - 1]
					lp["x"] = blob_x
					lp["node"].position.x = blob_x
			if spike_demo:
				var srng := RandomNumberGenerator.new()
				srng.seed = 7
				_spawn_hazard(-20.0, srng)
				_spawn_hazard(-34.0, srng)
			if screen_arg == "win":
				call_deferred("_debug_win")
				if autonext:
					call_deferred("_debug_click_next")
			elif screen_arg == "lose":
				call_deferred("_debug_lose")
				if autorevive:
					call_deferred("_debug_click_revive")
			elif screen_arg == "pause":
				call_deferred("_toggle_pause")
		_:
			_show_menu()


func _debug_win() -> void:
	mass = goal * 1.55
	radius = _radius_for(mass)
	_win()


func _debug_lose() -> void:
	_die("Your blob shrank to nothing")


# =============================================================== level
func _start_mass() -> float:
	# Scales with the level so an endless ladder stays playable at level 300.
	return maxf(BASE_MASS, round(unit * 0.22)) + Profile.start_mass_bonus()


func _preview_op(m: float, op: Dictionary) -> float:
	var v := float(op["value"])
	match String(op["kind"]):
		"mul":
			return m * v
		"pct":
			return m * (1.0 + v)
		_:
			return m + v


func _estimate_goal() -> float:
	# Uses the base start mass so shop upgrades stay a real advantage.
	var m := maxf(BASE_MASS, round(unit * 0.22))
	for g in gates:
		var ops: Array = g["ops"]
		m = maxf(_preview_op(m, ops[0]), _preview_op(m, ops[1]))
	return maxf(30.0, round(m * 0.60))


func _goal_for(lv: int) -> float:
	# Soft curve: endless levels without numbers exploding into the millions.
	return round(90.0 + pow(float(clampi(lv - 1, 0, 120)), 1.18) * 26.0)


func _start_run(lv: int) -> void:
	level = maxi(1, lv)
	unit = _goal_for(level)
	goal = unit
	level_len = 60.0 if force_short else clampf(190.0 + float(level) * 6.0, 190.0, 460.0)
	mass = _start_mass()
	radius = _radius_for(mass)
	shield_left = Profile.shields()
	z = 0.0
	prev_z = 0.0
	lane = 0
	blob_x = LANE_X[0]
	run_time = 0.0
	bad_hits = 0
	eaten = 0
	coins_run = 0
	won_boss = false
	invuln = 0.0
	revives = 0
	combo = 0
	magnet_t = 0.0
	double_t = 0.0
	landed = false
	coin_shown = float(Profile.coins + coins_run)
	hitstop = 0.0
	shake = 0.0
	pop_t = 0.0
	squash = 0.0
	boss_active = level % 10 == 0
	boss_mass = goal * 0.92
	menu.visible = false
	hud.visible = true
	_clear_panel()
	_clear_world()
	_apply_biome()
	_build_scenery()
	_populate()
	_spawn_ramp()
	_apply_skin()
	_update_hud()
	lbl_hint.visible = true
	lbl_hint.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(3.2)
	tw.tween_property(lbl_hint, "modulate:a", 0.0, 0.8)
	state = "play"
	_play("pop", 0.9)
	_snap_camera()
	if steam_demo:
		var st := get_tree().create_timer(1.1).timeout
		st.connect(func() -> void: _steam(Vector3(blob_x, radius * 1.4, z), 34.0))
	if nearmiss_demo:
		var nt := get_tree().create_timer(1.0).timeout
		nt.connect(_near_miss)
	_tutorial_clear()
	if level == 1 and not Profile.tutorial_done:
		_tutorial_begin()


func _apply_biome() -> void:
	var biome: Dictionary = BIOMES[int(floor(float(level - 1) / 5.0)) % BIOMES.size()]
	var sky: ProceduralSkyMaterial = (env.sky as Sky).sky_material as ProceduralSkyMaterial
	sky.sky_top_color = biome["sky_top"]
	sky.sky_horizon_color = biome["sky_horizon"]
	sky.ground_horizon_color = biome["sky_horizon"]
	env.ambient_light_color = biome["ambient"]
	env.fog_light_color = biome["fog"]
	lbl_biome.text = String(biome["name"])
	if trace:
		print("BIOME %s level=%d" % [biome["name"], level])


func _clear_world() -> void:
	for c in world.get_children():
		c.queue_free()
	gates.clear()
	enemies.clear()
	pickups.clear()
	hazards.clear()


func _biome() -> Dictionary:
	return BIOMES[int(floor(float(level - 1) / 5.0)) % BIOMES.size()]


func _build_ground() -> void:
	var gc: Color = _biome()["ground"]
	var ground := _box(Vector3(420, 1.2, 2400), Vector3(0, -0.62, -600), gc, world)
	ground.material_override = _mat(gc, 0.95)
	var side := _box(Vector3(420, 0.4, 2400), Vector3(0, 0.02, -600), gc.darkened(0.06), world)
	side.material_override = _mat(gc.darkened(0.06), 1.0)
	_build_track()


func _build_track() -> void:
	var tc: Color = _biome()["track"]
	var track := _box(Vector3(TRACK_WIDTH, 0.5, level_len + 40.0), Vector3(0, 0.30, -(level_len + 40.0) * 0.5 + 6.0), tc, world)
	track.material_override = _mat(tc, 0.82)
	var i := 0
	var zz := 4.0
	while zz > -level_len - 20.0:
		var shade := tc.darkened(0.05) if i % 2 == 0 else tc.lightened(0.04)
		var slab := _box(Vector3(TRACK_WIDTH - 0.1, 0.06, 3.6), Vector3(0, 0.57, zz), shade, world)
		slab.material_override = _mat(shade, 0.9)
		zz -= 7.2
		i += 1
	for s in [-1.0, 1.0]:
		var rail := _box(Vector3(0.18, 0.10, level_len + 40.0), Vector3(s * (TRACK_WIDTH * 0.5 - 0.18), 0.60, -(level_len + 40.0) * 0.5 + 6.0), Color("#FF8A3D"), world)
		var rm := _mat(Color("#FF8A3D"), 0.5)
		rm.emission_enabled = true
		rm.emission = Color("#FF7A2A")
		rm.emission_energy_multiplier = 0.7
		rail.material_override = rm
	var dz := 2.0
	while dz > -level_len - 10.0:
		_box(Vector3(0.10, 0.05, 1.5), Vector3(0, 0.60, dz), Color(1, 1, 1, 0.85), world)
		dz -= 4.0


func _build_scenery() -> void:
	_build_ground()
	var biome := _biome()
	var rng := RandomNumberGenerator.new()
	rng.seed = (daily_seed + 9871) if daily_mode else (9871 + level * 37)
	var zz := 10.0
	while zz > -level_len - 40.0:
		for s: float in [-1.0, 1.0]:
			var d: float = rng.randf_range(7.0, 22.0) * s
			match String(biome["decor"]):
				"city":
					var h := rng.randf_range(4.0, 15.0)
					var w := rng.randf_range(2.4, 5.2)
					var c := Color("#26365C").lerp(Color("#3A4E7A"), rng.randf())
					var b := _box(Vector3(w, h, w), Vector3(d, h * 0.5, zz), c, world)
					b.material_override = _mat(c, 0.9)
					var light := _box(Vector3(w * 1.02, 0.5, w * 1.02), Vector3(d, h - 0.4, zz), Color("#FFD36E"), world)
					var lm := _mat(Color("#FFD36E"), 0.4)
					lm.emission_enabled = true
					lm.emission = Color("#FFC94A")
					lm.emission_energy_multiplier = 1.2
					light.material_override = lm
				"trees":
					var th := rng.randf_range(3.0, 6.0)
					var trunk := _box(Vector3(0.5, th, 0.5), Vector3(d, th * 0.5, zz), Color("#5A3B25"), world)
					trunk.material_override = _mat(Color("#5A3B25"), 0.95)
					var cone := MeshInstance3D.new()
					var cm := CylinderMesh.new()
					cm.top_radius = 0.0
					cm.bottom_radius = rng.randf_range(1.6, 2.6)
					cm.height = rng.randf_range(2.4, 4.2)
					cone.mesh = cm
					cone.position = Vector3(d, th + cm.height * 0.32, zz)
					cone.material_override = _mat(Color("#2FA05C").lerp(Color("#4FD07A"), rng.randf()), 0.9)
					world.add_child(cone)
				"rocks":
					var r := MeshInstance3D.new()
					var sm := SphereMesh.new()
					sm.radius = rng.randf_range(1.2, 3.0)
					sm.height = sm.radius * 1.7
					sm.radial_segments = 8
					sm.rings = 5
					r.mesh = sm
					r.position = Vector3(d, sm.radius * 0.5, zz)
					r.rotation_degrees = Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 360), rng.randf_range(-12, 12))
					r.material_override = _mat(Color("#A75B37").lerp(Color("#D08856"), rng.randf()), 1.0)
					world.add_child(r)
				"coral":
					var hh := rng.randf_range(3.0, 8.0)
					var cyl := MeshInstance3D.new()
					var cym := CylinderMesh.new()
					cym.top_radius = 0.22
					cym.bottom_radius = 0.55
					cym.height = hh
					cyl.mesh = cym
					cyl.position = Vector3(d, hh * 0.5, zz)
					var cc := Color("#2ED3C0").lerp(Color("#8F6BFF"), rng.randf())
					cyl.material_override = _mat(cc, 0.8)
					world.add_child(cyl)
					var tip := _box(Vector3(0.5, 0.5, 0.5), Vector3(d, hh + 0.1, zz), cc, world)
					var tm := _mat(cc, 0.5)
					tm.emission_enabled = true
					tm.emission = cc
					tm.emission_energy_multiplier = 1.4
					tip.material_override = tm
		zz -= rng.randf_range(7.0, 13.0)


func _populate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (daily_seed + 4242) if daily_mode else (4242 + level * 91)
	var gz := -38.0
	while gz > -level_len + 18.0:
		_spawn_gate_pair(gz, rng)
		var mid := gz - GATE_STEP * 0.5
		if mid > -level_len + 14.0:
			var lane_a := rng.randi_range(0, 1)
			var lane_b := 1 - lane_a
			var roll := rng.randf()
			if roll < 0.45 and level >= 3:
				_spawn_hazard(mid, rng, lane_a)
				_spawn_pickup(mid, rng, "", lane_b)
			elif roll < 0.78:
				_spawn_pickup(mid, rng, "", lane_a)
				_spawn_enemy_group(mid, rng, lane_b)
			else:
				_spawn_enemy_group(mid, rng, lane_a)
			if trace:
				print("GAP gate=%.1f mid=%.1f roll=%.2f hazard_z=%.1f pickup_z=%.1f" % [gz, mid, roll, mid, mid])
		gz -= GATE_STEP
	goal = _estimate_goal()
	boss_mass = goal * 0.92
	if boss_active:
		_spawn_boss()


func _random_good_op(rng: RandomNumberGenerator) -> Dictionary:
	# Gate values scale with the level goal so the mass economy stays readable
	# at any level number - the run is generated, never hand-tuned per level.
	var a1 := maxf(4.0, round(unit * 0.26))
	var a2 := maxf(6.0, round(unit * 0.38))
	var pool := [
		{"kind": "add", "value": a1, "text": "+%d" % int(a1)},
		{"kind": "add", "value": a2, "text": "+%d" % int(a2)},
		{"kind": "add", "value": a1, "text": "+%d" % int(a1)},
		{"kind": "mul", "value": 1.5, "text": "\u00d71.5"},
		{"kind": "mul", "value": 2.0, "text": "\u00d72"},
	]
	return pool[rng.randi_range(0, pool.size() - 1)]


func _random_bad_op(rng: RandomNumberGenerator) -> Dictionary:
	var pool := [
		{"kind": "mul", "value": 0.5, "text": "\u00f72"},
		{"kind": "mul", "value": 0.7, "text": "\u00d70.7"},
		{"kind": "pct", "value": -0.35, "text": "-35%"},
	]
	return pool[rng.randi_range(0, pool.size() - 1)]


func _op_is_good(op: Dictionary) -> bool:
	if String(op["kind"]) == "mul":
		return float(op["value"]) >= 1.0
	return float(op["value"]) >= 0.0


func _spawn_gate_pair(gz: float, rng: RandomNumberGenerator) -> void:
	var swap := rng.randf() < 0.5
	var op_left: Dictionary = _random_bad_op(rng) if swap else _random_good_op(rng)
	var op_right: Dictionary = _random_good_op(rng) if swap else _random_bad_op(rng)
	var ops: Array = [op_left, op_right]
	var nodes: Array = []
	for i in range(2):
		var side := -1.0 if i == 0 else 1.0
		var op: Dictionary = ops[i]
		var good := _op_is_good(op)
		var col: Color = GATE_COLORS[rng.randi_range(0, GATE_COLORS.size() - 1)]
		var mi := _box(Vector3(4.0, 3.8, 0.55), Vector3(side * 2.0, 1.95, gz), col, world)
		var gm := _mat(col, 0.4)
		gm.emission_enabled = true
		gm.emission = col.darkened(0.2)
		gm.emission_energy_multiplier = 0.55
		mi.material_override = gm
		var strip := _box(Vector3(4.0, 0.22, 0.66), Vector3(side * 2.0, 4.06, gz), Color(1, 1, 1), world)
		var sm := _mat(Color(1, 1, 1), 0.3)
		sm.emission_enabled = true
		sm.emission = Color(1, 1, 1)
		sm.emission_energy_multiplier = 1.15
		strip.material_override = sm
		var chip := MeshInstance3D.new()
		var cq := QuadMesh.new()
		cq.size = Vector2(3.2, 2.0)
		chip.mesh = cq
		var cm := StandardMaterial3D.new()
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cm.albedo_texture = _halo_texture()
		cm.albedo_color = Color(0.02, 0.04, 0.08, 0.55)
		cm.disable_receive_shadows = true
		chip.material_override = cm
		chip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		chip.position = Vector3(side * 2.0, 2.02, gz + 0.50)
		world.add_child(chip)
		var lbl := _label3d(String(op["text"]), 180, 0.0080, Vector3(side * 2.0, 2.02, gz + 0.56))
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.rotation_degrees = Vector3.ZERO
		lbl.no_depth_test = true
		_halo(col, 6.2, Vector3(side * 2.0, 1.95, gz - 0.35), 0.22)
		nodes.append({"panel": mi, "mat": gm, "label": lbl, "base_col": col})
	gates.append({"z": gz, "ops": ops, "nodes": nodes, "done": false})


func _spawn_enemy_group(gz: float, rng: RandomNumberGenerator, force_lane := -1) -> void:
	if gz < -level_len + 4.0:
		return
	var count := 1 if rng.randf() < 0.45 else 2
	var order := [0, 1]
	if force_lane >= 0:
		order = [force_lane, 1 - force_lane]
	elif rng.randf() < 0.5:
		order = [1, 0]
	for i in range(count):
		var ln: int = order[i]
		var em := _start_mass() * rng.randf_range(0.40, 1.05)
		if i == 1:
			em = minf(em, _start_mass() * 0.72)
		_spawn_enemy(gz - i * 1.6, LANE_X[ln], em)


func _spawn_enemy(ez: float, ex: float, em: float) -> void:
	var r := _radius_for(em)
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	mesh.radial_segments = 24
	mesh.rings = 14
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(ex, r + 0.62, ez)
	var col := Color("#5CFF9A")
	var m := _mat(col, 0.45)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 0.55
	mi.material_override = m
	world.add_child(mi)
	var lbl := _label3d(str(int(em)), 96, 0.0062, Vector3(ex, r * 2.0 + 1.05, ez))
	enemies.append({"node": mi, "mat": m, "label": lbl, "x": ex, "z": ez, "mass": em, "r": r, "alive": true, "lane": 0 if ex < 0.0 else 1})


func _spawn_pickup(pz: float, rng: RandomNumberGenerator, force := "", force_lane := -1) -> void:
	if pz < -level_len + 4.0:
		return
	var ln := force_lane if force_lane >= 0 else rng.randi_range(0, 1)
	var ex: float = LANE_X[ln]
	var roll := rng.randf()
	var kind := force if force != "" else "crystal"
	var col := Color("#42F3FF")
	if force != "":
		pass
	elif roll > 0.60 and roll <= 0.77:
		kind = "magnet"
		col = Color("#FF5E8A")
	elif roll > 0.77 and roll <= 0.92:
		kind = "shield"
		col = Color("#8CF5FF")
	elif roll > 0.92:
		kind = "double"
		col = Color("#FFD166")
	var mi := MeshInstance3D.new()
	if kind == "crystal":
		var mesh := SphereMesh.new()
		mesh.radius = 0.34
		mesh.height = 0.62
		mesh.radial_segments = 4
		mesh.rings = 2
		mi.mesh = mesh
		mi.rotation_degrees = Vector3(0, 45, 0)
	elif kind == "magnet":
		var t := TorusMesh.new()
		t.inner_radius = 0.22
		t.outer_radius = 0.40
		t.rings = 12
		t.ring_segments = 6
		mi.mesh = t
		mi.rotation_degrees = Vector3(90, 0, 0)
	elif kind == "shield":
		var sm := SphereMesh.new()
		sm.radius = 0.36
		sm.height = 0.72
		sm.radial_segments = 12
		sm.rings = 8
		mi.mesh = sm
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.5, 0.5)
		mi.mesh = bm
		mi.rotation_degrees = Vector3(0, 45, 0)
	mi.position = Vector3(ex, 1.05, pz)
	var m := _mat(col, 0.25)
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 2.2
	mi.material_override = m
	world.add_child(mi)
	pickups.append({"node": mi, "x": ex, "z": pz, "alive": true, "type": kind, "col": col})


func _spawn_hazard(hz: float, rng: RandomNumberGenerator, force_lane := -1) -> void:
	if hz < -level_len + 6.0:
		return
	var ln := force_lane if force_lane >= 0 else rng.randi_range(0, 1)
	var ex: float = LANE_X[ln]
	var swing := level >= 3 and rng.randf() < 0.45
	var root := Node3D.new()
	root.position = Vector3(ex, 0, hz)
	world.add_child(root)
	var flames: Array = []
	for k in range(3):
		var bx: float = (float(k) - 1.0) * 1.05
		# charred base
		_box(Vector3(0.86, 0.16, 0.62), Vector3(bx, 0.14, 0), Color("#2A2118"), root)
		for layer in range(2):
			var cone := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			var h := 1.35 if layer == 0 else 0.85
			cm.height = h
			cm.top_radius = 0.015
			cm.bottom_radius = 0.34 if layer == 0 else 0.22
			cm.radial_segments = 9
			cm.rings = 2
			cone.mesh = cm
			cone.position = Vector3(bx, 0.20 + h * 0.5, 0)
			var col := Color("#FF2E00") if layer == 0 else Color("#FFB020")
			var fm := _mat(col, 0.35)
			fm.emission_enabled = true
			fm.emission = col
			fm.emission_energy_multiplier = 4.2 if layer == 0 else 5.4
			fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			fm.albedo_color.a = 0.86
			cone.material_override = fm
			cone.set_meta("by", cone.position.y)
			root.add_child(cone)
			flames.append(cone)
	var lbl := _label3d("FIRE", 90, 0.0062, Vector3(0, 2.4, 0))
	lbl.modulate = Color("#FFB59A")
	lbl.reparent(root, false)
	lbl.position = Vector3(0, 2.4, 0)

	# embers rising out of the flames
	var embers := CPUParticles3D.new()
	embers.mesh = _particle_mesh()
	embers.amount = 22
	embers.lifetime = 0.85
	embers.local_coords = false
	embers.emitting = true
	embers.direction = Vector3(0, 1, 0)
	embers.spread = 26.0
	embers.gravity = Vector3(0, 3.2, 0)
	embers.initial_velocity_min = 0.6
	embers.initial_velocity_max = 1.8
	embers.scale_amount_min = 0.05
	embers.scale_amount_max = 0.14
	var eramp := Gradient.new()
	eramp.set_color(0, Color(1.0, 0.72, 0.25, 1.0))
	eramp.set_color(1, Color(1.0, 0.25, 0.05, 0.0))
	embers.color_ramp = eramp
	embers.color = Color(1.0, 0.62, 0.2, 1.0)
	embers.position = Vector3(0, 0.5, 0)
	root.add_child(embers)
	hazards.append({"node": root, "z": hz, "x": ex, "lane": ln, "done": false, "swing": swing, "phase": rng.randf() * TAU, "flames": flames})


func _spawn_ramp() -> void:
	var fz := -level_len + 3.0
	var ramp := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(TRACK_WIDTH, 0.7, 13.0)
	ramp.mesh = bm
	ramp.position = Vector3(0, 0.9, fz - 3.0)
	ramp.rotation_degrees = Vector3(13.0, 0, 0)
	var m := _mat(Color("#FF9A3C"), 0.55)
	m.emission_enabled = true
	m.emission = Color("#FF7A1A")
	m.emission_energy_multiplier = 0.35
	ramp.material_override = m
	world.add_child(ramp)

	var pool := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 9.0
	pm.bottom_radius = 8.0
	pm.height = 0.8
	pool.mesh = pm
	pool.position = Vector3(0, 0.55, fz - 12.0)
	var pmat := _mat(Color("#1FD8FF"), 0.18)
	pmat.emission_enabled = true
	pmat.emission = Color("#22C8FF")
	pmat.emission_energy_multiplier = 1.4
	pool.material_override = pmat
	world.add_child(pool)

	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 8.8
	tm.outer_radius = 9.6
	tm.rings = 48
	ring.mesh = tm
	ring.position = Vector3(0, 0.95, fz - 12.0)
	ring.rotation_degrees = Vector3(90, 0, 0)
	var rmat := _mat(Color(1, 1, 1), 0.4)
	rmat.emission_enabled = true
	rmat.emission = Color(1, 1, 1)
	rmat.emission_energy_multiplier = 1.8
	ring.material_override = rmat
	world.add_child(ring)

	var lbl := _label3d("POOL", 120, 0.008, Vector3(0, 4.4, fz - 12.0))
	lbl.modulate = Color("#BFF7FF")


func _spawn_boss() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 40
	mesh.rings = 24
	var boss := MeshInstance3D.new()
	boss.mesh = mesh
	var br := 1.15 + boss_mass * 0.0035
	boss_br = clampf(br, 1.15, 3.2)
	boss.scale = Vector3.ONE * boss_br
	boss.position = Vector3(0, boss_br + 1.2, z - 16.0)
	var m := _mat(Color("#FF2E6A"), 0.35)
	m.emission_enabled = true
	m.emission = Color("#FF2E6A")
	m.emission_energy_multiplier = 0.9
	boss.material_override = m
	world.add_child(boss)
	boss_node = boss
	boss_lbl = _label3d(str(int(boss_mass)), 130, 0.0078, Vector3(0, boss_br * 2.0 + 2.2, z - 16.0))
	boss_lbl.modulate = Color("#FFD0DD")
	boss_box.visible = true


# =============================================================== loop
func _process(delta: float) -> void:
	clock += delta
	if want_shot and not shot_taken and clock >= shot_delay:
		shot_taken = true
		_capture_shot()
	match state:
		"play":
			_update_gate_visuals()
			lbl_combo.text = ("PERFECT ×%d" % combo) if combo >= 2 else ""
			var buffs: Array = []
			if magnet_t > 0.0:
				buffs.append("MAGNET %ds" % int(ceil(magnet_t)))
			if double_t > 0.0:
				buffs.append("×2 GATES %ds" % int(ceil(double_t)))
			if shield_left > 0:
				buffs.append("SHIELD %d" % shield_left)
			lbl_buffs.text = "   ".join(buffs)
			coin_shown = lerpf(coin_shown, float(Profile.coins + coins_run), 6.0 * delta)
			lbl_coins.text = UIKit.short_num(int(round(coin_shown)))
			if hitstop > 0.0:
				hitstop -= delta
				_update_blob_visual(delta)
				_update_camera(delta)
				return
			_advance(delta)
			_check_gates()
			_check_enemies()
			_check_pickups()
			_check_hazards()
			_check_finish()
			_update_blob_visual(delta)
			_update_camera(delta)
		_:
			_update_camera(delta)
	if fx_mat != null:
		var target := 0.0
		if state == "play":
			target = clampf((radius - 0.85) / 1.5, 0.0, 1.0) * 0.55 + near_t * 0.35
		fx_strength = lerpf(fx_strength, target, 4.0 * delta)
		fx_mat.set_shader_parameter("strength", fx_strength)


func _advance(delta: float) -> void:
	prev_z = z
	run_time += delta
	var speed := SPEED_BASE + minf(4.0, float(level) * 0.12) + minf(2.5, radius * 0.2)
	z -= speed * delta
	if forced_lane >= 0:
		lane = forced_lane
	elif autoplay:
		_auto_steer()
	blob_x = move_toward(blob_x, LANE_X[lane], Profile.lane_speed() * delta)
	blob.position = Vector3(blob_x, ROAD_TOP + _ramp_height(z), z)
	if boss_node != null and is_instance_valid(boss_node):
		var bx := sin(clock * 0.8) * 2.0
		var by := boss_br + 1.25 + sin(clock * 1.7) * 0.16
		boss_node.position = Vector3(bx, by, z - 15.0)
		boss_node.rotation.y += delta * 0.6
		if boss_lbl != null and is_instance_valid(boss_lbl):
			boss_lbl.position = Vector3(bx, by + boss_br + 1.4, z - 15.0)
	magnet_t = maxf(0.0, magnet_t - delta)
	double_t = maxf(0.0, double_t - delta)
	if not landed and z <= -level_len + 3.0:
		landed = true
		shake = 0.7
		_burst(Vector3(blob_x, 0.6, z - 0.5), Color("#EAF6FF"), 16, 7.0, 0.9)
		_play("pop", 0.7)
	if invuln > 0.0:
		invuln -= delta
	for h in hazards:
		if h["done"]:
			continue
		var ph := float(h["phase"])
		for i in range(h["flames"].size()):
			var f: MeshInstance3D = h["flames"][i]
			if f == null or not is_instance_valid(f):
				continue
			var w := sin(clock * 9.0 + ph + float(i) * 1.7)
			f.scale = Vector3(1.0 + w * 0.12, 1.0 + w * 0.26, 1.0 + w * 0.12)
			f.position.y = f.get_meta("by", f.position.y) + sin(clock * 7.0 + ph + float(i)) * 0.06
			f.rotation.y += 0.9 * get_process_delta_time()
		if not h["swing"]:
			continue
		var hn: Node3D = h["node"]
		if hn != null and is_instance_valid(hn):
			hn.position.x = sin(clock * 1.25 + ph) * 2.0


func _auto_steer() -> void:
	var best := lane
	var best_val := -999.0
	for i in range(2):
		var val := 0.0
		for g in gates:
			if g["done"]:
				continue
			var gz: float = g["z"]
			var ahead := z - gz
			if ahead < -2.0 or ahead > 34.0:
				continue
			var op: Dictionary = g["ops"][i]
			val += (1.0 if _op_is_good(op) else -1.0) * (1.0 - ahead / 40.0)
		for e in enemies:
			if not e["alive"]:
				continue
			var d := z - float(e["z"])
			if d < -2.0 or d > 20.0:
				continue
			if int(e["lane"]) == i and float(e["mass"]) > mass * 1.05:
				val -= 1.2
		if val > best_val:
			best_val = val
			best = i
	lane = best


func _ramp_height(zz: float) -> float:
	var start := -level_len + 3.0
	var t := clampf((start - zz) / 12.0, 0.0, 1.0)
	return t * 2.6


func _snap_camera() -> void:
	cam.position = Vector3(blob_x * 0.45, 4.8 + radius * 0.7 + 6.8, z + 9.6 + 10.0)
	cam.look_at(Vector3(blob_x * 0.75, ROAD_TOP + radius * 0.85, z - 18.0))


func _update_camera(delta: float) -> void:
	var t := 1.0 - exp(-6.5 * delta)
	var desired := Vector3(blob_x * 0.45, 4.8 + radius * 0.7, z + 9.6)
	cam.position = cam.position.lerp(desired, t)
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 2.6)
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.22
	cam.look_at(Vector3(blob_x * 0.7, ROAD_TOP + radius * 0.85, z - 18.0))
	fov_punch = maxf(0.0, fov_punch - delta * 26.0)
	cam.fov = lerpf(cam.fov, 60.0 + minf(5.0, radius * 0.5) + fov_punch, 6.0 * delta)


# =============================================================== interactions
func _check_gates() -> void:
	for g in gates:
		if g["done"]:
			continue
		var gz: float = g["z"]
		if z <= gz + 0.4 and prev_z >= gz + 0.4:
			g["done"] = true
			var idx := clampi(lane, 0, 1)
			var op: Dictionary = g["ops"][idx]
			var good := _op_is_good(op)
			_flash_gate(g, idx)
			var nodes_b: Array = g["nodes"]
			var bcol: Color = nodes_b[idx]["base_col"] if idx < nodes_b.size() else Color("#7BE8FF")
			_burst(Vector3(LANE_X[idx], 1.9, gz + 0.6), bcol, 12, 6.5, 0.75)
			if tutorial_active():
				tut_gates += 1
				if tut_step == 0:
					_tutorial_advance()
				elif tut_step == 1 and good:
					_tutorial_advance()
				elif tut_step >= 2:
					_tutorial_advance()
			if trace:
				print("GATE z=%.1f lane=%d op=%s" % [gz, idx, op["text"]])
			_apply_op(op)
			_play("pop", 1.0 if good else 0.78)
			_buzz(18)
			if good:
				Profile.mission_add("good", 1)
				combo += 1
				_combo_reward()
			else:
				combo = 0


func _update_gate_visuals() -> void:
	# Bad gates breathe so they read as danger without relying on colour alone,
	# and enemy numbers fade out while a gate is close enough to collide visually.
	for g in gates:
		if g["done"]:
			continue
		var ops: Array = g["ops"]
		var nodes: Array = g["nodes"]
		var ahead: float = z - float(g["z"])
		var dist := maxf(5.0, ahead)
		var fade := clampf((46.0 - dist) / 14.0, 0.0, 1.0)
		for i in range(2):
			var lbl: Label3D = nodes[i]["label"]
			if lbl != null:
				lbl.modulate.a = fade
				lbl.visible = fade > 0.05
			var m: StandardMaterial3D = nodes[i]["mat"]
			if m != null:
				m.emission_energy_multiplier = 0.55 + 0.12 * (0.5 + 0.5 * sin(clock * 2.2 + float(i)))
	for e in enemies:
		if not e["alive"]:
			continue
		var lbl: Label3D = e["label"]
		if lbl == null:
			continue
		var ez: float = e["z"]
		var near := false
		for g in gates:
			if g["done"]:
				continue
			if absf(float(g["z"]) - ez) < 7.0:
				near = true
				break
		lbl.visible = not near


func _flash_gate(g: Dictionary, idx: int) -> void:
	var nodes: Array = g["nodes"]
	if idx >= nodes.size():
		return
	var n: Dictionary = nodes[idx]
	var m: StandardMaterial3D = n["mat"]
	var tw := create_tween()
	tw.tween_property(m, "emission_energy_multiplier", 3.2, 0.06)
	tw.tween_property(m, "emission_energy_multiplier", 0.55, 0.30)


func _combo_reward() -> void:
	var bonus := 0.0
	match combo:
		3:
			bonus = 0.06
		5:
			bonus = 0.10
		8:
			bonus = 0.15
	if bonus <= 0.0:
		_play("pop", 1.0 + minf(0.4, float(combo) * 0.05))
		return
	mass *= 1.0 + bonus
	radius = _radius_for(mass)
	_float_text(Vector3(blob_x, radius * 2.2 + 1.2, z - 1.0), "COMBO ×%d  +%d%%" % [combo, int(bonus * 100.0)], UIKit.C_GOLD)
	_play("star", 1.0 + minf(0.5, float(combo) * 0.05))
	_buzz(25)
	_update_hud()


func _apply_op(op: Dictionary) -> void:
	var before := mass
	var good := _op_is_good(op)
	var times := 2 if double_t > 0.0 else 1
	for i in range(times):
		match String(op["kind"]):
			"mul":
				mass *= float(op["value"])
			"pct":
				mass += mass * float(op["value"])
			_:
				mass += float(op["value"])
	mass = maxf(mass, 0.5)
	radius = _radius_for(mass)
	if trace:
		print("MASS %.1f -> %.1f" % [before, mass])
	_float_text(Vector3(blob_x, radius * 2.0 + 1.4, z - 1.0), String(op["text"]), UIKit.C_LIME if good else UIKit.C_DANGER)
	_pop_blob()
	if not good:
		bad_hits += 1
		shake = maxf(shake, 0.55)
	_update_hud()
	if mass < MASS_MIN:
		_die("Your blob shrank to nothing")


func _check_enemies() -> void:
	for e in enemies:
		if not e["alive"]:
			continue
		var ez: float = e["z"]
		if z > ez + 0.8 or prev_z < ez + 0.8:
			continue
		var dx: float = absf(blob_x - float(e["x"]))
		if dx > radius + float(e["r"]) + 0.25:
			continue
		e["alive"] = false
		var em: float = e["mass"]
		var node: MeshInstance3D = e["node"]
		var lbl: Label3D = e["label"]
		if lbl != null:
			lbl.queue_free()
		if mass > em * 1.06:
			mass += em * 0.55
			radius = _radius_for(mass)
			eaten += 1
			coins_run += 2
			Profile.mission_add("eaten", 1)
			_float_text(node.position + Vector3(0, 1.2, 0), "+%d" % int(em * 0.55), UIKit.C_LIME)
			_play("eat", 0.9 + minf(0.5, mass / 400.0))
			_buzz(12)
			_absorb(node)
			hitstop = 0.045
			shake = maxf(shake, 0.25)
		else:
			var tw := create_tween()
			tw.tween_property(node, "scale", Vector3.ONE * 1.8, 0.18)
			_die("A bigger blob absorbed you")
		_update_hud()


func _absorb(node: Node3D) -> void:
	_burst(node.global_position, Color("#5CFF9A"), 16, 8.0, 0.85)
	var target := Vector3(blob_x, radius, z)
	var tw := create_tween()
	tw.tween_property(node, "global_position", target, 0.16).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(node, "scale", Vector3.ONE * 0.05, 0.16)
	tw.tween_callback(node.queue_free)


func _check_pickups() -> void:
	var mag := Profile.magnet_radius() + (10.0 if magnet_t > 0.0 else 0.0)
	for p in pickups:
		if not p["alive"]:
			continue
		var pz: float = p["z"]
		var node: MeshInstance3D = p["node"]
		var dist := z - pz
		if dist < -1.0 or dist > 40.0:
			continue
		if mag > 0.0 and dist < 16.0:
			node.position.x = move_toward(node.position.x, blob_x, 4.0 * get_process_delta_time() * (1.0 + mag))
		if absf(z - pz) < 1.2 and absf(blob_x - node.position.x) < radius + 0.75 + mag * 0.35:
			p["alive"] = false
			var kind := String(p.get("type", "crystal"))
			var col: Color = p.get("col", UIKit.C_ACCENT)
			match kind:
				"magnet":
					magnet_t = 8.0
					_float_text(node.position + Vector3(0, 1.1, 0), "MAGNET 8s", col)
					_play("buy")
					_buzz(30)
				"shield":
					shield_left += 1
					_float_text(node.position + Vector3(0, 1.1, 0), "SHIELD +1", col)
					_play("star")
					_buzz(30)
				"double":
					double_t = 6.0
					_float_text(node.position + Vector3(0, 1.1, 0), "×2 GATES 6s", col)
					_play("star", 1.15)
					_buzz(35)
				_:
					mass += maxf(3.0, mass * 0.10)
					radius = _radius_for(mass)
					coins_run += 5
					_float_text(node.position + Vector3(0, 1.0, 0), "+ORB", col)
					_play("pop", 1.25)
			_burst(node.position, col, 12, 6.0, 0.8)
			var tw := create_tween()
			tw.tween_property(node, "scale", Vector3.ONE * 0.05, 0.12)
			tw.tween_callback(node.queue_free)
			_update_hud()


func _check_hazards() -> void:
	for h in hazards:
		if h["done"]:
			continue
		var hz: float = h["z"]
		if prev_z >= hz and z < hz:
			h["done"] = true
			var node: Node3D = h["node"]
			var hx := node.position.x if node != null else float(h["x"])
			if invuln > 0.0:
				continue
			if absf(blob_x - hx) < radius + 0.35:
				var before := mass
				mass *= 0.7
				radius = _radius_for(mass)
				var lost := maxf(0.0, before - mass)
				bad_hits += 1
				combo = 0
				shake = 0.9
				_play("hurt", 0.9)
				_play("steam")
				_buzz(70)
				_burst(Vector3(blob_x, radius * 1.3, z + 0.4), Color("#FF7A1A"), 16, 8.0, 0.9)
				_steam(Vector3(blob_x, radius * 1.5, z + 0.2), lost)
				if trace:
					print("FIRE hit lost=%.1f steam=%s" % [lost, str(sfx.has("steam"))])
				_float_text(Vector3(blob_x, radius * 2.0 + 1.1, z - 1.0), "-%d%%" % 30, UIKit.C_DANGER)
				_update_hud()
				if mass < MASS_MIN:
					_die("The spikes drained you")


func _check_finish() -> void:
	if z <= -level_len + 1.0:
		var need := boss_mass if boss_active else goal
		if mass < need and not invincible:
			_die("You needed %d mass to fill the pool" % int(need))
		else:
			won_boss = boss_active
			_win()


# =============================================================== visuals
func _radius_for(m: float) -> float:
	return clampf(0.174 + pow(maxf(m, 1.0), 1.0 / 3.0) * 0.087, 0.17, 1.35)


func _apply_skin() -> void:
	var sd := Profile.skin_data()
	blob_mat.set_shader_parameter("base_color", sd["base"])
	blob_mat.set_shader_parameter("rim_color", sd["rim"])
	if blob_halo != null:
		var hm: StandardMaterial3D = blob_halo.material_override
		var bc: Color = sd["base"]
		hm.albedo_color = Color(bc.r, bc.g, bc.b, 0.30)


func _update_blob_visual(delta: float) -> void:
	pop_t = maxf(0.0, pop_t - delta * 2.4)
	var target_sq := clampf((LANE_X[lane] - blob_x) * 0.05, -0.16, 0.16)
	squash = lerpf(squash, target_sq, 8.0 * delta)
	var pop := 1.0 + pop_t * 0.45
	var base := radius * pop
	blob.scale = Vector3(base * (1.0 - squash * 0.5), base * (1.0 + squash), base * (1.0 - squash * 0.5))
	blob.position = Vector3(blob_x, radius + _ramp_height(z), z)
	blob.rotation.z = lerpf(blob.rotation.z, -squash * 0.8, 6.0 * delta)
	blob.visible = true if invuln <= 0.0 else int(clock * 14.0) % 2 == 0
	if blob_halo != null:
		blob_halo.position = Vector3(blob_x, ROAD_TOP + _ramp_height(z) + radius * 1.18, z + 0.12)
		blob_halo.scale = Vector3.ONE * radius * 3.4
	if blob_shadow != null:
		blob_shadow.position = Vector3(blob_x, ROAD_TOP + _ramp_height(z) + 0.02, z + 0.1)
		blob_shadow.scale = Vector3.ONE * radius * 2.5
	if trail != null:
		trail.position = Vector3(blob_x, ROAD_TOP + _ramp_height(z) + radius * 0.55, z + radius * 0.75)
		trail.emitting = state == "play" and radius > 0.45


func _pop_blob() -> void:
	pop_t = 0.32
	shake = maxf(shake, 0.2)


func _float_text(pos: Vector3, text: String, color: Color) -> void:
	var lbl := _label3d(text, 130, 0.008, pos)
	lbl.modulate = color
	lbl.outline_size = 22
	lbl.outline_modulate = Color(0.02, 0.03, 0.08, 0.9)
	var tw := create_tween()
	tw.parallel().tween_property(lbl, "position:y", pos.y + 1.9, 0.65).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.65)
	tw.tween_callback(lbl.queue_free)


# =============================================================== flow
func _die(reason: String) -> void:
	if state != "play":
		return
	if invincible:
		mass = maxf(mass, MASS_MIN + 2.0)
		radius = _radius_for(mass)
		invuln = 0.8
		_update_hud()
		return
	if shield_left > 0:
		shield_left -= 1
		invuln = 1.4
		mass = maxf(MASS_MIN + 2.0, mass)
		radius = _radius_for(mass)
		_play("hurt", 1.3)
		_buzz(120)
		shake = 1.0
		_float_text(Vector3(blob_x, radius * 2.0 + 1.0, z - 1.0), "SHIELD!", UIKit.C_ACCENT)
		_update_hud()
		return
	state = "dead"
	_burst(Vector3(blob_x, radius, z), Color("#7BE8FF"), 24, 10.0, 1.2)
	_play("lose")
	_buzz(180)
	shake = 1.4
	death_tw = create_tween()
	death_tw.tween_property(blob, "scale", Vector3(radius * 1.4, radius * 0.2, radius * 1.4), 0.30)
	death_tw.tween_callback(func() -> void: blob.visible = false)
	_show_lose(reason)


func _win() -> void:
	if state != "play":
		return
	state = "win"
	_burst(Vector3(blob_x, 1.6, z - 1.2), Color("#8FE6FF"), 30, 12.0, 1.4)
	_play("win")
	_buzz(80)
	var earned := int(mass * 0.22) + 20
	if won_boss:
		earned += 100
	coins_run += earned
	var star_count := 1
	if mass >= goal * 1.25:
		star_count = 2
	if mass >= goal * 1.6:
		star_count = 3
	if daily_mode:
		# a daily run never unlocks progression - it only pays coins and sets the day's best
		Profile.daily_date = Time.get_date_string_from_system()
		Profile.daily_best = maxi(Profile.daily_best, int(mass))
		Profile.coins += earned
		Profile.best_mass = maxi(Profile.best_mass, int(mass))
		Profile.mission_add("pools", 1)
		Profile.mission_add("coins", earned)
		Profile.save_profile()
	else:
		Profile.finish_level(level, star_count, int(mass), earned)
	if trace:
		print("RESULT win level=%d mass=%.0f goal=%.0f ratio=%.2f stars=%d" % [level, mass, goal, mass / maxf(goal, 1.0), star_count])
	_show_win(star_count, earned)


# =============================================================== panels
func _clear_panel() -> void:
	for c in panel_layer.get_children():
		c.queue_free()


func _panel_shell(_unused := 0) -> VBoxContainer:
	_clear_panel()
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.09, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.panel_style(30, Color("#111B38"), Color(1, 1, 1, 0.12), 1, 28))
	card.custom_minimum_size = Vector2(600, 0)
	center.add_child(card)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 30)
	for side in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 28)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	return v


func _show_win(stars: int, earned: int) -> void:
	_tutorial_clear()
	hud.visible = false
	var v := _panel_shell()
	var cap := UIKit.label("LEVEL %d CLEAR" % level, 13, UIKit.C_ACCENT, 700, false)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	var title := UIKit.title("NICE!", 54, UIKit.C_TEXT, 700, 12, Color(0.03, 0.05, 0.12, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)

	var sr := StarRow.new()
	sr.count = 3
	sr.star_size = 44
	sr.gap = 12
	sr.filled = 0
	sr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sr.fit()
	v.add_child(sr)
	for i in range(stars):
		var idx := i
		var timer := get_tree().create_timer(0.18 + 0.16 * float(i))
		timer.timeout.connect(func() -> void:
			sr.filled = idx + 1
			_play("star", 1.0 + 0.08 * float(idx))
		)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	v.add_child(stats)
	stats.add_child(_stat_box("MASS", str(int(mass))))
	stats.add_child(_stat_box("GOAL", str(int(goal))))
	stats.add_child(_stat_box("STARS", "%d/3" % stars))

	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_row.add_theme_constant_override("separation", 8)
	v.add_child(coin_row)
	coin_row.add_child(UIKit.coin_icon(26))
	var cl := UIKit.title("+%d" % earned, 30, UIKit.C_GOLD, 600)
	coin_row.add_child(cl)

	v.add_child(UIKit.hsep(6))
	var next := UIKit.button("NEXT LEVEL", "primary", 62, 23)
	next.pressed.connect(func() -> void:
		_play("click")
		_start_run(level + 1)
	)
	v.add_child(next)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	v.add_child(row)
	var replay := UIKit.button("REPLAY", "ghost", 52, 17)
	replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay.pressed.connect(func() -> void:
		_play("click")
		_start_run(level)
	)
	row.add_child(replay)
	var home := UIKit.button("HOME", "ghost", 52, 17)
	home.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.pressed.connect(func() -> void:
		_play("click")
		_show_menu()
	)
	row.add_child(home)
	_play("star", 1.0)


func tutorial_active() -> bool:
	return tut_layer != null and is_instance_valid(tut_layer) and tut_step < 3


func _tutorial_begin() -> void:
	tut_step = 0
	tut_gates = 0
	lbl_hint.visible = false
	tut_layer = Control.new()
	tut_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	tut_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(tut_layer)

	tut_label = UIKit.label("TAP LEFT OR RIGHT TO SWITCH LANES", 19, UIKit.C_TEXT, 800, true)
	tut_label.add_theme_constant_override("outline_size", 6)
	tut_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.92))
	tut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tut_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	tut_label.offset_top = -300.0
	tut_label.offset_bottom = -250.0
	tut_layer.add_child(tut_label)

	tut_hand = UIKit.panel(UIKit.C_ACCENT, 44, Color(1, 1, 1, 0.55), 0)
	tut_hand.size = Vector2(88, 88)
	tut_hand.position = Vector2(120, 1240)
	tut_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tut_layer.add_child(tut_hand)
	var hl := UIKit.label("TAP", 15, Color("#07101F"), 800, false)
	hl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tut_hand.add_child(hl)
	var tw := create_tween().set_loops()
	tw.tween_property(tut_hand, "position:x", 510.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(tut_hand, "position:x", 120.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _tutorial_advance() -> void:
	if tut_layer == null:
		return
	tut_step += 1
	match tut_step:
		1:
			tut_label.text = "NOW ROLL THROUGH A GREEN GATE"
		2:
			tut_label.text = "RED GATES SHRINK YOU - DODGE THEM"
		_:
			_tutorial_finish()


func _tutorial_clear() -> void:
	if tut_layer != null and is_instance_valid(tut_layer):
		tut_layer.queue_free()
	tut_layer = null
	tut_step = 3


func _tutorial_finish() -> void:
	Profile.tutorial_done = true
	Profile.save_profile()
	if tut_layer != null and is_instance_valid(tut_layer):
		var tw := create_tween()
		tw.tween_property(tut_layer, "modulate:a", 0.0, 0.35)
		tw.tween_callback(tut_layer.queue_free)


func _revive_cost() -> int:
	return 120 + revives * 80


func _do_revive() -> void:
	# only from the death screen: a second tap must never charge coins again
	if state != "dead":
		return
	var cost := _revive_cost()
	if Profile.coins < cost:
		return
	Profile.coins -= cost
	Profile.save_profile()
	revives += 1
	if death_tw != null and death_tw.is_valid():
		death_tw.kill()
	death_tw = null
	_clear_panel()
	hud.visible = true
	state = "play"
	mass = maxf(mass, goal * 0.55)
	radius = _radius_for(mass)
	invuln = 3.0
	prev_z = z
	blob.visible = true
	blob.scale = Vector3.ONE * radius
	_play("buy")
	_buzz(45)
	_burst(Vector3(blob_x, radius, z), Color("#7BE8FF"), 20, 9.0, 1.0)
	_update_hud()


func _show_lose(reason: String) -> void:
	_tutorial_clear()
	hud.visible = false
	var v := _panel_shell()
	var cap := UIKit.label("RUN OVER", 13, UIKit.C_DANGER, 700, false)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	var title := UIKit.title("TOO SMALL", 46, UIKit.C_TEXT, 700, 12, Color(0.03, 0.05, 0.12, 0.8))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UIKit.label(reason, 16, UIKit.C_MUTED, 700, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sub)

	var bar := GoalBar.new()
	bar.custom_minimum_size = Vector2(0, 14)
	bar.fill_b = UIKit.C_DANGER
	bar.fill_a = UIKit.C_PINK
	bar.value = mass / maxf(goal, 1.0)
	v.add_child(bar)
	var gl := UIKit.label("%d / %d MASS" % [int(mass), int(goal)], 14, UIKit.C_MUTED, 700, false)
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(gl)
	v.add_child(UIKit.hsep(8))
	var retry := UIKit.button("RETRY", "primary", 64, 24)
	retry.pressed.connect(func() -> void:
		_play("click")
		_start_run(level)
	)
	v.add_child(retry)
	var can_revive := revives < 2 and Profile.coins >= _revive_cost()
	if can_revive:
		var cont := UIKit.button("REVIVE  ·  %d COINS" % _revive_cost(), "gold", 58, 19)
		cont.pressed.connect(func() -> void:
			_play("click")
			_do_revive()
		)
		v.add_child(cont)
	var home := UIKit.button("HOME", "ghost", 52, 17)
	home.pressed.connect(func() -> void:
		_play("click")
		_show_menu()
	)
	v.add_child(home)


func _stat_box(caption: String, value: String) -> Panel:
	var p := UIKit.panel(Color(1, 1, 1, 0.06), 18, Color(1, 1, 1, 0.09), 0)
	p.custom_minimum_size = Vector2(0, 74)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 12
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 0)
	p.add_child(v)
	var c := UIKit.label(caption, 10, UIKit.C_MUTED, 700, false)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(c)
	var val := UIKit.label(value, 24, UIKit.C_TEXT, 600)
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(val)
	return p


func _toggle_pause() -> void:
	if state == "play":
		state = "paused"
		_show_pause()
	elif state == "paused":
		state = "play"
		hud.visible = true
		_clear_panel()


func _show_pause() -> void:
	hud.visible = false
	var v := _panel_shell()
	var t := UIKit.title("PAUSED", 44, UIKit.C_TEXT, 600)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var s := UIKit.label("LEVEL %d  ·  %d MASS" % [level, int(mass)], 15, UIKit.C_MUTED, 700, false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	v.add_child(UIKit.hsep(10))
	var resume := UIKit.button("RESUME", "primary", 60, 22)
	resume.pressed.connect(func() -> void:
		_play("click")
		_toggle_pause()
	)
	v.add_child(resume)
	var restart := UIKit.button("RESTART", "ghost", 50, 17)
	restart.pressed.connect(func() -> void:
		_play("click")
		_start_run(level)
	)
	v.add_child(restart)
	var home := UIKit.button("HOME", "ghost", 50, 17)
	home.pressed.connect(func() -> void:
		_play("click")
		_show_menu()
	)
	v.add_child(home)


# =============================================================== input
func _unhandled_input(event: InputEvent) -> void:
	if state == "paused":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match (event as InputEventKey).keycode:
			KEY_LEFT, KEY_A:
				_set_lane(lane - 1)
			KEY_RIGHT, KEY_D:
				_set_lane(lane + 1)
	elif event is InputEventScreenTouch and event.pressed:
		if state == "play":
			_tap_side((event as InputEventScreenTouch).position.x)
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if state == "play":
			_tap_side((event as InputEventMouseButton).position.x)
	elif event is InputEventScreenDrag:
		_swipe((event as InputEventScreenDrag).relative.x)
	elif event is InputEventMouseMotion and ((event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT):
		_swipe((event as InputEventMouseMotion).relative.x)


func _tap_side(px: float) -> void:
	var half := get_viewport().get_visible_rect().size.x * 0.5
	_set_lane(0 if px < half else 1)


func _swipe(dx: float) -> void:
	if state != "play" or absf(dx) < 12.0:
		return
	_set_lane(lane + (1 if dx > 0.0 else -1))


func _set_lane(i: int) -> void:
	var n := clampi(i, 0, 1)
	if n == lane:
		return
	lane = n
	_play("click", 1.35, -8.0)
	for g in gates:
		if g["done"]:
			continue
		var ahead: float = z - float(g["z"])
		if ahead > 0.0 and ahead < 8.5:
			_near_miss()
			break
	if tut_step == 0:
		_tutorial_advance()


func _near_miss() -> void:
	if trace:
		print("NEAR_MISS z=%.1f" % z)
	fov_punch = 7.5
	near_t = 1.0
	Engine.time_scale = 0.55
	var t := get_tree().create_timer(0.13, true, false, true)
	t.timeout.connect(func() -> void:
		Engine.time_scale = 1.0
		near_t = 0.0
	)


# =============================================================== hud
func _update_hud() -> void:
	lbl_level.text = "DAILY RUN" if daily_mode else "LEVEL %d" % level
	lbl_mass.text = str(int(mass))
	lbl_coins.text = UIKit.short_num(Profile.coins + coins_run)
	lbl_goal.text = "GOAL %d" % int(goal)
	goal_bar.value = mass / maxf(goal, 1.0)
	goal_bar.fill_b = UIKit.C_LIME if mass >= goal else UIKit.C_ACCENT
	for c in shield_row.get_children():
		c.queue_free()
	for i in range(shield_left):
		var p := Panel.new()
		p.custom_minimum_size = Vector2(16, 16)
		p.add_theme_stylebox_override("panel", UIKit.panel_style(8, UIKit.C_ACCENT, Color(1, 1, 1, 0.5), 0, 0))
		shield_row.add_child(p)
	if boss_active:
		boss_box.visible = true
		lbl_boss.text = "RIVAL  %d" % int(boss_mass)
		boss_bar.value = mass / maxf(boss_mass, 1.0)


# =============================================================== utils
func _mat(c: Color, rough := 0.75, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _box(size: Vector3, pos: Vector3, c: Color, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _mat(c, 0.8)
	parent.add_child(mi)
	return mi


func _label3d(text: String, size: int, px: float, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = UIKit.display(600)
	l.font_size = size
	l.pixel_size = px
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 18
	l.outline_modulate = Color(0.02, 0.03, 0.08, 0.85)
	world.add_child(l)
	return l


func _capture_shot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "user://shot_%d.png" % Time.get_ticks_msec()
	img.save_png(path)
	print("DEBUG_LAYOUT win=%s vp=%s ui=%s menu=%s bg=%s img=%s" % [
		get_window().size, get_viewport().get_visible_rect().size, ui_root.size,
		menu.size, (menu.get_child(0) as Control).size, img.get_size()])
	print("SHOT_SAVED::%s" % ProjectSettings.globalize_path(path))
	get_tree().quit()


func _on_daily() -> void:
	daily_mode = true
	daily_seed = 7717 + int(Time.get_unix_time_from_system() / 86400.0) * 131
	_start_run(1)


func _on_play() -> void:
	daily_mode = false
	_play("click")
	_start_run(maxi(1, Profile.unlocked))


func _on_level_selected(n: int) -> void:
	daily_mode = false
	_start_run(n)
