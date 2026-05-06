extends Node2D

enum SpawnMode {LOOP, LIMITED}

@export var enemy_scene: PackedScene 
@export var spawn_positions: Array[Vector2] = []
@export var spawn_directions: Array[int] = [] # 1 OR -1
@export var spawn_max_enemies: Array[int] = []
@export var spawn_intervals: Array[float] = []
@export var spawn_SPEED: Array[int] = []


@export var deactivation_distance: float = 800.0

var spawn_timers: Array[float] = []
var spawn_current_enemies: Array[int] = []
var total_spawned_per_point: Array[int] = []

@export var spawn_interval: float = 3.0
@export var max_enemies: int = 0

#This var dont do nothing for now
@export var spawn_mode = SpawnMode.LOOP

@export var spawn_limit: int = 0 #Only used in LIMITED
#@export var spawn_direction = 1 

@export var stop_and_exit: bool = true

var triggered = false
var current_enemies = 0
var total_spawned = 0

var cached_player: Node2D = null

var is_spawning = false
@onready var area = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	for i in spawn_positions.size():
		spawn_timers.append(0.0)
		spawn_current_enemies.append(0)
		total_spawned_per_point.append(0)

func _physics_process(delta: float) -> void:
	if triggered and cached_player:
		var player = get_tree().get_first_node_in_group("player")
		'''
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) > despawn_distance:
			queue_free()
			return
		'''
		if player:
			var min_distance = 9999999.0
			
			for spawn_pos in spawn_positions:
				var d = spawn_pos.distance_to(player.global_position)
				if d < min_distance:
					min_distance = d

			if min_distance > deactivation_distance:
				triggered = false
				return
	if not triggered:
		return
		
	for i in spawn_positions.size():
		spawn_timers[i] += delta
		var interval = spawn_intervals[i] if i < spawn_intervals.size() else spawn_interval
		var max_e = spawn_max_enemies[i] if i < spawn_max_enemies.size() else max_enemies
		#print(max_e)
		#print(spawn_max_enemies.size())
		if spawn_timers[i] >= interval and spawn_current_enemies[i] < max_e:
			spawn_timers[i] = 0.0
			_spawn_enemy_at(i)
func _draw() -> void:
	# Apenas desenha no editor para te ajudar a configurar
	if Engine.is_editor_hint() or OS.is_debug_build():
		var color = Color(1,0,0,0.2)
		draw_arc(Vector2.ZERO, deactivation_distance, 0, TAU, 64, color, 2.0) # Círculo vermelho transparente
		
func _spawn_enemy_at(index: int) -> void:
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_positions[index]
	if index < spawn_positions.size():
		enemy.direction = spawn_directions[index]
		enemy.SPEED = spawn_SPEED[index]
	spawn_current_enemies[index] += 1
	match spawn_mode:
		SpawnMode.LOOP:
			#Loop mode decreases index to loop enemies 
			enemy.tree_exited.connect(func(): spawn_current_enemies[index] -= 1)
		SpawnMode.LIMITED:
			#Just pass, 'if' will lock it in spawn_current_enemes[i] < max_e (FALSE):
			pass

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		#print("Detectou o Player!!")
		triggered = true
		cached_player = body
		#if not is_spawning:
			#_start_spawning()
		#if spawn_mode == SpawnMode.LIMITED or spawn_mode == SpawnMode.LOOP:
		#total_spawned = 0

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and stop_and_exit:
		triggered = false

'''
func _start_spawning() -> void:
	is_spawning = true
	while triggered:
		if current_enemies < max_enemies:
			match spawn_mode:
				SpawnMode.LOOP:
					if current_enemies < max_enemies:
						_spawn_enemy()
				SpawnMode.LIMITED:
					if total_spawned >= spawn_limit:
						return
					_spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout
	is_spawning = false
'''
'''
func _spawn_enemy() -> void:
	if spawn_positions.is_empty():
		return
	var index = randi() % spawn_positions.size()
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_positions[index]
	if index < spawn_directions.size():
		enemy.direction = spawn_directions[index]
		
	#if index < max_enemies_spawn.size():
 		#enemy.max_enemies = max_enemies_spawn[index]
	current_enemies += 1
	total_spawned += 1
	enemy.tree_exited.connect(func(): current_enemies -= 1)
	print("Enemy spawned at: ", enemy.global_position)
'''
