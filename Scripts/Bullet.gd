extends Area2D

export(int) var speed = 350
var direction = 1

func _ready():
	set_process(true)
	add_to_group("enemy_weapons")

func _process(delta):
	var motion = Vector2(1, 0) * speed * direction
	set_position(get_position() + motion * delta)
	if direction == 1:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false

func _on_Bullet_timeout():
	$Sprite.visible = false
	queue_free()

func _on_Bullet_body_entered(body):
	if body.name == "Player":
		$Sprite.visible = false
		queue_free()

func _on_Bullet_area_entered(area):
	if area.name == "Block":
		$Sprite.visible = false
		queue_free()