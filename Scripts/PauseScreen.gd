extends CanvasLayer

func _ready():
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_pause_action()

func _on_Resume():
	_pause_action()


func _on_Restart():
	get_tree().change_scene("res://Scenes/Levels/Level_1.tscn")
	_pause_action()


func _pause_action():
	get_tree().paused = not get_tree().paused
	$Control.visible = not $Control.visible
	if $Control.visible == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_QtD():
	get_tree().quit()
