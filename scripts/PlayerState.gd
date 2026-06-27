extends Node

# Diccionario que guardará las posiciones: { "ruta_de_la_escena": Vector2(x, y) }
var position := {}

# Guarda la posición del jugador asociada a la escena actual
func save_position(scene_path: String, pos: Vector2) -> void:
	position[scene_path] = pos

# Verifica si este nivel ya tiene un checkpoint registrado
func has_position(scene_path: String) -> bool:
	return position.has(scene_path)

# Devuelve las coordenadas del checkpoint para la escena solicitada
func get_position(scene_path: String) -> Vector2:
	return position[scene_path]
