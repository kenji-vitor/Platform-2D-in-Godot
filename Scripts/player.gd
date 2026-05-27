extends "res://Scripts/entity.gd"

var SPEED = 100.0
var JUMP_VEL = -300.0
@onready var player: AnimatedSprite2D = $AnimatedSprite2D

var knockback_force = Vector2(100,-250)
var is_knockback = false

@onready var shoot_point = $ShootPoint
var current_weapon = 2


@export var max_jumps: int = 2
var jump_left : int = 2

var has_jumped = false
var was_on_floor = false
var fell_off_platform = false

var air_direction = 0
var air_control_locked = false

var max_bullet = 0
var current_bullets = 0
var fire_cooldown = 0.4
var can_shoot = true

#Timers
@onready var knockback_timer = $KnockbackTimer
@onready var invincibility_timer = $InvincibilityTimer

var classic_knockback_timer = 5.0
var normal_knock_back_timer = 0.4
var is_invincible = false

#Difficulty
var code_sequence = ["h","a","r","d"]
var code_progress = 0
var classic = false #Oldschool movement
var classic_deceleration = 100
var normal_deceleration = 8


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var weapon1_scene = preload("res://Scenes/weapon_1.tscn")
@onready var weapon2_scene = preload("res://Scenes/weapon_2.tscn")

@onready var hitbox = $Area2D
var spawn_position: Vector2

const weapon1_limit = 20
const weapon1_cooldwon = 0.4

const  weapon2_limit = 15
const weapon2_cooldown = 0.8

var can_swap = true

var is_running = false

var was_on_floor_hit = false

var hit_position_y = 0.0

var knockback_timer_shortened = false

func _ready() -> void:
	spawn_position = global_position
	jump_left = max_jumps

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and classic == false:
		var key = OS.get_keycode_string(event.keycode).to_lower()
		if key == code_sequence[code_progress]:
			code_progress += 1
			if code_progress == code_sequence.size():
				classic = not classic
				code_progress = 0
				#if classic:
					#is_running = false #Remove sing from classic mode
				print("Classic Controllers!!", classic)
		else:
			code_progress = 0
	
	if Input.is_action_just_pressed("swap_weapon"):
		swap_weapon()
	
	#print("Jump left: ", jump_left)
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("down") and jump_left > 0:
		drop_through_platform()
		return
	if Input.is_action_just_pressed("jump") and jump_left > 0 and not is_knockback:
		jump()

		if jump_left == max_jumps - 1:
			air_direction = sign(velocity.x)
			if air_direction == 0:
				#air_direction = Input.get_axis("ui_left","ui_right")
				air_direction = Input.get_axis("move_left","move_right")
			air_control_locked = true
		else:
			#air_direction = Input.get_axis("ui_left","ui_right")
			air_direction = Input.get_axis("move_left","move_right")
	if not classic:
		if Input.is_action_just_pressed("run"):
			is_running = not is_running

	#if Input.is_action_just_pressed("down"):
	#	await get_tree().create_timer(0.3)
	#	set_collision_mask_value(10,false)
	#else:
	#	set_collision_mask_value(10,true)

func _physics_process(delta: float) -> void:
	#var parallax = get_parent().get_node("$ParallaxBackground")
	#aparallax.scroll_offset.y = global_position.y
	#print(player.global_position)
	_check_enemy_overlay()
	if is_knockback:
		if not is_on_floor():
			velocity.y += gravity * delta
			if classic and not knockback_timer_shortened:
				var fall_distance = global_position.y - hit_position_y
				#print(fall_distance)
				if fall_distance < 20 and velocity.y > 0:
					knockback_timer.start(0.8)
					knockback_timer_shortened = true
				elif fall_distance >= 20 and velocity.y > 0:
					#if knockback_timer.time_left > 0.8:
						#knockback_timer.start(0.8)
					knockback_timer_shortened = true
		else:
			velocity.x = move_toward(velocity.x,0,20)
			if classic and was_on_floor_hit:
				if knockback_timer.time_left > 1.0:
					knockback_timer.start(1.0)
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y < 0:
			player.animation = "Jump"
		else:
			player.animation = "Fall"
	elif(velocity.x > 1 || velocity.x < -1):
		player.animation = "Sprint"
	else:
		player.animation = "Idle"
		
	if Input.is_action_pressed("shoot"):
		if classic:
			if not is_knockback:
				shoot()
		else:
			shoot()
	#Gravity

	#Horizontal Movement
	#var direction = Input.get_axis("ui_left","ui_right")
	var direction = Input.get_axis("move_left","move_right")
	var current_speed = SPEED + 70 if is_running else SPEED
	if classic:
		if not is_on_floor() and not air_control_locked:
			air_control_locked = true
			if has_jumped:
				air_direction = Input.get_axis("move_left","move_right")
			else:
				air_direction = 0
		if air_control_locked:
			velocity.x = air_direction * current_speed
			
			var look_direction = Input.get_axis("move_left","move_right")
			if look_direction < 0:
				player.flip_h = true
			elif look_direction > 0:
				player.flip_h = false
		else:
			movement(direction,current_speed,classic_deceleration)
	else:
		movement(direction,current_speed,normal_deceleration)
		
	move_and_slide()
	
	if is_on_floor():
		jump_left = max_jumps
		has_jumped = false
		air_control_locked = false
		if classic:
			if velocity.x > 0:
				player.flip_h = false
			elif velocity.x < 0:
				player.flip_h = true

		
	elif was_on_floor and not has_jumped:
		jump_left = 1
	was_on_floor = is_on_floor()
	


	
	#if Input.is_action_just_pressed('ui_left'):
	if not classic:
		if velocity.x < 0:
			player.flip_h = true
		elif velocity.x > 0:
			player.flip_h = false

	#var is_falling_off = was_on_floor and not on_floor and velocity.y >= 0

	
	if global_position.y > 1500:
		die()

func movement(direction,current_speed,deceleration = 8):
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = 0

func swap_weapon() -> void:
	if not can_swap:
		return
	current_weapon = 2 if current_weapon == 1 else 1
	can_swap = false
	get_tree().create_timer(2.5).timeout.connect(func(): can_swap = true)

	
			

func shoot() -> void:
	if not can_shoot:
		return
	match current_weapon:
		1: 
			shoot_weapon1()
			
		2: 
			shoot_weapon2()

func shoot_weapon1() -> void:
	max_bullet = weapon1_scene.instantiate()
	if current_bullets >= weapon1_limit:
		return
	can_shoot = false
	get_tree().create_timer(weapon1_cooldwon).timeout.connect(func(): can_shoot = true)
	_shoot_bullet(weapon1_scene)

func shoot_weapon2() -> void:
	max_bullet = weapon2_scene.instantiate()
	if current_bullets >= weapon2_limit:
		return
	can_shoot = false
	get_tree().create_timer(weapon2_cooldown).timeout.connect(func(): can_shoot = true)
	for i in range(3):
		_shoot_bullet(weapon2_scene)
		await get_tree().create_timer(0.15).timeout

func _shoot_bullet(scene: PackedScene) -> void:
	var bullet = scene.instantiate()
	get_parent().add_child(bullet)
	if player.flip_h:
		bullet.global_position = shoot_point.global_position+ Vector2(-10,0)
		bullet.direction = -1
	else:
		bullet.global_position = shoot_point.global_position+ Vector2(10,0)
		bullet.direction = 1
	bullet.target = self
	bullet.add_collision_exception_with(self)
	for existing_bullet in get_tree().get_nodes_in_group("bullet"):
		bullet.add_collision_exception_with(existing_bullet)
		existing_bullet.add_collision_exception_with(bullet)
	bullet.add_to_group("bullet")
	current_bullets += 1
	bullet.tree_exited.connect(func(): current_bullets -= 1)

	
func apply_knockback(from_position: Vector2):
	var direction = sign(global_position.x - from_position.x)
	
	velocity.x = direction * knockback_force.x
	velocity.y = knockback_force.y
	is_knockback = true
	was_on_floor_hit = is_on_floor()
	hit_position_y = global_position.y
	if classic:
		knockback_timer.start(classic_knockback_timer)
	else:
		knockback_timer.start(normal_knock_back_timer)
	knockback_timer_shortened = false
	

func jump():
	if jump_left <= 0:
		return
	velocity.y = JUMP_VEL - 15
	jump_left -= 1
	has_jumped = true

func drop_through_platform():
	set_collision_mask_value(10,false)
	await get_tree().create_timer(0.3).timeout
	set_collision_mask_value(10,true)

func die():
	global_position = spawn_position
	velocity = Vector2.ZERO
	
	jump_left = max_jumps
	has_jumped = false
	fell_off_platform = false
	air_control_locked = false
	current_bullets = 0
	get_tree().reload_current_scene()

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
		die()

func _on_area_2d_area_exited(area: Area2D) -> void:
	pass # Replace with function body.
	
func _check_enemy_overlay() -> void:
	for area in $Area2D.get_overlapping_areas():
		var enemy = area.get_parent()
		if enemy.is_in_group("enemy") and not is_invincible:
			take_damage()
			apply_knockback(enemy.global_position)
			
func _on_knockback_timer_timeout() -> void:
	is_knockback = false
	velocity.x = 0

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false
	$Area2D.monitoring = true
