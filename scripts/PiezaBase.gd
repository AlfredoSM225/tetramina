extends CharacterBody2D
class_name PiezaBase

@export var ruta_escena: String = ""
@export var puede_rotar: bool = true
@export var grid_size: int = 32 
@export_enum("Rojo", "Azul", "Verde", "Morado", "Amarillo", "Naranja", "Aqua") var color_pieza: String = "Rojo"
@export var id_tileset: int = 1 
@export var tile_map_layer: TileMapLayer 

var esta_activa: bool = false 
var en_caida_libre: bool = false
var jugador_ref: CharacterBody2D = null 
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	add_to_group("Piezas")
	
	var mapa_encontrado = get_tree().get_first_node_in_group("CapaPiezas")
	if mapa_encontrado is TileMapLayer:
		tile_map_layer = mapa_encontrado
	
	for hijo in get_children():
		var anim_sprite = hijo.get_node_or_null("Sprite2D")
		if not anim_sprite:
			anim_sprite = hijo.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.animation = color_pieza
			anim_sprite.frame = 0

func _physics_process(delta: float) -> void:
	if not esta_activa:
		# 1. Aplicamos gravedad a la velocidad si no estamos tocando el piso
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
			
		velocity.x = 0
		
		# 2. EL SECRETO: Ejecutar move_and_slide PRIMERO.
		# Esto obliga a Godot a moverse un milímetro, recalcular todo y darse cuenta
		# de que la pieza está en el aire flotando.
		move_and_slide()
		
		# 3. AHORA SÍ comprobamos si realmente acaba de chocar contra el suelo
		if is_on_floor() and en_caida_libre:
			fijar_en_mapa()

func activar_control(jugador: CharacterBody2D) -> void:
	esta_activa = true
	en_caida_libre = false
	jugador_ref = jugador
	add_collision_exception_with(jugador)
	
	# === EL TRUCO: ROBAR LA CÁMARA ===
	var camara = jugador.get_node_or_null("Camera2D")
	if camara:
		camara.reparent(self)
		camara.position = Vector2.ZERO 
	
	if tile_map_layer:
		for hijo in get_children():
			if hijo is CollisionShape2D or hijo is Node2D:
				var pos_local = tile_map_layer.to_local(hijo.global_position)
				
				var celda_x = round((pos_local.x - grid_size / 2.0) / grid_size)
				var celda_y = round((pos_local.y - grid_size / 2.0) / grid_size)
				var celda_exacta = Vector2i(celda_x, celda_y)
				
				var centro_celda = tile_map_layer.map_to_local(celda_exacta)
				var centro_global = tile_map_layer.to_global(centro_celda)
				
				global_position = centro_global - hijo.position.rotated(rotation)
				break
	esta_activa = true
	en_caida_libre = false
	jugador_ref = jugador
	add_collision_exception_with(jugador)
	
	# === EL SECRETO 1: ALINEACIÓN ABSOLUTA AL TILEMAP ===
	if tile_map_layer:
		for hijo in get_children():
			if hijo is CollisionShape2D or hijo is Node2D:
				# 1. Vemos en qué celda está tocando este bloque
				var pos_local = tile_map_layer.to_local(hijo.global_position)
				var celda = tile_map_layer.local_to_map(pos_local)
				
				# 2. Le pedimos al TileMap el centro matemático PERFECTO de esa celda
				var centro_celda = tile_map_layer.map_to_local(celda)
				var centro_global = tile_map_layer.to_global(centro_celda)
				
				# 3. Anclamos toda la pieza para que el bloque quede en ese centro exacto
				global_position = centro_global - hijo.position.rotated(rotation)
				break # Solo necesitamos hacerlo con el primer bloque
				
				
func _unhandled_input(event: InputEvent) -> void:
	if not esta_activa:
		return
		
	get_viewport().set_input_as_handled()

	if event.is_action_pressed("Left"): intentar_moverse(Vector2.LEFT)
	elif event.is_action_pressed("Right"): intentar_moverse(Vector2.RIGHT)
	elif event.is_action_pressed("Down"): intentar_moverse(Vector2.DOWN)
	elif event.is_action_pressed("Up"): intentar_moverse(Vector2.UP)
	elif event.is_action_pressed("rotar_pieza"): intentar_rotar()
	elif event.is_action_pressed("colocar_pieza"): soltar_pieza()

func intentar_moverse(direccion: Vector2) -> void:
	var colision = move_and_collide(direccion * grid_size, true)
	if not colision:
		global_position += direccion * grid_size

func intentar_rotar() -> void:
	if not puede_rotar: return
	var rotacion_anterior = rotation
	rotation_degrees += 90
	if move_and_collide(Vector2.ZERO, true):
		rotation = rotacion_anterior

func soltar_pieza() -> void:
	esta_activa = false
	en_caida_libre = true 
	devolver_camara()
	if jugador_ref:
		remove_collision_exception_with(jugador_ref)
		jugador_ref.recuperar_control()


func fijar_en_mapa() -> void:
	en_caida_libre = false
	if not tile_map_layer: return

	var celdas_registradas = []
	var offset_root_perfecto = Vector2.ZERO
	var tiene_primer_hijo = false

	for hijo in get_children():
		if hijo is CollisionShape2D or hijo is Node2D:
			# Usamos la posición directa. local_to_map ya es suficientemente inteligente
			# para saber en qué celda cayó sin necesidad de que nosotros redondeemos nada.
			var pos_local = tile_map_layer.to_local(hijo.global_position)
			var coord_rejilla = tile_map_layer.local_to_map(pos_local)
			
			tile_map_layer.set_cell(coord_rejilla, id_tileset, Vector2i(0, 0))
			celdas_registradas.append(coord_rejilla)
			
			if not tiene_primer_hijo:
				# === EL SECRETO 2: DISTANCIA PURA ===
				# En vez de restar posiciones globales afectadas por la caída, usamos 
				# la posición local perfecta del nodo interno.
				offset_root_perfecto = -hijo.position.rotated(rotation)
				tiene_primer_hijo = true
	
	if celdas_registradas.size() == 4 and ruta_escena != "":
		var id_unico = Time.get_ticks_msec() + randi()
		ScriptGlobal.registrar_pieza(id_unico, ruta_escena, celdas_registradas, id_tileset, offset_root_perfecto, rotation)
	
	if has_node("/root/ScriptGlobal"):
		get_node("/root/ScriptGlobal").revisar_lineas_completas()
	
	queue_free()
	
func devolver_camara() -> void:
	var camara = get_node_or_null("Camera2D")
	if camara and jugador_ref:
		# Le regresamos la cámara al jugador
		camara.reparent(jugador_ref)
		# La centramos de nuevo en el cuerpo del jugador
		camara.position = Vector2.ZERO
