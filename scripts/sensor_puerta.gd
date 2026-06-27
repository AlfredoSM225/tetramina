extends Area2D

# Arrastra la puerta desde el árbol de escenas hacia esta propiedad en el Inspector
@export var puerta_a_controlar: Puerta 

func _ready() -> void:
	# Conectamos la señal de detección de cuerpos
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Si lo que pisó el sensor es el jugador y asignaste una puerta...
	if body.is_in_group("jugador") and puerta_a_controlar != null:
		puerta_a_controlar.activar_secuencia_puerta()
