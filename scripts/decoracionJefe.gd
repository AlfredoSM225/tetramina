extends AnimatedSprite2D

# Configuración del tiempo en segundos para la animación de muerte
@export var tiempo_muerto_min: float = 1.5
@export var tiempo_muerto_max: float = 3.0

# Configuración del tiempo en segundos que pasará activo en 'default' antes de parpadear a muerto
@export var tiempo_vida_min: float = 4.0
@export var tiempo_vida_max: float = 8.0

func _ready() -> void:
	# Iniciamos el bucle infinito de estados
	bucle_de_animacion()

func bucle_de_animacion() -> void:
	while true:
		# 1. Reproducir la animación por defecto
		play("default")
		
		# Calcular un tiempo al azar para estar vivo y esperar
		var tiempo_vivo = randf_range(tiempo_vida_min, tiempo_vida_max)
		await get_tree().create_timer(tiempo_vivo).timeout
		
		# 2. Cambiar a la animación de muerte
		play("dead")
		
		# Calcular un tiempo al azar para quedarse muerto y esperar
		var tiempo_muerto = randf_range(tiempo_muerto_min, tiempo_muerto_max)
		await get_tree().create_timer(tiempo_muerto).timeout
		
		# Al terminar el tiempo muerto, el ciclo 'while' se repite regresando a default
