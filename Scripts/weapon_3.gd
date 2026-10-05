extends MeleeWeaponBase

@export var knockback_force: float = 300.0
#@export var attack_dash_speed: float = 150.0



func _apply_damage(target: Node2D) -> void:
	super._apply_damage(target)
	if target.has_method("apply_knockback"):
		var knockback_dir = Vector2(direction, -0.2).normalized()
		target.apply_knockback(knockback_dir * knockback_force)
