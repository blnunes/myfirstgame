extends SceneTree


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var packed_scene := load("res://MainScene.tscn") as PackedScene
    var main_scene: Node = packed_scene.instantiate()
    root.add_child(main_scene)
    await process_frame
    await process_frame

    var start_overlay := main_scene.get_node("Interface/StartOverlay") as ColorRect
    var play_button := main_scene.get_node(
        "Interface/StartOverlay/StartPanel/StartMargin/StartContent/PlayButton"
    ) as Button
    assert(start_overlay.visible)
    play_button.pressed.emit()
    await process_frame
    await physics_frame
    assert(not start_overlay.visible)

    await _move_and_verify(main_scene, "ui_right", "walk_side", false, 1)
    await _move_and_verify(main_scene, "ui_left", "walk_side", true, 1)
    await _move_and_verify(main_scene, "ui_down", "walk_down", false, 0)
    await _move_and_verify(main_scene, "ui_up", "walk_up", false, 3)
    _verify_gait_phase_memory(main_scene)
    quit()


func _verify_gait_phase_memory(main_scene: Node) -> void:
    var player := main_scene.get_node("Player") as CharacterBody2D
    var visual_controller := player.get_node("VisualRoot") as PlayerVisualController
    var dog_sprite := player.get_node("VisualRoot/DogSprite") as AnimatedSprite2D
    player.set_movement_enabled(false)

    dog_sprite.animation = &"walk_side"
    dog_sprite.set_frame_and_progress(2, 0.4)
    dog_sprite.play()
    visual_controller.set_motion(Vector2.ZERO, 260.0)
    visual_controller.call("_update_directional_animation", 0.0)
    assert(not dog_sprite.is_playing())
    assert(dog_sprite.frame == 2)
    assert(is_equal_approx(dog_sprite.frame_progress, 0.4))

    visual_controller.set_motion(Vector2.RIGHT * 260.0, 260.0)
    visual_controller.call("_update_directional_animation", 1.0)
    assert(dog_sprite.is_playing())
    assert(dog_sprite.animation == &"walk_side")
    assert(dog_sprite.frame == 2)
    assert(is_equal_approx(dog_sprite.frame_progress, 0.4))

    dog_sprite.pause()
    dog_sprite.set_frame_and_progress(3, 0.25)
    visual_controller.set_motion(Vector2.UP * 260.0, 260.0)
    visual_controller.call("_update_directional_animation", 1.0)
    assert(dog_sprite.animation == &"walk_up")
    assert(dog_sprite.frame == 3)
    assert(is_equal_approx(dog_sprite.frame_progress, 0.25))
    print("OK gait phase is preserved across idle and direction changes")


func _move_and_verify(
    main_scene: Node,
    action: StringName,
    expected_animation: StringName,
    expected_flip: bool,
    expected_sheet_row: int
) -> void:
    Input.action_press(action)
    for _frame in 18:
        await physics_frame
        await process_frame

    var dog_sprite := main_scene.get_node("Player/VisualRoot/DogSprite") as AnimatedSprite2D
    assert(dog_sprite.animation == expected_animation)
    assert(dog_sprite.is_playing())
    assert(dog_sprite.frame > 0 or dog_sprite.frame_progress > 0.05)
    assert(dog_sprite.flip_h == expected_flip)
    var frame_texture := dog_sprite.sprite_frames.get_frame_texture(
        expected_animation,
        dog_sprite.frame
    ) as AtlasTexture
    assert(frame_texture != null)
    assert(frame_texture.region.position.y == expected_sheet_row * frame_texture.region.size.y)
    print(
        "OK ", action, ": ", dog_sprite.animation,
        " frame=", dog_sprite.frame, " flip=", dog_sprite.flip_h
    )

    Input.action_release(action)
    for _frame in 16:
        await physics_frame
        await process_frame
