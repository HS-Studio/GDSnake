extends Node2D

var tileSize = Vector2i(16, 16)
const GRID_WIDTH = 16
const GRID_HEIGHT = 16
var gridOffset = Vector2i(0, 32)
var globalScale = Vector2i(1, 1)

var swipe_start = Vector2.ZERO
var swipe_threshold = 100  # Mindestdistanz für einen Swipe

var easy_mode = false

enum Direction { UP, RIGHT, DOWN, LEFT }

class Segment:
	var x: int
	var y: int
	var dir: int

@onready var snakeTiles = $snake_tiles1
@onready var gameTiles = $game_tiles
@onready var bgTiles = $bg_tiles

@onready var score_icons = $ScoreIcons
@onready var score_label = $ScoreValue
@onready var hiscore_label = $HighscoreValue

var snake = []
var digesting_segments = []
var current_dir = Direction.RIGHT
var next_dir = current_dir
var should_grow = false
var fruit_pos = Vector2.ZERO
var score = 0
var topscore = 0
var lastscore = 0
var move_timer = 0.35
var time_since_last_move = 0.0

var dayTiles = [Vector2(0, 3), Vector2(1, 3)]
var nightTiles = [Vector2(0, 2), Vector2(1, 2)]

func _ready():
	topscore = Highscores.get_top_score()
	lastscore = Highscores.get_last_score()
	get_viewport().connect("size_changed", Callable(self, "_on_window_resized"))
	_on_window_resized()

	bgTiles.clear()

	# generate Background
	#for x in range(GRID_WIDTH):
	#	for y in range(GRID_HEIGHT):
	#		var atlas_coord = Vector2(0, 3) if (x + y) % 2 == 0 else Vector2(1, 3)
	#		bgTiles.set_cell(Vector2(x, y), 0, atlas_coord)

	if randf() < 0.5:
		for x in range(GRID_WIDTH):
			for y in range(GRID_HEIGHT):
				var atlas_coord = dayTiles[0] if randf() < 0.15 else dayTiles[1]
				bgTiles.set_cell(Vector2(x, y), 0, atlas_coord)
	else:
		for x in range(GRID_WIDTH):
			for y in range(GRID_HEIGHT):
				var atlas_coord = nightTiles[0] if randf() < 0.15 else nightTiles[1]
				bgTiles.set_cell(Vector2(x, y), 0, atlas_coord)

	reset_game()

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

func _process(delta):
	if Input.is_action_just_pressed("ui_up"):
		change_direction(Direction.UP)
	elif Input.is_action_just_pressed("ui_down"):
		change_direction(Direction.DOWN)
	elif Input.is_action_just_pressed("ui_left"):
		change_direction(Direction.LEFT)
	elif Input.is_action_just_pressed("ui_right"):
		change_direction(Direction.RIGHT)

	time_since_last_move += delta
	if time_since_last_move >= move_timer:
		time_since_last_move = 0
		update_game()

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:  # Finger berührt den Bildschirm
			swipe_start = event.position
		else:  # Finger wird losgelassen
			var swipe_end = event.position
			detect_swipe(swipe_start, swipe_end)

func detect_swipe(start, end):
	var swipe_vector = end - start
	if abs(swipe_vector.x) > swipe_threshold:  # Horizontaler Swipe
		if swipe_vector.x > 0:
			change_direction(Direction.RIGHT)
		else:
			change_direction(Direction.LEFT)
	elif abs(swipe_vector.y) > swipe_threshold:  # Vertikaler Swipe
		if swipe_vector.y > 0:
			change_direction(Direction.DOWN)
		else:
			change_direction(Direction.UP)

func size_changed():
	tileSize = gameTiles.tile_set.tile_size
	var total_size = Vector2(GRID_WIDTH * tileSize.x * globalScale.x, GRID_HEIGHT * tileSize.y * globalScale.y)
	gridOffset = Vector2((get_window().size.x - total_size.x) / 2, (get_window().size.y - total_size.y) / 2)

	snakeTiles.global_position = gridOffset
	gameTiles.global_position = gridOffset
	bgTiles.global_position = gridOffset

	snakeTiles.global_scale = globalScale
	gameTiles.global_scale = globalScale
	bgTiles.global_scale = globalScale

	score_icons.global_scale = globalScale
	score_icons.global_position = Vector2(Vector2(gridOffset.x, gridOffset.y -tileSize.y * globalScale.y))
	
	score_label.label_settings.font_size = 16 * globalScale.x
	hiscore_label.label_settings.font_size = score_label.label_settings.font_size

	score_label.global_position = Vector2((score_icons.global_position.x + tileSize.x * globalScale.x), score_icons.global_position.y)
	hiscore_label.global_position = Vector2((score_icons.global_position.x + (tileSize.x * globalScale.x)*5), score_icons.global_position.y)

func reset_game():
	current_dir = Direction.RIGHT
	next_dir = current_dir
	
	gameTiles.clear()
	snakeTiles.clear()

	snake.clear()
	snake.append(Segment.new())
	snake.append(Segment.new())
	snake.append(Segment.new())
	snake[0] = {x=5, y=5, dir=Direction.RIGHT}
	snake[1] = {x=4, y=5, dir=Direction.RIGHT}
	snake[2] = {x=3, y=5, dir=Direction.RIGHT}
	
	digesting_segments.clear()
	current_dir = Direction.RIGHT
	should_grow = false
	score = 0
	move_timer = 0.35
	spawn_fruit()
	render()

func game_over():
	if Highscores.highscores.size() < Highscores.max_entries or score >= lastscore:
		Highscores.pending_score = int(score)
		get_tree().change_scene_to_file("res://scenes/highscore_entry.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func update_game():
	current_dir = next_dir
	var head = snake[0]
	var new_head = Segment.new()
	new_head.x = head.x
	new_head.y = head.y
	new_head.dir = current_dir

	match current_dir:
		Direction.UP: new_head.y -= 1
		Direction.DOWN: new_head.y += 1
		Direction.LEFT: new_head.x -= 1
		Direction.RIGHT: new_head.x += 1

	if easy_mode:
		# Wrap around
		new_head.x = ((new_head.x + GRID_WIDTH) % GRID_WIDTH)
		new_head.y = ((new_head.y + GRID_HEIGHT) % GRID_HEIGHT)
	elif !easy_mode:
		if head.x == 0 and next_dir == Direction.LEFT:
			game_over()
		elif head.x == GRID_WIDTH-1 and next_dir == Direction.RIGHT:
			game_over()
		elif head.y == 0 and next_dir == Direction.UP:
			game_over()
		elif head.y == GRID_HEIGHT-1 and next_dir == Direction.DOWN:
			game_over()

	# Collision mit Snake selbst
	if is_occupied(new_head.x, new_head.y):
		#reset_game()
		game_over()
		return

	snake.insert(0, new_head)

	if new_head.x == fruit_pos.x and new_head.y == fruit_pos.y:
		should_grow = true
		digesting_segments.append(new_head)
		spawn_fruit()
		score += 1
		move_timer = max(0.2, move_timer - 0.001)
		if score > topscore:
			topscore = score

	if digesting_segments.size() > 0 and digesting_segments[0].x == snake[-1].x and digesting_segments[0].y == snake[-1].y:
		digesting_segments.pop_front()
	if not should_grow:
		snake.pop_back()
	else:
		should_grow = false
	render()

func change_direction(new_dir: Direction):
	if new_dir == null:
		return
	elif (new_dir + 2) % 4 != current_dir:
		next_dir = new_dir

func spawn_fruit():
	while true:
		var x = (randi() % GRID_WIDTH)
		var y = (randi() % GRID_HEIGHT)
		if not is_occupied(x, y):
			fruit_pos = Vector2(x, y)
			break

func is_occupied(x: int, y: int) -> bool:
	for s in snake:
		if s.x == x and s.y == y:
			return true
	return false

func render():
	snakeTiles.clear()
	gameTiles.clear()

	for i in snake.size():
		var seg = snake[i]
		var tile = get_tile_for_segment(i)
		snakeTiles.set_cell(Vector2(seg.x, seg.y), 0, tile)

	gameTiles.set_cell(fruit_pos, 0, Vector2(0, 0))

	score_label.text = "%d" % [score]
	hiscore_label.text =  "%d" % [topscore]

func get_tile_for_segment(i: int) -> Vector2:
	
	var from_dir = snake[i].dir
	var to_dir = snake[i - 1].dir
	
	if i == 0:  # Kopf
		for j in range(digesting_segments.size()):  # Verdauungsteile
			if digesting_segments[j].x == snake[i].x and digesting_segments[j].y == snake[i].y:
				return Vector2(snake[i].dir,1)
		return Vector2(snake[i].dir,0)

	if i == snake.size() - 1:  # Schwanz
		return Vector2(snake[i -1].dir, 4)

	# Kurven
	if (from_dir == Direction.UP and to_dir == Direction.RIGHT) or (from_dir == Direction.LEFT and to_dir == Direction.DOWN):
			for j in range(digesting_segments.size()):  # Verdauungsteile
				if digesting_segments[j].x == snake[i].x and digesting_segments[j].y == snake[i].y:
					return Vector2(4,0)
			return Vector2(0,2)

	if (from_dir == Direction.UP and to_dir == Direction.LEFT) or (from_dir == Direction.RIGHT and to_dir == Direction.DOWN):
			for j in range(digesting_segments.size()):  # Verdauungsteile
				if digesting_segments[j].x == snake[i].x and digesting_segments[j].y == snake[i].y:
					return Vector2(4,1)
			return Vector2(1,2)

	if (from_dir == Direction.DOWN and to_dir == Direction.RIGHT) or (from_dir == Direction.LEFT and to_dir == Direction.UP):
			for j in range(digesting_segments.size()):  # Verdauungsteile
				if digesting_segments[j].x == snake[i].x and digesting_segments[j].y == snake[i].y:
					return Vector2(4,2)
			return Vector2(2,2)

	if (from_dir == Direction.DOWN and to_dir == Direction.LEFT) or (from_dir == Direction.RIGHT and to_dir == Direction.UP):
			for j in range(digesting_segments.size()):  # Verdauungsteile
				if digesting_segments[j].x == snake[i].x and digesting_segments[j].y == snake[i].y:
					return Vector2(4,3)
			return Vector2(3,2)

	# Gerade
	if (from_dir == Direction.UP and to_dir == Direction.UP) or (from_dir == Direction.DOWN and to_dir == Direction.DOWN):
		for j in range(digesting_segments.size()):  # Verdauungsteile
			if digesting_segments[j].x == snake[i].x and digesting_segments[j].y == snake[i].y:
				return Vector2(3,3)
		return Vector2(1,3)

	if (from_dir == Direction.LEFT and to_dir == Direction.LEFT) or (from_dir == Direction.RIGHT and to_dir == Direction.RIGHT):
		for j in range(digesting_segments.size()):  # Verdauungsteile
			if digesting_segments[j].x == snake[i].x and digesting_segments[j].y == snake[i].y:
				return Vector2(2,3)
		return Vector2(0,3)

	return Vector2(4,4)  # Fallback
