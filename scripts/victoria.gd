extends Control


@onready var titulo: Label = $ContenedorStats/LabelTitulo
@onready var lbl_nivel1: Label = $ContenedorStats/LabelNivel1
@onready var lbl_nivel2: Label = $ContenedorStats/LabelNivel2

@onready var label_creditos: Label = $LabelCreditos
@onready var btn_volver: Button = $BotonVolver

var rodando_creditos: bool = false
var velocidad_creditos: float = 60.0 # Píxeles por segundo

func _ready() -> void:
	# 1. Escondemos el botón al principio
	btn_volver.hide()
	
	# 2. Actualizamos las estadísticas leyendo tu SaveManager
	lbl_nivel1.text = "Monedas Nivel 1: " + str(SaveManager.monedas_nivel_1) + " / 3"
	lbl_nivel2.text = "Monedas Nivel 2: " + str(SaveManager.monedas_nivel_2) + " / 3"
	
	# 3. Preparamos los créditos (Los mandamos al fondo de la pantalla, fuera de la vista)
	label_creditos.position.y = get_viewport_rect().size.y
	
	# 4. Esperamos 3 segundos para que el jugador lea sus estadísticas, y empezamos a rodar
	await get_tree().create_timer(3.0).timeout
	rodando_creditos = true
	titulo.hide()
	lbl_nivel1.hide()
	lbl_nivel2.hide()
	

func _process(delta: float) -> void:
	if rodando_creditos:
		# Movemos los créditos hacia arriba
		label_creditos.position.y -= velocidad_creditos * delta
		
		# Si los créditos ya subieron por completo y salieron por arriba de la pantalla:
		if label_creditos.position.y < -label_creditos.size.y:
			rodando_creditos = false
			mostrar_boton()
			
func _unhandled_input(event: InputEvent) -> void:
	# Un pequeño truco: Si el jugador presiona ESC, Enter o el botón de saltar, cortamos los créditos
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if rodando_creditos:
			rodando_creditos = false
			label_creditos.hide() # Escondemos los créditos
			mostrar_boton()

func mostrar_boton() -> void:
	btn_volver.show()
	btn_volver.grab_focus() # Importante para que el mando lo seleccione

func _on_boton_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu_principal.tscn")
