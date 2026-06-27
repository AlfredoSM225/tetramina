extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var activado: bool = false
# Generamos un ID único usando sus coordenadas para que no se confunda con otros checkpoints
@onready var id_unico = "checkpoint_" + str(global_position.x) + "_" + str(global_position.y)
var scene_path : String

func _ready() -> void:
	scene_path = get_tree().current_scene.scene_file_path
	
	body_entered.connect(_on_body_entered)
	
	# === COMPROBACIÓN DE PERSISTENCIA ===
	# Esperamos un frame para asegurarnos de que WorldState esté listo
	await get_tree().process_frame
	
	# Le preguntamos a WorldState si este checkpoint específico ya había sido encendido antes
	var ya_estaba_encendido = WorldState.get_state(scene_path, id_unico, "ya_activado", false)
	
	if ya_estaba_encendido:
		activado = true
		sprite.play("encendida")
	else:
		sprite.play("apagada")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not activado:
		activado = true
		
		sprite.play("encendida")
		
		# Guardamos en el almacén global que ESTE checkpoint ya se prendió para siempre
		WorldState.set_state(scene_path, id_unico, "ya_activado", true)
		
		guardar_aqui_checkpoint(body.global_position)

func guardar_aqui_checkpoint(posicion_jugador: Vector2) -> void:
	# 1. Guardamos las coordenadas del robot en tu script global PlayerState
	PlayerState.save_position(scene_path, posicion_jugador)
	
	# 2. Le ordenamos a todas las monedas y piezas mecánicas del grupo que tomen su "foto"
	get_tree().call_group("Reseteables", "guardar_estado_en_checkpoint")
	
	print("¡Punto de control guardado permanentemente en la memoria del mundo!")
