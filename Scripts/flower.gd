extends Node2D

@onready var flower: AnimatedSprite2D = $AnimatedSprite2D
var already_collected: bool = false
@onready var thank_you_sfx: AudioStreamPlayer2D = $thank_you_sfx


func _ready() -> void:
	$AnimatedSprite2D.play("default")
	pass

	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if not already_collected:
			GameManager.add_flower()
			already_collected = true
			$AnimatedSprite2D.play("collected")
			thank_you_sfx.play()
			
			await thank_you_sfx.finished
			self.queue_free()
