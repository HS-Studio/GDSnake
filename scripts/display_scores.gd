extends Node2D

var globalScale = Vector2(1, 1)
@onready var backTile = $back/backTile

func _ready():
	get_viewport().connect("size_changed", Callable(self, "_on_window_resized"))
	_on_window_resized()

	Highscores.load_highscores()
	display_scores()

func display_scores():
	for i in range(Highscores.highscores.size()):
		var entry = Highscores.highscores[i]
		
		var name_label = $HBoxContainer/VBoxContainer.get_child(i)
		var score_label = $HBoxContainer/VBoxContainer2.get_child(i)
		
		name_label.text = entry["name"] + " "
		score_label.text = " " + str(int(entry["score"]))
		
		name_label.remove_theme_color_override("font_color")
		score_label.remove_theme_color_override("font_color")
		
		if entry["last"]:
			name_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.46, 1))
			score_label.add_theme_color_override("font_color", Color(1.0, 0.80, 0.46, 1))

func _on_window_resized():
	$HBoxContainer.size = get_window().size
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

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func size_changed():
	$back.size = 16*globalScale
	backTile.global_scale = globalScale
	for i in range(Highscores.highscores.size()):
		$HBoxContainer/VBoxContainer.get_child(i).add_theme_font_size_override("font_size", 16 * globalScale.x)
		$HBoxContainer/VBoxContainer2.get_child(i).add_theme_font_size_override("font_size", 16 * globalScale.x)
