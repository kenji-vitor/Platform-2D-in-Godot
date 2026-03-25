extends StaticBody2D

@export var crab_item_scene : PackedScene
var used = false
	
func spawn_item():
	var item = crab_item_scene.instantiate()
	get_parent().add_child(item)
	item.global_position = global_position + Vector2(0,-16)


#func _on_area_2d_body_entered(body) -> void:
#	print("Detectou o player")
#	if used:
#		return
#	if body.is_in_group("player"):	
#		if body.velocity.y < 0:
#			spawn_item()
#			used = true


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Detectou o player")
	if used:
		return
	if body.is_in_group("player"):	
		if body.velocity.y < 0:
			spawn_item()
			used = true
