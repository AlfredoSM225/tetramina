extends Node2D

# Esta variable debe tener el mismo número que le pusiste al Jefe
@export var lineas_para_vencer: int = 5
var lineas_actuales: int = 0

@onready var texto_label: Label = $Label

func _ready() -> void:
	# Escribimos el texto inicial (0/5) apenas carga el nivel
	actualizar_texto()
	
	# Conectamos este letrero directamente a la señal global de las piezas
	if ScriptGlobal.has_signal("lineas_borradas"):
		ScriptGlobal.lineas_borradas.connect(_on_jugador_hace_linea)

func _on_jugador_hace_linea(cantidad: int) -> void:
	lineas_actuales += cantidad
	
	# Evitamos que el contador sobrepase el límite máximo
	if lineas_actuales > lineas_para_vencer:
		lineas_actuales = lineas_para_vencer 
		
	actualizar_texto()
	
	# Si ya llegamos a la meta, desconectamos el letrero para que no siga contando
	if lineas_actuales == lineas_para_vencer:
		if ScriptGlobal.lineas_borradas.is_connected(_on_jugador_hace_linea):
			ScriptGlobal.lineas_borradas.disconnect(_on_jugador_hace_linea)

func actualizar_texto() -> void:
	if lineas_actuales >= lineas_para_vencer:
		texto_label.text = "¡JEFE\nDERROTADO!"
		texto_label.modulate = Color(0, 1, 0) # Pinta las letras de verde al ganar
	else:
		texto_label.text = "DAÑO AL JEFE:\n" + str(lineas_actuales) + " / " + str(lineas_para_vencer)
