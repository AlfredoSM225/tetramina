extends Area2D

@export var puerta_a_controlar: PuertaSensor

func _ready() -> void:
	# Conectamos la señal de detección de cuerpos
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Si lo que pisó el sensor es el jugador y asignaste una puerta...
	if body.is_in_group("Player") and puerta_a_controlar != null:
		puerta_a_controlar.activar_secuencia_puerta()
		
		if body_entered.is_connected(_on_body_entered):
			body_entered.disconnect(_on_body_entered)
