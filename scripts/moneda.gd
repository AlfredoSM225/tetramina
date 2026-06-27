extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# --- VARIABLES ÚNICAS PARA EL CHECKPOINT ---
@onready var id_unico = "moneda_" + str(global_position.x) + "_" + str(global_position.y)
var scene_path : String
var ya_recolectada: bool = false

func _ready() -> void:
	# Nos unimos a los grupos lógicos indispensables
	add_to_group("Monedas")
	add_to_group("Reseteables")
	scene_path = get_tree().current_scene.scene_file_path
	
	if anim != null:
		anim.play("default")
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and not ya_recolectada:
		ya_recolectada = true
		GameManager.contar_moneda() # Suma la moneda a tu contador global
		
		# En lugar de usar queue_free(), la desactivamos visual y físicamente
		hide()
		collision.set_deferred("disabled", true)

# --- FUNCIONES NUEVAS DEL SISTEMA DE CHECKPOINTS ---

# Guarda si la moneda existía o no en el instante que tocaste el checkpoint
func guardar_estado_en_checkpoint() -> void:
	WorldState.set_state(scene_path, id_unico, "recolectada_en_checkpoint", ya_recolectada)

# Revive la moneda si no la habías recolectado cuando tocaste el checkpoint
func cargar_estado_de_checkpoint() -> void:
	if not WorldState.scene_states.has(scene_path):
		return
		
	# Averiguamos cómo estaba esta moneda en el checkpoint
	var estaba_recolectada = WorldState.get_state(scene_path, id_unico, "recolectada_en_checkpoint", false)
	
	ya_recolectada = estaba_recolectada
	
	if not ya_recolectada:
		show()
		collision.set_deferred("disabled", false)
		if anim != null:
			anim.play("default")
	else:
		hide()
		collision.set_deferred("disabled", true)
