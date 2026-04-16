extends "res://Scripts/entity.gd"

var SPEED = 100.0
var JUMP_VEL = -300.0
@onready var player: AnimatedSprite2D = $AnimatedSprite2D



@onready var shoot_point = $ShootPoint

@export var max_jumps: int = 2
var jump_left : int = 2

var has_jumped = false
var was_on_floor = false
var fell_off_platform = false

var air_direction = 0
var air_control_locked = false

var max_bullet = 40
var current_bullets = 0
var fire_cooldown = 0.4
var can_shoot = true


#Difficulty
var code_sequence = ["h","a","r","d"]
var code_progress = 0
var classic = false #Oldschool movement

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var weapon1_scene = preload("res://Scenes/weapon_1.tscn")

@onready var hitbox = $Area2D
var spawn_position: Vector2


var is_running = false

func _ready() -> void:
	var health = 10
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
				if classic:
					is_running = false #Remove sprinting from classic mode
				print("Classic Controllers!!", classic)
		else:
			code_progress = 0
		
	
	#print("Jump left: ", jump_left)
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("down") and jump_left > 0:
		drop_through_platform()
		return
	if Input.is_action_just_pressed("jump") and jump_left > 0:
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
		shoot()
	#Gravity

	#Horizontal Movement
	#var direction = Input.get_axis("ui_left","ui_right")
	var direction = Input.get_axis("move_left","move_right")
	var current_speed = SPEED + 40 if is_running else SPEED
	if classic:
		if air_control_locked:
			velocity.x = air_direction * current_speed
		else:
			movement(direction,current_speed)
			#if direction:
			#	velocity.x = direction * current_speed
			#else:
				#velocity.x = move_toward(velocity.x,0,8)
	else:
		movement(direction,current_speed)
		
	move_and_slide()
	
	if is_on_floor():
		jump_left = max_jumps
		has_jumped = false
		air_control_locked = false
		
	elif was_on_floor and not has_jumped:
		jump_left = 1
	was_on_floor = is_on_floor()
	


	
	#if Input.is_action_just_pressed('ui_left'):
	if velocity.x < 0:
		player.flip_h = true
	elif velocity.x > 0:
		player.flip_h = false

	#var is_falling_off = was_on_floor and not on_floor and velocity.y >= 0

	
	if global_position.y > 1500:
		die()

func movement(direction,current_speed):
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x,0,8)

func shoot():
	#print(global_position)
	if current_bullets >= max_bullet or not can_shoot:
		return
	can_shoot = false
	get_tree().create_timer(fire_cooldown).timeout.connect(func(): can_shoot = true)
	var bullet = weapon1_scene.instantiate()
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
	#aprint("Current bullets: ", current_bullets)

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

func take_damage(s: AnimatedSprite2D = player) -> void:
	print("TAKE DAMAGE CHAMADO")
	super.take_damage(s)
	if health <= 0:
		die()

func _on_area_2d_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy.is_in_group("enemy"):
		take_damage()
