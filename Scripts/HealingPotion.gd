extends RigidBody2D

var stats = {
	"type": "heal_item",
	"strength": 30,
}
var dir
#signal picked_up

func _ready():
	add_to_group("loot")
	add_to_group("healing_potion")
	$AnimationPlayer.play("idle")
	randomize_dir()
	apply_central_impulse(Vector2(dir, -80))



func randomize_dir():
	randomize()
	var d = randi()%2 +1
	match d:
		1:
			dir = 50
		2:
			dir = -50

func _on_IdentifyRange_entered(body):
#	if body.name == "Player":
#		emit_signal("picked_up", stats)
	pass

func _spawn_sound():
	var audiofile = "res://Resources/audio/item_sounds/bottle_spawn.wav"
	get_parent().get_parent().get_node("ItemSFX").stream = load(audiofile)
	get_parent().get_parent().get_node("ItemSFX").play()
	
func item_picked_up():
	queue_free()

func _on_HealingPotion_sleeping_state_changed():
	print("state changed")
	_spawn_sound()
