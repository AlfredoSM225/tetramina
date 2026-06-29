extends Area2D

# Arrastra aquí tu nodo de bloques secretos desde el árbol de escenas si el nombre cambia
@onready var capa_secreta: TileMapLayer = $"../Tile frente/Castillo Frente"

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
	
	# Cambia el '0.5' por el tiempo que quieras. 
	# Por ejemplo, '1.5' hará que tarde segundo y medio en desaparecer por completo.
	tween.tween_property(capa_secreta, "modulate:a", 0.0, 1.5)
	
	# Esperamos a que termine la animación antes de borrar los nodos
	await tween.finished
	capa_secreta.queue_free()
	queue_free()
