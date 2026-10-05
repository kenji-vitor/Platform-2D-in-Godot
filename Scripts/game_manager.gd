extends Node

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
#UI
@onready var modifier_menu_scene: PackedScene = preload("res://Scenes/ModifierMenu.tscn")
var modifier_menu_instance = null

var active_modifier_session: int = 0

#Hearts UI
@onready var heart_ui_scene: PackedScene = preload("res://Scenes/Heart_UI.tscn")
var heart_ui_instance = null

#Estado do jogo 
var total_flower: int = 100
signal classic_mode_changed(enabled:bool)
var classic: bool = false:
	set(value):
		classic = value
		classic_mode_changed.emit(classic)

#Codigo para mudanca do estilo do jogo
var code_sequence = ["h","a","r","d"]
var code_progress = 0


#MODIFICADORES
var is_drunk: bool = false
var drunk_direction: float = 0.0

var is_s_speed: bool = false
var is_slippery: bool = false 
var is_invincible: bool = false #Invincible + Invisible
var is_autorunning: bool = false
var is_superjumping: bool = false

var is_gravity_changed: bool = false
var gravity_factor: float = 1.0


var is_glass_cannon: bool = false
var is_tank: bool = false
var is_small: bool = false
var is_big: bool = false
#Lista dos modificadores
#Choose from 3 modifiers and roll a die to determine the duration. (1 Flower to Reroll)
var all_modifiers: Array = [
	"is_s_speed",
	"is_drunk",
	"is_slippery",
	"is_invincible",
	"is_autorunning",
	"is_superjumping",
	"is_gravity_changed",
	"extra_heart",
	"is_glass_cannon",
	"is_tank",
	"is_small",
	"is_big"
]
func is_modifier_active(mod_name: String) -> bool:
	match mod_name:
		"is_glass_cannon": return is_glass_cannon
		"is_tank": return is_tank
		"is_small": return is_small
		"is_drunk": return is_drunk
		"is_s_speed": return is_s_speed
		"is_slippery": return is_slippery
		"is_invincible": return is_invincible
		"is_autorunning": return is_autorunning
		"is_superjumping": return is_superjumping
		"is_gravity_changed": return is_gravity_changed
		"extra_heart": return false
		"is_big": return is_big
		_: return false


var current_options: Array = []

func _ready() -> void:
	modifier_menu_instance = modifier_menu_scene.instantiate()
	get_tree().root.call_deferred("add_child",modifier_menu_instance)
	heart_ui_instance = heart_ui_scene.instantiate()
	get_tree().root.call_deferred("add_child",heart_ui_instance)

#RANDOMIZAR MODIFICADORES E ESCOLHE-LOS
func trigger_modifier_selection() -> void:
	var options = roll_modifiers()
	modifier_menu_instance.display_options(options,total_flower)
	get_tree().paused = true
	
func roll_modifiers() -> Array:
	var available_pool: Array = []
	for mod in all_modifiers:
		if not is_modifier_active(mod):
			available_pool.append(mod)
	if available_pool.size() < 3:
		available_pool = all_modifiers.duplicate()
	available_pool.shuffle()
	#get_tree().paused = true
	current_options = available_pool.slice(0,3)
	print("Jogo pausado. Escolha um modificador: ",current_options)
	return current_options

func reroll_modifiers() -> Array:
	if total_flower >= 1:
		total_flower -= 1
		print("Flor gasta! Flor(es) restantes: ",total_flower)
		#duration = roll_die_duration()
		return roll_modifiers()
	else:
		print("Flores insuficientes")
		return current_options

func roll_die_duration() -> int:
	var duration = randf_range(8,20)
	print("Resultado da duracao: ",duration)
	return duration
	

func choose_modifiers(index: int) -> void:
	if current_options.is_empty() or index < 0 or index >= current_options.size():
		return
	var selected_modifier: String = current_options[index]
	var die_duration: float = roll_die_duration()
	if modifier_menu_instance:
		modifier_menu_instance.hide()
	get_tree().paused = false
	#var player_node = get_tree().get_first_node_in_group("player")
	#if player_node and player_node.has_method("respawn"):
	#d	player_node.respawn()
	current_options.clear()
	apply_modifier(selected_modifier,die_duration)

#APLICACAO DOS MODIFICADORES
func apply_modifier(mod_name: String, duration: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	match mod_name:
		"extra_heart":
			apply_extra_heart_modifier()
			return
		"is_glass_cannon":
			apply_glass_cannon_modifier()
			return
		"is_gravity_changed":
			apply_gravity_modifier()
		#set(mod_name,true)
		"is_drunk":
			is_drunk = true
			#drunk_direction = 1.0 if randf() > 0.5 else -1.0
		"is_tank":
			apply_extra_heart_modifier_tank()
			duration = randf_range(120,300)
		"is_small":
			if is_big:
				is_big = false
			is_small = true
			apply_player_scale()
			return
		"is_big":
			if is_small:
				is_small = false # Desativa a flag do Small
			is_big = true
			apply_player_scale()
			return
		"is_s_speed":
			is_s_speed = true
		"is_slippery":
			is_slippery = true
		"is_autorunning":
			is_autorunning = true
	print("Modificador ativo: {0} por {1}s".format([mod_name,duration]))
	var current_session = active_modifier_session
	await get_tree().create_timer(duration).timeout
	
	if current_session == active_modifier_session:
		set(mod_name,false)
		var current_player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(current_player) and current_player.has_method("reset_camera"):
			current_player.reset_camera()

func apply_player_scale() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("update_player_scale"):
		player.update_player_scale()

func reset_modifiers() -> void:
	var player = get_tree().get_first_node_in_group("player")
	active_modifier_session += 1
	is_drunk = false
	drunk_direction = 0.0
	is_s_speed = false
	is_slippery = false
	is_invincible = false
	is_autorunning = false
	is_superjumping = false
	is_gravity_changed = false
	is_glass_cannon = false
	is_tank = false
	is_small = false
	gravity_factor = 1.0
	apply_player_scale()
	print("Todos os modificadores foram desligados!")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				choose_modifiers(0)
			KEY_2, KEY_KP_2:
				choose_modifiers(1)
			KEY_3, KEY_KP_3:
				choose_modifiers(2)
			KEY_R:
				call_deferred("trigger_modifier_selection")
	if event is InputEventKey and event.pressed:
		if event.echo:
			return
		var key = OS.get_keycode_string(event.keycode).to_lower()
		if key == code_sequence[code_progress]:
			code_progress += 1
			if code_progress == code_sequence.size():
				classic = not classic
				code_progress = 0
			#if classic:
				#is_running = false #Remove sing from classic mode
				print("Modo Classic alterado para: ", classic)
		else:
			if key == code_sequence[0]:
				code_progress = 1
			else:
				code_progress = 0
				
func is_action_just_pressed(action: String) -> bool:
	if is_drunk:
		if action == "jump":
			return Input.is_action_just_pressed("shoot")
		elif action == "shoot":
			return Input.is_action_just_pressed("jump")
	return Input.is_action_just_pressed(action)
	
func is_action_pressed(action: String) -> bool:
	if is_drunk:
		if action == "jump":
			return Input.is_action_pressed("shoot")
		elif action == "shoot":
			return Input.is_action_pressed("jump")
	return Input.is_action_pressed(action)

func apply_extra_heart_modifier() -> void:
	if is_glass_cannon:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Aumenta a vida máxima em 1 e emite o sinal
		player.add_max_health(1, true)
func apply_extra_heart_modifier_tank() -> void:
	if is_glass_cannon:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Aumenta a vida máxima em 7 e emite o sinal
		player.add_max_health(7, true)

func apply_glass_cannon_modifier() -> void:
	is_glass_cannon = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Diminui a vida máxima para 1 e emite o sinal
		player.remove_max_health(100, true)

func apply_gravity_modifier() -> void:
	is_gravity_changed = true
	gravity_factor = randf_range(0.8,1.2)
	

func add_flower():
	total_flower += 1
	print("Flower(s): ",total_flower)
