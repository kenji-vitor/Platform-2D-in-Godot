extends CharacterBody2D

@export var health: int
var is_damaged = false

func on_death():
	queue_free()

func _turn_red(s: AnimatedSprite2D) -> void:
	s.modulate = Color(1,0.3,0.3,1)
	await get_tree().create_timer(0.1).timeout
	s.modulate = Color(1,1,1,1)
	await get_tree().create_timer(0.1).timeout
	is_damaged = false
	
func take_damage(s: AnimatedSprite2D) -> void:
	if is_damaged:
		return #Prevents multi hit damage
	health -= 1
	print("Health: ", health)
	if health <= 0:
		on_death()
		return
	is_damaged = true
	_turn_red(s)
