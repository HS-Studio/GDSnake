extends Node2D

#@onready var btn_start = $CenterContainer/HBoxContainer/VBoxContainer/btn_start
#@onready var btn_mode = $CenterContainer/HBoxContainer/VBoxContainer/btn_mode

var globalScale = Vector2(1, 1)
var easy_mode = false
#var font = $HBoxContainer.get_theme_font("menu").duplicate()

func _ready():
	get_viewport().connect("size_changed", Callable(self, "_on_window_resized"))
	_on_window_resized()
	
	%btn_start.grab_focus()

func _on_window_resized():
	#$HBoxContainer.set_position(Vector2(get_window().size.x * 0.5 - $CenterContainer/HBoxContainer.size.x * 0.5, get_window().size.y * 0.5 - $CenterContainer/HBoxContainer.size.y * 0.5))
	var width = get_viewport().get_visible_rect().size.x
	var height = get_viewport().get_visible_rect().size.y
	
	$CenterContainer.set_size(Vector2(width, height))

	if height <= 600:
		globalScale = Vector2(1, 1)
		size_changed()
	elif height <= 1080:
		globalScale = Vector2(2, 2)
		size_changed()
	elif height <= 2000:
		globalScale = Vector2(3, 3)
		size_changed()
	else:
		globalScale = Vector2(4, 4)
		size_changed()

func _on_btn_start_pressed():
	var game_scene = load("res://scenes/game.tscn").instantiate()
	game_scene.easy_mode = easy_mode
	get_tree().root.add_child(game_scene)
	get_tree().current_scene.queue_free()  # Menu entfernen
	get_tree().current_scene = game_scene
	#get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_btn_highscore_pressed():
	get_tree().change_scene_to_file("res://scenes/highscores.tscn")

func _on_btn_mode_toggled(pressed):
	easy_mode = pressed
	%btn_mode.text = "Easy Mode ON" if easy_mode else "Easy Mode"

func size_changed():
	for i in range($CenterContainer/HBoxContainer/VBoxContainer.get_child_count()):
		$CenterContainer/HBoxContainer/VBoxContainer.get_child(i).add_theme_font_size_override("font_size", 16 * globalScale.x)
