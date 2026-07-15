class_name PlayerSkinCatalog
extends RefCounted


static func create_skins() -> Array[PlayerSkin]:
    return [
        PlayerSkin.new(
            &"midnight",
            "MIDNIGHT",
            "res://assets/characters/dog/spritesheets/dog_walk_midnight_v3.png",
            {
                "walk_down": 0,
                "walk_side": 1,
                "walk_up": 3,
            },
            Vector2i(0, 0)
        ),
        PlayerSkin.new(
            &"golden",
            "GOLDEN",
            "res://assets/characters/dog/spritesheets/dog_walk_golden.png",
            {
                "walk_down": 0,
                "walk_side": 1,
                "walk_up": 3,
            },
            Vector2i(0, 0)
        ),
        PlayerSkin.new(
            &"dapple",
            "DAPPLE",
            "res://assets/characters/dog/spritesheets/dog_walk_dapple.png",
            {
                "walk_down": 0,
                "walk_side": 1,
                "walk_up": 3,
            },
            Vector2i(0, 0)
        ),
    ]
