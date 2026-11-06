extends Node3D
func _ready() -> void:
    var game: Node = load("res://scenes/main.tscn").instantiate()
    add_child(game)
    for i in range(8): await get_tree().process_frame
    game.open_gacha()
