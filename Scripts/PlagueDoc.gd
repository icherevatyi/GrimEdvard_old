extends "res://Scripts/Enemy_parent.gd"

onready var bulletSpawn = $BulletContianer/BulletSpawn
onready var bullet = preload("res://Scenes/Helpers/Bullet.tscn")
var soul_amount = 35
signal _on_souls_released


func _ready():
	bulletSpawn.position.x = -13.875
	state_machine = $AnimationTree.get("parameters/playback")
	state_machine.start("idle")


func _physics_process(delta):
	match movedir:
		-1:
			$BulletContianer/BulletSpawn.position.x = -13.875
		1:
			$BulletContianer/BulletSpawn.position.x = 13.875


func _shoot():
	var bullet_instance = bullet.instance()
	add_child(bullet_instance)
	bullet_instance.set_global_position(bulletSpawn.get_global_position())
	bullet_instance.direction = movedir


func _ouch():
	var audiofile
	randomize()
	var random = randi()%4
	match random:
		0:
			audiofile = "res://Resources/audio/getting_hit/enemy_getting_hit_1.wav"
		1:
			audiofile = "res://Resources/audio/getting_hit/enemy_getting_hit_2.wav"
		2:
			audiofile = "res://Resources/audio/getting_hit/enemy_getting_hit_3.wav"
		3:
			audiofile = "res://Resources/audio/getting_hit/enemy_getting_hit_4.wav"
		4:
			audiofile = "res://Resources/audio/getting_hit/enemy_getting_hit_5.wav"
			
	var SFX_player = $Audio/SFX
	SFX_player.stream = load(audiofile)
	SFX_player.play()


func _generate_loot():
	emit_signal("_on_souls_released", soul_amount)