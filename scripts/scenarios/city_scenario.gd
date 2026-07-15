extends BaseScenario


func get_title() -> String:
    return "CITY"


func get_instruction() -> String:
    return "Find the fire hydrant."


func get_success_message() -> String:
    return "Hydrant marked! Travelling somewhere new..."


func get_background_color() -> Color:
    return Color("8e9aa3")


func get_target_positions() -> Array[Vector2]:
    return [
        Vector2(105.0, 365.0), Vector2(255.0, 120.0),
        Vector2(390.0, 370.0), Vector2(545.0, 125.0),
    ]


func get_target_interaction_position() -> Vector2:
    return target_position + Vector2(0.0, -8.0)


func draw_environment() -> void:
    draw_rect(Rect2(0, 185, 640, 115), Color("3f4850"))
    draw_rect(Rect2(0, 205, 640, 75), Color("57616a"))
    for x in range(15, 640, 80):
        draw_rect(Rect2(x, 240, 42, 5), Color("f3d46b"))

    for building in [
        Rect2(22, 55, 112, 130), Rect2(155, 24, 128, 161),
        Rect2(455, 48, 155, 137),
    ]:
        draw_rect(building, Color("596b7b"))
        draw_rect(Rect2(building.position + Vector2(8, 8), building.size - Vector2(16, 8)), Color("6f8291"))
        for window_y in range(int(building.position.y + 20), int(building.end.y - 15), 34):
            for window_x in range(int(building.position.x + 18), int(building.end.x - 15), 35):
                draw_rect(Rect2(window_x, window_y, 17, 20), Color("b8dbe3"))

    draw_rect(Rect2(0, 300, 640, 180), Color("aeb5b7"))
    for x in range(0, 640, 64):
        draw_line(Vector2(x, 300), Vector2(x + 25, 480), Color("969fa2"), 1.0)
    _draw_hydrant(target_position)


func _draw_hydrant(position: Vector2) -> void:
    draw_circle(position + Vector2(0, -25), 15.0, Color("e64b3c"))
    draw_rect(Rect2(position + Vector2(-14, -25), Vector2(28, 43)), Color("d83b32"))
    draw_rect(Rect2(position + Vector2(-23, -15), Vector2(46, 10)), Color("f06452"))
    draw_circle(position + Vector2(-24, -10), 7.0, Color("b92928"))
    draw_circle(position + Vector2(24, -10), 7.0, Color("b92928"))
    draw_rect(Rect2(position + Vector2(-20, 15), Vector2(40, 7)), Color("a82927"))
    draw_arc(position + Vector2(0, -8), 38.0, 0.0, TAU, 32, Color("f4d35e"), 3.0, true)
