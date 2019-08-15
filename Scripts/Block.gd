extends Area2D

func _ready():
	pass

func _on_Block_area_entered(area):
	if area.is_in_group("enemy_weapons"):
		$BlockedStrike.visible = true
		$BlockedStrike.set_emitting(true)