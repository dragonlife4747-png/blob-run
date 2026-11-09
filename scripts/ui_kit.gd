class_name UIKit
extends RefCounted

const L10n = preload("res://scripts/l10n.gd")
## Shared visual language: palette, fonts, panels, buttons.

const C_BG_TOP := Color("#070B1E")
const C_BG_MID := Color("#101B3F")
const C_BG_BOT := Color("#1D2B60")
const C_TEXT := Color("#F5F7FF")
const C_MUTED := Color("#9EB0D9")
const C_DIM := Color("#5F6E96")
const C_ACCENT := Color("#35E6FF")
const C_ACCENT_DARK := Color("#0A93B8")
const C_PINK := Color("#FF4D8F")
const C_LIME := Color("#A8FF3E")
const C_GOLD := Color("#FFC63D")
const C_DANGER := Color("#FF5C6C")
const C_CARD := Color(1, 1, 1, 0.055)
const C_CARD_SOFT := Color(1, 1, 1, 0.035)
const C_BORDER := Color(1, 1, 1, 0.10)

static var _fonts := {}


static func _tag(name: String) -> int:
	return TextServerManager.get_primary_interface().name_to_tag(name)


static func _font(path: String, weight: int) -> Font:
	var key := "%s_%d" % [path, weight]
	if _fonts.has(key):
		return _fonts[key]
	var base: FontFile = load(path)
	var fv := FontVariation.new()
	fv.base_font = base
	var d := {}
	d[_tag("wght")] = float(weight)
	fv.variation_opentype = d
	_fonts[key] = fv
	return fv


static func _fa() -> bool:
	var p := Engine.get_main_loop()
	if p == null:
		return false
	var prof: Node = p.root.get_node_or_null("Profile")
	return prof != null and String(prof.get("lang")) == "fa"


static func clear_font_cache() -> void:
	_fonts.clear()


static func display(weight := 600) -> Font:
	if _fa():
		return _font("res://assets/fonts/Vazirmatn-Bold.ttf", 700)
	return _font("res://assets/fonts/Fredoka.ttf", weight)


static func body(weight := 700) -> Font:
	if _fa():
		return _font("res://assets/fonts/Vazirmatn-Bold.ttf", 700)
	return _font("res://assets/fonts/Nunito.ttf", weight)


# ------------------------------------------------------------------ labels
static func label(text: String, size: int, color: Color = C_TEXT, weight := 700, display_font := true) -> Label:
	var l := Label.new()
	l.text = L10n.d(text)
	l.add_theme_font_override("font", display(weight) if display_font else body(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	return l


static func title(text: String, size: int, color: Color = C_TEXT, weight := 600, outline := 0, outline_color := Color(0, 0, 0, 0.55)) -> Label:
	var l := label(text, size, color, weight)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", outline_color)
	return l


static func shadowed(text: String, size: int, color: Color, weight := 600) -> Label:
	var l := title(text, size, color, weight)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.32))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.add_theme_constant_override("shadow_outline_size", 5)
	return l


# ------------------------------------------------------------------ boxes
static func panel_style(radius := 24, bg := C_CARD, border := C_BORDER, border_w := 1, shadow := 18, shadow_alpha := 0.35) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(border_w)
	s.border_color = border
	s.anti_aliasing = true
	if shadow > 0:
		s.shadow_size = shadow
		s.shadow_color = Color(0, 0, 0, shadow_alpha)
		s.shadow_offset = Vector2(0, 8)
	return s


static func panel(bg := C_CARD, radius := 24, border := C_BORDER, shadow := 18) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", panel_style(radius, bg, border, 1, shadow))
	return p


# ------------------------------------------------------------------ buttons
static func _btn_style(bg: Color, radius: int, border: Color, shadow_alpha: float, top_highlight := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = border
	s.anti_aliasing = true
	s.shadow_size = 16
	s.shadow_color = Color(0, 0, 0, shadow_alpha)
	s.shadow_offset = Vector2(0, 6)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	if top_highlight:
		s.border_width_top = 2
		s.border_color = border
	return s


static func button(text: String, kind := "primary", height := 62, font_size := 24) -> Button:
	var b := Button.new()
	b.text = L10n.d(text)
	b.custom_minimum_size = Vector2(0, height)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", display(600))
	b.add_theme_font_size_override("font_size", font_size)
	var base := C_ACCENT
	var fg := Color("#04121C")
	var border := Color(1, 1, 1, 0.28)
	match kind:
		"primary":
			base = C_ACCENT
			fg = Color("#04121C")
		"pink":
			base = C_PINK
			fg = Color("#25040F")
		"gold":
			base = C_GOLD
			fg = Color("#2A1A00")
		"lime":
			base = C_LIME
			fg = Color("#122000")
		"ghost":
			base = Color(1, 1, 1, 0.07)
			fg = C_TEXT
		"danger":
			base = C_DANGER
			fg = Color("#2A0509")
	b.add_theme_stylebox_override("normal", _btn_style(base, height / 2, border, 0.30))
	b.add_theme_stylebox_override("hover", _btn_style(base.lightened(0.10), height / 2, border, 0.36))
	b.add_theme_stylebox_override("pressed", _btn_style(base.darkened(0.14), height / 2, border, 0.18))
	b.add_theme_stylebox_override("disabled", _btn_style(Color(1, 1, 1, 0.06), height / 2, Color(1, 1, 1, 0.06), 0.0, false))
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	_press_feel(b)
	return b


static func _press_feel(b: Button) -> void:
	b.pivot_offset = Vector2(0, 0)
	b.button_down.connect(func() -> void:
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2(0.97, 0.97), 0.06)
	)
	b.button_up.connect(func() -> void:
		var tw := b.create_tween()
		tw.tween_property(b, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


static func icon_button(glyph: String, size := 52) -> Button:
	var b := Button.new()
	b.text = glyph
	b.custom_minimum_size = Vector2(size, size)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", display(600))
	b.add_theme_font_size_override("font_size", int(size * 0.42))
	b.add_theme_stylebox_override("normal", panel_style(size / 2, Color(0.04, 0.07, 0.16, 0.62), Color(1, 1, 1, 0.18), 1, 10, 0.42))
	b.add_theme_stylebox_override("hover", panel_style(size / 2, Color(0.07, 0.11, 0.22, 0.72), Color(1, 1, 1, 0.26), 1, 12, 0.5))
	b.add_theme_stylebox_override("pressed", panel_style(size / 2, Color(0.03, 0.05, 0.12, 0.72), Color(1, 1, 1, 0.18), 1, 6, 0.4))
	b.add_theme_color_override("font_color", C_TEXT)
	b.add_theme_color_override("font_hover_color", C_TEXT)
	b.add_theme_color_override("font_pressed_color", C_MUTED)
	_press_feel(b)
	return b


# ------------------------------------------------------------------ misc
static func coin_icon(size := 22) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(size, size)
	var outer := Panel.new()
	outer.size = Vector2(size, size)
	outer.add_theme_stylebox_override("panel", panel_style(size / 2, C_GOLD, C_GOLD.lightened(0.3), 0, 0))
	root.add_child(outer)
	var inner := Panel.new()
	inner.position = Vector2(size * 0.22, size * 0.22)
	inner.size = Vector2(size * 0.56, size * 0.56)
	inner.add_theme_stylebox_override("panel", panel_style(size / 3, Color("#FFE08A"), Color(1, 1, 1, 0.0), 0, 0))
	root.add_child(inner)
	return root


static func star_glyph() -> Control:
	var s := StarRow.new()
	s.custom_minimum_size = Vector2(64, 22)
	s.count = 3
	return s


static func hsep(height := 12) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


static func short_num(v: int) -> String:
	if L10n.fa:
		if v < 10000:
			return L10n.num(v)
		if v < 1000000:
			return "%s هزار" % L10n.num(int(round(float(v) / 1000.0)))
		return "%s میلیون" % L10n.num(int(round(float(v) / 1000000.0)))
	if v < 10000:
		return str(v)
	if v < 100000:
		return "%.1fK" % (float(v) / 1000.0)
	if v < 1000000:
		return "%dK" % int(round(float(v) / 1000.0))
	return "%.2fM" % (float(v) / 1000000.0)


static func chip(text: String, icon_color: Color) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", panel_style(24, Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.14), 1, 12, 0.35))
	p.custom_minimum_size = Vector2(132, 48)
	var h := HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	h.offset_right = -16
	h.offset_top = 6
	h.offset_bottom = -6
	h.add_theme_constant_override("separation", 7)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(h)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(14, 14)
	dot.add_theme_stylebox_override("panel", panel_style(7, icon_color, Color(1, 1, 1, 0.35), 0, 0))
	h.add_child(dot)
	var l := label(text, 19, C_TEXT, 700, false)
	h.add_child(l)
	return p
