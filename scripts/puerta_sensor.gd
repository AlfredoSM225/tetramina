extends StaticBody2D
class_name PuertaSensor

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var distancia_apertura: float = -48.0
@export var tiempo_animacion: float = 0.4

@export var tiempo_espera: float = 3.0 

var posicion_inicial: Vector2
var posicion_abierta: Vector2
var tween: Tween
var esta_abriendose: bool = false

func _ready() -> void:
	posicion_inicial = position
	posicion_abierta = posicion_inicial + Vector2(0, distancia_apertura)

# Esta función la llama el Area2D cuando el jugador la pise
func activar_secuencia_puerta() -> void:
	# Si ya está abierta o abriéndose, ignoramos para que no reinicie el tiempo a mitad de camino
	if esta_abriendose:
		return
		
	esta_abriendose = true
	
	if tween:
		tween.kill()
	
	tween = create_tween().set_parallel(false).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Subir Puerta
	tween.tween_property(self, "position", posicion_abierta, tiempo_animacion)
	
	# Espera
	tween.tween_interval(tiempo_espera)
	
	# Bajar y subir puerta
	tween.tween_property(self, "position", posicion_inicial, tiempo_animacion)
	
	# Aviso de finalización
	tween.tween_callback(func(): esta_abriendose = false)
