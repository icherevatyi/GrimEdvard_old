extends Node2D

var Player = preload("res://Scenes/Characters/Player/Player.tscn").instance()
onready var player_spawn_point = $PlayerSpawnPoint
onready var enemies = $Enemies.get_children()
onready var Loot_area = $Loot_area


func _ready():
	SceneChanger.game_start()
	_spawn_player()
	_connect_signals()

	
func _spawn_player():
	add_child(Player)
	Player.set_position(player_spawn_point.get_global_position())
	
func _connect_signals():
	for enemy in enemies:
		Player.connect("_on_pass_damage", enemy, "_on_damage_received")
		enemy.connect("_on_souls_released", Player, "_on_souls_received")