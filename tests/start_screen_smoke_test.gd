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
    var initials_input := main_scene.get_node(
        "Interface/EndGameOverlay/ResultsPanel/ResultsContent/InitialsRow/InitialsInput"
    ) as LineEdit

    assert(start_overlay.visible)
    assert(not hud.visible)
    assert(not player.visible)
    assert(not bool(main_scene.get("game_running")))
    print("OK start screen blocks gameplay")

    play_button.pressed.emit()
    await process_frame
    await physics_frame
    assert(not start_overlay.visible)
    assert(hud.visible)
    assert(player.visible)
    assert(bool(main_scene.get("game_running")))
    print("OK PLAY starts gameplay")

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
    var saved_entries: Array[Dictionary] = main_scene.get("leaderboard_store").get_entries()
    assert(saved_entries.size() == 1)
    assert(saved_entries[0]["initials"] == "ABC")
    print("OK saved score returns to start screen")
    quit()
