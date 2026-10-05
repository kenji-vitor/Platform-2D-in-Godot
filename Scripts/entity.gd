extends CharacterBody2D
class_name Entity
#Parent for Player, Purple Mushroom

@export var health: int
var is_damaged = false
var blink_tween: Tween

func _turn_red(s: AnimatedSprite2D) -> void:
	s.modulate = Color(1,0.3,0.3,1)
	await get_tree().create_timer(0.1).timeout
	s.modulate = Color(1,1,1,1)
	await get_tree().create_timer(0.1).timeout
	is_damaged = false
'''
func _turn_red() -> void:
	purple_mushroom.modulate = Color(1,0.3,0.3,1)
	await get_tree().create_timer(0.1).timeout
	purple_mushroom.modulate = Color(1,1,1,1)
	await get_tree().create_timer(0.1).timeout
	is_damaged = false
'''
	
	
func _invincible_frames_blinks(s: AnimatedSprite2D) -> void:
	var blinks = 4
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
	s.modulate.a = 0.25
	blink_tween = create_tween()
	for i in range(blinks):
		blink_tween.tween_property(s, "modulate:a", 1.0, 0.1)
		blink_tween.tween_property(s, "modulate:a", 0.25, 0.1)
	blink_tween.tween_property(s, "modulate:a", 1.0, 0.0)
	
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
	
