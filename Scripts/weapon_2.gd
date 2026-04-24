extends "res://Scripts/weapon_base.gd"
#Throws 3 bullets one after one after one


func _ready() -> void:
	start_x = global_position.x



func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _exit_tree() -> void:
	super._exit_tree()
