class_name BlobHero
extends Control
## Cute 2D blob mascot for menus, drawn entirely in code.

var color_a := Color("#2EE6C8")
var color_b := Color("#0E9C8A")
var rim := Color("#FFB347")
var t := 0.0
var mood := 0  # 0 idle, 1 happy, 2 sad


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _wobble_points(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		var k := 1.0 + 0.035 * sin(a * 3.0 + t * 1.7) + 0.02 * sin(a * 5.0 - t * 1.1)
		pts.append(c + Vector2(cos(a), sin(a)) * r * k)
	return pts


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.56)
	var r := minf(size.x, size.y) * 0.36
	var squash := 1.0 + 0.03 * sin(t * 2.1)
	var pts := _wobble_points(c + Vector2(0, r * 0.06), r * 1.02, 64)

	# ground shadow
	draw_set_transform(Vector2(0, 0))
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0, 0, 0, 0.22)
	sh.set_corner_radius_all(int(r * 0.5))
	draw_style_box(sh, Rect2(c.x - r * 0.75, c.y + r * 0.92, r * 1.5, r * 0.22))

	# rim glow
	for i in range(3):
		var glow := pts.duplicate()
		for j in range(glow.size()):
			glow[j] = c + (glow[j] - c) * (1.0 + 0.035 * float(i + 1))
		draw_colored_polygon(glow, Color(rim.r, rim.g, rim.b, 0.05 + 0.03 * float(2 - i)))

	# body
	draw_colored_polygon(pts, color_b)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.90 + Vector2(0, -r * 0.06))
	draw_colored_polygon(inner, color_a)

	# glossy highlight
	draw_circle(c + Vector2(-r * 0.34, -r * 0.40), r * 0.20, Color(1, 1, 1, 0.35))
	draw_circle(c + Vector2(-r * 0.36, -r * 0.42), r * 0.10, Color(1, 1, 1, 0.55))

	# eyes
	var eye_dx := r * 0.30
	var eye_y := c.y - r * 0.10
	for side in [-1.0, 1.0]:
		var ec := Vector2(c.x + side * eye_dx, eye_y)
		if mood == 1:
			draw_arc(ec, r * 0.11, PI * 1.15, PI * 1.85, 16, Color("#0B1B2A"), r * 0.075, true)
		elif mood == 2:
			draw_line(ec + Vector2(-r * 0.09, -r * 0.06), ec + Vector2(r * 0.09, r * 0.02), Color("#0B1B2A"), r * 0.055, true)
		else:
			draw_circle(ec, r * 0.115, Color("#0B1B2A"))
			draw_circle(ec + Vector2(-r * 0.03, -r * 0.04), r * 0.035, Color(1, 1, 1, 0.9))

	# mouth
	if mood == 2:
		draw_arc(c + Vector2(0, r * 0.28), r * 0.12, PI * 1.15, PI * 1.85, 16, Color("#0B1B2A"), r * 0.05, true)
	else:
		draw_arc(c + Vector2(0, r * 0.14), r * 0.15, PI * 0.15, PI * 0.85, 20, Color("#0B1B2A"), r * 0.05, true)
