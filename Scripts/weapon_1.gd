extends "res://Scripts/weapon_base_ranged.gd"

func _ready() -> void:
	start_x = global_position.x


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
func _exit_tree() -> void:
	super._exit_tree()
