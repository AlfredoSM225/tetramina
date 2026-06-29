extends CanvasLayer

@onready var panel_menu: Control = $Control
@onready var lbl_titulo: Label = $Control/VBoxContainer/LabelTitulo
@onready var btn_continuar: Button = $Control/VBoxContainer/BotonContinuar
@onready var btn_reiniciar: Button = $Control/VBoxContainer/BotonReiniciar

var esta_muerto: bool = false

func _ready() -> void:
	# El menú siempre arranca escondido
	panel_menu.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not esta_muerto:
		if get_tree().paused:
			reanudar_juego()
		else:
			pausar_juego()

func pausar_juego() -> void:
	get_tree().paused = true
	panel_menu.show()
	lbl_titulo.text = "PAUSA"
	btn_continuar.show()
	btn_continuar.grab_focus() 

func reanudar_juego() -> void:
	get_tree().paused = false
	panel_menu.hide()

# Esta función la llamaremos desde el script del jugador cuando muera
func mostrar_pantalla_muerte() -> void:
	esta_muerto = true
	get_tree().paused = true
	panel_menu.show()
	lbl_titulo.text = "HAS MUERTO"
	
	btn_continuar.hide() 
	btn_reiniciar.grab_focus()

func limpiar_progreso_temporal() -> void:
	if WorldState.scene_states:
		WorldState.scene_states.clear()
	if GameManager:
		GameManager.reiniciar_monedas() # <--- Cambio aquí

# === SEÑALES DE LOS BOTONES ===
func _on_boton_continuar_pressed() -> void:
	reanudar_juego()

func _on_boton_reiniciar_pressed() -> void:
	get_tree().paused = false # Quitamos la pausa ANTES de reiniciar
	limpiar_progreso_temporal()
	get_tree().reload_current_scene()

func _on_boton_salir_pressed() -> void:
	get_tree().paused = false # Quitamos la pausa ANTES de salir
	limpiar_progreso_temporal()
	get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")
