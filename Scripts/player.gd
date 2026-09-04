extends "res://Scripts/entity.gd"

var SPEED = 130.0
var JUMP_VEL = -300.0

var speed_mult: float = 1.0
var jump_mult: float = 1.0

@onready var player: AnimatedSprite2D = $AnimatedSprite2D

var knockback_force = Vector2(100,-250)
var is_knockback = false

@onready var shoot_point = $ShootPoint
var current_weapon = 2

var hearts_list : Array[TextureRect]


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
@onready var jump_forgiveness_timer = $JumpForgiveTimer
var jump_forgiveness_counter = 0.0

var is_skidding: bool = false
var skid_delay_timer: Timer

@export var skid_delay_time: float = 0.24

var classic_knockback_timer = 1.5
var normal_knock_back_timer = 0.4
#Invincibility + invencibility
var is_stealth_active: bool = false
var stealth_timer: SceneTreeTimer
var is_invincible = false
var is_player_invincible: bool :
	get:
		return is_invincible or GameManager.is_invincible 
#var is_invincible = false



#Difficulty
#var code_sequence = ["h","a","r","d"]
#var code_progress = 0
#var classic = false #Oldschool movement
var classic_deceleration = 100
var normal_deceleration = 8


var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var weapon1_scene = preload("res://Scenes/weapon_1.tscn")
@onready var weapon2_scene = preload("res://Scenes/weapon_2.tscn")

@onready var hitbox = $Area2D
var spawn_position: Vector2

const weapon1_limit = 20
const weapon1_cooldown = 0.4

const weapon2_limit = 15
const weapon2_cooldown = 0.8

var can_swap = true

#Run
@export var ACCELERATION: float = 250.0
@export var FRICTION: float = 120.0
@export var SKID_FORCE: float = 120.0
#Friction = 1 para nao ter friccao
var is_running = GameManager.is_action_pressed("run")

#AutoRun
@export var AUTORUN_CHANGE_INTERVAL: float = 2.0
var autorun_speed_modifier: float = 1.0
var autorun_tween: Tween

var was_on_floor_hit = false

var hit_position_y = 0.0

var knockback_timer_shortened = false

#SFX
@onready var jump_sfx: AudioStreamPlayer2D = $jump_sfx
@onready var weapon_sfx: AudioStreamPlayer2D = $weapon_sfx

var sfx_weapon_variations: Array[AudioStream] = [
	load("res://SFX/weapon_variation1.wav"),
	load("res://SFX/weapon_variation2.wav"),
	load("res://SFX/weapon_variation3.wav"),
	load("res://SFX/weapon_variation4.wav"),
	load("res://SFX/weapon_variation5.wav"),
]

func _ready() -> void:
	skid_delay_timer = Timer.new()
	skid_delay_timer.one_shot = true
	skid_delay_timer.timeout.connect(_on_skid_delay_timeout)
	add_child(skid_delay_timer)
	
	
	
	var hearts_parent = $health_bar/HBoxContainer
	hearts_list.clear()
	for child in hearts_parent.get_children():
		if child is TextureRect:
			hearts_list.append(child)
	health = hearts_list.size()
	
	print("Corações carregados: ", hearts_list.size())
	print("Vida inicializada em: ", health)
		
	spawn_position = global_position
	jump_left = max_jumps

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("jump") and Input.is_action_pressed("down") and jump_left > 0:
		drop_through_platform()
		return
	if GameManager.is_action_just_pressed("jump") and not is_knockback:
		if GameManager.classic:
			if jump_left > 0:
				jump()
		else:
			if jump_left > 0 or jump_forgiveness_counter > 0.0:
				if not is_on_floor() and jump_forgiveness_counter > 0.0 and jump_left == max_jumps:
					jump_forgiveness_counter = 0.0
					print("Salvo pelo Coyote Time")
				jump()

	if Input.is_action_just_pressed("swap_weapon"):
		swap_weapon()

	if GameManager.is_action_just_pressed("run"):
		is_running = not is_running
		print("Is Running?: ",is_running)
		# Tiro estático ou em movimento
	if GameManager.is_action_pressed("shoot"):
		shoot()

	#if Input.is_action_just_pressed("down"):
	#	await get_tree().create_timer(0.3)
	#	set_collision_mask_value(10,false)
	#else:
	#	set_collision_mask_value(10,true)

func _physics_process(delta: float) -> void:
	var base_speed: float = SPEED
	if GameManager.is_s_speed:
		base_speed = SPEED * 3
	elif is_running:
		base_speed = SPEED + 80.0
	if is_knockback:
		var is_grounded_after_hit = is_on_floor() and velocity.x >= 0.0
		if not is_grounded_after_hit:
			velocity.y += gravity * delta
		else:
			velocity.x = move_toward(velocity.x,0.0,FRICTION * delta)
			if was_on_floor_hit and not knockback_timer_shortened:
				if knockback_timer.time_left > 1.0:
					knockback_timer.start(1.0)
				knockback_timer_shortened = true
		move_and_slide()
		return
	var direction = Input.get_axis("move_left","move_right")
	#var target_max_speed = (SPEED + 80.0) if is_running else SPEED
	var target_max_speed = (SPEED + 80.0) if is_running else SPEED
	if GameManager.is_drunk:
		direction = Input.get_axis("move_right","move_left")
		if direction != 0:
			GameManager.drunk_direction = direction
		else:
			GameManager.drunk_direction = 0.0
		direction = GameManager.drunk_direction

	if GameManager.is_s_speed:
		target_max_speed = (SPEED * 3)
	if GameManager.is_invincible and not is_stealth_active:
		activate_stealth_mode()
	#
	'''
	if GameManager.is_autorunning:
		is_running = true
		if direction == 0.0:
			direction = 1.0 if player.flip_h == false else -1.0
		if autorun_tween == null or not autorun_tween.is_running():
			update_autorun_speed()
		target_max_speed = SPEED * autorun_speed_modifier
	else:
		if autorun_tween and autorun_tween.is_running():
			autorun_tween.kill()
		autorun_speed_modifier = 1.0
	'''
	if GameManager.is_autorunning:
		is_running = true
		if direction == 0.0:
			direction = 1.0 if player.flip_h == false else -1.0
		if autorun_tween == null or not autorun_tween.is_running():
			update_autorun_speed()
		target_max_speed = base_speed * autorun_speed_modifier
	else:
		target_max_speed = base_speed
		#if autorun_tween and autorun_tween.is_running():
			#autorun_tween.kill()
		#autorun_speed_modifier = 1.0
		
	var target_velocity_x = direction * target_max_speed
	# Aplica Movimento e Animações
	apply_gravity_and_movement(direction,target_max_speed,delta)
	handle_animations(delta)
	handle_sprite_flip()
	move_and_slide()

		# Checa Dano contínuo
	_check_enemy_overlay()

		# Morte por Queda
	if global_position.y > 1500:
		die()

func update_autorun_speed() -> void:
	if autorun_tween and autorun_tween.is_running():
		autorun_tween.kill()
	var target_mult = randf_range(0.5,1.8)
	autorun_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	autorun_tween.tween_property(self,"autorun_speed_modifier",target_mult,AUTORUN_CHANGE_INTERVAL)
	

func activate_stealth_mode(duration: float = randf_range(4.0,6.0))-> void:
		is_stealth_active = true
		set_stealth_state(true)
		stealth_timer = get_tree().create_timer(duration)
		await stealth_timer.timeout
		set_stealth_state(false)
		GameManager.is_invincible = false
		is_stealth_active = false

func set_stealth_state(active: bool) -> void:
	is_invincible = active
	
	if active:
		player.modulate.a = 0.0
		
		jump_mult = randf_range(0.85,1.3)
		speed_mult = randf_range(0.6,1.3)
	else:
		if blink_tween and blink_tween.is_running():
			blink_tween.kill()
			
		player.modulate.a = 1.0
		jump_mult = 1.0
		speed_mult = 1.0

func set_invisibility(active: bool) -> void:
	if active:
		player.modulate.a = 0
	else:
		player.modulate.a = 1.0
		
func handle_animations(delta):
	if not is_on_floor():
		#velocity.y += gravity * delta
		if velocity.y < 0:
			player.animation = "Jump"
		else:
			player.animation = "Fall"
	elif(velocity.x > 1 || velocity.x < -1):
		player.animation = "Sprint"
	else:
		player.animation = "Idle"
	


func handle_sprite_flip() -> void:
	if velocity.x < 0:
		player.flip_h = true
	elif velocity.x > 0:
		player.flip_h = false
	

func movement(direction: float, target_speed: float, delta: float) -> void:
	if GameManager.is_slippery and is_on_floor():
		var target_velocity_x = direction * target_speed
		var speed_ratio: float = target_speed / SPEED if SPEED > 0 else 1.0
		var current_accel: float = ACCELERATION * speed_ratio
		var current_skid: float = SKID_FORCE * speed_ratio
		if direction != 0:
			var is_reversing: bool = (direction > 0 and velocity.x < -10.0) or (direction < 0 and velocity.x > 10.0) 
			if is_reversing and is_skidding:
				is_skidding = true
				skid_delay_timer.start(skid_delay_time)
				#velocity.x = move_toward(velocity.x,target_velocity_x,current_skid*delta)
			if is_skidding:
				velocity.x = move_toward(velocity.x, 0.0, current_skid * delta)
				if abs(velocity.x) <= 5.0:
					is_skidding = false
					skid_delay_timer.stop()
			else:
				if abs(velocity.x) > target_speed and sign(velocity.x) == sign(direction):
					velocity.x = move_toward(velocity.x, target_velocity_x, FRICTION * delta)
				else:
					velocity.x = move_toward(velocity.x, target_velocity_x, current_accel * delta)

		else:
			is_skidding = false
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	else:
		is_skidding = false
		velocity.x = direction * target_speed


func apply_gravity_and_movement(direction: float,target_max_speed: float,delta:float) -> void:
	movement(direction,target_max_speed,delta)
	if GameManager.classic:
		if not is_on_floor():
			velocity.y += gravity * delta
			if jump_left == max_jumps and not has_jumped:
				jump_left = max_jumps - 1
			if not air_control_locked:
				air_control_locked = true
				air_direction = direction if direction != 0 else sign(velocity.x)
			velocity.x = air_direction * target_max_speed
		else:
			if velocity.y >= 0:
				has_jumped = false
				air_control_locked = false
				jump_left = max_jumps
	else:
		if not is_on_floor():
			velocity.y += gravity * delta
			jump_forgiveness_counter -= delta
			if jump_forgiveness_counter <= 0.0 and jump_left == max_jumps:
				jump_left = max_jumps - 1
		else:
			jump_forgiveness_counter = jump_forgiveness_timer.wait_time
			has_jumped = false
			air_control_locked = false
			jump_left = max_jumps
		

func swap_weapon() -> void:
	if not can_swap:
		return
	current_weapon = 2 if current_weapon == 1 else 1
	can_swap = false
	get_tree().create_timer(1.0).timeout.connect(func(): can_swap = true)

	
			

func shoot() -> void:
	if not can_shoot:
		return
	match current_weapon:
		1: 
			shoot_weapon1()
			play_weapon_sfx()
		2: 
			shoot_weapon2()
			play_weapon_sfx()

func play_weapon_sfx():
	if sfx_weapon_variations.size() > 0:
		var random_sound = sfx_weapon_variations.pick_random()
		weapon_sfx.stream = random_sound
		weapon_sfx.play() 

func shoot_weapon1() -> void:
	max_bullet = weapon1_scene.instantiate()
	if current_bullets >= weapon1_limit:
		return
	can_shoot = false
	get_tree().create_timer(weapon1_cooldown).timeout.connect(func(): can_shoot = true)
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
		bullet.global_position = shoot_point.global_position + Vector2(-10,0)
		bullet.direction = -1
	else:
		bullet.global_position = shoot_point.global_position + Vector2(10,0)
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
	if direction == 0:
		direction = 1.0
	
	velocity.x = direction * knockback_force.x
	velocity.y = knockback_force.y
	is_knockback = true
	was_on_floor_hit = is_on_floor()
	hit_position_y = global_position.y
	knockback_timer_shortened = false
	if GameManager.classic:
		knockback_timer.start(classic_knockback_timer)
	else:
		knockback_timer.start(normal_knock_back_timer)

func jump() -> void:
	if jump_left <= 0:
		return
		
	jump_sfx.play()
	var current_jump_mult: float = jump_mult 
	if not GameManager.is_invincible:
		if is_running:
			current_jump_mult -= 0.25  
		else:
			current_jump_mult += 0.05  
	else:
		if is_running:
			current_jump_mult -= randf_range(0.30, 0.45)
		else:
			current_jump_mult += randf_range(0.10, 0.35)
	velocity.y = JUMP_VEL * current_jump_mult
		
	
	if GameManager.classic:
		var jump_direction = Input.get_axis("move_left","move_right")
		if jump_left == max_jumps:
			if jump_direction != 0:
				air_direction = jump_direction
			else:
				air_direction = sign(velocity.x)
		else:
			if jump_direction != 0:
				air_direction = jump_direction
		air_control_locked = true
	jump_left -= 1
	print("Jump left: ",jump_left)
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
	if is_player_invincible:
		return
	if s == null:
		s = player
	super.take_damage(s)
	update_heart_display()
	is_invincible = true
	$Area2D.monitoring = false
	_invincible_frames_blinks(s)
	invincibility_timer.start()
	if health <= 0:
		die()

func update_heart_display():
	for i in range(hearts_list.size()):
		hearts_list[i].visible = i < health
		


func _on_area_2d_area_exited(area: Area2D) -> void:
	pass # Replace with function body.
	
func _check_enemy_overlay() -> void:
	for area in $Area2D.get_overlapping_areas():
		var enemy = area.get_parent()
		if enemy.is_in_group("enemy") and not is_player_invincible:
			take_damage()
			apply_knockback(enemy.global_position)
			
func _on_knockback_timer_timeout() -> void:
	is_knockback = false
	was_on_floor_hit = false

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false
	$Area2D.monitoring = true


func _on_jump_forgive_timer_timeout() -> void:
	pass # Replace with function body.
	
func _on_skid_delay_timeout() -> void:
	is_skidding = false
