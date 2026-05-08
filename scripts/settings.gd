extends Node2D

var globalScale = Vector2(1, 1)
@onready var backTile = $back/backTile

func _ready():
	get_viewport().connect("size_changed", Callable(self, "_on_window_resized"))
	_on_window_resized()
	
func _on_window_resized():
	if get_window().size.y <= 600:
		globalScale = Vector2(1, 1)
		size_changed()
	elif get_window().size.y <= 1080:
		globalScale = Vector2(2, 2)
		size_changed()
	elif get_window().size.y <= 2000:
		globalScale = Vector2(3, 3)
		size_changed()
	else:
		globalScale = Vector2(4, 4)
		size_changed()
func size_changed():
	$back.size = 16*globalScale
	backTile.global_scale = globalScale

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
