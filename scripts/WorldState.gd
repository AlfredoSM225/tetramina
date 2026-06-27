extends Node

# Diccionario bidimensional para almacenar el estado de cada objeto en cada nivel
var scene_states := {}

func set_state(scene_path: String, object_id: String, key: String, value) -> void:
	if not scene_states.has(scene_path):
		scene_states[scene_path] = {}
	
	if not scene_states[scene_path].has(object_id):
		scene_states[scene_path][object_id] = {}
	
	scene_states[scene_path][object_id][key] = value

func get_state(scene_path: String, object_id: String, key: String, default_value = null):
	if scene_states.has(scene_path):
		if scene_states[scene_path].has(object_id):
			if scene_states[scene_path][object_id].has(key):
				return scene_states[scene_path][object_id][key]
	return default_value
