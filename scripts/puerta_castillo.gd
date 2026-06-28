extends Area2D

# Te permite elegir a qué nivel viajar desde el Inspector (.tscn)
@export_file("*.tscn") var escena_destino: String = ""

var botones_activos: int = 0
var abierta: bool = false
var jugador_dentro: bool = false

func _ready() -> void:
	$AnimatedSprite2D.play("cerrada")
	# Conectamos las señales para saber si el jugador está parado frente a la puerta
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Si la puerta está abierta, el jugador está ahí y presiona hacia arriba, cambia de nivel
	if abierta and jugador_dentro and Input.is_action_just_pressed("Up"):
		cambiar_de_nivel()

# Estas funciones las llaman los botones automáticamente
func registrar_boton_encendido() -> void:
	botones_activos += 1
	comprobar_puzle()

func registrar_boton_apagado() -> void:
	botones_activos -= 1
	if botones_activos < 0: 
		botones_activos = 0
	comprobar_puzle()

func comprobar_puzle() -> void:
	if botones_activos >= 3:
		abierta = true
		$AnimatedSprite2D.play("abierta") # <-- Cambiado a tu animación cuando se activa
		print("¡Puzle resuelto! Los 3 botones están presionados. Puerta abierta.")
	else:
		abierta = false
		$AnimatedSprite2D.play("cerrada") # <-- Cambiado a tu animación cuando se bloquea
		print("Botones listos: ", botones_activos, "/3. Puerta bloqueada.")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		jugador_dentro = true
		if not abierta:
			print("La puerta está cerrada. Necesitas encender las 3 antorchas.")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		jugador_dentro = false

func cambiar_de_nivel() -> void:
	if escena_destino != "":
		var current_scene_path = get_tree().current_scene.scene_file_path
		# Limpiamos posición guardada para que el jugador aparezca en el inicio del nuevo mapa
		if PlayerState.has_position(current_scene_path):
			# Suponiendo que tu PlayerState tiene un método para borrar o limpiar
			pass 
		get_tree().change_scene_to_file(escena_destino)
