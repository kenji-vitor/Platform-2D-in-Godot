extends "res://Scripts/entity.gd"


@export var despawn_distance = 1200.0
@onready var mosquito: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox = $Area2D
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var SPEED = 160

var start_y : float

@export var amplitude = randi_range(60,120)

@export var frequency = randf_range(1,5)
var direction = 1
var time = 0.0

func _ready() -> void:
	#floor_check.position.x = 20 * direction
	start_y = global_position.y
	direction = [-1,1].pick_random()
	hitbox.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	time += delta
	
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.distance_to(player.global_position) > despawn_distance:
		queue_free()
		return
	
	velocity.x = SPEED * direction
	velocity.y = sin(time * frequency) * amplitude
	move_and_slide()
	#is_jumping = true
	#edge_detected = false
	
	if velocity.x < 0:
		mosquito.flip_h = false
	elif velocity.x > 0:
		mosquito.flip_h = true
	

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		body.queue_free()
		take_damage()

func take_damage(s: AnimatedSprite2D = mosquito) -> void:
	health -= 1
	if health <= 0:
		queue_free()
		return
	is_damaged = true
	_turn_red(s)
	
func _turn_red(s: AnimatedSprite2D) -> void:
	super._turn_red(s)
