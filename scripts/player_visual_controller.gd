class_name PlayerVisualController
extends Node2D

@export var maximum_speed := 260.0
@export var idle_bob_height := 0.9
@export var walk_bob_height := 1.8
@export var maximum_tilt := 0.035
@export var maximum_squash := 0.02
@export var visual_response := 12.0
@export var down_sprite_scale := 0.4
@export var side_sprite_scale := 0.47
@export var up_sprite_scale := 0.4

@onready var dog_sprite: AnimatedSprite2D = $DogSprite
@onready var accessories: PlayerAccessories = $Accessories
@onready var shadow: Node2D = $"../Shadow"

var motion_velocity := Vector2.ZERO
var animation_phase := 0.0
var facing_direction := 1.0
var current_direction := "down"
var target_sprite_scale := 0.4
var accessories_base_scale := Vector2.ONE


func _ready() -> void:
    accessories_base_scale = accessories.scale


func set_motion(new_velocity: Vector2, new_maximum_speed: float) -> void:
    motion_velocity = new_velocity
    maximum_speed = maxf(new_maximum_speed, 1.0)


func _process(delta: float) -> void:
    var movement_strength := clampf(motion_velocity.length() / maximum_speed, 0.0, 1.0)
    var cadence := lerpf(2.2, 10.5, movement_strength)
    animation_phase = fmod(animation_phase + delta * cadence, TAU)

    _update_directional_animation(movement_strength)
    _animate_body(delta, movement_strength)
    _animate_shadow(delta, movement_strength)


func _update_directional_animation(movement_strength: float) -> void:
    if movement_strength < 0.03:
        if dog_sprite.is_playing():
            dog_sprite.pause()
            dog_sprite.set_frame_and_progress(0, 0.0)
        return

    if absf(motion_velocity.x) > absf(motion_velocity.y):
        current_direction = "side"
        facing_direction = signf(motion_velocity.x)
        target_sprite_scale = side_sprite_scale
    elif motion_velocity.y < 0.0:
        current_direction = "up"
        facing_direction = 1.0
        target_sprite_scale = up_sprite_scale
    else:
        current_direction = "down"
        facing_direction = 1.0
        target_sprite_scale = down_sprite_scale

    var animation_name := "walk_%s" % current_direction
    if dog_sprite.sprite_frames.has_animation(animation_name):
        if dog_sprite.animation != animation_name:
            dog_sprite.play(animation_name)
        elif not dog_sprite.is_playing():
            dog_sprite.play()
        dog_sprite.speed_scale = lerpf(0.72, 1.18, movement_strength)

    dog_sprite.flip_h = current_direction == "side" and facing_direction < 0.0
    accessories.scale.x = accessories_base_scale.x * facing_direction
    accessories.set_visual_direction(current_direction)


func _animate_body(delta: float, movement_strength: float) -> void:
    var smoothing := 1.0 - exp(-visual_response * delta)
    var bob_height := lerpf(idle_bob_height, walk_bob_height, movement_strength)
    var body_bob := sin(animation_phase) * bob_height
    var foot_impact := (sin(animation_phase * 2.0) + 1.0) * 0.5 * movement_strength
    var idle_breath := sin(animation_phase) * 0.012 * (1.0 - movement_strength)

    var target_position := Vector2(0.0, body_bob)
    var target_rotation := clampf(
        motion_velocity.x / maximum_speed,
        -1.0,
        1.0
    ) * maximum_tilt
    var target_scale := Vector2(
        1.0 + maximum_squash * foot_impact - idle_breath * 0.45,
        1.0 - maximum_squash * foot_impact + idle_breath
    )

    position = position.lerp(target_position, smoothing)
    rotation = lerp_angle(rotation, target_rotation, smoothing)
    scale = scale.lerp(target_scale, smoothing)
    dog_sprite.scale = dog_sprite.scale.lerp(Vector2.ONE * target_sprite_scale, smoothing)


func _animate_shadow(delta: float, movement_strength: float) -> void:
    var smoothing := 1.0 - exp(-visual_response * delta)
    var lift := absf(sin(animation_phase))
    var target_scale := Vector2(
        lerpf(1.0, 1.14, movement_strength) - lift * 0.035,
        lerpf(1.0, 0.82, movement_strength) - lift * 0.025
    )
    var target_position := Vector2(-motion_velocity.x / maximum_speed * 2.0, 38.0)
    var target_opacity := lerpf(0.78, 1.0, 1.0 - lift * movement_strength)

    shadow.scale = shadow.scale.lerp(target_scale, smoothing)
    shadow.position = shadow.position.lerp(target_position, smoothing)
    shadow.modulate.a = lerpf(shadow.modulate.a, target_opacity, smoothing)
