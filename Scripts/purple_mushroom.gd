extends "res://Scripts/entity.gd" # Herda as propriedades básicas de uma entidade (como vida)

# Configurações de movimento ajustáveis no Editor (Inspetor)
@export var SPEED = 30
@export var JUMP_FORCE = -350.0 #* randf_range(0.8,1.2)
@export var extra_x_speed = 0 # Velocidade adicional quando o bicho pula

# Variáveis de controle de física e componentes
var direction = 1 # 1 para direita, -1 para esquerda
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var purple_mushroom: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox = $Area2D
@onready var delay_after_jump_timer = $DelayAfterJumpTimer

# Sensores (RayCasts) para detectar se há chão à frente ou atrás
@onready var floor_check_right = $RayCast2DDownRight
@onready var floor_check_left = $RayCast2DDownLeft
@onready var wall_check = $WallCheck

# Timers internos para IA (mudança de direção e pulo)
var change_direction_timer = 0.0
var time_to_change = 0.0
var jump_timer = 0.0
var time_to_jump = 0.0
var is_climbing = false
var wall_sensor_cooldown = false
var bump_counter = 0
var last_bump_position = Vector2.ZERO
var is_escaping = false
var escape_jump_multiplier = 1.0
# Estados do personagem
var is_jumping = false
var is_jumping_boost = false
var can_change_direction = true

func _ready() -> void:

	jump_frames_animation()
	hitbox.body_entered.connect(_on_body_entered)
	direction = [-1,1].pick_random()
	_set_random_jump()
	_set_random_timer()
	update_sensors()

func jump_frames_animation():
	var jump_duration = (2 * abs(JUMP_FORCE)) / gravity
	var frame_count = purple_mushroom.sprite_frames.get_frame_count("Jump")
	var ideal_fps = frame_count/jump_duration
	purple_mushroom.sprite_frames.set_animation_speed("Jump", ideal_fps)
	#print("Jump duration: ", jump_time)
	#print("Ideal FPS: ", ideal_fps)
	

func _set_random_timer() -> void:
	
	time_to_change = randf_range(8.0,12.0)
	change_direction_timer = 0.0

func _set_random_jump() -> void:
	time_to_jump = randf_range(1.0,3.0)
	jump_timer = randf_range(-4.0,-2.0)
	

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		is_jumping = true
		velocity.y += gravity * delta
		if is_escaping:
			velocity.x = 250 * direction
		else:
			velocity.x = SPEED * direction
	else:
		is_jumping = false
		if is_escaping:
			velocity.x = 250 * direction
			#velocity.x = SPEED * direction
			#return
		else:
			var hole_right = not floor_check_right.is_colliding()
			var hole_left = not floor_check_left.is_colliding()
			'''
			if hole_left or hole_right:
				if hole_left and hole_right:
					print("Preso em 1 tile")
					_force_escape_jump()
				else:
					#print("Chamando buping edge")
					unstuck_from_buping_edges(hole_left,hole_right)
			else:
				velocity.x = SPEED * direction
			'''
			if hole_right and hole_left:
				_force_escape_jump()
			elif hole_right and direction == 1:
				velocity.x = 0
				_flip_direction(direction * -1)
			elif hole_left and direction == -1:
				velocity.x = 0
				_flip_direction(direction * -1)
			else:
				velocity.x = SPEED * direction
			
	if not is_escaping:
		
		change_direction_timer += delta
		if change_direction_timer >= time_to_change:
			_flip_direction(direction * -1)
			#_set_random_timer()
		jump_timer += delta
		if jump_timer >= time_to_jump and is_on_floor():
			_handle_random_jump_ia()
			
	if is_jumping:
		purple_mushroom.play("Jump")
	else:
		purple_mushroom.play("Move")
	move_and_slide()

		
	

	if is_on_wall() and is_on_floor():
		if wall_check.enabled and wall_check.is_colliding():
			unstuck_from_buping_walls()
		
	if velocity.x < 0:
		purple_mushroom.flip_h = true
	elif velocity.x > 0:
		purple_mushroom.flip_h = false
		
			
	if global_position.y > 1500:
		queue_free()

func _handle_random_jump_ia() -> void:
	var jump_dist = 40
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(jump_dist * direction,0),
		global_position + Vector2(jump_dist * direction,50),
	)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result:
		velocity.y = JUMP_FORCE

		velocity.x = SPEED * direction
		is_jumping = true
		_set_random_jump()
	else:
		_flip_direction(direction * -1)
		_set_random_jump()
func _force_escape_jump() -> void:
	is_escaping = true
	direction = [-1,1].pick_random()
	update_sensors()
	
	velocity.y = JUMP_FORCE * (escape_jump_multiplier + 0.4)
	velocity.x = 250 * direction
	is_jumping = true
	get_tree().create_timer(0.5).timeout.connect(func(): is_escaping = false)
	#set_physics_process(false)
	#get_tree().create_timer(0.1).timeout.connect(func(): set_process(true))

func unstuck_from_buping_edges(hole_left,hole_right) -> void:
	if global_position.distance_to(last_bump_position) < 30:
		bump_counter += 1
	else:
		bump_counter = 1
		last_bump_position = global_position
	if bump_counter > 3:
		velocity.y = JUMP_FORCE - 50
		velocity.x = (SPEED + 50) * direction
		is_jumping = true
		bump_counter = 0
		get_tree().create_timer(0.5).timeout.connect(func(): 
			if is_instance_valid(self):
				set_physics_process(true))
	elif wall_check.is_colliding():
		direction *= -1
		update_sensors()
		velocity.x = SPEED * direction
		wall_check.enabled = false
		get_tree().create_timer(1.0).timeout.connect(func():
			if is_instance_valid(wall_check):
				wall_check.enabled = true)
	else:
		_flip_direction(direction * -1)
		bump_counter = 0
		'''
		if hole_right:
			direction = -1
		elif hole_left:
			direction = 1
		update_sensors()
		velocity.y = JUMP_FORCE 
		velocity.x = 250 * direction
		is_jumping = true
		bump_counter = 0
		
		is_escaping = true
		
		#_apply_physics_freeze(0.15)
		get_tree().create_timer(0.5).timeout.connect(func(): is_escaping = false)
	else:
		print("Bump counter baixo, mudando a direcao")
		_flip_direction(direction * -1)
		'''
func _apply_physics_freeze(time: float) -> void:
	set_physics_process(false)
	get_tree().create_timer(time).timeout.connect(func(): if is_instance_valid(self): set_physics_process(true))
	


func unstuck_from_buping_walls() -> void:
	#print("Chamou buping walls")
			#print("No chao com wall enabled e wall_check colidindo")
	if global_position.distance_to(last_bump_position) > 30:
		bump_counter += 1
		#print("Bateu: ",bump_counter)
	else:
		bump_counter = 1
		last_bump_position = global_position
	if bump_counter >= 2:
		velocity.y = JUMP_FORCE * (escape_jump_multiplier + 0.6)
		velocity.x = (SPEED+200) * direction
		is_jumping = true
		bump_counter = 0
		set_physics_process(false)
		#get_tree().create_timer(0.15).timeout.connect(func(): set_physics_process(true))
		get_tree().create_timer(0.5).timeout.connect(func(): if is_instance_valid(wall_check): wall_check.enabled = true)
		_flip_direction(direction * -1)
		set_physics_process(true)
	elif wall_check.is_colliding():
		velocity.y = JUMP_FORCE * randf_range(0.8, 1.2)
		velocity.x = (250) * direction
		wall_check.enabled = false
		get_tree().create_timer(0.5).timeout.connect(func(): if is_instance_valid(wall_check): wall_check.enabled = true)
	else:
		_flip_direction(direction * -1)
		bump_counter = 0
		
func update_sensors() -> void:
	wall_check.target_position.x = abs(wall_check.target_position.x) * direction
	purple_mushroom.flip_h = (direction == -1)

func _get_safe_jump_direction() -> int:
	var right_safe = floor_check_right.is_colliding()
	var left_safe = floor_check_left.is_colliding()
	
	#if right_safe and left_safe:
		#print("Right and left safe")
		#return[-1,1].pick_random()
		
	if right_safe:
		return 1
	if left_safe:
		return -1
	else:
		return 0


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
	#if not can_change_direction:
		#return
	if new_dir == 1:
		if not floor_check_right.is_colliding():
			new_dir = -1
	elif new_dir == -1:
		if not floor_check_left.is_colliding():
			new_dir = 1
	direction = new_dir
	update_sensors()
	_set_random_timer()
	#can_change_direction = false
	#get_tree().create_timer(2).timeout.connect(func(): can_change_direction = true)
