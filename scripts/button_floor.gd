extends StaticBody2D

@export var puerta_objetivo: Puerta
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var estado_previo: bool = false

func _ready() -> void:
	sprite.play("Unpressed")

# Reemplazamos las señales por un escáner constante y robusto
func _physics_process(delta: float) -> void:
	var hay_peso_ahora = false
	
	# Buscar objetos físicos libres (Jugador, Piezas cayendo)
	var cuerpos = area.get_overlapping_bodies()
	for cuerpo in cuerpos:
		# Ignoramos al propio botón y a los TileMaps (los escaneamos en el paso 2)
		if cuerpo != self and not (cuerpo is TileMapLayer):
			hay_peso_ahora = true
			break
			
	# Buscar pintura del TileMap (Cristales ya fijados)
	if not hay_peso_ahora:
		# Calculamos el punto exacto en el centro de la celda que está encima del botón
		var pos_arriba = global_position + Vector2(0, -16) 
		
		# Revisamos todas las capas del mapa
		var tilemaps = get_tree().current_scene.find_children("*", "TileMapLayer", true, false)
		for tm in tilemaps:
			# Solo nos importan los mapas que tengan colisiones sólidas
			if tm.tile_set != null and tm.tile_set.get_physics_layers_count() > 0:
				var celda = tm.local_to_map(tm.to_local(pos_arriba))
				# Si hay un bloque pintado en esa celda específica, hay peso
				if tm.get_cell_source_id(celda) != -1:
					hay_peso_ahora = true
					break

	# Ejecutar la animación y la puerta solo si hubo un cambio de estado
	if hay_peso_ahora and not estado_previo:
		estado_previo = true
		sprite.play("Pressed")
		if puerta_objetivo:
			puerta_objetivo.set_abierta(true)
			
	elif not hay_peso_ahora and estado_previo:
		estado_previo = false
		sprite.play("Unpressed")
		if puerta_objetivo:
			puerta_objetivo.set_abierta(false)


func _on_area_2d_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	pass

func _on_area_2d_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	pass

func _on_area_2d_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	pass
