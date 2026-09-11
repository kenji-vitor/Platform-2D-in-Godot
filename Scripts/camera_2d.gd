extends Camera2D

@export var normal_zoom: Vector2 = Vector2(1.0,1.0)
@export var fast_zoom: Vector2 = Vector2(0.75,0.75)
@export var zoom_duration: float = 0.4

var zoom_tween: Tween

func set_camera_zoom(target_zoom: Vector2) -> void:
	if zoom_tween and zoom_tween.is_running():
		zoom_tween.kill()
	zoom_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(self, "zoom", target_zoom, zoom_duration)
	
