extends CharacterBody2D
class_name PiezaBase

@export var puede_rotar: bool = true
@export var grid_size: int = 32 
@export_enum("Rojo", "Azul", "Verde", "Morado", "Amarillo", "Naranja", "Aqua") var color_pieza: String = "Rojo"
# Usaremos esta variable para saber qué imagen pintar del TileSet
@export var id_tileset: int = 1 
@export var tile_map_layer: TileMapLayer 

var esta_activa: bool = false 
var jugador_ref: CharacterBody2D = null 
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	add_to_group("Piezas")
	
	# Busca automáticamente tu nueva capa libre
	var mapa_encontrado = get_tree().get_first_node_in_group("CapaPiezas")
	if mapa_encontrado is TileMapLayer:
		tile_map_layer = mapa_encontrado
	
	for hijo in get_children():
		var anim_sprite = hijo.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.animation = color_pieza
			anim_sprite.frame = 0

func _physics_process(delta: float) -> void:
	if not esta_activa:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0
		move_and_slide()

func activar_control(jugador: CharacterBody2D) -> void:
	esta_activa = true
	jugador_ref = jugador
	add_collision_exception_with(jugador)
	global_position = global_position.snapped(Vector2(grid_size, grid_size))

func _unhandled_input(event: InputEvent) -> void:
	if not esta_activa:
		return
		
	get_viewport().set_input_as_handled()

	if event.is_action_pressed("Left"):
		intentar_moverse(Vector2.LEFT)
	elif event.is_action_pressed("Right"):
		intentar_moverse(Vector2.RIGHT)
	elif event.is_action_pressed("Down"):
		intentar_moverse(Vector2.DOWN)
	elif event.is_action_pressed("Up"): 
		intentar_moverse(Vector2.UP)
	elif event.is_action_pressed("rotar_pieza"): 
		intentar_rotar()
	elif event.is_action_pressed("colocar_pieza"): 
		colocar_pieza()

func intentar_moverse(direccion: Vector2) -> void:
	var colision = move_and_collide(direccion * grid_size, true)
	if not colision:
		global_position += direccion * grid_size

func intentar_rotar() -> void:
	if not puede_rotar:
		return
		
	var rotacion_anterior = rotation
	rotation_degrees += 90
	if move_and_collide(Vector2.ZERO, true):
		rotation = rotacion_anterior

func colocar_pieza() -> void:
	if not tile_map_layer:
		push_error("TileMapLayer no asignado")
		return

	for hijo in get_children():
		if hijo is CollisionShape2D or hijo is Node2D:
			var anim_sprite = hijo.get_node_or_null("Sprite2D")
			if not anim_sprite:
				anim_sprite = hijo.get_node_or_null("AnimatedSprite2D")
			
			if anim_sprite:
				var pos_local_al_mapa = tile_map_layer.to_local(hijo.global_position)
				var coord_rejilla = tile_map_layer.local_to_map(pos_local_al_mapa)
				
				# ¡LA MAGIA! Ahora pintamos el bloque usando su ID de imagen
				tile_map_layer.set_cell(coord_rejilla, id_tileset, Vector2i(0, 0))
	
	if jugador_ref:
		remove_collision_exception_with(jugador_ref)
		jugador_ref.recuperar_control()
	
	esta_activa = false
	
	if has_node("/root/ScriptGlobal"):
		get_node("/root/ScriptGlobal").revisar_lineas_completas()
	
	queue_free()
