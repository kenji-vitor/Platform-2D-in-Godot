extends "res://Scripts/weapon_base_ranged.gd"
#Throws 3 bullets one after one after one


func _ready() -> void:
	start_x = global_position.x

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage") and body.is_in_group("enemy"):
		if "is_damaged" in body and body.is_damaged:
			return
		body.take_damage(damage)
		queue_free()
		return
	if body is TileMap or body is StaticBody2D:
		queue_free()
	

func _physics_process(delta: float) -> void:
	super._physics_process(delta)

func _exit_tree() -> void:
	super._exit_tree()
