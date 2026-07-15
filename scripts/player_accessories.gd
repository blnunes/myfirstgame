class_name PlayerAccessories
extends Node2D

const HELMET_CENTER := Vector2(19.0, -28.0)
const HELMET_RADIUS := 40.0

var helmet_visible := false
var pee_target := Vector2.ZERO
var pee_effect_time := 0.0


func _process(delta: float) -> void:
    if pee_effect_time <= 0.0:
        return
    pee_effect_time = maxf(pee_effect_time - delta, 0.0)
    queue_redraw()


func set_helmet_visible(is_visible: bool) -> void:
    helmet_visible = is_visible
    queue_redraw()


func play_pee_effect(global_target: Vector2) -> void:
    pee_target = to_local(global_target)
    pee_effect_time = 0.6
    queue_redraw()


func _draw() -> void:
    if helmet_visible:
        draw_circle(HELMET_CENTER, HELMET_RADIUS, Color(0.55, 0.88, 1.0, 0.16))
        draw_arc(HELMET_CENTER, HELMET_RADIUS, 0.0, TAU, 48, Color("a7e8ff"), 3.0, true)
        draw_arc(HELMET_CENTER, 33.0, 3.55, 5.05, 18, Color(0.9, 0.98, 1.0, 0.8), 2.0, true)
        draw_rect(Rect2(-12, 7, 62, 6), Color("d8e7ed"))
        draw_rect(Rect2(-8, 13, 54, 4), Color("7189a3"))

    if pee_effect_time > 0.0:
        var direction := pee_target.normalized()
        var stream_start := direction * 33.0 + Vector2(0, 12)
        var stream_end := direction * minf(pee_target.length() - 24.0, 62.0)
        draw_line(stream_start, stream_end, Color("f4d13d"), 5.0, true)
        draw_circle(stream_end, 6.0, Color(0.96, 0.78, 0.15, pee_effect_time))
