extends Control

@onready var boton_continuar: Button = $VBoxContainer/BotonContinuar

func _ready() -> void:
	# Verificamos si existe el archivo que creamos con el SaveManager
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		boton_continuar.disabled = false
	else:
		# Si no hay partida, apagamos el botón para que no pueda presionarlo
		boton_continuar.disabled = true

func _on_boton_nuevo_pressed() -> void:
	SaveManager.borrar_partida()
	if WorldState.scene_states:
		WorldState.scene_states.clear()
	if GameManager:
		GameManager.reiniciar_monedas() 
	get_tree().change_scene_to_file("res://scenes/Nivel1.tscn")

func _on_boton_continuar_pressed() -> void:
	# Aquí usaremos change_scene_to_file para mandarlo a la "Selección de Niveles"
	# Como aún no creamos esa escena, por ahora solo imprimimos un mensaje para probar.
	print("Yendo a Selección de Niveles...")
	get_tree().change_scene_to_file("res://scenes/seleccion_nivel.tscn")

func _on_boton_salir_pressed() -> void:
	get_tree().quit()
