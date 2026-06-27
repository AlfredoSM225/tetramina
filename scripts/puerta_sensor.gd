extends StaticBody2D
class_name Puerta

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Cuántos píxeles se moverá la puerta hacia ARRIBA (por eso es negativo) al abrirse
@export var distancia_apertura: float = -48.0 # Ajusta según el alto de tu puerta
@export var tiempo_animacion: float = 0.4
# Cuántos segundos se queda arriba antes de cerrarse sola
@export var tiempo_espera: float = 3.0 

var posicion_inicial: Vector2
var posicion_abierta: Vector2
var tween: Tween
var esta_abriendose: bool = false

func _ready() -> void:
	posicion_inicial = position
	# Modificado a Vector2(0, distancia_apertura) para que suba si el valor es negativo
	posicion_abierta = posicion_inicial + Vector2(0, distancia_apertura)

# Esta función la llamará el Area2D cuando el jugador la pise
func activar_secuencia_puerta() -> void:
	# Si ya está abierta o abriéndose, ignoramos para que no reinicie el tiempo a mitad de camino
	if esta_abriendose:
		return
		
	esta_abriendose = true
	
	if tween:
		tween.kill()
	
	# Creamos una cadena de eventos secuencial (.set_parallel(false))
	tween = create_tween().set_parallel(false).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# 1. SUBIR LA PUERTA
	tween.tween_property(self, "position", posicion_abierta, tiempo_animacion)
	
	# 2. ESPERAR X SEGUNDOS (Aquí hace la pausa automática en el aire)
	tween.tween_interval(tiempo_espera)
	
	# 3. BAJAR LA PUERTA Y CERRAR
	tween.tween_property(self, "position", posicion_inicial, tiempo_animacion)
	
	# 4. AVISAR QUE YA TERMINÓ TODO EL PROCESO
	tween.tween_callback(func(): esta_abriendose = false)
