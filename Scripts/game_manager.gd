extends Node


signal classic_mode_changed(enabled:bool)

var classic: bool = false:
	set(value):
		classic = value
		classic_mode_changed.emit(classic)
var code_sequence = ["h","a","r","d"]
var code_progress = 0

#Drunk Mechanic
var is_drunk: bool = false
var drunk_timer: Timer
var drunk_direction: float = 1.0 # 1.0 (Direita) ou -1.0 (Esquerda)

#Die Mechanic
var duration_multipliers: Array[float] = [2.0,3.0,4.0,5.0] 
var is_die: bool = false
var die_timer: Timer

#Super speed
var is_s_speed: bool = false
var s_speed_timer: Timer

#Flower Collectable
var total_flower: int = 0

#Slippery floor
var is_slippery: bool = false 
var slippery_timer: Timer

#Invincible + Invisible
var is_invincible: bool = false
var invincible_timer: Timer

#AutoRun
var is_autorunning: bool = false
var autorun_timer: Timer
'''
func roll_double_dice() -> void:
	var effect_dice: int = randi_range(1,6)
	var duration_dice: int = randi_range(1,6)
	
	var final_duration: float = duration_multipliers[duration_dice-1]
'''



func make_die(duration: float = 15.0) -> void:
	is_die = true
	die_timer.start(duration)
	print("Hora de girar os dados!")
	

func make_slippery(duration: float = randf_range(4.0,5.0)) -> void:
	is_slippery = true
	slippery_timer.start(duration)
	print("Chao escorregadio por: ",duration)
	
func make_s_speed(duration: float = 5.0) -> void:
	is_s_speed = true
	s_speed_timer.start(duration)
	print("Super speed ativado!")
	
func make_drunk(duration: float = randf_range(4.0,5.0)) -> void:
	is_drunk = true
	drunk_direction = 1.0 if randf() > 0.5 else -1.0
	drunk_timer.start(duration)
	print("Modo bebado ativado!")

func make_invincible(duration: float = 5.0) -> void:
	is_invincible = true
	invincible_timer.start(duration)
	print("Esta invencivel por: ",duration)
	
func make_autorun(duration: float = 5.0) -> void:
	is_autorunning = true
	autorun_timer.start(duration)
	print("Autorunning por: ",duration)



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
	
	#Die 
	die_timer = Timer.new()
	die_timer.one_shot = true
	die_timer.timeout.connect(_on_die_timer_timeout)
	add_child(die_timer)
	
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
	


func _on_drunk_timer_timeout() -> void:
	is_drunk = false
	print("Modo bebado expirou!")

func _on_slippery_timer_timeout() -> void:
	is_slippery = false
	print("Chao nao esta escorregio agora")
	
func _on_die_timer_timeout() -> void:
	is_die = false
	print("")
	
func _on_s_speed_timer_timeout() -> void:
	is_s_speed = false
	print("Super speed expirou!")

func _on_invincible_timer_timeout() -> void:
	is_invincible = false
	print("Invencibilidade expirou!")

func _on_autorun_timer_timeout() -> void:
	is_autorunning = false
	print("Auto Run expirou!")

func _input(event: InputEvent) -> void:
	#COMANDO TEMPORARIO PARA ATIVAR AS MECANICAS!!!!!!!!
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			make_drunk()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			make_slippery()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_J:
			make_s_speed()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_L:
			make_invincible()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Y:
			make_autorun()
	###################################################
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
