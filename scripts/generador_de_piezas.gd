extends Node2D

@export var piezas_disponibles: Array[PackedScene]

@export var ancho_en_columnas: int = 8
@export var profundidad_en_filas: int = 16

@export var lineas_para_vencer: int = 5
var lineas_actuales: int = 0

# Variables internas que calculará solo
var columna_prohibida: int = -999
var columnas_mapa: Array = []
var y_fondo_pozo: int = 0

func _ready() -> void:
	if ScriptGlobal.has_signal("lineas_borradas"):
		ScriptGlobal.lineas_borradas.connect(_on_jugador_hace_linea)
	ScriptGlobal.salto_infinito_permitido = true
	
func _on_timer_timeout() -> void:
	lanzar_pieza_basura()

func lanzar_pieza_basura() -> void:
	var mapa = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
	if not mapa: return

	#Configuración del generador
	if columna_prohibida == -999:
		# El jefe busca en qué celda exacta del mapa lo colocaste en el editor
		var pos_celda_jefe = mapa.local_to_map(mapa.to_local(global_position))
		var columna_inicial = pos_celda_jefe.x
		
		# Genera su lista de columnas a partir de donde está parado
		columnas_mapa = range(columna_inicial, columna_inicial + ancho_en_columnas)
		
		# Calcula dónde está el fondo sumando la profundidad a su altura actual
		y_fondo_pozo = pos_celda_jefe.y + profundidad_en_filas
		
		# Elige la columna que nunca tocará
		columna_prohibida = columnas_mapa.pick_random()
		print("Jefe anclado en la columna: ", columna_inicial, ". Prohibida: ", columna_prohibida)

	# CREAR EL MAPA DE ALTURAS
	var cima_columnas = {}
	for x in columnas_mapa:
		cima_columnas[x] = y_fondo_pozo 

	var celdas_usadas = mapa.get_used_cells()
	for celda in celdas_usadas:
		if celda.x in cima_columnas:
			# Si encuentra un bloque pintado más alto, actualiza la cima
			if celda.y < cima_columnas[celda.x]:
				cima_columnas[celda.x] = celda.y

	#Encontrar columna vacia
	var columna_elegida = -1
	var y_mas_profundo = -999999

	for x in cima_columnas.keys():
		if x == columna_prohibida:
			continue
			
		if cima_columnas[x] > y_mas_profundo:
			y_mas_profundo = cima_columnas[x]
			columna_elegida = x

#Crear y lanzar pieza
	if columna_elegida != -1 and piezas_disponibles.size() > 0:
		var escena_aleatoria = piezas_disponibles.pick_random()
		var nueva_pieza = escena_aleatoria.instantiate() as CharacterBody2D
		
		var rotaciones_posibles = [0.0, PI/2, PI, 3*PI/2]
		#nueva_pieza.rotation = rotaciones_posibles.pick_random()
		
		var offset_primer_bloque = Vector2.ZERO
		for hijo in nueva_pieza.get_children():
			if hijo is CollisionShape2D or hijo is Node2D:
				offset_primer_bloque = hijo.position.rotated(nueva_pieza.rotation)
				break
		
		var pos_celda_spawn = Vector2i(columna_elegida, mapa.local_to_map(mapa.to_local(global_position)).y)
		var centro_celda_mapa = mapa.map_to_local(pos_celda_spawn)
		var pos_global_spawn = mapa.to_global(centro_celda_mapa)
		
		nueva_pieza.global_position = pos_global_spawn - offset_primer_bloque
		
		var limite_izq = columnas_mapa[0]
		var limite_der = columnas_mapa[-1]
		var ajuste_columnas = 0
		
		# Revisamos dónde quedaron los 4 bloques después de rotar
		for hijo in nueva_pieza.get_children():
			if hijo is CollisionShape2D or hijo is Node2D:
				var pos_bloque = nueva_pieza.global_position + hijo.position.rotated(nueva_pieza.rotation)
				var celda_bloque = mapa.local_to_map(mapa.to_local(pos_bloque))
				
				if celda_bloque.x < limite_izq:
					var empuje = limite_izq - celda_bloque.x
					if empuje > ajuste_columnas:
						ajuste_columnas = empuje # Empujamos hacia la derecha (Positivo)
				elif celda_bloque.x > limite_der:
					var empuje = limite_der - celda_bloque.x 
					if empuje < ajuste_columnas:
						ajuste_columnas = empuje # Empujamos hacia la izquierda (Negativo)
						
		# Si la pieza invadió la pared, aplicamos la corrección matemática
		if ajuste_columnas != 0:
			var tamano_celda = mapa.tile_set.tile_size.x # Extrae automáticamente el 32x32
			nueva_pieza.global_position.x += ajuste_columnas * tamano_celda

		#Soltamos con físicas
		if "en_caida_libre" in nueva_pieza:
			nueva_pieza.en_caida_libre = true
		
		mapa.get_parent().add_child(nueva_pieza)
		

func _on_jugador_hace_linea(cantidad: int) -> void:
	# Sumamos el daño
	lineas_actuales += cantidad
	print("El jefe recibió daño: ", lineas_actuales, "/", lineas_para_vencer)
	
	# Comprobamos si ya lo matamos
	if lineas_actuales >= lineas_para_vencer:
		derrotar_jefe()
		
func derrotar_jefe() -> void:
	print("¡JEFE DERROTADO!")
	ScriptGlobal.salto_infinito_permitido = false
	var timer = get_node_or_null("Timer")
	if timer:
		timer.stop()
		
	if ScriptGlobal.lineas_borradas.is_connected(_on_jugador_hace_linea):
		ScriptGlobal.lineas_borradas.disconnect(_on_jugador_hace_linea)
		

	SaveManager.guardar_partida()
	

	await get_tree().create_timer(4.0).timeout
	
	# Cambiamos a la pantalla de victoria
	get_tree().change_scene_to_file("res://scenes/victoria.tscn")
