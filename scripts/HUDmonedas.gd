extends Control

@onready var label: Label = $HBoxContainer/Label

func _ready() -> void:
	GameManager.monedas_actualizadas.connect(_on_monedas_actualizadas)
	actualizar_texto(GameManager.monedas_recolectadas)

func _on_monedas_actualizadas(nuevas_monedas: int) -> void:
	actualizar_texto(nuevas_monedas)

func actualizar_texto(cantidad: int) -> void:
	label.text = str(cantidad) + " / " + str(GameManager.total_monedas)
