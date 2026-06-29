extends Node2D

@export var piezas_disponibles: Array[PackedScene] = []
@export var tiempo_entre_piezas: float = 8.0
@export var grid_size: int = 32

# === CONFIGURACIÓN DE LÍMITE Y ACTIVACIÓN ===
@export var max_piezas_a_generar: int = 5
var piezas_generadas_actualmente: int = 0

var ya_se_activo: bool = false

@onready var timer: Timer = $Timer
@onready var notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	if timer:
		timer.wait_time = tiempo_entre_piezas
	
	if notifier:
		notifier.screen_entered.connect(_on_entró_en_pantalla)
	else:
		push_error("¡ERROR: No se encontró el nodo VisibleOnScreenNotifier2D en el Generador!")

func _on_entró_en_pantalla() -> void:
	if not ya_se_activo and piezas_generadas_actualmente < max_piezas_a_generar:
		ya_se_activo = true
		print("¡Generador activado por la cámara! Iniciando secuencia...")
		timer.start()
		generar_pieza_aleatoria()

func _on_timer_timeout() -> void:
	generar_pieza_aleatoria()

func generar_pieza_aleatoria() -> void:
	if piezas_generadas_actualmente >= max_piezas_a_generar:
		print("Generador vaciado. Deteniendo producción.")
		timer.stop()
		return
		
	if piezas_disponibles.is_empty():
		return
		
	var indice_aleatorio = randi() % piezas_disponibles.size()
	var escena_pieza = piezas_disponibles[indice_aleatorio]
	
	if escena_pieza:
		var nueva_pieza = escena_pieza.instantiate()
		
		# === CALCULAR POSICIÓN ALEATORIA EN LA ZONA ===
		var x_final = global_position.x
		
		if notifier:
			# Obtenemos el rectángulo visual del Notifier
			var rect = notifier.rect
			# Calculamos los límites globales izquierdo y derecho basados en su tamaño
			var limite_izquierdo = global_position.x + rect.position.x
			var limite_derecho = global_position.x + rect.position.x + rect.size.x
			
			# Elegimos un punto X al azar dentro de esos límites
			var x_aleatoria = randf_range(limite_izquierdo, limite_derecho)
			
			# TRUCO CRÍTICO: Redondeamos el número a la cuadrícula (múltiplos de 32)
			# para que encajen perfecto y no clipeen en las paredes al caer.
			x_final = round(x_aleatoria / grid_size) * grid_size
		
		# Asignamos la nueva posición (mantiene la altura Y del generador)
		nueva_pieza.global_position = Vector2(x_final, global_position.y)
		
		# Forzamos la caída libre si tu script de PiezaBase lo requiere
		if "en_caida_libre" in nueva_pieza:
			nueva_pieza.en_caida_libre = true
			
		get_tree().current_scene.add_child(nueva_pieza)
		
		piezas_generadas_actualmente += 1
		print("Pieza lanzada aleatoriamente en X(", x_final, "): ", piezas_generadas_actualmente, "/", max_piezas_a_generar)
