extends StaticBody2D

@export var puerta_objetivo: Puerta
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var estado_previo: bool = false

func _ready() -> void:
	sprite.play("Unpressed")

func _physics_process(delta: float) -> void:
	var hay_peso_ahora = false
	
	#Objetos fisicos, jugador o piezas
	var cuerpos = area.get_overlapping_bodies()
	for cuerpo in cuerpos:
		if cuerpo != self and not (cuerpo is TileMapLayer):
			if cuerpo.is_in_group("Player") or cuerpo.is_in_group("Piezas") or cuerpo.is_in_group("Reseteables"):
				hay_peso_ahora = true
				break
			
	# Bloques en el TileMap
	if not hay_peso_ahora:
		var pos_arriba = global_position + Vector2(0, -24) 
		
		# Buscamos todos los TileMapLayers en la escena
		var tilemaps = get_tree().current_scene.find_children("*", "TileMapLayer", true, false)
		for tm in tilemaps:
			var nombre_mapa = tm.name.to_lower()
			
			#Si es el fondo ("tile atras", "fondo", "escenario"), lo ignoramos
			if "atras" in nombre_mapa or "fondo" in nombre_mapa or tm.is_in_group("Escenario"):
				continue
				
			var celda = tm.local_to_map(tm.to_local(pos_arriba))
			if tm.get_cell_source_id(celda) != -1:
				hay_peso_ahora = true
				break

	# Cambio de estado
	if hay_peso_ahora and not estado_previo:
		estado_previo = true
		sprite.play("Pressed")
		if puerta_objetivo:
			puerta_objetivo.set_abierta(true)
			print("Botón presionado")
			
	elif not hay_peso_ahora and estado_previo:
		estado_previo = false
		sprite.play("Unpressed")
		if puerta_objetivo:
			puerta_objetivo.set_abierta(false)
			print("Botón liberado")
