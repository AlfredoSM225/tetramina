extends Node

const SAVE_PATH = "user://partida_tetramina.json"

# === VARIABLES GLOBALES DE PROGRESO ===
var nivel_maximo_alcanzado: int = 1
var monedas_nivel_1: int = 0
var monedas_nivel_2: int = 0
var monedas_jefe: int = 0

func _ready() -> void:
	# En cuanto el juego arranca, intentamos recordar al jugador
	cargar_partida()

# Toma las variables actuales y las escribe en el disco duro
func guardar_partida() -> void:
	var datos_a_guardar = {
		"nivel_maximo": nivel_maximo_alcanzado,
		"monedas_1": monedas_nivel_1,
		"monedas_2": monedas_nivel_2,
		"monedas_jefe": monedas_jefe
	}
	
	var archivo = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if archivo:
		# Guardamos en formato JSON con una tabulación ("\t") para que sea legible
		archivo.store_string(JSON.stringify(datos_a_guardar, "\t"))
		archivo.close()
		print("Partida guardada con éxito en: ", SAVE_PATH)

# Lee el archivo del disco duro y actualiza las variables
func cargar_partida() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No se encontró partida previa. Iniciando una nueva.")
		return # Mantiene los valores por defecto (Nivel 1, 0 monedas)
		
	var archivo = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if archivo:
		var contenido = archivo.get_as_text()
		archivo.close()
		
		var datos = JSON.parse_string(contenido)
		if datos is Dictionary:
			# Usamos .get("llave", valor_por_defecto) por si en el futuro agregas más niveles
			# y el archivo viejo del jugador no tiene esas llaves aún.
			nivel_maximo_alcanzado = datos.get("nivel_maximo", 1)
			monedas_nivel_1 = datos.get("monedas_1", 0)
			monedas_nivel_2 = datos.get("monedas_2", 0)
			monedas_jefe = datos.get("monedas_jefe", 0)
			print("Partida cargada correctamente.")

# Se llama cuando el jugador presiona "Nuevo Juego" en el Menú Principal
func borrar_partida() -> void:
	nivel_maximo_alcanzado = 1
	monedas_nivel_1 = 0
	monedas_nivel_2 = 0
	monedas_jefe = 0
	
	guardar_partida() # Sobrescribimos el archivo con los ceros
	print("Partida borrada. Empezando de cero.")
