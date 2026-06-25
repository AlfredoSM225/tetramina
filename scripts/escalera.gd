extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("jugador") and body.has_method("set_en_escalera"):
		body.set_en_escalera(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("jugador") and body.has_method("set_en_escalera"):
		body.set_en_escalera(false)
