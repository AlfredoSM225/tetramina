extends Control

# Referencias a los botones y etiquetas (Asegúrate de que los nombres coincidan con los tuyos)
@onready var btn_nivel_1: Button = $HBoxContainer/Nivel1/BotonNivel1
@onready var lbl_monedas_1: Label = $HBoxContainer/Nivel1/LabelMonedas1

@onready var btn_nivel_2: Button = $HBoxContainer/Nivel2/BotonNivel2
@onready var lbl_monedas_2: Label = $HBoxContainer/Nivel2/LabelMonedas2

@onready var btn_jefe: Button = $HBoxContainer/Jefe/BotonJefe

func _ready() -> void:
	# El control del mando empieza en el nivel 1
	btn_nivel_1.grab_focus()
	
	# === CONFIGURAR NIVEL 1 (Siempre desbloqueado) ===
	lbl_monedas_1.text = "Monedas: " + str(SaveManager.monedas_nivel_1) + "/3"
	
	# === CONFIGURAR NIVEL 2 ===
	lbl_monedas_2.text = "Monedas: " + str(SaveManager.monedas_nivel_2) + "/3"
	if SaveManager.nivel_maximo_alcanzado >= 2:
		btn_nivel_2.disabled = false
	else:
		btn_nivel_2.disabled = true
		
	# === CONFIGURAR JEFE FINAL ===
	if SaveManager.nivel_maximo_alcanzado >= 3:
		btn_jefe.disabled = false
	else:
		btn_jefe.disabled = true

func preparar_nivel_nuevo() -> void:
	if WorldState.scene_states:
		WorldState.scene_states.clear()
	if GameManager:
		GameManager.reiniciar_monedas()

func _on_boton_nivel_1_pressed() -> void:
	preparar_nivel_nuevo()
	get_tree().change_scene_to_file("res://scenes/Nivel1.tscn")

func _on_boton_nivel_2_pressed() -> void:
	preparar_nivel_nuevo()
	get_tree().change_scene_to_file("res://scenes/Nivel2.tscn")

func _on_boton_jefe_pressed() -> void:
	preparar_nivel_nuevo()
	get_tree().change_scene_to_file("res://scenes/Jefe.tscn")

func _on_boton_regresar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")
