extends StaticBody2D
class_name Puerta

@onready var sonido_abrir: AudioStreamPlayer = $Abrir
@onready var sonido_cerrar: AudioStreamPlayer = $Cerrar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Cuántos píxeles se moverá la puerta hacia abajo al abrirse
@export var distancia_apertura: float = 160.0
# Cuánto tiempo (en segundos) tardará en abrirse/cerrarse
@export var tiempo_animacion: float = 0.3

var posicion_inicial: Vector2
var posicion_abierta: Vector2
var tween: Tween

func _ready() -> void:
	posicion_inicial = position
	posicion_abierta = posicion_inicial + Vector2(0, distancia_apertura)

# Esta función será llamada automáticamente por el botón
func set_abierta(abrir: bool) -> void:
	# Si ya había una animación ejecutándose, la detenemos
	if tween:
		tween.kill()
	
	tween = create_tween().set_parallel(false).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	if abrir:
		sonido_abrir.play()
		tween.tween_property(self, "position", posicion_abierta, tiempo_animacion)
		

	else:
		collision_shape.set_deferred("disabled", false)
		sonido_cerrar.play()
		tween.tween_property(self, "position", posicion_inicial, tiempo_animacion)
		
