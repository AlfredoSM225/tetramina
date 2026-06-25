extends Area2D

# Obtenemos la referencia al nodo de la animación
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Forzamos a la moneda a reproducir su animación 'default' apenas aparezca
	if anim != null:
		anim.play("default")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("jugador"):
		GameManager.contar_moneda()
		queue_free()
