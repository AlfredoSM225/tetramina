extends Node2D

@export var piezas_disponibles: Array[PackedScene] = []
@export var tiempo_entre_piezas: float = 8.0

# === CONFIGURACIÓN DE LÍMITE Y ACTIVACIÓN ===
@export var max_piezas_a_generar: int = 5
var piezas_generadas_actualmente: int = 0

var ya_se_activo: bool = false

@onready var timer: Timer = $Timer

func _ready() -> void:
	# Ajustamos el tiempo del timer si existe
	if timer:
		timer.wait_time = tiempo_entre_piezas
	
	# Buscamos el notificador de forma segura
	var notifier = get_node_or_null("VisibleOnScreenNotifier2D")
	
	if notifier:
		# Si lo encuentra, lo conecta perfectamente
		notifier.screen_entered.connect(_on_entró_en_pantalla)
	else:
		# Si se nos olvidó ponerlo o se llama diferente, te avisará en la consola sin romper el juego
		push_error("¡ERROR: No se encontró el nodo VisibleOnScreenNotifier2D en el Generador!")

func _on_entró_en_pantalla() -> void:
	# Solo se activa la primera vez que la cámara lo enfoca
	if not ya_se_activo and piezas_generadas_actualmente < max_piezas_a_generar:
		ya_se_activo = true
		print("¡Generador activado por la cámara! Iniciando secuencia...")
		timer.start()
		generar_pieza_aleatoria() # Suelta la primera pieza inmediatamente

func _on_timer_timeout() -> void:
	generar_pieza_aleatoria()

func generar_pieza_aleatoria() -> void:
	# Si ya alcanzamos el límite de piezas, se apaga definitivamente
	if piezas_generadas_actualmente >= max_piezas_a_generar:
		print("Generador vaciado. Deteniendo producción.")
		timer.stop()
		return
		
	if piezas_disponibles.is_empty():
		return
		
	# Seleccionamos e instanciamos la pieza aleatoria
	var indice_aleatorio = randi() % piezas_disponibles.size()
	var escena_pieza = piezas_disponibles[indice_aleatorio]
	
	if escena_pieza:
		var nueva_pieza = escena_pieza.instantiate()
		# Nace exactamente en la posición de este generador en el mapa
		nueva_pieza.global_position = global_position
		
		# La añadimos a la escena actual
		get_tree().current_scene.add_child(nueva_pieza)
		
		# Contamos la pieza y aumentamos el registro
		piezas_generadas_actualmente += 1
		print("Pieza lanzada: ", piezas_generadas_actualmente, "/", max_piezas_a_generar)
