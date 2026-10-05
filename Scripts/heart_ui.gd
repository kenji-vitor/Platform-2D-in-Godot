extends CanvasLayer

@export var heart_full: Texture2D
@export var heart_empty: Texture2D

@onready var health_container: HBoxContainer = $HealthBoxContainer


func _ready() -> void:
	await get_tree().process_frame
	_connect_to_player()


func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		call_deferred("_connect_to_player")

func _connect_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if not player.health_changed.is_connected(update_health):
			player.health_changed.connect(update_health)
		#print("HeartUI conectada com sucesso ao Player!")
		update_health(player.health, player.max_health)
	

func update_health(current_health: int, max_health: int) -> void:
	#print("UI recebeu -> Vida Atual: ", current_health, " | Vida Maxima: ", max_health)
	if health_container == null:
		return
	for child in health_container.get_children():
		child.queue_free()
	
	for i in range(max_health):
		var heart = TextureRect.new()
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		heart.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = Vector2(16,16)
		if i < current_health:
			heart.texture = heart_full
		else:
			heart.texture = heart_empty
		health_container.add_child(heart)
