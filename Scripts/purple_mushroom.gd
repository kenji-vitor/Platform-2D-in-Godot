extends "res://Scripts/entity.gd"

@export var SPEED = 30
@export var JUMP_FORCE = -350.0

var direction = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var purple_mushroom: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox = $Area2D
@onready var delay_after_jump_timer = $DelayAfterJumpTimer

#var health = 5
#var is_damaged = false

#X direction 
var change_direction_timer = 0.0
var time_to_change = 0.0
var jump_timer = 0.0
var time_to_jump = 0.0
var is_jumping = false

var jump_time = 0.0
var tracking_jump = false
var is_jumping_boost = false
@export var extra_x_speed = 0

@onready var floor_check_right = $RayCast2DDownRight
@onready var floor_check_left = $RayCast2DDownLeft
var edge_detected = false

var can_change_direction = true

func _ready() -> void:

	#floor_check.position.x = 20 * direction
	jump_frames_animation()
	hitbox.body_entered.connect(_on_body_entered)
	direction = [-1,1].pick_random()
	_set_random_jump()
	_set_random_timer()

func jump_frames_animation():
	var jump_duration = (2 * abs(JUMP_FORCE)) / gravity
	var frame_count = purple_mushroom.sprite_frames.get_frame_count("Jump")
	var ideal_fps = frame_count/jump_duration
	purple_mushroom.sprite_frames.set_animation_speed("Jump", ideal_fps)
	#print("Jump duration: ", jump_time)
	#print("Ideal FPS: ", ideal_fps)
	

func _set_random_timer() -> void:
	time_to_change = randf_range(0,5.0)
	change_direction_timer = 0.0

func _set_random_jump() -> void:
	time_to_jump = randf_range(1.0,3.0)
	jump_timer = randf_range(-2.0,0.0)
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		is_jumping = true
		velocity.y += gravity * delta
		if not is_jumping_boost:
			velocity.x = SPEED * direction
		edge_detected = false
	else:
		is_jumping_boost = false
		is_jumping = false
		velocity.x = SPEED * direction
		if direction == 1 and not floor_check_right.is_colliding():
			direction = -1
			velocity.x = SPEED * direction
			#print("Velocity on ground: ", velocity.x)
		elif direction == -1 and not floor_check_left.is_colliding():
			direction = 1
			velocity.x = SPEED * direction
			#print("Velocity on ground: ", velocity.x)


	
	#if is_on_wall():
		#_flip_direction(direction * -1)

			

	if is_jumping:
		purple_mushroom.play("Jump")
	else:
		purple_mushroom.play("Move")
		
		
	change_direction_timer += delta
	if change_direction_timer >= time_to_change:
		_flip_direction(direction * -1)
		_set_random_timer()
	
	#Jump control
	jump_timer += delta
	if jump_timer >= time_to_jump and is_on_floor():
		#velocity.y = JUMP_FORCE
		#velocity.x = (SPEED + extra_x_speed) * direction
		#print(velocity.x)
		#var safe_dir = _get_safe_jump_direction()
		#if safe_dir == 0:
		#	_set_random_jump()
			#return
		#direction = safe_dir
		velocity.y = JUMP_FORCE
		#velocity.x = (SPEED + extra_x_speed) * direction
		velocity.x = SPEED * direction
		is_jumping_boost = true
		is_jumping = true
		purple_mushroom.play("Jump")
		_flip_direction([-1,1].pick_random())
		_set_random_jump()
		
	if velocity.x < 0:
		purple_mushroom.flip_h = true
	elif velocity.x > 0:
		purple_mushroom.flip_h = false

	#velocity.x = SPEED * direction
	move_and_slide()
	
	if global_position.y > 1500:
		queue_free()


func _get_safe_jump_direction() -> int:
	var right_safe = floor_check_right.is_colliding()
	var left_safe = floor_check_left.is_colliding()
	
	if right_safe and left_safe:
		return[-1,1].pick_random()
	elif right_safe:
		return 1
	elif left_safe:
		return -1
	else:
		return 0

'''
func _turn_red() -> void:
	purple_mushroom.modulate = Color(1,0.3,0.3,1)
	await get_tree().create_timer(0.1).timeout
	purple_mushroom.modulate = Color(1,1,1,1)
	await get_tree().create_timer(0.1).timeout
	is_damaged = false
'''

'''
func take_damage(s: AnimatedSprite2D = player) -> void:
	if is_invincible:
		return
	if s == null:
		s = player
	super.take_damage(s)
	is_invincible = true
	$Area2D.monitoring = false
	_invincible_frames_blinks(s)
	invincibility_timer.start(2)
	if health <= 0:
		#print("Die chamado")
		die()
'''
func _turn_red(s: AnimatedSprite2D) -> void:
	super._turn_red(s)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		body.queue_free()
		take_damage()
		
func take_damage(s: AnimatedSprite2D = purple_mushroom) -> void:
	health -= 1
	if health <= 0:
		queue_free()
		return
	is_damaged = true
	_turn_red(s)

func _flip_direction(new_dir: int) -> void:
	if not can_change_direction:
		return
	if new_dir == 1:
		if not floor_check_right.is_colliding():
			new_dir = -1
	elif new_dir == -1:
		if not floor_check_left.is_colliding():
			new_dir = 1
	direction = new_dir
	can_change_direction = false
	get_tree().create_timer(2).timeout.connect(func(): can_change_direction = true)


func _on_delay_after_jump_timer_timeout() -> void:
	return
