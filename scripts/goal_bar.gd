class_name GoalBar
extends Control
## Rounded progress bar drawn in code (goal / boss health / mission).

var value := 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
var fill_a := Color("#35E6FF"):
	set(v):
		fill_a = v
		queue_redraw()
var fill_b := Color("#A8FF3E"):
	set(v):
		fill_b = v
		queue_redraw()
var bg_color := Color(1, 1, 1, 0.10)
var radius := 9.0
var glow := true


func _ready() -> void:
	if custom_minimum_size.y <= 0.0:
		custom_minimum_size.y = 14.0


func _draw() -> void:
	var r := minf(radius, size.y * 0.5)
	var bg := StyleBoxFlat.new()
	bg.bg_color = bg_color
	bg.set_corner_radius_all(int(r))
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	if value <= 0.001:
		return
	var w := maxf(size.y, size.x * value)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill_b
	fg.set_corner_radius_all(int(r))
	fg.border_width_top = 2
	fg.border_color = Color(1, 1, 1, 0.22)
	draw_style_box(fg, Rect2(Vector2.ZERO, Vector2(w, size.y)))
	# soft leading highlight
	var dot := Vector2(w - r, size.y * 0.5)
	draw_circle(dot, maxf(2.0, size.y * 0.22), Color(1, 1, 1, 0.55))
