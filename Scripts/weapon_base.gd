extends CharacterBody2D

@export var speed = 600
var direction = 2
@export var rotation_speed = 18
var target : Node2D
@export var x_limit = 750.0
@export var x_min_limit = -3000.0
@export var x_max_limit = 3000.0
@export var damage = 0
var start_x : float

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	
	var collision = move_and_collide(Vector2(speed*direction,0) * delta)
	if collision:
		queue_free()
		
	
	
	#if target != null:
		#var diff = target.global_position.y - global_position.y
		#velocity.y = diff * 1.0
	
	sprite.rotation += rotation_speed * direction * delta
	if global_position.x > x_max_limit or global_position.x < -x_max_limit:#or global_position.x < x_min_limit:
		queue_free()

func _exit_tree() -> void:
	remove_from_group("bullet")
