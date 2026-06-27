extends Area2D

@onready var camara_zona: Camera2D = $Camera2D

var resolucion_original: Vector2i
var camara_jugador_ref: Camera2D = null

func _ready() -> void:
	camara_zona.enabled = false
	camara_zona.global_position = global_position
	
	# Guardamos el tamaño físico real de la ventana al iniciar
	resolucion_original = DisplayServer.window_get_size()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		camara_jugador_ref = body.get_node_or_null("Camera2D")
		if camara_jugador_ref:
			camara_jugador_ref.enabled = false

		# === FORZAR CAMBIO FÍSICO DE VENTANA ===
		# Cambiamos el tamaño de la ventana exterior de la computadora
		DisplayServer.window_set_size(Vector2i(256, 640))
		
		# (Opcional) Centramos la ventana en la pantalla para que no se mueva feo a una esquina
		var pantalla_centro = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
		DisplayServer.window_set_position(pantalla_centro - Vector2i(128, 320))

		camara_zona.enabled = true
		camara_zona.make_current()
		
		print("¡Ventana encogida físicamente a 256x640!")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		restaurar_pantalla_normal()

func restaurar_pantalla_normal() -> void:
	# Regresamos la ventana a su tamaño original de cueva horizontal
	DisplayServer.window_set_size(resolucion_original)
	
	# Centramos de nuevo la ventana grande
	var pantalla_centro = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
	DisplayServer.window_set_position(pantalla_centro - (resolucion_original / 2))
	
	if camara_jugador_ref != null:
		camara_jugador_ref.enabled = true
		camara_jugador_ref.make_current()
		
	camara_zona.enabled = false
	print("Ventana restaurada.")
