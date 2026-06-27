extends Area2D

func _ready() -> void:
	# Conectamos la señal para detectar cuándo entra un cuerpo físico
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si el cuerpo que entró pertenece al grupo de nuestro jugador
	if body.is_in_group("Player"):
		if body.has_method("morir"):
			body.morir()
