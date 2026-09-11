extends Node

#UI
@onready var modifier_menu_scene: PackedScene = preload("res://Scenes/ModifierMenu.tscn")
var modifier_menu_instance = null

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





#Lista dos modificadores
#Choose from 3 modifiers and roll a die to determine the duration. (1 Flower to Reroll)
var all_modifiers: Array = [
	"is_s_speed",
	"is_drunk",
	"is_slippery",
	"is_invincible",
	"is_autorunning",
	"is_superjumping",
	"is_gravity_changed"
]

var current_options: Array = []

func _ready() -> void:
	modifier_menu_instance = modifier_menu_scene.instantiate()
	get_tree().root.call_deferred("add_child",modifier_menu_instance)
	
	call_deferred("trigger_modifier_selection")

#RANDOMIZAR MODIFICADORES E ESCOLHE-LOS
func trigger_modifier_selection() -> void:
	var options = roll_modifiers()
	modifier_menu_instance.display_options(options,total_flower)
	get_tree().paused = true
	
func roll_modifiers() -> Array:
	var pool = all_modifiers.duplicate()
	pool.shuffle()
	current_options = pool.slice(0,3)
	#get_tree().paused = true
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
	print("Botao clicado! Index: ",index)
	if current_options.is_empty() or index < 0 or index >= current_options.size():
		print("Falhou na validacao: current_options esta vazio ou indice invalido")
		return
	var selected_modifier: String = current_options[index]
	var die_duration: float = roll_die_duration()
	get_tree().paused = false
	if modifier_menu_instance:
		modifier_menu_instance.hide()
	current_options.clear()
	apply_modifier(selected_modifier,die_duration)
	

#APLICACAO DOS MODIFICADORES
func apply_modifier(mod_name: String, duration: float) -> void:
	set(mod_name,true)
	if mod_name == "is_drunk":
		drunk_direction = 1.0 if randf() > 0.5 else -1.0
	print("Modificador ativo: {0} por {1}s".format([mod_name,duration]))
	await get_tree().create_timer(duration).timeout
	
	set(mod_name,false)
	print("Efeito expirou: ",mod_name)

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
				reroll_modifiers()
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


func add_flower():
	total_flower += 1
	print("Flower(s): ",total_flower)
'''
COPIA DO CODIGO ORIGINAL
extends Node


signal classic_mode_changed(enabled:bool)

var duration: float = 0.00

var classic: bool = false:
	set(value):
		classic = value
		classic_mode_changed.emit(classic)
var code_sequence = ["h","a","r","d"]
var code_progress = 0

#Flower Collectable
var total_flower: int = 0

#Drunk Mechanic
var is_drunk: bool = false
var drunk_timer: Timer
var drunk_direction: float = 1.0 # 1.0 (Direita) ou -1.0 (Esquerda)

#Super speed
var is_s_speed: bool = false
var s_speed_timer: Timer

#Slippery floor
var is_slippery: bool = false 
var slippery_timer: Timer

#Invincible + Invisible
var is_invincible: bool = false
var invincible_timer: Timer

#AutoRun
var is_autorunning: bool = false
var autorun_timer: Timer

#SuperJump
var is_superjumping: bool = false
var superjump_timer: Timer

#Change gravity
var is_gravity_changed: bool = false
var gravity_timer: Timer

@onready var modifier_menu_scene: PackedScene = preload("res://Scenes/ModifierMenu.tscn")
var modifier_menu_instance = null



#Randomly select modifiers
#Choose from 3 modifiers and roll a die to determine the duration. (1 Flower to Reroll)
var all_modifiers: Array = [
	"is_s_speed",
	"is_drunk",
	"is_slippery",
	"is_invincible",
	"is_autorunning",
	"is_superjumping",
	"is_gravity_changed"
]

var current_options: Array = []
func roll_modifiers() -> Array:
	var pool = all_modifiers.duplicate()
	pool.shuffle()
	current_options = pool.slice(0,3)
	#get_tree().paused = true
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
	#get_tree().paused = false
	start_modifier_timer(selected_modifier,die_duration)
	current_options.clear()

func start_modifier_timer(mod_name: String, duration: float) -> void:
	GameManager.set(mod_name,true)
	await get_tree().create_timer(duration).timeout
	GameManager.set(mod_name,false)
	print("O efeito {0} expirou!".format([mod_name]))
	


func make_slippery(duration: float) -> void:
	is_slippery = true
	slippery_timer.start(duration)
	print("Chao escorregadio por: ",duration)
	
func make_s_speed(duration: float) -> void:
	is_s_speed = true
	s_speed_timer.start(duration)
	print("Super speed ativado!")
	
func make_drunk(duration: float) -> void:
	is_drunk = true
	drunk_direction = 1.0 if randf() > 0.5 else -1.0
	drunk_timer.start(duration)
	print("Modo bebado ativado!")

func make_invincible(duration: float) -> void:
	is_invincible = true
	invincible_timer.start(duration)
	print("Esta invencivel por: ",duration)
	
func make_autorun(duration: float) -> void:
	is_autorunning = true
	autorun_timer.start(duration)
	print("Autorunning por: ",duration)

func make_superjump(duration: float) -> void:
	is_superjumping = true
	superjump_timer.start(duration)
	print("Super jump por: ",duration)

func make_gravity(duration: float) -> void:
	is_gravity_changed = true
	gravity_timer.start(duration)
	print("Gravidade trocada por: ",duration)

func _ready() -> void:
	#Drunk
	drunk_timer = Timer.new()
	drunk_timer.one_shot = true
	drunk_timer.timeout.connect(_on_drunk_timer_timeout)
	add_child(drunk_timer)
	
	#Slippery
	slippery_timer = Timer.new()
	slippery_timer.one_shot = true
	slippery_timer.timeout.connect(_on_slippery_timer_timeout)
	add_child(slippery_timer)
	

	
	#Super Speed 
	s_speed_timer = Timer.new()
	s_speed_timer.one_shot = true
	s_speed_timer.timeout.connect(_on_s_speed_timer_timeout)
	add_child(s_speed_timer)
	
	#Invincible
	invincible_timer = Timer.new()
	invincible_timer.one_shot = true
	invincible_timer.timeout.connect(_on_invincible_timer_timeout)
	add_child(invincible_timer)
	
	#AutoRun
	autorun_timer = Timer.new()
	autorun_timer.one_shot = true
	autorun_timer.timeout.connect(_on_autorun_timer_timeout)
	add_child(autorun_timer)
	
	#SuperJump
	superjump_timer = Timer.new()
	superjump_timer.one_shot = true
	superjump_timer.timeout.connect(_on_superjump_timer_timeout)
	add_child(superjump_timer)
	
	#Change Gravity
	gravity_timer = Timer.new()
	gravity_timer.one_shot = true
	gravity_timer.timeout.connect(_on_gravity_timer_timeout)
	add_child(gravity_timer)
	
	modifier_menu_instance = modifier_menu_scene.instantiate()
	get_tree().root.call_deferred("add_child",modifier_menu_instance)


func trigger_modifier_selection() -> void:
	var options = roll_modifiers()
	modifier_menu_instance.display_options(options,total_flower)
	get_tree().paused = true
	


func _on_drunk_timer_timeout() -> void:
	is_drunk = false
	print("Modo bebado expirou!")

func _on_slippery_timer_timeout() -> void:
	is_slippery = false
	print("Chao nao esta escorregio agora")

func _on_s_speed_timer_timeout() -> void:
	is_s_speed = false
	print("Super speed expirou!")

func _on_invincible_timer_timeout() -> void:
	is_invincible = false
	print("Invencibilidade expirou!")

func _on_autorun_timer_timeout() -> void:
	is_autorunning = false
	print("Auto Run expirou!")

func _on_superjump_timer_timeout() -> void:
	is_superjumping = false
	print("Super jump expirou")

func _on_gravity_timer_timeout() -> void:
	is_gravity_changed = false
	print("Super jump expirou")

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
				reroll_modifiers()
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


func add_flower():
	total_flower += 1
	print("Flower(s): ",total_flower)

'''
