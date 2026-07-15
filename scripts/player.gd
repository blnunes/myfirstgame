extends CharacterBody2D

@export var speed: float = 260.0
@export var movement_bounds := Rect2(0.0, 0.0, 640.0, 480.0)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var dog_sprite: Sprite2D = $DogSprite
@onready var accessories: PlayerAccessories = $Accessories

var movement_enabled := true


func _ready() -> void:
    add_to_group("player")
    var dog_image := Image.load_from_file("res://assets/characters/dog.png")
    if dog_image.is_empty():
        push_error("Nao foi possivel carregar a imagem do cao.")
        return

    dog_sprite.texture = ImageTexture.create_from_image(dog_image)


func _physics_process(_delta: float) -> void:
    if not movement_enabled:
        velocity = Vector2.ZERO
        return

    var input_vector = Vector2.ZERO
    input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

    if input_vector != Vector2.ZERO:
        input_vector = input_vector.normalized() * speed

    velocity = input_vector
    move_and_slide()
    _keep_inside_movement_bounds()


func set_movement_enabled(is_enabled: bool) -> void:
    movement_enabled = is_enabled
    if not movement_enabled:
        velocity = Vector2.ZERO


func set_space_helmet_visible(is_visible: bool) -> void:
    accessories.set_helmet_visible(is_visible)


func play_pee_effect(target_position: Vector2) -> void:
    accessories.play_pee_effect(target_position)


func _keep_inside_movement_bounds() -> void:
    var half_size := Vector2.ZERO
    if collision_shape.shape is RectangleShape2D:
        half_size = collision_shape.shape.size * 0.5

    var collision_offset := collision_shape.position
    var minimum_position := movement_bounds.position + half_size - collision_offset
    var maximum_position := movement_bounds.end - half_size - collision_offset

    position = position.clamp(minimum_position, maximum_position)
