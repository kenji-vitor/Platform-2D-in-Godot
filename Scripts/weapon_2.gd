extends "res://Scripts/weapon_base.gd"
#Throws 3 bullets one after one after one

@onready var ShootDelayTimer = $ShootDelayTimer
var is_shooting = false
var bullet_amount = 3
'''
@export var speed = 600
var direction = 2
@export var rotation_speed = 18
var target : Node2D
@export var bullet_limit = 20
@export var x_limit = 550.0
@export var x_min_limit = -2000.0
@export var x_max_limit = 2000.0
var start_x : float
'''
func _ready() -> void:
	start_x = global_position.x

func _physics_process(delta: float) -> void:
	'''

	velocity.x = speed * direction
	if is_on_wall():
		queue_free()
	move_and_slide()
	
	#if target != null:
		#var diff = target.global_position.y - global_position.y
		#velocity.y = diff * 1.0
	
	rotation += rotation_speed * direction * delta
	if global_position.x > x_max_limit or global_position.x < x_min_limit:
		queue_free()
	'''
	super._physics_process(delta)
	#for i in range(bullet_amount):
		
		
	
	
func _exit_tree() -> void:
	super._exit_tree()


func _on_shoot_delay_timer_timeout() -> void:
	is_shooting = false
