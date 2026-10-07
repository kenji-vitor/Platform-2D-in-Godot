extends "res://Scripts/weapon_base_melee.gd"
@export var big_scale_multiplier_x: float = 4.0
@export var big_scale_multiplier_y: float = 4.0


func _ready() -> void:
	super()
	if GameManager.is_big:
		scale *= Vector2(big_scale_multiplier_x,big_scale_multiplier_y)
