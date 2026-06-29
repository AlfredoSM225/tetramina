extends Area2D

@onready var capa_secreta: TileMapLayer = $"../Tile frente/TileMapLayer_Secretos2"

var ya_descubierto: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verificamos que lo que entró sea un CharacterBody2D y que no se haya descubierto antes
	if body is CharacterBody2D and not ya_descubierto:
		ya_descubierto = true
		desvanecer_zona()

func desvanecer_zona() -> void:
	# Creamos la animación por código
	var tween = create_tween()
	
	tween.tween_property(capa_secreta, "modulate:a", 0.0, 1.5)
	
	# Esperamos a que termine la animación antes de borrar los nodos
	await tween.finished
	capa_secreta.queue_free()
	queue_free()
