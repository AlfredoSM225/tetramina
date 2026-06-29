extends Node

signal monedas_actualizadas

var monedas_recolectadas: int = 0
var total_monedas: int = 3

func contar_moneda() -> void:
	monedas_recolectadas += 1
	monedas_actualizadas.emit(monedas_recolectadas)
	if monedas_recolectadas == total_monedas:
		print("¡Nivel completado!")

func reiniciar_monedas() -> void:
	monedas_recolectadas = 0
	monedas_actualizadas.emit(monedas_recolectadas)
