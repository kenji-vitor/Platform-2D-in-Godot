extends Node2D

enum SpawnMode {LOOP, LIMITED}

@export var enemy_scene: PackedScene 
@export var spawn_positions: Array[Vector2] = []
@export var spawn_directions: Array[int] = [] # 1 OR -1
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 4
@export var spawn_mode = SpawnMode.LOOP
@export var spawn_limit: int = 4 #Only used in LIMITED
#@export var spawn_direction = 1 

var triggered = false
var current_enemies = 0
var total_spawned = 0

var is_spawning = false
@onready var area = $Area2D

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Detectou o Player!!")
		triggered = true
		if not is_spawning:
			_start_spawning()
		if spawn_mode == SpawnMode.LIMITED or spawn_mode == SpawnMode.LOOP:
			total_spawned = 0

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		triggered = false

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

func _spawn_enemy() -> void:
	if spawn_positions.is_empty():
		return
	var index = randi() % spawn_positions.size()
	var enemy = enemy_scene.instantiate()
	get_parent().add_child(enemy)
	enemy.global_position = spawn_positions[index]
	if index < spawn_directions.size():
		enemy.direction = spawn_directions[index]
	current_enemies += 1
	total_spawned += 1
	enemy.tree_exited.connect(func(): current_enemies -= 1)
	print("Enemy spawned at: ", enemy.global_position)
