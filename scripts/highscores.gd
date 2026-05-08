extends Node2D

var highscores: Array = []
var max_entries := 10
var pending_score = 0

func _ready():
	load_highscores()

func load_highscores():
	if FileAccess.file_exists("user://highscores.json"):
		var file = FileAccess.open("user://highscores.json", FileAccess.READ)
		highscores = JSON.parse_string(file.get_as_text())
	else:
		highscores = []

func save_highscores():
	var file = FileAccess.open("user://highscores.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(highscores))

func add_score(_name: String, _score: int):
	for i in range(Highscores.highscores.size()):
		var entry = Highscores.highscores[i]
		entry["last"] = false
	
	highscores.append({ "name": _name, "score": int(_score) , "last": true})
	highscores.sort_custom(func(a, b): return a["score"] > b["score"])
	if highscores.size() > max_entries:
		highscores.resize(max_entries)
	save_highscores()

func get_top_score() -> int:
	if !highscores.is_empty():
		return highscores[0]["score"]
	return 0

func get_last_score() -> int:
	if !highscores.is_empty():
		return highscores[Highscores.highscores.size()-1]["score"]
	return 0
