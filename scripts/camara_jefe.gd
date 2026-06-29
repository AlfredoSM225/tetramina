extends Area2D

@onready var camara_zona: Camera2D = $Camera2D

# Variables exportadas para asignar el fondo y el marco en el Inspector
@export var fondo_gameboy: Node2D
@export var sprite_gameboy: Node2D

var resolucion_original: Vector2i
var modo_pantalla_original: DisplayServer.WindowMode
var camara_jugador_ref: Camera2D = null

func _ready() -> void:
	camara_zona.enabled = false
	camara_zona.global_position = global_position
	
	# Guardamos las configuraciones de fábrica de la pantalla del jugador
	resolucion_original = DisplayServer.window_get_size()
	modo_pantalla_original = DisplayServer.window_get_mode()
	
	# Oculta la interfaz Game Boy por defecto al iniciar el nivel
	set_visibilidad_gameboy(false)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Guarda el modo de pantalla justo antes de cambiarlo
		modo_pantalla_original = DisplayServer.window_get_mode()
		
		camara_jugador_ref = body.get_node_or_null("Camera2D")
		if camara_jugador_ref:
			camara_jugador_ref.enabled = false

		# Si está en pantalla completa, la ventana no se puede encoger, la forzamos a ventana
		if modo_pantalla_original == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

		DisplayServer.window_set_size(Vector2i(256, 640))
		
		var pantalla_centro = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
		DisplayServer.window_set_position(pantalla_centro - Vector2i(128, 320))

		#Activa camara y marco
		camara_zona.enabled = true
		camara_zona.make_current()
		
		set_visibilidad_gameboy(true)
		

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		restaurar_pantalla_normal()

func restaurar_pantalla_normal() -> void:
	# Regresamos el tamaño original a la ventana
	DisplayServer.window_set_size(resolucion_original)
	
	# Centramos la ventana normal en el monitor
	var pantalla_centro = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
	DisplayServer.window_set_position(pantalla_centro - (resolucion_original / 2))
	
	if modo_pantalla_original == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Ocultamos los overlays del Game Boy de nuevo
	set_visibilidad_gameboy(false)
	
	# Devolvemos el control visual al jugador
	if camara_jugador_ref != null:
		camara_jugador_ref.enabled = true
		camara_jugador_ref.make_current()
		
	camara_zona.enabled = false
	print("Pantalla y modos restaurados al estado original.")

# Función auxiliar para controlar de forma segura la visibilidad de los elementos decorativos
func set_visibilidad_gameboy(mostrar: bool) -> void:
	if fondo_gameboy:
		fondo_gameboy.visible = mostrar
	if sprite_gameboy:
		sprite_gameboy.visible = mostrar
