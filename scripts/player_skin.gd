class_name PlayerSkin
extends RefCounted

var id: StringName
var display_name: String
var texture_path: String
var animation_rows: Dictionary
var cover_frame: Vector2i


func _init(
    new_id: StringName,
    new_display_name: String,
    new_texture_path: String,
    new_animation_rows: Dictionary,
    new_cover_frame: Vector2i
) -> void:
    id = new_id
    display_name = new_display_name
    texture_path = new_texture_path
    animation_rows = new_animation_rows.duplicate(true)
    cover_frame = new_cover_frame
