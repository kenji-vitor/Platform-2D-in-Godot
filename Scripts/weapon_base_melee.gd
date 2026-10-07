
class_name MeleeWeaponBase
extends Area2D
#MELEE WEAPONS BASE

var can_attack: bool = true

@export var attack_duration: float = 0.25
@export var damage = 0
@export var weapon_cooldown: float = 0.5
@export var knockback_force: float = 200.0 # Força padrão do empurrão
@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var collision_shape = get_node_or_null("CollisionShape2D")

var direction = 1
var attacker: Node2D = null
		
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if sprite:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("normal_attack"):
			sprite.play("normal_attack")
		else:
			sprite.play()
		sprite.animation_finished.connect(_on_animation_finished)
	else:
		get_tree().create_timer(attack_duration).timeout.connect(queue_free)
	_setup_weapon()
	

func _setup_weapon():
	pass

func _on_animation_finished() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == attacker:
		return
	_apply_damage(body)


func _on_area_entered(area: Area2D) -> void:
	if area.get_parent() == attacker:
		return
	var target = area if area.has_method("take_damage") else area.get_parent()
	if target:
		_apply_damage(target)

func _apply_damage(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if target.has_method("apply_knockback"):
		var knockback_dir = Vector2(direction, -0.35).normalized()
		target.apply_knockback(knockback_dir * knockback_force)
	
func trigger_attack_cooldown() -> void:
	can_attack = false
	var timer = get_tree().create_timer(weapon_cooldown)
	await timer.timeout
	
	can_attack = true
	
func reset_cooldown() -> void:
	can_attack = true


	
