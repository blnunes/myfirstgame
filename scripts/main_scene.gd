extends Node2D

const LEADERBOARD_STORE_SCRIPT := preload("res://scripts/leaderboard_store.gd")
const SCENARIO_SCRIPTS: Array[Script] = [
    preload("res://scripts/scenarios/forest_scenario.gd"),
    preload("res://scripts/scenarios/city_scenario.gd"),
    preload("res://scripts/scenarios/desert_scenario.gd"),
    preload("res://scripts/scenarios/space_scenario.gd"),
]
const TRANSITIONS_TO_WIN := 10

@onready var player: CharacterBody2D = $Player
@onready var scenario_label: Label = $Interface/MarginContainer/PanelContainer/Content/ScenarioLabel
@onready var instruction_label: Label = $Interface/MarginContainer/PanelContainer/Content/InstructionLabel
@onready var stats_label: Label = $Interface/MarginContainer/PanelContainer/Content/StatsLabel
@onready var hud: MarginContainer = $Interface/MarginContainer
@onready var end_game_overlay: ColorRect = $Interface/EndGameOverlay
@onready var final_time_label: Label = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/FinalTimeLabel
@onready var qualification_label: Label = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/QualificationLabel
@onready var initials_row: HBoxContainer = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/InitialsRow
@onready var initials_input: LineEdit = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/InitialsRow/InitialsInput
@onready var submit_score_button: Button = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/InitialsRow/SubmitButton
@onready var validation_label: Label = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/ValidationLabel
@onready var leaderboard_label: Label = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/LeaderboardLabel
@onready var restart_button: Button = $Interface/EndGameOverlay/ResultsPanel/ResultsContent/RestartButton
@onready var start_overlay: ColorRect = $Interface/StartOverlay
@onready var play_button: Button = $Interface/StartOverlay/StartPanel/StartMargin/StartContent/PlayButton
@onready var previous_skin_button: Button = $Interface/StartOverlay/StartPanel/StartMargin/StartContent/SkinSelector/PreviousSkinButton
@onready var next_skin_button: Button = $Interface/StartOverlay/StartPanel/StartMargin/StartContent/SkinSelector/NextSkinButton
@onready var skin_preview: TextureRect = $Interface/StartOverlay/StartPanel/StartMargin/StartContent/SkinSelector/BruceFrame/BruceImage
@onready var skin_name_label: Label = $Interface/StartOverlay/StartPanel/StartMargin/StartContent/SkinNameLabel

var current_scenario: BaseScenario
var current_scenario_index := 0
var interaction_sound: AudioStreamPlayer
var random := RandomNumberGenerator.new()
var scenario_bag: Array[int] = []
var leaderboard_store := LEADERBOARD_STORE_SCRIPT.new()
var completed_transitions := 0
var session_start_msec := 0
var final_time_seconds := 0.0
var game_running := false
var is_changing_scenario := false
var available_skins: Array[PlayerSkin] = []
var selected_skin_index := 0


func _ready() -> void:
    random.randomize()
    available_skins = PlayerSkinCatalog.create_skins()
    _create_interaction_sound()
    leaderboard_store.load_entries()
    initials_input.text_changed.connect(_on_initials_text_changed)
    initials_input.text_submitted.connect(_on_initials_text_submitted)
    submit_score_button.pressed.connect(_submit_score)
    restart_button.pressed.connect(_show_start_screen)
    play_button.pressed.connect(_start_new_game)
    previous_skin_button.pressed.connect(_select_previous_skin)
    next_skin_button.pressed.connect(_select_next_skin)
    _update_skin_selection()
    _show_start_screen()


func _input(event: InputEvent) -> void:
    if not is_node_ready() or not start_overlay.visible:
        return
    if event.is_action_pressed("ui_left"):
        _select_previous_skin()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_right"):
        _select_next_skin()
        get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
    if game_running:
        _update_stats_label()


func _start_new_game() -> void:
    completed_transitions = 0
    final_time_seconds = 0.0
    game_running = true
    is_changing_scenario = false
    scenario_bag.clear()
    start_overlay.hide()
    end_game_overlay.hide()
    hud.show()
    player.show()
    initials_input.release_focus()
    initials_input.text = ""
    player.set_skin(available_skins[selected_skin_index])
    player.set_movement_enabled(true)
    _load_scenario(0)
    session_start_msec = Time.get_ticks_msec()
    _update_stats_label()


func _show_start_screen() -> void:
    game_running = false
    is_changing_scenario = false
    player.set_movement_enabled(false)
    player.set_space_helmet_visible(false)
    player.hide()
    hud.hide()
    end_game_overlay.hide()
    initials_input.release_focus()
    start_overlay.show()
    play_button.grab_focus()


func _select_previous_skin() -> void:
    _change_selected_skin(-1)


func _select_next_skin() -> void:
    _change_selected_skin(1)


func _change_selected_skin(direction: int) -> void:
    if available_skins.is_empty():
        return
    selected_skin_index = posmod(selected_skin_index + direction, available_skins.size())
    _update_skin_selection()


func _update_skin_selection() -> void:
    if available_skins.is_empty():
        skin_name_label.text = "NO SKINS"
        skin_preview.texture = null
        play_button.disabled = true
        return

    play_button.disabled = false
    var selected_skin := available_skins[selected_skin_index]
    skin_name_label.text = selected_skin.display_name
    var sheet_texture := load(selected_skin.texture_path) as Texture2D
    if sheet_texture == null:
        skin_preview.texture = null
        play_button.disabled = true
        push_error("Nao foi possivel carregar a capa da skin %s." % selected_skin.id)
        return

    var frame_size := Vector2i(
        sheet_texture.get_width() / 4,
        sheet_texture.get_height() / 4
    )
    var preview_texture := AtlasTexture.new()
    preview_texture.atlas = sheet_texture
    preview_texture.region = Rect2i(
        selected_skin.cover_frame.x * frame_size.x,
        selected_skin.cover_frame.y * frame_size.y,
        frame_size.x,
        frame_size.y
    )
    skin_preview.texture = preview_texture


func _load_scenario(scenario_index: int) -> void:
    if is_instance_valid(current_scenario):
        current_scenario.queue_free()

    current_scenario_index = scenario_index
    current_scenario = SCENARIO_SCRIPTS[current_scenario_index].new() as BaseScenario
    current_scenario.configure(random)
    current_scenario.target_reached.connect(_on_scenario_target_reached)
    player.position = current_scenario.get_safe_player_spawn(random)
    add_child(current_scenario)

    player.set_space_helmet_visible(current_scenario.requires_space_helmet())
    scenario_label.text = current_scenario.get_title()
    instruction_label.text = current_scenario.get_instruction()


func _on_scenario_target_reached(target_position: Vector2) -> void:
    if not game_running or is_changing_scenario:
        return

    is_changing_scenario = true
    completed_transitions += 1
    player.set_movement_enabled(false)
    player.play_pee_effect(target_position)
    instruction_label.text = current_scenario.get_success_message()
    interaction_sound.play()
    _update_stats_label()

    if completed_transitions >= TRANSITIONS_TO_WIN:
        final_time_seconds = _get_elapsed_time()
        game_running = false
        await get_tree().create_timer(0.7).timeout
        _finish_game()
        is_changing_scenario = false
        return

    await get_tree().create_timer(0.7).timeout
    _load_scenario(_pick_different_scenario())
    player.set_movement_enabled(true)
    is_changing_scenario = false


func _finish_game() -> void:
    player.set_movement_enabled(false)
    final_time_label.text = "TEMPO: %s" % _format_time(final_time_seconds)
    initials_input.text = ""
    submit_score_button.disabled = true
    _update_leaderboard_label()
    end_game_overlay.show()

    if leaderboard_store.qualifies(final_time_seconds):
        qualification_label.text = "TOP 10! DIGITE 3 INICIAIS"
        initials_row.show()
        validation_label.text = "Somente letras A-Z."
        restart_button.hide()
        initials_input.grab_focus()
    else:
        qualification_label.text = "O tempo nao entrou no TOP 10."
        initials_row.hide()
        validation_label.text = "Tente novamente para melhorar seu tempo."
        restart_button.show()


func _on_initials_text_changed(new_text: String) -> void:
    var sanitized_text := _sanitize_initials(new_text)
    if initials_input.text != sanitized_text:
        initials_input.text = sanitized_text
        initials_input.caret_column = sanitized_text.length()

    submit_score_button.disabled = sanitized_text.length() != 3
    if sanitized_text.is_empty():
        validation_label.text = "Somente letras A-Z."
    elif sanitized_text.length() < 3:
        validation_label.text = "Digite exatamente 3 letras."
    else:
        validation_label.text = "Pressione SALVAR ou Enter."


func _on_initials_text_submitted(_submitted_text: String) -> void:
    _submit_score()


func _submit_score() -> void:
    if game_running or not initials_row.visible or initials_input.text.length() != 3:
        return
    if not leaderboard_store.add_entry(initials_input.text, final_time_seconds):
        validation_label.text = "Este tempo nao esta mais no TOP 10."
        initials_row.hide()
        restart_button.show()
        return

    qualification_label.text = "RESULTADO SALVO!"
    validation_label.text = ""
    initials_row.hide()
    restart_button.show()
    _update_leaderboard_label()
    await get_tree().create_timer(0.9).timeout
    _show_start_screen()


func _sanitize_initials(value: String) -> String:
    var sanitized_text := ""
    for character in value.to_upper():
        var character_code := character.unicode_at(0)
        if character_code >= 65 and character_code <= 90:
            sanitized_text += character
        if sanitized_text.length() == 3:
            break
    return sanitized_text


func _update_stats_label() -> void:
    stats_label.text = "ALVOS %02d/%02d    TEMPO %s" % [
        completed_transitions,
        TRANSITIONS_TO_WIN,
        _format_time(_get_elapsed_time()),
    ]


func _update_leaderboard_label() -> void:
    var lines := PackedStringArray(["TOP 10"])
    var saved_entries := leaderboard_store.get_entries()
    if saved_entries.is_empty():
        lines.append("Ainda nao existem resultados.")
    else:
        for index in saved_entries.size():
            var entry := saved_entries[index]
            lines.append("%02d  %s    %s" % [
                index + 1,
                entry["initials"],
                _format_time(float(entry["time"])),
            ])
    leaderboard_label.text = "\n".join(lines)


func _get_elapsed_time() -> float:
    if not game_running:
        return final_time_seconds
    return float(Time.get_ticks_msec() - session_start_msec) / 1000.0


func _format_time(time_seconds: float) -> String:
    var total_milliseconds := int(time_seconds * 1000.0)
    var minutes := int(total_milliseconds / 60000.0)
    var seconds := int(total_milliseconds / 1000.0) % 60
    var milliseconds := total_milliseconds % 1000
    return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]


func _pick_different_scenario() -> int:
    if scenario_bag.is_empty():
        _refill_scenario_bag()
    return scenario_bag.pop_back()


func _refill_scenario_bag() -> void:
    for scenario_index in SCENARIO_SCRIPTS.size():
        if scenario_index != current_scenario_index:
            scenario_bag.append(scenario_index)

    # Fisher-Yates usa o mesmo gerador da sessão e garante um ciclo sem repetições.
    for index in range(scenario_bag.size() - 1, 0, -1):
        var swap_index := random.randi_range(0, index)
        var stored_index := scenario_bag[index]
        scenario_bag[index] = scenario_bag[swap_index]
        scenario_bag[swap_index] = stored_index


func _create_interaction_sound() -> void:
    interaction_sound = AudioStreamPlayer.new()
    interaction_sound.name = "InteractionSound"
    interaction_sound.volume_db = -8.0
    add_child(interaction_sound)

    var sample_rate := 22050
    var duration := 0.18
    var sample_count := int(sample_rate * duration)
    var sound_data := PackedByteArray()
    sound_data.resize(sample_count * 2)

    for index in sample_count:
        var time := float(index) / float(sample_rate)
        var envelope := pow(1.0 - float(index) / float(sample_count), 2.0)
        var wave := sin(TAU * 660.0 * time) + 0.35 * sin(TAU * 990.0 * time)
        var sample := int(clamp(wave * envelope * 13000.0, -32768.0, 32767.0))
        sound_data.encode_s16(index * 2, sample)

    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = sample_rate
    stream.stereo = false
    stream.data = sound_data
    interaction_sound.stream = stream
