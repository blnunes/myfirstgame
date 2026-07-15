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
    var hud := main_scene.get_node("Interface/MarginContainer") as MarginContainer
    var player := main_scene.get_node("Player") as CharacterBody2D
    var play_button := main_scene.get_node(
        "Interface/StartOverlay/StartPanel/StartMargin/StartContent/PlayButton"
    ) as Button
    var skin_name_label := main_scene.get_node(
        "Interface/StartOverlay/StartPanel/StartMargin/StartContent/SkinNameLabel"
    ) as Label
    var skin_preview := main_scene.get_node(
        "Interface/StartOverlay/StartPanel/StartMargin/StartContent/SkinSelector/BruceFrame/BruceImage"
    ) as TextureRect
    var previous_skin_button := main_scene.get_node(
        "Interface/StartOverlay/StartPanel/StartMargin/StartContent/SkinSelector/PreviousSkinButton"
    ) as Button
    var initials_input := main_scene.get_node(
        "Interface/EndGameOverlay/ResultsPanel/ResultsContent/InitialsRow/InitialsInput"
    ) as LineEdit

    assert(start_overlay.visible)
    assert(not hud.visible)
    assert(not player.visible)
    assert(not bool(main_scene.get("game_running")))
    assert(skin_name_label.text == "MIDNIGHT")
    assert(skin_preview.texture is AtlasTexture)
    print("OK start screen blocks gameplay")

    var select_next_skin := InputEventAction.new()
    select_next_skin.action = &"ui_right"
    select_next_skin.pressed = true
    Input.parse_input_event(select_next_skin)
    await process_frame
    select_next_skin.pressed = false
    Input.parse_input_event(select_next_skin)
    await process_frame
    assert(skin_name_label.text == "GOLDEN")
    assert(skin_preview.texture is AtlasTexture)
    _assert_sheet_integrity(
        "res://assets/characters/dog/spritesheets/dog_walk_golden.png",
        "GOLDEN",
        0
    )
    print("OK arrow key selects GOLDEN skin")

    var select_dapple_skin := InputEventAction.new()
    select_dapple_skin.action = &"ui_right"
    select_dapple_skin.pressed = true
    Input.parse_input_event(select_dapple_skin)
    await process_frame
    select_dapple_skin.pressed = false
    Input.parse_input_event(select_dapple_skin)
    await process_frame
    assert(skin_name_label.text == "DAPPLE")
    assert(skin_preview.texture is AtlasTexture)
    _assert_sheet_integrity(
        "res://assets/characters/dog/spritesheets/dog_walk_dapple.png",
        "DAPPLE",
        12
    )
    print("OK arrow key selects DAPPLE skin")

    play_button.pressed.emit()
    await process_frame
    await physics_frame
    assert(not start_overlay.visible)
    assert(hud.visible)
    assert(player.visible)
    assert(bool(main_scene.get("game_running")))
    assert(player.call("get_active_skin_id") == &"dapple")
    print("OK PLAY starts gameplay")

    await _move_skin_and_verify(
        player,
        &"ui_right",
        &"walk_side",
        1,
        "dog_walk_dapple.png"
    )
    await _move_skin_and_verify(
        player,
        &"ui_down",
        &"walk_down",
        0,
        "dog_walk_dapple.png"
    )
    await _move_skin_and_verify(
        player,
        &"ui_up",
        &"walk_up",
        3,
        "dog_walk_dapple.png"
    )
    print("OK DAPPLE skin uses horizontal and vertical rows")

    main_scene.set("game_running", false)
    main_scene.set("final_time_seconds", 12.345)
    main_scene.get("leaderboard_store").entries.clear()
    main_scene.call("_finish_game")
    initials_input.text = "ABC"
    main_scene.call("_submit_score")
    await create_timer(1.0).timeout

    assert(start_overlay.visible)
    assert(not hud.visible)
    assert(not player.visible)
    assert(not bool(main_scene.get("game_running")))
    assert(skin_name_label.text == "DAPPLE")
    var saved_entries: Array[Dictionary] = main_scene.get("leaderboard_store").get_entries()
    assert(saved_entries.size() == 1)
    assert(saved_entries[0]["initials"] == "ABC")
    print("OK saved score returns to start screen")

    previous_skin_button.pressed.emit()
    await process_frame
    assert(skin_name_label.text == "GOLDEN")
    previous_skin_button.pressed.emit()
    await process_frame
    assert(skin_name_label.text == "MIDNIGHT")
    print("OK on-screen selector button changes skin")
    quit()


func _move_skin_and_verify(
    player: CharacterBody2D,
    action: StringName,
    expected_animation: StringName,
    expected_row: int,
    expected_sheet_filename: String
) -> void:
    Input.action_press(action)
    for _frame in 18:
        await physics_frame
        await process_frame

    var dog_sprite := player.get_node("VisualRoot/DogSprite") as AnimatedSprite2D
    assert(dog_sprite.animation == expected_animation)
    assert(dog_sprite.is_playing())
    var frame_texture := dog_sprite.sprite_frames.get_frame_texture(
        expected_animation,
        dog_sprite.frame
    ) as AtlasTexture
    assert(frame_texture != null)
    assert(frame_texture.region.position.y == expected_row * frame_texture.region.size.y)
    assert(frame_texture.atlas.resource_path.ends_with(expected_sheet_filename))

    Input.action_release(action)
    for _frame in 16:
        await physics_frame
        await process_frame


func _assert_sheet_integrity(
    sheet_path: String,
    skin_name: String,
    minimum_safe_margin: int
) -> void:
    const CELL_SIZE := 313
    var sheet := Image.new()
    var png_data := FileAccess.get_file_as_bytes(sheet_path)
    assert(not png_data.is_empty())
    assert(sheet.load_png_from_buffer(png_data) == OK)
    assert(sheet.get_size() == Vector2i(4 * CELL_SIZE, 4 * CELL_SIZE))

    for row in range(4):
        var frame_hashes: Dictionary = {}
        for column in range(4):
            var frame := sheet.get_region(
                Rect2i(column * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)
            )
            assert(frame.get_pixel(0, 0).a < 0.05)
            assert(frame.get_pixel(CELL_SIZE - 1, 0).a < 0.05)
            assert(frame.get_pixel(0, CELL_SIZE - 1).a < 0.05)
            assert(frame.get_pixel(CELL_SIZE - 1, CELL_SIZE - 1).a < 0.05)
            if minimum_safe_margin > 0:
                var visible_bounds := _visible_alpha_bounds(frame)
                assert(visible_bounds.position.x >= minimum_safe_margin)
                assert(visible_bounds.position.y >= minimum_safe_margin)
                assert(CELL_SIZE - visible_bounds.end.x >= minimum_safe_margin)
                assert(CELL_SIZE - visible_bounds.end.y >= minimum_safe_margin)
            var visible_pixels := _visible_pixel_count(frame)
            assert(visible_pixels > 15000)
            assert(visible_pixels < 30000)
            frame_hashes[hash(frame.get_data())] = true
        assert(frame_hashes.size() == 4)
    print("OK %s source sheet has transparent, distinct and complete frames" % skin_name)


func _visible_pixel_count(image: Image) -> int:
    var count := 0
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            if image.get_pixel(x, y).a > 0.25:
                count += 1
    return count


func _visible_alpha_bounds(image: Image) -> Rect2i:
    var minimum := Vector2i(image.get_width(), image.get_height())
    var maximum := Vector2i(-1, -1)
    for y in range(image.get_height()):
        for x in range(image.get_width()):
            if image.get_pixel(x, y).a > 0.0:
                minimum.x = mini(minimum.x, x)
                minimum.y = mini(minimum.y, y)
                maximum.x = maxi(maximum.x, x)
                maximum.y = maxi(maximum.y, y)
    assert(maximum.x >= minimum.x and maximum.y >= minimum.y)
    return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
