extends Node

var bloques_para_linea = 8 

# === MEMORIA DE PIEZAS ===
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
		
		# Recopilamos todos los mapas sólidos (Tu cueva, paredes, etc.) ignorando los fondos sin físicas
		var mapas_colision = []
		if get_tree().current_scene:
			var todos_tilemaps = get_tree().current_scene.find_children("*", "TileMapLayer", true, false)
			for tm in todos_tilemaps:
				if tm != capa_piezas and tm.tile_set != null:
					# Si tiene físicas, significa que es un muro o suelo real
					if tm.tile_set.get_physics_layers_count() > 0:
						mapas_colision.append(tm)
		
		aplicar_gravedad_aislada(capa_piezas, columnas_afectadas, y_max_borrado, celdas_borradas, mapas_colision)
		await get_tree().process_frame
		revisar_lineas_completas()

# === NUEVO RADAR: Verifica si una celda está vacía tanto en el Tetris como en la Cueva ===
func es_celda_libre(coord: Vector2i, capa_piezas: TileMapLayer, mapas_colision: Array) -> bool:
	if capa_piezas.get_cell_source_id(coord) != -1:
		return false
		
	var global_pos = capa_piezas.to_global(capa_piezas.map_to_local(coord))
	for tm in mapas_colision:
		var tm_local = tm.to_local(global_pos)
		var tm_cell = tm.local_to_map(tm_local)
		
		if tm.get_cell_source_id(tm_cell) != -1:
			return false
			
	return true

# === LA NUEVA GRAVEDAD PROFUNDA ===
func aplicar_gravedad_aislada(capa: TileMapLayer, columnas_afectadas: Array, y_max_global: int, celdas_borradas: Dictionary, mapas_colision: Array):
	for x in columnas_afectadas:
		var y_inicio = y_max_global
		while not celdas_borradas.has(Vector2i(x, y_inicio)) and y_inicio > y_max_global - 50:
			y_inicio -= 1
			
		var y = y_inicio - 1
		var bloques_a_mover = []
		
		# 1. RASTREAR LA CADENA: Recolectamos todos los bloques que estaban apoyados en la explosión
		while true:
			var celda = Vector2i(x, y)
			if celdas_borradas.has(celda):
				y -= 1
				continue
				
			var source_id = capa.get_cell_source_id(celda)
			if source_id != -1:
				bloques_a_mover.append(celda)
				y -= 1
			else:
				# Si tocamos aire, rompemos la cadena. ¡Las piezas flotantes lejanas están a salvo!
				break
				
		# 2. CAÍDA LIBRE: Soltamos los bloques recolectados para que caigan al vacío
		for celda_origen in bloques_a_mover:
			var source_id = capa.get_cell_source_id(celda_origen)
			var atlas = capa.get_cell_atlas_coords(celda_origen)
			
			# Lo borramos un milisegundo para que no estorbe su propia caída
			capa.set_cell(celda_origen, -1)
			
			var celda_destino = celda_origen
			# Mientras la celda de abajo esté libre de piezas y de cueva, sigue cayendo
			while es_celda_libre(Vector2i(celda_destino.x, celda_destino.y + 1), capa, mapas_colision) and celda_destino.y < celda_origen.y + 100:
				celda_destino.y += 1
				
			capa.set_cell(celda_destino, source_id, atlas)
			
			# 3. Actualizamos la memoria para que sigan siendo seleccionables (Si no perdieron piezas)
			if celda_destino != celda_origen:
				if celda_origen in celda_a_pieza:
					var id_p = celda_a_pieza[celda_origen]
					celda_a_pieza.erase(celda_origen)
					celda_a_pieza[celda_destino] = id_p
					
					if id_p in registro_piezas:
						var celdas_p = registro_piezas[id_p]["celdas"]
						var idx = celdas_p.find(celda_origen)
						if idx != -1:
							celdas_p[idx] = celda_destino

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
