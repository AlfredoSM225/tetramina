extends Node

# ¿Cuántos bloques juntos forman una línea en tu mundo abierto?
var bloques_para_linea = 8 

func revisar_lineas_completas():
	var capa_piezas = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
	if not capa_piezas: return
	
	var celdas_usadas = capa_piezas.get_used_cells()
	if celdas_usadas.is_empty(): return
	
	# 1. Agrupamos todas las celdas del mundo por su altura (eje Y)
	var filas = {}
	for celda in celdas_usadas:
		if not filas.has(celda.y):
			filas[celda.y] = []
		filas[celda.y].append(celda.x)
		
	var lineas_a_borrar = []
	
	# 2. Buscamos secuencias horizontales continuas en cualquier rincón del mapa
	for y in filas.keys():
		var columnas = filas[y]
		columnas.sort() # Ordenar de izquierda a derecha
		
		var secuencia = []
		for x in columnas:
			# Si están juntos, los sumamos a la secuencia
			if secuencia.is_empty() or x == secuencia[-1] + 1:
				secuencia.append(x)
			else:
				# Si se cortó la línea, verificamos si era lo suficientemente larga
				if secuencia.size() >= bloques_para_linea:
					lineas_a_borrar.append({"y": y, "xs": secuencia.duplicate()})
				secuencia = [x] # Empezamos una nueva secuencia
		
		# Revisar la última secuencia de la fila
		if secuencia.size() >= bloques_para_linea:
			lineas_a_borrar.append({"y": y, "xs": secuencia.duplicate()})
			
	# 3. Procedemos a destruir y aplicar gravedad
	if lineas_a_borrar.size() > 0:
		var columnas_afectadas = []
		var y_max_borrado = -999999
		
		for linea in lineas_a_borrar:
			if linea["y"] > y_max_borrado: y_max_borrado = linea["y"]
			
			for x in linea["xs"]:
				# Borramos el bloque de cristal
				capa_piezas.set_cell(Vector2i(x, linea["y"]), -1)
				columnas_afectadas.append(x)
				
		# 4. Aplicamos gravedad universal a las columnas que sufrieron cambios
		aplicar_gravedad_universal(capa_piezas, columnas_afectadas, y_max_borrado)
		
		# 5. Si cayeron bloques y formaron OTRA línea nueva (Efecto Combo)
		await get_tree().process_frame
		revisar_lineas_completas()

# Gravedad tipo Tetris que funciona en cualquier terreno
func aplicar_gravedad_universal(capa: TileMapLayer, columnas_afectadas: Array, y_max_global: int):
	var rect = capa.get_used_rect()
	var y_min = rect.position.y
	
	# Filtramos columnas duplicadas
	var xs_unicas = []
	for x in columnas_afectadas:
		if not x in xs_unicas:
			xs_unicas.append(x)
			
	# Para cada columna donde se borró algo, bajamos los bloques flotantes
	for x in xs_unicas:
		# Revisamos la columna de abajo hacia arriba
		for y in range(y_max_global, y_min - 1, -1):
			var celda_actual = Vector2i(x, y)
			
			if capa.get_cell_source_id(celda_actual) == -1: # Si hay un hueco de aire
				# Buscamos el primer cristal que esté encima y lo tiramos aquí
				for y_arriba in range(y - 1, y_min - 1, -1):
					var celda_arriba = Vector2i(x, y_arriba)
					var source_id = capa.get_cell_source_id(celda_arriba)
					
					if source_id != -1:
						var atlas = capa.get_cell_atlas_coords(celda_arriba)
						capa.set_cell(celda_actual, source_id, atlas)
						capa.set_cell(celda_arriba, -1)
						break # Hueco rellenado, pasamos al siguiente
