extends CharacterBody2D
class_name PiezaBase

@export var puede_rotar: bool = true
@export var grid_size: int = 16
@export var atlas_coords: Vector2i # Coordenadas en el TileSet para este color

# Filtro de color usando un Setter. Cambia el color automáticamente en el Inspector
@export_enum("Rojo", "Azul", "Verde", "Morado", "Amarillo", "Naranja", "Aqua") var color_pieza: String = "Rojo":
	set(value):
		color_pieza = value
		if is_node_ready():
			actualizar_color_bloques()

# ¡MUY IMPORTANTE! Tienes que arrastrar tu nodo TileMapLayer a esta casilla en el Inspector
@export var tile_map_layer: TileMapLayer 

# Esta variable controlará si el jugador puede mover la pieza o si está en espera
var esta_activa: bool = false 

func _ready() -> void:
	actualizar_color_bloques()

# Cambia la animación de los 4 cuadritos hijos al color elegido
func actualizar_color_bloques() -> void:
	for hijo in get_children():
		var anim_sprite = hijo.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.animation = color_pieza
			anim_sprite.frame = 0 # Evita que intente reproducir una secuencia si es un solo frame

# Captura los movimientos del jugador (solo cuando la pieza esté activa)
func _unhandled_input(event: InputEvent) -> void:
	if not esta_activa:
		return
		
	if event.is_action_pressed("ui_left"):
		intentar_moverse(Vector2.LEFT)
	elif event.is_action_pressed("ui_right"):
		intentar_moverse(Vector2.RIGHT)
	elif event.is_action_pressed("ui_down"):
		intentar_moverse(Vector2.DOWN)
	elif event.is_action_pressed("ui_up"): # Usamos Arriba para rotar, o puedes mapear otra tecla
		intentar_rotar()
	elif event.is_action_pressed("ui_accept"): # Barra espaciadora o Enter para colocar
		colocar_pieza()

# Mueve la pieza un bloque entero si el espacio está libre
func intentar_moverse(direccion: Vector2) -> void:
	var posicion_anterior = global_position
	global_position += direccion * grid_size
	
	if verificar_colisiones():
		global_position = posicion_anterior # Deshace el movimiento si choca

# Rota la pieza 90 grados si hay espacio libre en la cueva
func intentar_rotar() -> void:
	if not puede_rotar:
		return
		
	var rotacion_anterior = rotation
	rotation_degrees += 90
	
	if verificar_colisiones():
		rotation = rotacion_anterior # Deshace la rotación si se encaja en una pared

# Sistema de escaneo: Verifica si alguno de los 4 bloques se encaja en un obstáculo
func verificar_colisiones() -> bool:
	if not tile_map_layer:
		push_warning("Falta asignar el TileMapLayer en el inspector de la pieza.")
		return false
		
	for hijo in get_children():
		# Solo verificamos los nodos que representan tus bloques de cristal
		if hijo is Node2D and hijo.get_node_or_null("AnimatedSprite2D"):
			var coord_rejilla = tile_map_layer.local_to_map(hijo.global_position)
			
			# Si la celda del TileMap NO está vacía (diferente de -1), significa que hay colisión
			if tile_map_layer.get_cell_source_id(coord_rejilla) != -1:
				return true
	return false

# Fija la pieza definitivamente en el mapa y la disuelve
func colocar_pieza() -> void:
	if not tile_map_layer:
		push_error("No se pudo colocar la pieza: TileMapLayer no asignado.")
		return

	# Recorremos los 4 hijos para transformarlos en celdas del escenario
	for hijo in get_children():
		if hijo is Node2D and hijo.get_node_or_null("AnimatedSprite2D"):
			var coord_rejilla = tile_map_layer.local_to_map(hijo.global_position)
			# Pintamos el bloque usando el ID de tu TileSet (0) y las coordenadas de su color
			tile_map_layer.set_cell(coord_rejilla, 0, atlas_coords)
	
	# Llamamos al script global (Autoload) para comprobar si se hicieron líneas
	if has_node("/root/ScriptGlobal"):
		get_node("/root/ScriptGlobal").revisar_lineas_completas()
	
	# Eliminamos la escena de la pieza de forma limpia
	queue_free()
