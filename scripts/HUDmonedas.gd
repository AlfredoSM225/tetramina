extends Control

@onready var label: Label = $HBoxContainer/Label

func _ready() -> void:
	# === RESETEO DE MONEDAS AL CAMBIAR DE NIVEL ===
	GameManager.monedas_recolectadas = 0
	# Nota: Si en el Nivel 2 cambia el total de monedas, recuerda actualizar 
	# también GameManager.total_monedas = (el número del nuevo nivel)
	
	GameManager.monedas_actualizadas.connect(_on_monedas_actualizadas)
	actualizar_texto(GameManager.monedas_recolectadas)

func _on_monedas_actualizadas(nuevas_monedas: int) -> void:
	actualizar_texto(nuevas_monedas)

func actualizar_texto(cantidad: int) -> void:
	label.text = str(cantidad) + " / " + str(GameManager.total_monedas)
