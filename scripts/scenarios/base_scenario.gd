class_name BaseScenario
extends Node2D

signal target_reached(target_position: Vector2)

const MAP_SIZE := Vector2(640.0, 480.0)
const TARGET_ACTIVATION_DISTANCE := 52.0
const MIN_PLAYER_SPAWN_DISTANCE := 230.0
const PLAYER_SPAWN_POSITIONS: Array[Vector2] = [
    Vector2(72.0, 100.0), Vector2(200.0, 72.0),
    Vector2(440.0, 72.0), Vector2(568.0, 100.0),
    Vector2(72.0, 240.0), Vector2(568.0, 240.0),
    Vector2(72.0, 400.0), Vector2(200.0, 408.0),
    Vector2(440.0, 408.0), Vector2(568.0, 400.0),
]

var target_position := Vector2.ZERO
var tracked_player: CharacterBody2D
var previous_player_position := Vector2.ZERO
var player_was_inside_target := false
var target_consumed := false


func _init() -> void:
    z_index = -10


func configure(random: RandomNumberGenerator) -> void:
    var positions := get_target_positions()
    assert(not positions.is_empty(), "%s must provide at least one target position." % get_script().resource_path)
    target_position = positions[random.randi_range(0, positions.size() - 1)]


func _ready() -> void:
    _find_player()
    if is_instance_valid(tracked_player):
        previous_player_position = tracked_player.global_position
        player_was_inside_target = _distance_to_player() <= TARGET_ACTIVATION_DISTANCE
    queue_redraw()


func _physics_process(_delta: float) -> void:
    if target_consumed:
        return
    if not is_instance_valid(tracked_player):
        _find_player()
        if is_instance_valid(tracked_player):
            previous_player_position = tracked_player.global_position
            player_was_inside_target = _distance_to_player() <= TARGET_ACTIVATION_DISTANCE
        return

    var current_player_position := tracked_player.global_position
    var is_inside_target := _distance_to_player() <= TARGET_ACTIVATION_DISTANCE
    var player_is_moving := current_player_position.distance_squared_to(previous_player_position) > 0.01
    if is_inside_target and not player_was_inside_target and player_is_moving:
        target_consumed = true
        target_reached.emit(to_global(get_target_interaction_position()))
    player_was_inside_target = is_inside_target
    previous_player_position = current_player_position


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), get_background_color())
    draw_environment()


func get_title() -> String:
    return "Scenario"


func get_instruction() -> String:
    return "Find the target."


func get_success_message() -> String:
    return "Target found! Changing scenario..."


func get_background_color() -> Color:
    return Color("74b85a")


func get_target_positions() -> Array[Vector2]:
    return [Vector2(120.0, 120.0), Vector2(520.0, 360.0)]


func requires_space_helmet() -> bool:
    return false


func get_target_interaction_position() -> Vector2:
    return target_position


func get_safe_player_spawn(random: RandomNumberGenerator) -> Vector2:
    var safe_positions: Array[Vector2] = []
    var interaction_position := get_target_interaction_position()
    var farthest_position := PLAYER_SPAWN_POSITIONS[0]
    var farthest_distance := farthest_position.distance_to(interaction_position)

    for spawn_position in PLAYER_SPAWN_POSITIONS:
        var target_distance := spawn_position.distance_to(interaction_position)
        if target_distance >= MIN_PLAYER_SPAWN_DISTANCE:
            safe_positions.append(spawn_position)
        if target_distance > farthest_distance:
            farthest_position = spawn_position
            farthest_distance = target_distance

    if safe_positions.is_empty():
        assert(false, "O mapa nao possui spawn a distancia minima do alvo.")
        push_warning("Nenhum spawn atingiu a distancia minima; usando o ponto mais distante.")
        return farthest_position

    var selected_position := safe_positions[random.randi_range(0, safe_positions.size() - 1)]
    assert(selected_position.distance_to(interaction_position) >= MIN_PLAYER_SPAWN_DISTANCE)
    return selected_position


func draw_environment() -> void:
    pass


func ellipse_points(center: Vector2, radii: Vector2, point_count: int = 48) -> PackedVector2Array:
    var points := PackedVector2Array()
    for index in point_count:
        var angle := TAU * float(index) / float(point_count)
        points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
    return points


func draw_tree(tree_position: Vector2) -> void:
    draw_colored_polygon(
        ellipse_points(tree_position + Vector2(7, 11), Vector2(32, 13), 24),
        Color(0.13, 0.25, 0.12, 0.3)
    )
    draw_rect(Rect2(tree_position + Vector2(-8, -13), Vector2(16, 42)), Color("75452b"))
    draw_rect(Rect2(tree_position + Vector2(-4, -11), Vector2(5, 38)), Color("a1683c"))
    draw_circle(tree_position + Vector2(-19, -23), 24.0, Color("28643a"))
    draw_circle(tree_position + Vector2(18, -22), 25.0, Color("2e7040"))
    draw_circle(tree_position + Vector2(0, -41), 30.0, Color("347d46"))
    draw_circle(tree_position + Vector2(-7, -48), 13.0, Color("55a557"))
    draw_circle(tree_position + Vector2(17, -36), 9.0, Color("66b45e"))


func _find_player() -> void:
    var player_node := get_tree().get_first_node_in_group("player")
    if player_node is CharacterBody2D:
        tracked_player = player_node


func _distance_to_player() -> float:
    return tracked_player.global_position.distance_to(to_global(get_target_interaction_position()))
