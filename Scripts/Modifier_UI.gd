extends CanvasLayer

@onready var btn_option_1: Button = $Control/BtnOption1
@onready var btn_option_2: Button = $Control/BtnOption2
@onready var btn_option_3: Button = $Control/BtnOption3
@onready var btn_reroll: Button = $Control/BtnReroll
@onready var lbl_inforeroll: Label = $Control/InfoReroll
@onready var lbl_flowers: Label = $Control/LblFlowers

@onready var buttons: Array[Button] = [btn_option_1, btn_option_2, btn_option_3]
var current_focus_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	btn_option_1.pressed.connect(_on_option_selected.bind(0))
	btn_option_2.pressed.connect(_on_option_selected.bind(1))
	btn_option_3.pressed.connect(_on_option_selected.bind(2))
	btn_reroll.pressed.connect(_on_reroll_pressed)

func display_options(options: Array,flowers_count: int) -> void:
	if options.size() >= 3:
		btn_option_1.text = "1. " + options[0].replace("is_","").capitalize()
		btn_option_2.text = "2. " + options[1].replace("is_","").capitalize()
		btn_option_3.text = "3. " + options[2].replace("is_","").capitalize()
	lbl_flowers.text = "Flower(s): {0}".format([flowers_count])
	btn_reroll.text = "Reroll"
	current_focus_index = 0
	_update_button_focus()
	show()

func _on_option_selected(index: int) -> void:
	print("Sinal do botao recebido na UI para o indice: ", index)
	hide()
	GameManager.choose_modifiers(index)

func _on_reroll_pressed() -> void:
	var new_options = GameManager.reroll_modifiers()
	display_options(new_options,GameManager.total_flower)
	
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W:
			current_focus_index = posmod(current_focus_index - 1, buttons.size())
			_update_button_focus()
			get_viewport().set_input_as_handled()
		if event.keycode == KEY_S:
			current_focus_index = posmod(current_focus_index + 1, buttons.size())
			_update_button_focus()
			get_viewport().set_input_as_handled()

		if event.keycode == KEY_G:
			buttons[current_focus_index].emit_signal("pressed")
			get_viewport().set_input_as_handled()
		#Atalhos
		elif event.keycode == KEY_R:
			_on_reroll_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_1:
			_on_option_selected(0)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_2:
			_on_option_selected(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_3:
			_on_option_selected(2)
			get_viewport().set_input_as_handled()
func _update_button_focus() -> void:
	if current_focus_index >= 0 and current_focus_index < buttons.size():
		buttons[current_focus_index].grab_focus()
