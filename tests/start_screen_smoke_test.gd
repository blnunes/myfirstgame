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
    assert(skin_name_label.text == "GOLDEN")
    assert(skin_preview.texture is AtlasTexture)
    print("OK arrow key selects GOLDEN skin")

    play_button.pressed.emit()
    await process_frame
    await physics_frame
    assert(not start_overlay.visible)
    assert(hud.visible)
    assert(player.visible)
    assert(bool(main_scene.get("game_running")))
    assert(player.call("get_active_skin_id") == &"golden")
    print("OK PLAY starts gameplay")

    Input.action_press("ui_right")
    for _frame in 18:
        await physics_frame
        await process_frame
    var dog_sprite := player.get_node("VisualRoot/DogSprite") as AnimatedSprite2D
    assert(dog_sprite.animation == &"walk_side")
    var golden_side_frame := dog_sprite.sprite_frames.get_frame_texture(
        &"walk_side",
        dog_sprite.frame
    ) as AtlasTexture
    assert(golden_side_frame != null)
    assert(golden_side_frame.region.position.y == golden_side_frame.region.size.y)
    Input.action_release("ui_right")
    print("OK GOLDEN skin uses its own side-animation row")

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
    assert(skin_name_label.text == "GOLDEN")
    var saved_entries: Array[Dictionary] = main_scene.get("leaderboard_store").get_entries()
    assert(saved_entries.size() == 1)
    assert(saved_entries[0]["initials"] == "ABC")
    print("OK saved score returns to start screen")

    previous_skin_button.pressed.emit()
    await process_frame
    assert(skin_name_label.text == "MIDNIGHT")
    print("OK on-screen selector button changes skin")
    quit()
