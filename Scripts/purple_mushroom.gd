extends CharacterBody2D

@export var SPEED = 30
@export var JUMP_FORCE = -350.0

var direction = 1
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var purple_mushroom: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox = $Area2D
@onready var delay_after_jump_timer = $DelayAfterJumpTimer

var health = 3
var is_damaged = false

#X direction 
var change_direction_timer = 0.0
var time_to_change = 0.0
var jump_timer = 0.0
var time_to_jump = 0.0
var is_jumping = false



var jump_time = 0.0
var tracking_jump = false

func _ready() -> void:
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
	time_to_change = randf_range(1.0,3.0)
	change_direction_timer = 0.0

func _set_random_jump() -> void:
	time_to_jump = randf_range(1.0,3.0)
	jump_timer = randf_range(-2.0,0.0)
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		is_jumping = true
	else:
		#velocity.x += SPEED * direction * delta
		is_jumping = false

	
	if is_jumping:
		purple_mushroom.play("Jump")
	else:
		purple_mushroom.play("Move")
		
		
	if is_jumping and is_on_floor() == false:
		jump_time += delta
	elif not is_jumping and jump_time > 0:
		
		jump_time = 0.0
		

	move_and_slide()
	
	if is_on_wall():
		direction *= -1
		_set_random_timer()
		
	change_direction_timer += delta
	if change_direction_timer >= time_to_change:
		direction *= -1
		_set_random_timer()
	
	jump_timer += delta
	if jump_timer >= time_to_jump and is_on_floor():
		velocity.y = JUMP_FORCE
		velocity.x = SPEED * direction
		is_jumping = true
		purple_mushroom.play("Jump")
		#print("JUMPING: ", is_jumping)  # add this
		direction = [-1,1].pick_random()
		_set_random_jump()
		
	if velocity.x < 0:
		purple_mushroom.flip_h = true
	elif velocity.x > 0:
		purple_mushroom.flip_h = false
		

	
func _turn_red() -> void:
	purple_mushroom.modulate = Color(1,0.3,0.3,1)
	await get_tree().create_timer(0.1).timeout
	purple_mushroom.modulate = Color(1,1,1,1)
	await get_tree().create_timer(0.1).timeout
	is_damaged = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		body.queue_free()
		take_damage()
		
func take_damage() -> void:
	if is_damaged:
		return #Prevents multi hit damage
	health -= 1
	if health <= 0:
		queue_free()
		return
	is_damaged = true
	_turn_red()


func _on_delay_after_jump_timer_timeout() -> void:
	return
