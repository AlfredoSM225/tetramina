extends Node

var bloques_para_linea = 8

var registro_piezas = {} 
var celda_a_pieza = {}   

func registrar_pieza(id_p: int, ruta: String, celdas: Array, id_tileset: int, offset_root: Vector2, rot: float):
	registro_piezas[id_p] = {
		"ruta_escena": ruta,
		"celdas": celdas,
		"id_tileset": id_tileset,
		"offset_root": offset_root,
		"rotation": rot
	}
	for celda in celdas:
		celda_a_pieza[celda] = id_p

func revisar_lineas_completas():
	var capa_piezas = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
	if not capa_piezas: return
	
	var celdas_usadas = capa_piezas.get_used_cells()
	if celdas_usadas.is_empty(): return
	
	var filas = {}
	for celda in celdas_usadas:
		if not filas.has(celda.y):
			filas[celda.y] = []
		filas[celda.y].append(celda.x)
		
	var lineas_a_borrar = []
	
	for y in filas.keys():
		var columnas = filas[y]
		columnas.sort() 
		
		var secuencia = []
		for x in columnas:
			if secuencia.is_empty() or x == secuencia[-1] + 1:
				secuencia.append(x)
			else:
				if secuencia.size() >= bloques_para_linea:
					lineas_a_borrar.append({"y": y, "xs": secuencia.duplicate()})
				secuencia = [x] 
		
		if secuencia.size() >= bloques_para_linea:
			lineas_a_borrar.append({"y": y, "xs": secuencia.duplicate()})
			
	if lineas_a_borrar.size() > 0:
		var columnas_afectadas = []
		var y_max_borrado = -999999
		var celdas_borradas = {} 
		
		for linea in lineas_a_borrar:
			if linea["y"] > y_max_borrado: y_max_borrado = linea["y"]
			
			for x in linea["xs"]:
				var celda = Vector2i(x, linea["y"])
				capa_piezas.set_cell(celda, -1)
				celdas_borradas[celda] = true 
				
				if not x in columnas_afectadas:
					columnas_afectadas.append(x)
				
				if celda in celda_a_pieza:
					var id_p = celda_a_pieza[celda]
					if id_p in registro_piezas:
						registro_piezas[id_p]["celdas"].erase(celda)
					celda_a_pieza.erase(celda)
		
		var mapas_colision = []
		if get_tree().current_scene:
			var todos_tilemaps = get_tree().current_scene.find_children("*", "TileMapLayer", true, false)
			for tm in todos_tilemaps:
				if tm != capa_piezas and tm.tile_set != null:
					if tm.tile_set.get_physics_layers_count() > 0:
						mapas_colision.append(tm)
		

		await aplicar_gravedad_aislada(capa_piezas, columnas_afectadas, y_max_borrado, celdas_borradas, mapas_colision)
		
		revisar_lineas_completas()

func es_celda_libre(coord: Vector2i, capa_piezas: TileMapLayer, mapas_colision: Array) -> bool:
	#¿Choca con otra pieza del Tetris?
	if capa_piezas.get_cell_source_id(coord) != -1:
		return false
		
#¿Choca con el escenario sólido (de 16x16 o cualquier tamaño)?
	var centro_global = capa_piezas.to_global(capa_piezas.map_to_local(coord))

	# Un bloque de 32x32 cubre 4 bloques de 16x16. 
	# El offset (8 píxeles) nos sitúa exactamente en el centro de esos 4 cuadrantes.
	var offset = capa_piezas.tile_set.tile_size.x / 4.0 
	
	var puntos_escaneo = [
		centro_global + Vector2(-offset, -offset), # Arriba-Izquierda
		centro_global + Vector2(offset, -offset),  # Arriba-Derecha
		centro_global + Vector2(-offset, offset),  # Abajo-Izquierda
		centro_global + Vector2(offset, offset)    # Abajo-Derecha
	]
	
	for tm in mapas_colision:
		for punto in puntos_escaneo:
			var tm_local = tm.to_local(punto)
			var tm_cell = tm.local_to_map(tm_local)
			
			var tile_data = tm.get_cell_tile_data(tm_cell)
			if tile_data:
				var capas_fisicas = tm.tile_set.get_physics_layers_count()
				for i in range(capas_fisicas):
					# Si AL MENOS UNO de los 4 puntos toca un polígono de colisión, se detiene en seco.
					if tile_data.get_collision_polygons_count(i) > 0:
						return false
						
	return true

# === CORRUTINA DE CAÍDA ANIMADA ===
func aplicar_gravedad_aislada(capa: TileMapLayer, columnas_afectadas: Array, y_max_global: int, celdas_borradas: Dictionary, mapas_colision: Array):
	var bloques_a_mover = []
	
	# 1. RASTREAR LA CADENA: Recopilamos todos los bloques flotantes
	for x in columnas_afectadas:
		var y_inicio = y_max_global
		while not celdas_borradas.has(Vector2i(x, y_inicio)) and y_inicio > y_max_global - 50:
			y_inicio -= 1
			
		var y = y_inicio - 1
		while true:
			var celda = Vector2i(x, y)
			if celdas_borradas.has(celda):
				y -= 1
				continue
				
			var source_id = capa.get_cell_source_id(celda)
			if source_id != -1:
				if not celda in bloques_a_mover:
					bloques_a_mover.append(celda)
				y -= 1
			else:
				break
				
	# 2. BUCLE DE ANIMACIÓN
	var cayendo = true
	while cayendo:
		cayendo = false
		
		# Ordenamos los bloques de abajo hacia arriba (Para que caigan los de abajo primero y abran paso)
		bloques_a_mover.sort_custom(func(a, b): return a.y > b.y)
		var nuevos_bloques = []
		
		for celda in bloques_a_mover:
			var celda_abajo = Vector2i(celda.x, celda.y + 1)
			var source_id = capa.get_cell_source_id(celda)
			
			# Si el bloque sigue existiendo, el camino hacia abajo está libre, y no se ha caído al infinito
			if source_id != -1 and es_celda_libre(celda_abajo, capa, mapas_colision) and celda.y < y_max_global + 100:
				var atlas = capa.get_cell_atlas_coords(celda)
				
				# Lo movemos un solo cuadro hacia abajo
				capa.set_cell(celda, -1)
				capa.set_cell(celda_abajo, source_id, atlas)
				
				# Actualizamos su memoria para que la pieza siga unida
				if celda in celda_a_pieza:
					var id_p = celda_a_pieza[celda]
					celda_a_pieza.erase(celda)
					celda_a_pieza[celda_abajo] = id_p
					
					if id_p in registro_piezas:
						var celdas_p = registro_piezas[id_p]["celdas"]
						var idx = celdas_p.find(celda)
						if idx != -1:
							celdas_p[idx] = celda_abajo
				
				nuevos_bloques.append(celda_abajo)
				cayendo = true # Como algo se movió, repetiremos el bucle
			else:
				# Chocó con algo, ya no se mueve y se queda en su posición final
				nuevos_bloques.append(celda)
				
		bloques_a_mover = nuevos_bloques
		
		# 3. LA PAUSA VISUAL (Magia de Godot)
		if cayendo:
			# Esperamos 0.05 segundos antes de que bajen el siguiente cuadro
			await get_tree().create_timer(0.05).timeout

func intentar_recuperar_pieza(celda: Vector2i) -> CharacterBody2D:
	if not celda_a_pieza.has(celda): return null
	var id_p = celda_a_pieza[celda]
	
	if not registro_piezas.has(id_p): return null
	var datos = registro_piezas[id_p]
	
	if datos["celdas"].size() < 4: return null
		
	var capa_piezas = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
	if not capa_piezas: return null
	
	for c in datos["celdas"]:
		var celda_arriba = Vector2i(c.x, c.y - 1)
		var source_id = capa_piezas.get_cell_source_id(celda_arriba)
		
		if source_id != -1:
			if not celda_a_pieza.has(celda_arriba) or celda_a_pieza[celda_arriba] != id_p:
				print("Bloqueada: Esta pieza tiene peso encima y no puede ser extraída.")
				return null

	for c in datos["celdas"]:
		capa_piezas.set_cell(c, -1)
		celda_a_pieza.erase(c)
	registro_piezas.erase(id_p)
	
	var escena = load(datos["ruta_escena"])
	if not escena: return null
	
	var nueva_pieza = escena.instantiate()
	var pos_local_mapa = capa_piezas.map_to_local(datos["celdas"][0])
	var pos_celda_global = capa_piezas.to_global(pos_local_mapa)
	
	nueva_pieza.global_position = pos_celda_global + datos["offset_root"]
	nueva_pieza.rotation = datos["rotation"]
	
	capa_piezas.get_parent().add_child(nueva_pieza)
	return nueva_pieza
