class_name StarRow
extends Control
## Small vector star rating row.

var count := 3:
	set(v):
		count = v
		queue_redraw()
var filled := 0:
	set(v):
		filled = v
		queue_redraw()
var star_size := 18.0:
	set(v):
		star_size = v
		queue_redraw()
var gap := 7.0
var full_color := Color("#FFC63D")
var empty_color := Color(1, 1, 1, 0.13)


func _ready() -> void:
	custom_minimum_size = Vector2(count * star_size + (count - 1) * gap, star_size)


func fit() -> void:
	var w := count * star_size + (count - 1) * gap
	custom_minimum_size = Vector2(w, star_size)
	size = custom_minimum_size


func _star_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang := -PI / 2.0 + float(i) * PI / 5.0
		var rad := r if i % 2 == 0 else r * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * rad)
	return pts


func _draw() -> void:
	for i in range(count):
		var c := Vector2(star_size * 0.5 + float(i) * (star_size + gap), size.y * 0.5)
		var pts := _star_points(c, star_size * 0.5)
		if i < filled:
			draw_colored_polygon(pts, full_color)
			draw_polyline(pts + PackedVector2Array([pts[0]]), full_color.lightened(0.45), 1.2, true)
		else:
			draw_colored_polygon(pts, empty_color)
