extends Node2D

@export var piezas_disponibles: Array[PackedScene]

# Límites visuales por si el dispensador está pegado a una pared del nivel (para el Wall Kick)
@export var ancho_en_columnas: int = 8
# Tiempo de espera en segundos antes de poder pedir otra pieza
@export var tiempo_cooldown: float = 10.0

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var zona_interaccion: Area2D = $ZonaInteraccion

var columnas_mapa: Array = []
var se_puede_pedir: bool = true
var jugador_en_zona: bool = false

func _ready() -> void:
	# Conectamos las señales del Area2D automáticamente por código
	zona_interaccion.body_entered.connect(_on_body_entered)
	zona_interaccion.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	# Solo funciona si presionas Up, no estás en cooldown Y el robot está debajo
	if event.is_action_pressed("Up") and se_puede_pedir and jugador_en_zona:
		var mapa = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
		if not mapa: return
		
		lanzar_pieza_dispensador(mapa)
		activar_cooldown()

func lanzar_pieza_dispensador(mapa: TileMapLayer) -> void:
	if piezas_disponibles.size() == 0: return

	# CONFIGURACIÓN DE LÍMITES (Para el sensor de paredes basado en la posición del Marker)
	if columnas_mapa.size() == 0:
		var pos_celda_dispensador = mapa.local_to_map(mapa.to_local(spawn_point.global_position))
		columnas_mapa = range(pos_celda_dispensador.x, pos_celda_dispensador.x + ancho_en_columnas)

	# 1. Instanciamos la pieza aleatoria
	var escena_aleatoria = piezas_disponibles.pick_random()
	var nueva_pieza = escena_aleatoria.instantiate() as CharacterBody2D
	
	# [SE QUITO LA ROTACIÓN ALEATORIA AQUÍ]
	
	# 2. Buscamos el offset del primer bloque de la pieza para centrarlo en el Marker
	var offset_primer_bloque = Vector2.ZERO
	for hijo in nueva_pieza.get_children():
		if hijo is CollisionShape2D or hijo is Node2D:
			offset_primer_bloque = hijo.position
			break
	
	# Alineamos el spawn perfectamente a la rejilla del TileMap usando el Marker2D como guía
	var pos_celda_spawn = mapa.local_to_map(mapa.to_local(spawn_point.global_position))
	var centro_celda_mapa = mapa.map_to_local(pos_celda_spawn)
	var pos_global_spawn = mapa.to_global(centro_celda_mapa)
	
	nueva_pieza.global_position = pos_global_spawn - offset_primer_bloque
	
	# 3. EL WALL KICK (Evita que traspase paredes laterales al aparecer)
	var limite_izq = columnas_mapa[0]
	var limite_der = columnas_mapa[-1]
	var ajuste_columnas = 0
	
	for hijo in nueva_pieza.get_children():
		if hijo is CollisionShape2D or hijo is Node2D:
			var pos_bloque = nueva_pieza.global_position + hijo.position
			var celda_bloque = mapa.local_to_map(mapa.to_local(pos_bloque))
			
			if celda_bloque.x < limite_izq:
				var empuje = limite_izq - celda_bloque.x
				if empuje > ajuste_columnas: ajuste_columnas = empuje
			elif celda_bloque.x > limite_der:
				var empuje = limite_der - celda_bloque.x 
				if empuje < ajuste_columnas: ajuste_columnas = empuje
					
	if ajuste_columnas != 0:
		var tamano_celda = mapa.tile_set.tile_size.x
		nueva_pieza.global_position.x += ajuste_columnas * tamano_celda

	# 4. Caída libre activa
	if "en_caida_libre" in nueva_pieza:
		nueva_pieza.en_caida_libre = true
	
	mapa.get_parent().add_child(nueva_pieza)

func activar_cooldown() -> void:
	se_puede_pedir = false
	await get_tree().create_timer(tiempo_cooldown).timeout
	se_puede_pedir = true

# === SEÑALES DE DETECCIÓN DEL JUGADOR ===
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		jugador_en_zona = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		jugador_en_zona = false
