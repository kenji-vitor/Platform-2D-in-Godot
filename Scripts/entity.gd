extends CharacterBody2D
class_name Entity
# Parent for Player, Purple Mushroom

@export var health: int = 3
var is_damaged: bool = false
var blink_tween: Tween

# Busca automaticamente o AnimatedSprite2D filho caso nenhum seja passado
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _turn_red(s: AnimatedSprite2D = null) -> void:
	# Se 's' não for passado, usa o 'sprite' padrão do nó
	var target_sprite = s if s != null else sprite
	if target_sprite == null:
		return
		
	target_sprite.modulate = Color(1, 0.3, 0.3, 1)
	await get_tree().create_timer(0.1).timeout
	target_sprite.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(0.1).timeout
	is_damaged = false

func _invincible_frames_blinks(s: AnimatedSprite2D = null) -> void:
	# Garante que temos um sprite válido antes de manipular o modulate
	var target_sprite = s if s != null else sprite
	if target_sprite == null:
		return

	var blinks = 4
	if blink_tween and blink_tween.is_running():
		blink_tween.kill()
		
	target_sprite.modulate.a = 0.25
	blink_tween = create_tween()
	for i in range(blinks):
		blink_tween.tween_property(target_sprite, "modulate:a", 1.0, 0.1)
		blink_tween.tween_property(target_sprite, "modulate:a", 0.25, 0.1)
	blink_tween.tween_property(target_sprite, "modulate:a", 1.0, 0.0)

func take_damage(amount: int = 1) -> void:
	if is_damaged:
		return # Prevents multi hit damage
	
	health -= amount # Aplica o valor real do dano recebido
	print(name, " Health: ", health)
	
	if health <= 0:
		_on_death()
		return
		
	is_damaged = true
	_turn_red()

func _on_death() -> void:
	queue_free()
