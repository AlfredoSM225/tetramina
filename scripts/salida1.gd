extends Area2D

# Te permite escribir la ruta de la escena directamente desde el Inspector de Godot
@export_file("*.tscn") var escena_destino: String = ""

var jugador_dentro: bool = false

func _ready() -> void:
	# Conectamos las señales para saber cuándo entra y sale el robot
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# Si el jugador está dentro de la zona y presiona la acción hacia arriba
	if jugador_dentro and Input.is_action_just_pressed("Up"):
		cambiar_de_nivel()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		jugador_dentro = true
		print("Jugador listo para entrar. Presiona arriba.")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		jugador_dentro = false

func cambiar_de_nivel() -> void:
	if escena_destino != "":
		# IMPORTANTE: Antes de irnos, borramos la posición vieja del checkpoint
		# para que el robot aparezca en el inicio del Nivel 2 y no se teletransporte feo.
		var current_scene_path = get_tree().current_scene.scene_file_path
		if PlayerState.position.has(current_scene_path):
			PlayerState.position.erase(current_scene_path)
			
		# Cambiamos de escena
		get_tree().change_scene_to_file(escena_destino)
	else:
		push_warning("¡Cuidado! No has asignado ninguna escena de destino en el Inspector.")
