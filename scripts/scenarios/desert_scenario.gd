extends BaseScenario


func get_title() -> String:
    return "DESERT"


func get_instruction() -> String:
    return "Find the glowing cactus."


func get_success_message() -> String:
    return "Cactus marked! A new landscape is forming..."


func get_background_color() -> Color:
    return Color("e9bd68")


func get_target_positions() -> Array[Vector2]:
    return [
        Vector2(105.0, 150.0), Vector2(260.0, 380.0),
        Vector2(420.0, 145.0), Vector2(545.0, 360.0),
    ]


func get_target_interaction_position() -> Vector2:
    return target_position + Vector2(0.0, -18.0)


func draw_environment() -> void:
    draw_colored_polygon(ellipse_points(Vector2(120, 355), Vector2(250, 100)), Color("f3ce7d"))
    draw_colored_polygon(ellipse_points(Vector2(500, 335), Vector2(260, 125)), Color("dca957"))
    draw_circle(Vector2(555, 75), 36.0, Color("ffe29a"))

    for rock in [Vector2(70, 410), Vector2(330, 90), Vector2(575, 225)]:
        draw_colored_polygon(ellipse_points(rock, Vector2(17, 10), 18), Color("9d7650"))

    for cactus in [Vector2(160, 315), Vector2(475, 395)]:
        _draw_cactus(cactus, false)
    _draw_cactus(target_position, true)


func _draw_cactus(position: Vector2, is_target: bool) -> void:
    var cactus_color := Color("3f8b55")
    draw_rect(Rect2(position + Vector2(-9, -48), Vector2(18, 68)), cactus_color)
    draw_circle(position + Vector2(0, -48), 9.0, cactus_color)
    draw_rect(Rect2(position + Vector2(-27, -31), Vector2(19, 10)), cactus_color)
    draw_rect(Rect2(position + Vector2(-27, -45), Vector2(10, 20)), cactus_color)
    draw_circle(position + Vector2(-22, -45), 5.0, cactus_color)
    draw_rect(Rect2(position + Vector2(8, -23), Vector2(22, 10)), cactus_color)
    draw_rect(Rect2(position + Vector2(20, -35), Vector2(10, 18)), cactus_color)
    draw_circle(position + Vector2(25, -35), 5.0, cactus_color)
    if is_target:
        draw_arc(position + Vector2(0, -18), 42.0, 0.0, TAU, 32, Color("fff1a8"), 3.0, true)
