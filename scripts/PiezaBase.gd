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

# --- VARIABLES PARA EL CHECKPOINT ---
@onready var id_unico = "pieza_" + str(global_position.x) + "_" + str(global_position.y)
var scene_path : String

func _ready() -> void:
	add_to_group("Piezas")
	add_to_group("Reseteables")
	scene_path = get_tree().current_scene.scene_file_path
	
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

	# === APAGAR COLISIÓN DEL FONDO POR CÓDIGO ===
	var fondo = get_tree().current_scene.find_child("Tile atras", true, false)
	if fondo and "collision_enabled" in fondo:
		# Si es un TileMapLayer de Godot 4, desactivamos sus físicas por completo
		fondo.collision_enabled = false
		

func _physics_process(delta: float) -> void:
	if not esta_activa:
		# 1. Aplicamos gravedad a la velocidad si no estamos tocando el piso
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
			
		velocity.x = 0
		
		# 2. Movemos la pieza y registramos las colisiones
		move_and_slide()
		
		# === NUEVO: SISTEMA DE APLASTAMIENTO ===
		if en_caida_libre:
			for i in get_slide_collision_count():
				var colision = get_slide_collision(i)
				var cuerpo = colision.get_collider()
				
				# Revisamos si lo que acabamos de golpear es el Jugador
				if cuerpo and cuerpo.is_in_group("Player"):
					# get_normal() nos dice hacia dónde apunta la superficie chocada.
					# Si la 'y' es negativa (apunta hacia arriba), golpeamos el techo del jugador (su cabeza)
					if colision.get_normal().y < -0.5:
						if cuerpo.has_method("morir"):
							cuerpo.morir()
							# Evitamos que la pieza se pinte en el TileMap sobre tu cadáver
							en_caida_libre = false 
						break # Ya lo mató, no necesitamos seguir revisando otros choques
		
		# 3. AHORA SÍ comprobamos si realmente acaba de chocar contra el suelo
		if is_on_floor() and en_caida_libre:
			fijar_en_mapa()

func activar_control(jugador: CharacterBody2D) -> void:
	esta_activa = true
	en_caida_libre = false
	jugador_ref = jugador
	add_collision_exception_with(jugador)
	set_shader_seleccionable(false)
	set_shader_en_uso(true)
	
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
	set_shader_en_uso(false)

func fijar_en_mapa() -> void:
	en_caida_libre = false
	if not tile_map_layer: return

	var celdas_registradas = []
	var offset_root_perfecto = Vector2.ZERO
	var tiene_primer_hijo = false

	for hijo in get_children():
		if hijo is CollisionShape2D or hijo is Node2D:
			var pos_local = tile_map_layer.to_local(hijo.global_position)
			var coord_rejilla = tile_map_layer.local_to_map(pos_local)
			
			tile_map_layer.set_cell(coord_rejilla, id_tileset, Vector2i(0, 0))
			celdas_registradas.append(coord_rejilla)
			
			if not tiene_primer_hijo:
				offset_root_perfecto = -hijo.position.rotated(rotation)
				tiene_primer_hijo = true
	
	if celdas_registradas.size() == 4 and ruta_escena != "":
		var id_unico_guardado = Time.get_ticks_msec() + randi()
		ScriptGlobal.registrar_pieza(id_unico_guardado, ruta_escena, celdas_registradas, id_tileset, offset_root_perfecto, rotation)
	
	if has_node("/root/ScriptGlobal"):
		get_node("/root/ScriptGlobal").revisar_lineas_completas()
	
	queue_free()
	
func devolver_camara() -> void:
	var camara = get_node_or_null("Camera2D")
	if camara and jugador_ref:
		camara.reparent(jugador_ref)
		camara.position = Vector2.ZERO

func set_shader_seleccionable(activar: bool) -> void:
	var color_rects = find_children("*", "ColorRect", true, false)
	for rect in color_rects:
		rect.visible = activar

func set_shader_en_uso(activar: bool) -> void:
	var sprites = find_children("*", "AnimatedSprite2D", true, false)
	for sprite in sprites:
		if sprite.material:
			sprite.material.set_shader_parameter("activado", activar)

# --- FUNCIONES NUEVAS DEL SISTEMA DE CHECKPOINTS ---

# Se llama automáticamente cuando el jugador pisa un Checkpoint
func guardar_estado_en_checkpoint() -> void:
	WorldState.set_state(scene_path, id_unico, "pos_x", global_position.x)
	WorldState.set_state(scene_path, id_unico, "pos_y", global_position.y)
	WorldState.set_state(scene_path, id_unico, "rotacion", rotation)
	WorldState.set_state(scene_path, id_unico, "existe", true)

# Se llama automáticamente cuando el jugador presiona K
func cargar_estado_de_checkpoint() -> void:
	if not WorldState.scene_states.has(scene_path):
		return
		
	var guardado_existe = WorldState.get_state(scene_path, id_unico, "existe", false)
	
	if guardado_existe:
		# Si el jugador la estaba controlando en pleno reseteo, devolvemos la cámara de forma segura
		if esta_activa:
			desactivar_control()
			
		var px = WorldState.get_state(scene_path, id_unico, "pos_x", global_position.x)
		var py = WorldState.get_state(scene_path, id_unico, "pos_y", global_position.y)
		var rot = WorldState.get_state(scene_path, id_unico, "rotacion", rotation)
		
		global_position = Vector2(px, py)
		rotation = rot
		
		# Detenemos cualquier inercia de caída libre que trajera la pieza
		velocity = Vector2.ZERO
		en_caida_libre = false

# Fuerza la desconexión del control si el mundo se reinicia bruscamente
func desactivar_control() -> void:
	esta_activa = false
	en_caida_libre = false
	devolver_camara()
	if jugador_ref:
		remove_collision_exception_with(jugador_ref)
	set_shader_en_uso(false)
