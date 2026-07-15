extends BaseScenario

const DECORATIVE_TREES := [
    Vector2(82.0, 105.0),
    Vector2(230.0, 92.0),
    Vector2(545.0, 105.0),
    Vector2(100.0, 385.0),
]


func get_title() -> String:
    return "FOREST"


func get_instruction() -> String:
    return "Find the special tree so the dog can pee."


func get_success_message() -> String:
    return "Tree marked! Growing a new world..."


func get_background_color() -> Color:
    return Color("74b85a")


func get_target_positions() -> Array[Vector2]:
    return [
        Vector2(155.0, 175.0), Vector2(320.0, 105.0),
        Vector2(510.0, 190.0), Vector2(215.0, 385.0),
    ]


func get_target_interaction_position() -> Vector2:
    return target_position + Vector2(0.0, -17.0)


func draw_environment() -> void:
    draw_colored_polygon(ellipse_points(Vector2(170, 255), Vector2(235, 175)), Color("82c765"))
    draw_colored_polygon(ellipse_points(Vector2(515, 245), Vector2(180, 145)), Color("69aa50"))

    var path_points := PackedVector2Array([
        Vector2(-20, 275), Vector2(105, 245), Vector2(220, 268),
        Vector2(330, 238), Vector2(455, 260), Vector2(665, 225),
    ])
    draw_polyline(path_points, Color("c9a66b"), 62.0, true)
    draw_polyline(path_points, Color("dfbd7b"), 46.0, true)

    draw_colored_polygon(ellipse_points(Vector2(455, 380), Vector2(105, 62)), Color("d8c17e"))
    draw_colored_polygon(ellipse_points(Vector2(455, 380), Vector2(94, 53)), Color("3c91c4"))
    draw_arc(Vector2(440, 370), 43.0, 3.45, 5.75, 24, Color("a8e1ef"), 3.0, true)

    for tree_position in DECORATIVE_TREES:
        draw_tree(tree_position)
    draw_tree(target_position)
    draw_arc(target_position + Vector2(0, -17), 43.0, 0.0, TAU, 32, Color("f4d35e"), 3.0, true)
