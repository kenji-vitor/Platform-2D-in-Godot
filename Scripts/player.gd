extends "res://Scripts/entity.gd"

@onready var camera: Camera2D = $Camera2D
@onready var current_zoom: Vector2 = camera.zoom
#Heart
signal health_changed(current_health,max_health)
@export var max_health: int = 3
const DEFAULT_MAX_HEALTH: int = 3
var SPEED = 130.0
var JUMP_VEL = -300.0

var speed_mult: float = 1.0
var jump_mult: float = 1.0

@onready var player: AnimatedSprite2D = $AnimatedSprite2D

var offset_x: float = 0.0

var knockback_force = Vector2(100,-250)
var is_knockback = false

@onready var attack_point = $ShootPoint
var current_weapon = 3

const DEFAULT_MAX_JUMPS = 2
@export var max_jumps: int = DEFAULT_MAX_JUMPS
var jump_left : int = DEFAULT_MAX_JUMPS

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

var is_dead = false


#Difficulty
#var code_sequence = ["h","a","r","d"]
#var code_progress = 0
#var classic = false #Oldschool movement
var classic_deceleration = 100
var normal_deceleration = 8



var current_gravity = gravity
@onready var weapon1_scene = preload("res://Scenes/weapon_1.tscn")
@onready var weapon2_scene = preload("res://Scenes/weapon_2.tscn")
@onready var weapon3_scene = preload("res://Scenes/weapon_3.tscn")


@onready var hitbox = $Area2D
var spawn_position: Vector2

#const weapon1_limit = 20
#const weapon1_cooldown = 0.4

#const weapon2_limit = 100
#const weapon2_cooldown = 0.8


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
var weapon_list: Array = []
func _ready() -> void:
	#weapon_list.append(weapon)
	skid_delay_timer = Timer.new()
	skid_delay_timer.one_shot = true
	skid_delay_timer.timeout.connect(_on_skid_delay_timeout)
	add_child(skid_delay_timer)

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
				
				jump()

	if Input.is_action_just_pressed("swap_weapon"):
		swap_weapon()

	if GameManager.is_action_just_pressed("run") and not GameManager.is_tank:
		is_running = not is_running
		# Tiro estático ou em movimento
	#if GameManager.is_action_pressed("shoot") and not is_stealth_active:
		#shoot()

	#if Input.is_action_just_pressed("down"):
	#	await get_tree().create_timer(0.3)
	#	set_collision_mask_value(10,false)
	#else:
	#	set_collision_mask_value(10,true)

func _physics_process(delta: float) -> void:
	if not is_dead:
		var direction = Input.get_axis("move_left","move_right")
		var target_max_speed = (SPEED + 80.0) if is_running else SPEED
		if GameManager.is_action_pressed("shoot") and not is_stealth_active:
			active_weapon()
		var base_speed: float = SPEED
		if GameManager.is_s_speed:
			print("S speed aplicado")
			base_speed = SPEED * 3
			print("Velocidade com s_speed: ",base_speed)
			apply_camera_zoom(Vector2(2.0,2.0))
		elif is_running:
			base_speed = SPEED + 80.0
		if is_knockback:
			var is_grounded_after_hit = is_on_floor() and velocity.x >= 0.0
			if not is_grounded_after_hit:
				velocity.y += current_gravity * delta
			else:
				velocity.x = move_toward(velocity.x,0.0,FRICTION * delta)
				if was_on_floor_hit and not knockback_timer_shortened:
					if knockback_timer.time_left > 1.0:
						knockback_timer.start(1.0)
					knockback_timer_shortened = true
			move_and_slide()
			return

		if GameManager.is_drunk:
			direction = Input.get_axis("move_right","move_left")
			if direction != 0:
				GameManager.drunk_direction = direction
			else:
				GameManager.drunk_direction = 0.0
			direction = GameManager.drunk_direction
		if GameManager.is_invincible and not is_stealth_active:
			activate_stealth_mode()
		if GameManager.is_tank:
			target_max_speed /= 2
		if GameManager.is_small:
			update_player_scale()
			target_max_speed /= 1.5
			
		if GameManager.is_big:
			update_player_scale()
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
			_on_death()

func update_player_scale() -> void:
	if GameManager.is_small:
		scale = Vector2(0.5,0.5)
	elif GameManager.is_big:
		scale = Vector2(1.5,1.5)
	else:
		scale = Vector2(1.0,1.0)

func _on_death() -> void:
	die()

func reset_camera(duration: float = 0.5) -> void:
	if camera:
		camera.enabled = true
		camera.make_current()
		
		# 1. Desativa a suavização para o teleport instantâneo
		camera.reset_smoothing()
		
		# 2. Força o alinhamento imediato com a posição global do Player na Godot 4
		camera.align()
		
		# 3. Reseta offsets de drag
		camera.drag_horizontal_offset = 0.0
		camera.drag_vertical_offset = 0.0
		
		# 4. Animação de zoom
		var tween = create_tween()
		tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), duration)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)

func apply_camera_zoom(target_zoom: Vector2, duration: float = 0.5) -> void:
	if camera:
		var tween = create_tween()
		tween.tween_property(camera,"zoom",target_zoom,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func update_autorun_speed() -> void:
	if autorun_tween and autorun_tween.is_running():
		autorun_tween.kill()
	var target_mult = 1.8
	autorun_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	autorun_tween.tween_property(self,"autorun_speed_modifier",target_mult,AUTORUN_CHANGE_INTERVAL)
	

func activate_stealth_mode(duration: float = randf_range(4.0,6.0))-> void:
		is_stealth_active = true
		set_stealth_state(true)
		can_shoot = false
		stealth_timer = get_tree().create_timer(duration)
		await stealth_timer.timeout
		set_stealth_state(false)
		GameManager.is_invincible = false
		is_stealth_active = false
		can_shoot = true
		
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
	#current_gravity = current_gravity if not GameManager.is_gravity_changed else 
	var active_gravity: float = gravity
	if GameManager.is_gravity_changed:
		active_gravity = gravity * GameManager.gravity_factor
		#print("Nova gravidade: ",active_gravity)
	#else:
		#print("Gravidade sem o modificador: ",active_gravity)
	if GameManager.classic:
		if not is_on_floor():
			velocity.y += active_gravity * delta
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
			velocity.y += active_gravity * delta
			jump_forgiveness_counter -= delta
			if jump_forgiveness_counter <= 0.0 and jump_left == max_jumps:
				jump_left = max_jumps - 1
		else:
			jump_forgiveness_counter = jump_forgiveness_timer.wait_time
			has_jumped = false
			air_control_locked = false
			jump_left = max_jumps
'''
func set_random_gravity() -> void:
	current_gravity = gravity * randf_range(0.40,1.80)
	print("Nova gravidade: ",current_gravity)
'''
func swap_weapon() -> void:
	if not can_swap:
		return
	current_weapon = 1# if current_weapon == 1 else 1
	can_swap = false
	get_tree().create_timer(1.0).timeout.connect(func(): can_swap = true)

func active_weapon() -> void:
	if not can_shoot:
		return
	match current_weapon:
		1: 
			shoot_weapon1()
		2: 
			shoot_weapon2()
		3:
			attack_weapon3()
func play_weapon_sfx():
	if sfx_weapon_variations.size() > 0:
		var random_sound = sfx_weapon_variations.pick_random()
		weapon_sfx.stream = random_sound
		weapon_sfx.play() 

func _execute_weapon_attack(weapon_scene: PackedScene, is_ranged: bool = false, auto_shoot_bullet: bool = true) -> bool:
	if not can_shoot or weapon_scene == null:
		return false
	var weapon_temp = weapon_scene.instantiate()
	var bullet_limit = weapon_temp.bullet_limit if "bullet_limit" in weapon_temp else INF
	var cd = weapon_temp.weapon_cooldown
	weapon_temp.queue_free()
	if GameManager.is_glass_cannon:
		cd = maxf(0.08,cd * 0.60)
		print(cd)
	if is_ranged and current_bullets >= bullet_limit:
		return false
	can_shoot = false
	get_tree().create_timer(cd).timeout.connect(
		func(): can_shoot = true,
		CONNECT_ONE_SHOT
	)
	play_weapon_sfx()
	if is_ranged and auto_shoot_bullet:
		_shoot_bullet(weapon_scene)
	elif not is_ranged:
		_attack_melee(weapon_scene)
	return true
func shoot_weapon1() -> void:
	_execute_weapon_attack(weapon1_scene,true)

func shoot_weapon2() -> void:
	# 1. Validações básicas de disparo
	if not can_shoot or weapon2_scene == null:
		return
		
	# 2. Instancia a cena apenas para ler o limite de munição e cooldown
	var weapon_temp = weapon2_scene.instantiate()
	var bullet_limit = weapon_temp.bullet_limit if "bullet_limit" in weapon_temp else INF
	var cd = weapon_temp.weapon_cooldown
	weapon_temp.queue_free()
	
	# Checa limite de projgaéteis ativos
	if current_bullets >= bullet_limit:
		return
		
	# Trava o tiro imediatamente para evitar disparos em paralelo
	can_shoot = false
	
	# Aplica o modificador Glass Cannon no cooldown base
	if GameManager.is_glass_cannon:
		cd = maxf(0.08, cd * 0.60)
		
	play_weapon_sfx()
	
	# 3. Dispara a rajada de 3 tiros com intervalo
	var burst_interval: float = 0.10
	if GameManager.is_glass_cannon:
		burst_interval *= 0.60
		
	for i in range(3):
		if not is_inside_tree():
			can_shoot = true
			return
			
		_shoot_bullet(weapon2_scene)
		
		if i < 2:
			await get_tree().create_timer(burst_interval).timeout
			
	# 4. Inicia o cooldown da arma APÓS o término completo da rajada
	get_tree().create_timer(cd).timeout.connect(
		func(): can_shoot = true,
		CONNECT_ONE_SHOT
	)
'''
func shoot_weapon2() -> void:
	if current_bullets >= weapon2_limit:
		return
	can_shoot = false
	# 1. Calcula o cooldown base considerando o modificador sem alterar a variável original
	var effective_cooldown: float = weapon2_cooldown
	var burst_interval: float = 0.15
	if GameManager.is_glass_cannon:
		effective_cooldown = maxf(0.05,weapon2_cooldown - 0.3)
		burst_interval = 0.08
		
	
	# 2. Duração total da animação de rajada de 3 tiros (2 intervalos de 0.15s)
	var burst_duration: float = 2 * burst_interval
	
	# 3. O tempo total de reuso é o tempo de rajada + o cooldown calculado
	get_tree().create_timer(effective_cooldown + burst_duration).timeout.connect(
		func(): can_shoot = true,
		CONNECT_ONE_SHOT
	)
	play_weapon_sfx()
	# 4. Disparo da rajada
	for i in range(3):
		if not is_inside_tree():
			return
		_shoot_bullet(weapon2_scene)
		if i < 2:
			await get_tree().create_timer(burst_interval).timeout
'''


func _shoot_bullet(scene: PackedScene) -> void:
	if scene == null:
		return
	var bullet = scene.instantiate()
	get_parent().add_child(bullet)
	if player.flip_h:
		bullet.global_position = attack_point.global_position + Vector2(-10,0)
		bullet.direction = -1
	else:
		bullet.global_position = attack_point.global_position + Vector2(10,0)
		bullet.direction = 1
	bullet.target = self
	bullet.add_collision_exception_with(self)
	for existing_bullet in get_tree().get_nodes_in_group("bullet"):
		if is_instance_valid(existing_bullet):
			bullet.add_collision_exception_with(existing_bullet)
			existing_bullet.add_collision_exception_with(bullet)
	bullet.add_to_group("bullet")
	current_bullets += 1
	bullet.tree_exited.connect(func(): 
		current_bullets = max(0,current_bullets - 1),
		CONNECT_ONE_SHOT
	)
	
func attack_weapon3() -> void:
	_execute_weapon_attack(weapon3_scene,false)

func _attack_melee(scene: PackedScene) -> void:
	if scene == null:
		return
		
	var slash = scene.instantiate()
	get_parent().add_child(slash)
	
	slash.global_position = global_position
	var dir: int = 1
	var base_offset: float = 40.0 if (is_running or abs(velocity.x) > 10.0) else 18.0
	
	if player.flip_h:
		dir = -1
		offset_x = -base_offset
		slash.scale.x = -1.0
		
	else:
		dir = 1
		offset_x = base_offset
		slash.scale.x = 1.0
		
	slash.global_position = attack_point.global_position + Vector2(offset_x, -10.0)
	
	# Passa as variáveis para a arma corpo a corpo de forma segura
	if "direction" in slash:
		slash.direction = dir
		
	if "attacker" in slash:
		slash.attacker = self
	if "target" in slash:
		slash.target = self
		
	# Caso alguma arma melee precise da variável target no futuro:
	#if "target" in slash:
		#slash.target = self


	
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
	if GameManager.is_small:
		max_jumps = 1
	else:
		max_jumps = DEFAULT_MAX_JUMPS
	jump_sfx.play()
	var current_jump_mult: float = jump_mult 
	if GameManager.is_superjumping or GameManager.is_small:
		current_jump_mult = 1.6
	elif GameManager.is_big:
		current_jump_mult = 0.85
	else:
		current_jump_mult = 1.05
		
	velocity.y = JUMP_VEL * current_jump_mult
	#print("Current jump mult: ",current_jump_mult)
	
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
	#print("Jump left: ",jump_left)
	has_jumped = true

func apply_custom_gravity(new_gravity: float) -> void:
	current_gravity = new_gravity

func reset_gravity() -> void:
	current_gravity = gravity

func drop_through_platform():
	set_collision_mask_value(10,false)
	await get_tree().create_timer(0.3).timeout
	set_collision_mask_value(10,true)


func respawn() -> void:
	# 1. Reseta física e zeramento de forças
	velocity = Vector2.ZERO
	is_knockback = false
	knockback_timer_shortened = false
	
	if knockback_timer:
		knockback_timer.stop()
		
	# 2. Reseta estados da Entity
	is_dead = false
	is_damaged = false
	
	# 3. Garante a invulnerabilidade de respawn (evita knockback e dano instantâneo)
	is_invincible = true
	is_player_invincible = true
	
	# 4. Teleporta o Player e atualiza a vida e câmera
	global_position = spawn_position
	health = max_health
	health_changed.emit(health, max_health)
	reset_camera()
	
	if player:
		player.show()
		player.modulate = Color.WHITE
		
	if $Area2D:
		$Area2D.monitoring = true
		
	if invincibility_timer:
		invincibility_timer.stop()
		
	# 5. Remove a invulnerabilidade após 1 segundo (tempo seguro)
	get_tree().create_timer(1.0).timeout.connect(
		func():
			is_invincible = false
			is_player_invincible = false,
		CONNECT_ONE_SHOT
	)
		


func die() -> void:
	# 1. Reseta modificadores do jogo e seleções no GameManager
	GameManager.reset_modifiers()
	#GameManager.trigger_modifier_selection()
	
	# 2. Reseta estados físicos e controles do Player
	max_health = DEFAULT_MAX_HEALTH
	jump_left = max_jumps
	has_jumped = false
	fell_off_platform = false
	air_control_locked = false
	can_shoot = true
	current_bullets = 0
	is_dead = true
	# 3. Reseta visuais/animações
	if player:
		player.flip_h = false
		player.play("Idle")
		
	# 4. Teleporta o jogador para o spawn e ajusta a câmera/vida
	respawn()
	
func take_damage(amount: int = 1) -> void:
	if is_player_invincible:
		return
	super.take_damage(amount)
	health_changed.emit(health,max_health)
	if health <= 0 :
		_on_death()
		return
	is_invincible = true
	$Area2D.monitoring = false
	_invincible_frames_blinks(player)
	invincibility_timer.start()

func add_max_health(amount: int, fill_heart: bool) -> void:
	max_health += amount
	if fill_heart:
		health += amount
	health = min(health,max_health)
	health_changed.emit(health,max_health)

func remove_max_health(amount: int, reduce_current_health: bool = true) -> void:
	max_health = max(1, max_health - amount)
	if reduce_current_health:
		health = max(1, health - amount)
	else:
		health = min(health, max_health)
	health_changed.emit(health, max_health)

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
