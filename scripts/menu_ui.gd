class_name MenuUI
extends Control

const L10n = preload("res://scripts/l10n.gd")
## All menu screens: home, level select, upgrades, skins, settings.

signal play_pressed
signal daily_pressed
signal level_selected(level: int)
signal sfx_requested(name: String)

const BG_SHADER := preload("res://shaders/menu_bg.gdshader")

var screen := "menu"
var _content: Control
var _hero: BlobHero
var _settings_open := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_background()
	_content = Control.new()
	_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	show_screen("menu")


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = BG_SHADER
	bg.material = mat
	add_child(bg)


func _refresh() -> void:
	show_screen(screen)


func show_screen(name: String) -> void:
	screen = name
	_settings_open = false
	for c in _content.get_children():
		c.queue_free()
	match name:
		"levels":
			_build_levels()
		"shop":
			_build_shop()
		"skins":
			_build_skins()
		_:
			screen = "menu"
			_build_home()


# ---------------------------------------------------------------- helpers
func _click() -> void:
	sfx_requested.emit("click")


func _btn(text: String, kind := "primary", height := 62, font := 24) -> Button:
	var b := UIKit.button(text, kind, height, font)
	b.pressed.connect(_click)
	return b


func _top_bar(title_text: String, back := true) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.custom_minimum_size = Vector2(0, 52)
	if back:
		var b := UIKit.icon_button("<", 46)
		b.pressed.connect(func() -> void:
			_click()
			show_screen("menu")
		)
		row.add_child(b)
	var t := UIKit.title(title_text, 30, UIKit.C_TEXT, 600)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(t)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sp)
	row.add_child(_coin_chip())
	return row


func _coin_chip() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UIKit.panel_style(24, Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.14), 1, 10, 0.35))
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 7)
	m.add_theme_constant_override("margin_bottom", 7)
	p.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_child(h)
	var ic := UIKit.coin_icon(22)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	var l := UIKit.label(UIKit.short_num(Profile.coins), 21, UIKit.C_TEXT, 700, false)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	return p


func _screen_root() -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 26)
	m.add_theme_constant_override("margin_right", 26)
	m.add_theme_constant_override("margin_top", 36)
	m.add_theme_constant_override("margin_bottom", 40)
	_content.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)
	return v


# ---------------------------------------------------------------- home
func _build_home() -> void:
	var v := _screen_root()

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(_coin_chip())
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var best := UIKit.chip(("بهترین %s" if Profile.is_fa() else "BEST %s") % UIKit.short_num(Profile.best_mass), UIKit.C_GOLD)
	best.custom_minimum_size = Vector2(176, 48)
	top.add_child(best)
	var gear := UIKit.icon_button("...", 44)
	gear.pressed.connect(func() -> void:
		_click()
		_open_settings()
	)
	top.add_child(gear)
	v.add_child(top)

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grow)

	var hero_wrap := Control.new()
	hero_wrap.custom_minimum_size = Vector2(0, 232)
	hero_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(hero_wrap)
	_hero = BlobHero.new()
	_hero.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sd := Profile.skin_data()
	_hero.color_a = sd["base"]
	_hero.color_b = Color(sd["base"]).darkened(0.35)
	_hero.rim = sd["rim"]
	hero_wrap.add_child(_hero)

	var logo := UIKit.shadowed("قطره" if Profile.is_fa() else "BLOB", 88, UIKit.C_TEXT, 700)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(logo)
	var tag := UIKit.label(L10n.t("G R O W   ·   R O L L   ·   R E P E A T"), 15, UIKit.C_MUTED, 700, false)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tag)

	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, 18)
	v.add_child(pad)

	var play := _btn(L10n.t("PLAY"), "primary", 90, 34)
	play.pressed.connect(func() -> void: play_pressed.emit())
	v.add_child(play)

	var daily := _btn(("ران امروز  ·  رکورد %s" if Profile.is_fa() else "TODAY'S RUN  ·  BEST %s") % UIKit.short_num(Profile.daily_best), "ghost", 58, 17)
	daily.pressed.connect(func() -> void:
		_click()
		daily_pressed.emit()
	)
	v.add_child(daily)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for item in [[L10n.t("LEVELS"), "levels"], [L10n.t("SHOP"), "shop"], [L10n.t("SKINS"), "skins"]]:
		var b := _btn(item[0], "ghost", 60, 18)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var target: String = item[1]
		b.pressed.connect(func() -> void: show_screen(target))
		row.add_child(b)
	v.add_child(row)

	v.add_child(_stat_grid())
	v.add_child(_mission_card())
	v.add_child(_howto_card())
	var ver := UIKit.label("v0.2  ·  %d STARS" % Profile.total_stars(), 13, UIKit.C_DIM, 700, false)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ver)


func _stat_card(cap: String, val: String) -> Panel:
	var p := UIKit.panel(Color(1, 1, 1, 0.05), 18, Color(1, 1, 1, 0.09), 0)
	p.custom_minimum_size = Vector2(0, 86)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var b := VBoxContainer.new()
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.offset_top = 10
	b.offset_bottom = -10
	b.add_theme_constant_override("separation", 2)
	b.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(b)
	var c := UIKit.label(cap, 10, UIKit.C_MUTED, 700, false)
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(c)
	var t := UIKit.title(val, 30, UIKit.C_TEXT, 700)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(t)
	return p


func _stat_grid() -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 10)
	g.add_child(_stat_card(L10n.t("STARS"), "%d" % Profile.total_stars()))
	g.add_child(_stat_card(L10n.t("LEVEL"), "%d" % Profile.unlocked))
	g.add_child(_stat_card(L10n.t("SKINS"), "%d / %d" % [Profile.owned_skins.size(), Profile.SKINS.size()]))
	g.add_child(_stat_card(L10n.t("DAILY BEST"), UIKit.short_num(Profile.daily_best)))
	return g


func _howto_card() -> Panel:
	var p := UIKit.panel(Color("#101A33"), 20, UIKit.C_BORDER, 12)
	p.custom_minimum_size = Vector2(0, 106)
	var hv := VBoxContainer.new()
	hv.set_anchors_preset(Control.PRESET_FULL_RECT)
	hv.offset_left = 16
	hv.offset_right = -16
	hv.offset_top = 12
	hv.offset_bottom = -12
	hv.add_theme_constant_override("separation", 4)
	p.add_child(hv)
	hv.add_child(UIKit.label(L10n.t("HOW TO PLAY"), 10, UIKit.C_ACCENT, 800, false))
	for line in [L10n.t("TAP LEFT / RIGHT TO PICK A GATE"), L10n.t("COLOUR MEANS NOTHING - READ THE NUMBER"), L10n.t("FIRE BURNS 30% OF YOUR MASS")]:
		hv.add_child(UIKit.label(line, 12, UIKit.C_MUTED, 700, false))
	return p


func _mission_card() -> Panel:
	var p := UIKit.panel(UIKit.C_CARD, 22, UIKit.C_BORDER, 14)
	p.custom_minimum_size = Vector2(0, 124)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 18
	h.offset_right = -16
	h.offset_top = 14
	h.offset_bottom = -14
	h.add_theme_constant_override("separation", 12)
	p.add_child(h)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 5)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(left)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	left.add_child(head)
	var cap := UIKit.label(L10n.t("DAILY MISSION"), 12, UIKit.C_ACCENT, 700, false)
	head.add_child(cap)
	var prog := UIKit.label("%d/%d" % [int(Profile.mission.get("progress", 0)), int(Profile.mission.get("target", 1))], 12, UIKit.C_DIM, 700, false)
	head.add_child(prog)
	var txt := UIKit.label(L10n.t(Profile.mission_template()).replace("{n}", str(int(Profile.mission.get("target", 0)))), 19, UIKit.C_TEXT, 700, false)
	txt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	left.add_child(txt)
	var bar := GoalBar.new()
	bar.custom_minimum_size = Vector2(0, 10)
	bar.fill_a = UIKit.C_ACCENT
	bar.fill_b = UIKit.C_LIME
	var target := maxf(1.0, float(Profile.mission.get("target", 1)))
	bar.value = float(Profile.mission.get("progress", 0)) / target
	left.add_child(bar)

	var pill := UIKit.panel(Color(1, 1, 1, 0.06), 16, Color(1, 1, 1, 0.09), 0)
	pill.custom_minimum_size = Vector2(92, 46)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(pill)
	var ph := HBoxContainer.new()
	ph.set_anchors_preset(Control.PRESET_FULL_RECT)
	ph.add_theme_constant_override("separation", 5)
	ph.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(ph)
	ph.add_child(UIKit.coin_icon(18))
	var reward := UIKit.label("+%d" % int(Profile.mission.get("reward", 0)), 18, UIKit.C_GOLD, 700, false)
	ph.add_child(reward)

	if Profile.mission_done() and not bool(Profile.mission.get("claimed", false)):
		var claim := _btn(L10n.t("CLAIM"), "gold", 46, 15)
		claim.custom_minimum_size = Vector2(88, 46)
		claim.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		claim.pressed.connect(func() -> void:
			if Profile.claim_mission():
				sfx_requested.emit("buy")
				_refresh()
		)
		h.add_child(claim)
	elif bool(Profile.mission.get("claimed", false)):
		var done := UIKit.label(L10n.t("DONE"), 14, UIKit.C_LIME, 700, false)
		done.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(done)
	return p


# ---------------------------------------------------------------- levels
func _build_levels() -> void:
	var v := _screen_root()
	v.add_child(_top_bar(L10n.t("LEVELS")))
	var sub := UIKit.label(L10n.t("ENDLESS  ·  EVERY LEVEL IS GENERATED"), 11, UIKit.C_DIM, 700, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	stats.add_child(UIKit.chip(("ستاره %d" if Profile.is_fa() else "STARS %d") % Profile.total_stars(), UIKit.C_GOLD))
	stats.add_child(UIKit.chip(("باز %d" if Profile.is_fa() else "OPEN %d") % Profile.unlocked, UIKit.C_ACCENT))
	v.add_child(stats)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	var count := maxi(24, Profile.unlocked + 8)
	for i in range(1, count + 1):
		grid.add_child(_level_tile(i))


func _level_tile(n: int) -> Control:
	var locked := n > Profile.unlocked
	var p := UIKit.panel(
		Color(1, 1, 1, 0.03) if locked else Color(1, 1, 1, 0.07),
		20,
		Color(1, 1, 1, 0.06) if locked else Color(1, 1, 1, 0.12),
		10
	)
	p.custom_minimum_size = Vector2(0, 118)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := VBoxContainer.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.offset_top = 12
	inner.offset_bottom = -10
	inner.add_theme_constant_override("separation", 4)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(inner)

	var num := UIKit.title(str(n), 30, UIKit.C_DIM if locked else UIKit.C_TEXT, 600)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(num)

	if locked:
		var l := UIKit.label(L10n.t("LOCKED"), 9, UIKit.C_DIM, 700, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(l)
	else:
		var s := StarRow.new()
		s.count = 3
		s.star_size = 12
		s.gap = 4
		s.filled = Profile.stars_for(n)
		s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(s)

	if n % 10 == 0 and not locked:
		var badge := UIKit.label(L10n.t("BOSS"), 9, UIKit.C_PINK, 700, false)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner.add_child(badge)

	if not locked:
		var b := Button.new()
		b.flat = true
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.pressed.connect(func() -> void:
			_click()
			level_selected.emit(n)
		)
		p.add_child(b)
	return p


# ---------------------------------------------------------------- shop
func _build_shop() -> void:
	var v := _screen_root()
	v.add_child(_top_bar(L10n.t("UPGRADES")))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(col)
	for key in ["start", "magnet", "speed", "shield"]:
		col.add_child(_upgrade_card(key))
	var note := UIKit.label("Upgrades are permanent and apply to every run.", 14, UIKit.C_MUTED, 700, false)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)


func _upgrade_card(key: String) -> Control:
	var info: Dictionary = Profile.UPGRADES[key]
	var lvl: int = Profile.up_level(key)
	var maxed := lvl >= int(info["max"])
	var p := UIKit.panel(UIKit.C_CARD, 22, UIKit.C_BORDER, 12)
	p.custom_minimum_size = Vector2(0, 130)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16
	h.offset_right = -16
	h.offset_top = 12
	h.offset_bottom = -12
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)

	var icon := Panel.new()
	icon.custom_minimum_size = Vector2(58, 58)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic := UIKit.C_ACCENT
	match key:
		"start": ic = UIKit.C_LIME
		"magnet": ic = UIKit.C_ACCENT
		"speed": ic = UIKit.C_GOLD
		"shield": ic = UIKit.C_PINK
	icon.add_theme_stylebox_override("panel", UIKit.panel_style(18, Color(ic.r, ic.g, ic.b, 0.18), Color(ic.r, ic.g, ic.b, 0.45), 0, 0))
	h.add_child(icon)
	var glyph := UIKit.label(key.substr(0, 1).to_upper(), 26, ic, 700)
	glyph.set_anchors_preset(Control.PRESET_CENTER)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.add_child(glyph)

	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(mid)
	mid.add_child(UIKit.label(L10n.t(String(info["name"])), 21, UIKit.C_TEXT, 600))
	mid.add_child(UIKit.label(L10n.t(String(info["desc"])), 13, UIKit.C_MUTED, 700, false))

	var pips := HBoxContainer.new()
	pips.add_theme_constant_override("separation", 4)
	pips.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pip_row := HBoxContainer.new()
	pip_row.add_theme_constant_override("separation", 8)
	mid.add_child(pip_row)
	pip_row.add_child(pips)
	for i in range(int(info["max"])):
		var d := Panel.new()
		d.custom_minimum_size = Vector2(18, 6)
		var on := i < lvl
		d.add_theme_stylebox_override("panel", UIKit.panel_style(3, ic if on else Color(1, 1, 1, 0.13), Color(0, 0, 0, 0), 0, 0))
		pips.add_child(d)
	var lv_label := UIKit.label(("%d/%d" if Profile.is_fa() else "LV %d/%d") % [lvl, int(info["max"])], 11, UIKit.C_DIM, 700, false)
	pip_row.add_child(lv_label)

	if maxed:
		var tag := UIKit.label(L10n.t("MAX"), 18, UIKit.C_LIME, 700, false)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(tag)
	else:
		var cost := Profile.up_cost(key)
		var afford := Profile.coins >= cost
		var b := _btn((L10n.t("BUY") + "  %d") % cost, "primary" if afford else "ghost", 48, 16)
		b.custom_minimum_size = Vector2(118, 48)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.disabled = not afford
		b.modulate.a = 1.0 if afford else 0.55
		b.pressed.connect(func() -> void:
			if Profile.buy_upgrade(key):
				sfx_requested.emit("buy")
				_refresh()
			else:
				sfx_requested.emit("hurt")
		)
		h.add_child(b)
	return p


# ---------------------------------------------------------------- skins
func _build_skins() -> void:
	var v := _screen_root()
	v.add_child(_top_bar(L10n.t("SKINS")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(grid)
	for i in range(Profile.SKINS.size()):
		grid.add_child(_skin_card(i))


func _skin_card(i: int) -> Control:
	var sd: Dictionary = Profile.SKINS[i]
	var owned: bool = Profile.owns_skin(i)
	var selected: bool = Profile.skin == i
	var p := UIKit.panel(Color(1, 1, 1, 0.07) if selected else UIKit.C_CARD, 22,
		Color(sd["base"]).lightened(0.2) if selected else UIKit.C_BORDER, 12)
	p.custom_minimum_size = Vector2(0, 188)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 16
	v.offset_bottom = -14
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)

	var swatch := Panel.new()
	swatch.custom_minimum_size = Vector2(52, 52)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	swatch.add_theme_stylebox_override("panel", UIKit.panel_style(26, sd["base"], Color(sd["rim"]), 3, 10))
	v.add_child(swatch)
	var name_l := UIKit.label(L10n.t(String(sd["name"])), 19, UIKit.C_TEXT, 600)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_l)

	if selected:
		var on := UIKit.label(L10n.t("EQUIPPED"), 12, UIKit.C_LIME, 700, false)
		on.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(on)
	elif owned:
		var b := _btn(L10n.t("USE"), "ghost", 38, 14)
		b.pressed.connect(func() -> void:
			Profile.select_skin(i)
			_refresh()
		)
		v.add_child(b)
	else:
		var price := int(sd["price"])
		var afford := Profile.coins >= price
		var b := _btn((L10n.t("BUY") + "  %d") % price, "primary" if afford else "ghost", 38, 14)
		b.disabled = not afford
		b.modulate.a = 1.0 if afford else 0.55
		b.pressed.connect(func() -> void:
			if Profile.buy_skin(i):
				sfx_requested.emit("buy")
				_refresh()
			else:
				sfx_requested.emit("hurt")
		)
		v.add_child(b)
	return p


# ---------------------------------------------------------------- settings
func _open_settings() -> void:
	if _settings_open:
		return
	_settings_open = true
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.08, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_content.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.panel_style(26, Color("#111B38"), UIKit.C_BORDER, 1, 24))
	card.custom_minimum_size = Vector2(440, 0)
	center.add_child(card)
	var m := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	card.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	m.add_child(v)
	v.add_child(UIKit.title(L10n.t("SETTINGS"), 26, UIKit.C_TEXT, 600))
	v.add_child(_toggle_row(L10n.t("Music"), Profile.music_on, func() -> void:
		Profile.toggle_music()
		sfx_requested.emit("music_toggle")
		_refresh_settings(dim)
	))
	v.add_child(_toggle_row(L10n.t("Sound FX"), Profile.sfx_on, func() -> void:
		Profile.toggle_sfx()
		_refresh_settings(dim)
	))
	v.add_child(_toggle_row(L10n.t("Haptics"), Profile.haptics_on, func() -> void:
		Profile.toggle_haptics()
	))
	var lang_btn := _btn(("زبان  ·  English" if Profile.is_fa() else "LANGUAGE  ·  فارسی"), "ghost", 54, 17)
	lang_btn.pressed.connect(func() -> void:
		_click()
		Profile.set_lang("en" if Profile.is_fa() else "fa")
		UIKit.clear_font_cache()
		_settings_open = false
		dim.queue_free()
		show_screen("menu")
	)
	v.add_child(lang_btn)
	var close := _btn(L10n.t("CLOSE"), "primary", 54, 19)
	close.pressed.connect(func() -> void:
		_settings_open = false
		dim.queue_free()
	)
	v.add_child(close)


func _refresh_settings(dim: Control) -> void:
	# simplest: close and reopen so toggle labels re-read state
	_settings_open = false
	dim.queue_free()
	_open_settings()


func _toggle_row(title: String, on: bool, cb: Callable) -> Control:
	var h := HBoxContainer.new()
	h.custom_minimum_size = Vector2(0, 52)
	h.add_theme_constant_override("separation", 12)
	var l := UIKit.label(title, 19, UIKit.C_TEXT, 700, false)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(l)
	var b := _btn("ON" if on else "OFF", "lime" if on else "ghost", 42, 14)
	b.custom_minimum_size = Vector2(84, 42)
	b.pressed.connect(cb)
	h.add_child(b)
	return h
