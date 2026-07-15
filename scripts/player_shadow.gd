extends Node2D

const SHADOW_RADII := Vector2(37.0, 11.0)
const POINT_COUNT := 32


func _draw() -> void:
    var points := PackedVector2Array()
    for index in POINT_COUNT:
        var angle := TAU * float(index) / float(POINT_COUNT)
        points.append(Vector2(cos(angle) * SHADOW_RADII.x, sin(angle) * SHADOW_RADII.y))
    draw_colored_polygon(points, Color(0.08, 0.1, 0.13, 0.3))
