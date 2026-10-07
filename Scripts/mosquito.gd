extends "res://Scripts/entity.gd"


@export var despawn_distance = 800.0
@onready var mosquito: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox = $Area2D
var SPEED = 160
var is_dead = false

var start_y : float

@export var amplitude = randi_range(60,180)

@export var frequency = randf_range(1,5)
var direction = 1
var time = 0.0

func _ready() -> void:
	#floor_check.position.x = 20 * direction
	start_y = global_position.y
	direction = [-1,1].pick_random()
	hitbox.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_dead:
		time += delta
		
		var player = get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) > despawn_distance:
			queue_free()
			return
		
		velocity.x = SPEED * direction
		velocity.y = sin(time * frequency) * amplitude
		move_and_slide()
		#is_jumping = true
		#edge_detected = false
		
		if velocity.x < 0:
			mosquito.flip_h = false
		elif velocity.x > 0:
			mosquito.flip_h = true

func _on_death() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	hitbox.monitoring = false
	hitbox.monitorable = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled",true)
		
	if hitbox.has_node("CollisionShape2D"):
		hitbox.get_node("CollisionShape2D").set_deferred("disabled",true)
	if mosquito.sprite_frames.has_animation("Die"):
		mosquito.play("Die")
		await mosquito.animation_finished
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullet"):
		body.queue_free()
		take_damage()
		
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("slash"):
		take_damage()
