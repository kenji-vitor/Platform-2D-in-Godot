
class_name MeleeWeaponBase
extends Area2D
#MELEE WEAPONS BASE


@export var attack_duration: float = 0.25
@export var damage = 0

@onready var sprite = get_node_or_null("AnimatedSprite2D")
@onready var collision_shape = get_node_or_null("CollisionShape2D")

var direction = 1
var attacker: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if sprite:
		sprite.play("attack")
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
	if area.has_method("take_damage"):
		area.take_damage(damage)
	elif area.get_parent() and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)

func _apply_damage(target: Node2D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)



	
