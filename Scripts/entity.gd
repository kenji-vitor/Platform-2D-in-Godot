extends CharacterBody2D
class_name Entity


@export var health: int
var is_damaged = false

func _turn_red(s: AnimatedSprite2D) -> void:
	s.modulate = Color(1,0.3,0.3,1)
	await get_tree().create_timer(0.1).timeout
	s.modulate = Color(1,1,1,1)
	await get_tree().create_timer(0.1).timeout
	is_damaged = false

	
	
func _invincible_frames_blinks(s: AnimatedSprite2D) -> void:
	var blinks = 4
	for i in range(blinks):
		s.modulate = Color(1,1,1,0.25)
		await get_tree().create_timer(0.1).timeout
		s.modulate = Color(1,1,1,1)
		await get_tree().create_timer(0.1).timeout
	
func take_damage(s: AnimatedSprite2D) -> void:
	if is_damaged:
		return #Prevents multi hit damage
	health -= 1
	print("Health: ", health)
	if health <= 0:
		return
	is_damaged = true
	#_blink_white()
	_turn_red(s)
	
