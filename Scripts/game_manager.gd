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


#Flower Collectable
var total_flower: int = 0

#Slippery floor
var is_slippery: bool = false 
var slippery_timer: Timer

func make_slippery(duration: float = 4.0) -> void:
	is_slippery = true
	slippery_timer.start(duration)
	print("Chao escorregadio por: ",duration)

func _ready() -> void:
	drunk_timer = Timer.new()
	drunk_timer.one_shot = true
	drunk_timer.timeout.connect(_on_drunk_timer_timeout)
	slippery_timer = Timer.new()
	slippery_timer.one_shot = true
	slippery_timer.timeout.connect(_on_slippery_timer_timeout)
	add_child(drunk_timer)
	add_child(slippery_timer)

func make_drunk(duration: float = 5.0) -> void:
	is_drunk = true
	drunk_direction = 1.0 if randf() > 0.5 else -1.0
	drunk_timer.start(duration)
	
	print("Jogador esta bebado por: ",duration)

func _on_drunk_timer_timeout() -> void:
	is_drunk = false
	print("Modo bebado expirou!")

func _on_slippery_timer_timeout() -> void:
	is_slippery = false
	print("Chao nao esta escorregio agora")
	

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			make_drunk()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			make_slippery()
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
