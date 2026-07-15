class_name LeaderboardStore
extends RefCounted

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10

var entries: Array[Dictionary] = []


func load_entries() -> void:
    entries.clear()
    if not FileAccess.file_exists(SAVE_PATH):
        return

    var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if save_file == null:
        push_error("Nao foi possivel abrir o ranking para leitura.")
        return

    var decoded_data: Variant = JSON.parse_string(save_file.get_as_text())
    if not decoded_data is Array:
        push_warning("Ranking ignorado porque o arquivo salvo e invalido.")
        return

    var decoded_entries: Array = decoded_data
    for candidate_data in decoded_entries:
        if not candidate_data is Dictionary:
            continue
        var candidate: Dictionary = candidate_data
        if not candidate.has("initials") or not candidate.has("time"):
            continue

        var initials := str(candidate["initials"]).to_upper()
        var time_value: Variant = candidate["time"]
        if not _is_valid_initials(initials):
            continue
        if not (time_value is float or time_value is int) or float(time_value) <= 0.0:
            continue
        entries.append({"initials": initials, "time": float(time_value)})

    _sort_and_trim()


func qualifies(time_seconds: float) -> bool:
    return entries.size() < MAX_ENTRIES or time_seconds < float(entries[-1]["time"])


func add_entry(initials: String, time_seconds: float) -> bool:
    var normalized_initials := initials.to_upper()
    if not _is_valid_initials(normalized_initials) or not qualifies(time_seconds):
        return false

    entries.append({"initials": normalized_initials, "time": time_seconds})
    _sort_and_trim()
    _save_entries()
    return true


func get_entries() -> Array[Dictionary]:
    var entries_copy: Array[Dictionary] = []
    for entry in entries:
        entries_copy.append(entry.duplicate(true))
    return entries_copy


func _sort_and_trim() -> void:
    entries.sort_custom(_is_faster_entry)
    if entries.size() > MAX_ENTRIES:
        entries.resize(MAX_ENTRIES)


func _is_faster_entry(first: Dictionary, second: Dictionary) -> bool:
    return float(first["time"]) < float(second["time"])


func _save_entries() -> void:
    var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if save_file == null:
        push_error("Nao foi possivel salvar o ranking.")
        return
    save_file.store_string(JSON.stringify(entries))


func _is_valid_initials(initials: String) -> bool:
    if initials.length() != 3:
        return false
    for character in initials:
        var character_code := character.unicode_at(0)
        if character_code < 65 or character_code > 90:
            return false
    return true
