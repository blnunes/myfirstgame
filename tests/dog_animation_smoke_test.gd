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

    await _move_and_verify(main_scene, "ui_right", "walk_side", false, 2)
    await _move_and_verify(main_scene, "ui_left", "walk_side", true, 2)
    await _move_and_verify(main_scene, "ui_down", "walk_down", false, 0)
    await _move_and_verify(main_scene, "ui_up", "walk_up", false, 3)
    quit()


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
    assert(dog_sprite.frame > 0)
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
    for _frame in 4:
        await physics_frame
