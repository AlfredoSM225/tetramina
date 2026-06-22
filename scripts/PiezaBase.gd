extends CharacterBody2D
class_name PiezaBase

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
	
	if jugador_ref:
		remove_collision_exception_with(jugador_ref)
		jugador_ref.recuperar_control()

func fijar_en_mapa() -> void:
	en_caida_libre = false
	if not tile_map_layer: 
		print("ERROR: No hay CapaPiezas asignada")
		return

	var bloques_pintados = 0

	for hijo in get_children():
		# Ya no buscamos el nombre del sprite, simplemente pintamos 
		# todo hijo que tenga colisión (tus 4 cuadritos)
		if hijo is CollisionShape2D or hijo is Node2D:
			var pos_local_al_mapa = tile_map_layer.to_local(hijo.global_position)
			var coord_rejilla = tile_map_layer.local_to_map(pos_local_al_mapa)
			
			tile_map_layer.set_cell(coord_rejilla, id_tileset, Vector2i(0, 0))
			bloques_pintados += 1
	
	# === EL CHIVATO (Revisa la consola abajo en Godot) ===
	print("Se pintaron ", bloques_pintados, " bloques en el mapa con el ID: ", id_tileset)
	
	if has_node("/root/ScriptGlobal"):
		get_node("/root/ScriptGlobal").revisar_lineas_completas()
	
	queue_free()
