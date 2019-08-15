extends Node2D

var Plague_doc = preload("res://Scenes/Characters/Enemies/Plague_doc.tscn");
onready var spawn_points = get_children()


func _ready():
	for point in spawn_points:
		var plague_d_instance = Plague_doc.instance()
		get_parent().find_node("Enemies").add_child(plague_d_instance)
		plague_d_instance.set_position(point.get_global_position())