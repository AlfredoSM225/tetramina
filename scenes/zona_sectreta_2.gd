extends Area2D

# Rutas de los nodos basadas en tu jerarquía
@onready var capa_secreta1: TileMapLayer = $"../Tile frente/Castillo Frente"
@onready var capa_secreta2: TileMapLayer = $"../Tile frente/Castillo Frente3"

# Variable para controlar el Tween activo y evitar que se encimen las animaciones
var active_tween: Tween = null

func _ready() -> void:
	# Conectamos las dos señales necesarias: entrada y salida
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Si entra el jugador, desvanecemos el muro (opacidad a 0.0)
	if body.is_in_group("Player"):
		transicionar_muro(0.0)

func _on_body_exited(body: Node2D) -> void:
	# Si sale el jugador, volvemos a mostrar el muro (opacidad a 1.0)
	if body.is_in_group("Player"):
		transicionar_muro(1.0)

func transicionar_muro(target_alpha: float) -> void:
	# Si había una animación corriendo, la detenemos para que no parpadee
	if active_tween and active_tween.is_running():
		active_tween.kill()
	
	active_tween = create_tween()
	active_tween.set_parallel(true) # Ambas capas cambian al mismo tiempo
	
	# === MÁS RÁPIDO: Cambiamos el tiempo de 1.5 a 0.4 segundos ===
	active_tween.tween_property(capa_secreta1, "modulate:a", target_alpha, 0.4)
	active_tween.tween_property(capa_secreta2, "modulate:a", target_alpha, 0.4)
