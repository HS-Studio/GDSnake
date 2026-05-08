extends Node

func switchScene(scene_path: String):
	var packed_scene := ResourceLoader.load(scene_path)
	if packed_scene == null:
		push_error("Scene '%s' konnte nicht geladen werden." % scene_path)
		return

	var instance = packed_scene.instantiate()

	get_tree().root.call_deferred("add_child", instance)

	if get_tree().current_scene:
		get_tree().current_scene.queue_free()

	get_tree().current_scene = instance
