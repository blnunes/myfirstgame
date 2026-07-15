extends CharacterBody2D

const FALLBACK_DOG_PATH := "res://assets/characters/dog.png"
const WALK_FRAME_COLUMNS := 4
const WALK_FRAME_ROWS := 4

@export var speed: float = 260.0
@export var acceleration: float = 1450.0
@export var deceleration: float = 1850.0
@export var movement_bounds := Rect2(0.0, 0.0, 640.0, 480.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dog_sprite: AnimatedSprite2D = $VisualRoot/DogSprite
@onready var accessories: PlayerAccessories = $VisualRoot/Accessories
@onready var visual_controller: PlayerVisualController = $VisualRoot

var movement_enabled := true
var active_skin: PlayerSkin


func _ready() -> void:
    add_to_group("player")
    set_skin(PlayerSkinCatalog.create_skins()[0])


func _physics_process(delta: float) -> void:
    if not movement_enabled:
        velocity = Vector2.ZERO
        visual_controller.set_motion(velocity, speed)
        return

    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

    var target_velocity := Vector2.ZERO
    if input_vector != Vector2.ZERO:
        target_velocity = input_vector.normalized() * speed

    var velocity_change_rate := acceleration if target_velocity != Vector2.ZERO else deceleration
    velocity = velocity.move_toward(target_velocity, velocity_change_rate * delta)
    move_and_slide()
    _keep_inside_movement_bounds()
    visual_controller.set_motion(velocity, speed)


func set_movement_enabled(is_enabled: bool) -> void:
    movement_enabled = is_enabled
    if not movement_enabled:
        velocity = Vector2.ZERO
        visual_controller.set_motion(velocity, speed)


func set_space_helmet_visible(is_visible: bool) -> void:
    accessories.set_helmet_visible(is_visible)


func play_pee_effect(target_position: Vector2) -> void:
    accessories.play_pee_effect(target_position)


func set_skin(skin: PlayerSkin) -> void:
    active_skin = skin
    _load_dog_animations()


func get_active_skin_id() -> StringName:
    return active_skin.id if active_skin != null else &""


func _load_dog_animations() -> void:
    if active_skin == null:
        push_error("Nenhuma skin foi configurada para o jogador.")
        _load_static_fallback()
        return

    var sheet_texture := load(active_skin.texture_path) as Texture2D
    if sheet_texture == null:
        push_warning("Sprite sheet da skin %s indisponivel; usando imagem estatica." % active_skin.id)
        _load_static_fallback()
        return

    if sheet_texture.get_width() % WALK_FRAME_COLUMNS != 0 or sheet_texture.get_height() % WALK_FRAME_ROWS != 0:
        push_error("Sprite sheet do cao precisa ter uma grade 4 x 4 exata.")
        _load_static_fallback()
        return

    var frame_size := Vector2i(
        sheet_texture.get_width() / WALK_FRAME_COLUMNS,
        sheet_texture.get_height() / WALK_FRAME_ROWS
    )
    var sprite_frames := SpriteFrames.new()
    sprite_frames.remove_animation("default")

    for animation_name: String in active_skin.animation_rows:
        sprite_frames.add_animation(animation_name)
        sprite_frames.set_animation_loop(animation_name, true)
        sprite_frames.set_animation_speed(animation_name, 8.0)

        var row: int = active_skin.animation_rows[animation_name]
        for frame_index in WALK_FRAME_COLUMNS:
            var atlas_frame := AtlasTexture.new()
            atlas_frame.atlas = sheet_texture
            atlas_frame.region = Rect2i(
                frame_index * frame_size.x,
                row * frame_size.y,
                frame_size.x,
                frame_size.y
            )
            sprite_frames.add_frame(animation_name, atlas_frame)

    dog_sprite.sprite_frames = sprite_frames
    dog_sprite.animation = "walk_down"
    dog_sprite.frame = 0
    dog_sprite.flip_h = false
    dog_sprite.speed_scale = 1.0


func _load_static_fallback() -> void:
    var dog_image := Image.load_from_file(FALLBACK_DOG_PATH)
    if dog_image.is_empty():
        push_error("Nao foi possivel carregar nenhuma imagem do cao.")
        return

    var sprite_frames := SpriteFrames.new()
    sprite_frames.add_frame("default", ImageTexture.create_from_image(dog_image))
    dog_sprite.sprite_frames = sprite_frames
    dog_sprite.animation = "default"
    dog_sprite.scale = Vector2(0.1, 0.1)


func _keep_inside_movement_bounds() -> void:
    var half_size := Vector2.ZERO
    if collision_shape.shape is RectangleShape2D:
        half_size = collision_shape.shape.size * 0.5

    var collision_offset := collision_shape.position
    var minimum_position := movement_bounds.position + half_size - collision_offset
    var maximum_position := movement_bounds.end - half_size - collision_offset

    position = position.clamp(minimum_position, maximum_position)
