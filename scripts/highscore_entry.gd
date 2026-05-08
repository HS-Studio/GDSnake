extends Node2D

var score: int = 0
var name_chars := ["A", "A", "A"]
var current_index := 0
var score_submitted := false

var globalScale = Vector2(1, 1)

var swipe_start = Vector2.ZERO
var swipe_threshold = 100  # Mindestdistanz für einen Swipe

@onready var labels := [
	$HBoxContainer/Char1,
	$HBoxContainer/Char2,
	$HBoxContainer/Char3
]

func _ready():
	get_viewport().connect("size_changed", Callable(self, "_on_window_resized"))
	_on_window_resized()
	update_display()
	set_process_input(true)
	labels[0].add_theme_color_override("font_color", Color(1.0, 0.80, 0.46, 1))

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

func detect_swipe(start, end):
	var swipe_vector = end - start
	if abs(swipe_vector.x) > swipe_threshold:  # Horizontaler Swipe
		if swipe_vector.x > 0:
			move_cursor(1)
		else:
			move_cursor(-1)
	elif abs(swipe_vector.y) > swipe_threshold:  # Vertikaler Swipe
		if swipe_vector.y > 0:
			change_letter(1)
		else:
			change_letter(-1)
	else:
		submit_score()

func size_changed():
	for i in range(labels.size()):
		labels[i].add_theme_font_size_override("font_size", 16 * globalScale.x)


func set_score(value: int):
	score = value

func _input(event):
	if event.is_action_pressed("ui_right"):
		move_cursor(1)
	elif event.is_action_pressed("ui_left"):
		move_cursor(-1)
	elif event.is_action_pressed("ui_up"):
		change_letter(1)
	elif event.is_action_pressed("ui_down"):
		change_letter(-1)
	elif event.is_action_pressed("ui_accept"):
		submit_score()

	if event is InputEventScreenTouch:
		if event.pressed:  # Finger berührt den Bildschirm
			swipe_start = event.position
		else:  # Finger wird losgelassen
			var swipe_end = event.position
			detect_swipe(swipe_start, swipe_end)

func move_cursor(dir: int):
	labels[current_index].remove_theme_color_override("font_color")
	current_index = (current_index + dir) % 3
	labels[current_index].add_theme_color_override("font_color", Color(1.0, 0.80, 0.46, 1))

func change_letter(dir: int):
	var c = name_chars[current_index].unicode_at(0)
	c += dir
	if c > 90:
		c = 65
	elif c < 65:
		c = 90
	name_chars[current_index] = String.chr(c)
	update_display()

func update_display():
	for i in range(3):
		labels[i].text = name_chars[i]

func submit_score():
	if score_submitted:
		return
	score_submitted = true
	var _name = "".join(name_chars)
	Highscores.add_score(_name, Highscores.pending_score)
	get_tree().change_scene_to_file("res://scenes/highscores.tscn")
