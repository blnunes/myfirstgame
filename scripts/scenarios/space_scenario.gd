extends BaseScenario

const STARS := [
    Vector2(38, 58), Vector2(92, 204), Vector2(145, 82), Vector2(210, 155),
    Vector2(275, 52), Vector2(345, 118), Vector2(410, 42), Vector2(472, 202),
    Vector2(530, 76), Vector2(598, 152), Vector2(55, 395), Vector2(165, 435),
    Vector2(310, 398), Vector2(465, 430), Vector2(592, 370),
]


func get_title() -> String:
    return "SPACE"


func get_instruction() -> String:
    return "Helmet on! Find the glowing meteor."


func get_success_message() -> String:
    return "Meteor marked! Opening a portal..."


func get_background_color() -> Color:
    return Color("11152f")


func get_target_positions() -> Array[Vector2]:
    return [
        Vector2(105.0, 120.0), Vector2(235.0, 370.0),
        Vector2(425.0, 115.0), Vector2(550.0, 350.0),
    ]


func requires_space_helmet() -> bool:
    return true


func draw_environment() -> void:
    draw_colored_polygon(ellipse_points(Vector2(140, 130), Vector2(170, 95)), Color("252458"))
    draw_colored_polygon(ellipse_points(Vector2(510, 335), Vector2(210, 125)), Color("1c2852"))
    for star in STARS:
        draw_circle(star, 2.0, Color("f7f1c8"))
        draw_line(star - Vector2(5, 0), star + Vector2(5, 0), Color("cbd7ff"), 1.0)
        draw_line(star - Vector2(0, 5), star + Vector2(0, 5), Color("cbd7ff"), 1.0)

    draw_circle(Vector2(75, 410), 75.0, Color("626ba7"))
    draw_circle(Vector2(51, 385), 15.0, Color("4b548c"))
    draw_circle(Vector2(104, 428), 22.0, Color("505991"))
    for meteor in [Vector2(190, 100), Vector2(350, 350), Vector2(570, 190)]:
        _draw_meteor(meteor, false)
    _draw_meteor(target_position, true)


func _draw_meteor(position: Vector2, is_target: bool) -> void:
    draw_colored_polygon(ellipse_points(position, Vector2(31, 24), 18), Color("716577"))
    draw_circle(position + Vector2(-9, -5), 6.0, Color("4f485b"))
    draw_circle(position + Vector2(10, 7), 4.0, Color("514a5e"))
    draw_circle(position + Vector2(9, -9), 3.0, Color("95849a"))
    if is_target:
        draw_arc(position, 42.0, 0.0, TAU, 32, Color("71e7ff"), 4.0, true)
