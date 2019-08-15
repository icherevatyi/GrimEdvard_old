extends Area2D
var souls_stored
signal _send_souls

func _get_soul_amount(soul_amount):
	souls_stored = soul_amount
	
	

func _on_Soul_body_entered(body):
	if body.name == "Player":
		emit_signal("_send_souls", souls_stored)
		queue_free()