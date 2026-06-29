extends StaticBody2D

@export var puerta_objetivo: Node2D
@export var antorcha_sprite: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area: Area2D = $Area2D

var pesos_encima: int = 0
var esta_presionado: bool = false

func _ready() -> void:
	# Estado inicial visual del botón
	sprite.play("A-Unpressed")
	
	# Asegura que la antorcha empiece apagada al iniciar el nivel
	var anim_inicial = obtener_animated_sprite(antorcha_sprite)
	if anim_inicial:
		anim_inicial.play("apagada")

	# Conectamos las señales de la Area2D hija automáticamente
	if has_node("Area2D"):
		area.body_entered.connect(_on_area_2d_body_entered)
		area.body_exited.connect(_on_area_2d_body_exited)
	else:
		push_error("Error: No se encontró el nodo Area2D dentro de button_floor.")

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Detecta tanto al jugador como a las piezas físicas mientras caen o se empujan
	if body.is_in_group("Player") or body.is_in_group("Piezas") or body.is_in_group("Reseteables"):
		pesos_encima += 1

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("Piezas") or body.is_in_group("Reseteables"):
		pesos_encima -= 1
		if pesos_encima < 0: 
			pesos_encima = 0

func _physics_process(delta: float) -> void:
	# Verificamos primero si hay cuerpos físicos encima
	var hay_peso_ahora = pesos_encima > 0
	
	if not hay_peso_ahora:
		var pos_arriba = global_position + Vector2(0, -24) 
		
		var mapa_piezas = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
		if mapa_piezas:
			var celda = mapa_piezas.local_to_map(mapa_piezas.to_local(pos_arriba))
			
			if mapa_piezas.get_cell_source_id(celda) != -1:
				hay_peso_ahora = true

	#Cambio de animación de antorcha
	if hay_peso_ahora != esta_presionado:
		esta_presionado = hay_peso_ahora
		var anim_antorcha = obtener_animated_sprite(antorcha_sprite)
		
		if esta_presionado:
			sprite.play("A-Pressed")
			if anim_antorcha:
				anim_antorcha.play("encendida")
			
			if puerta_objetivo and puerta_objetivo.has_method("registrar_boton_encendido"):
				puerta_objetivo.registrar_boton_encendido()
			print("Botón de antorcha ACTIVADO.")
		else:
			sprite.play("A-Unpressed")
			if anim_antorcha:
				anim_antorcha.play("apagada")
				
			if puerta_objetivo and puerta_objetivo.has_method("registrar_boton_apagado"):
				puerta_objetivo.registrar_boton_apagado()
			print("Botón de antorcha DESACTIVADO.")

# Función auxiliar para extraer el AnimatedSprite2D de la antorcha
func obtener_animated_sprite(nodo: Node2D) -> AnimatedSprite2D:
	if nodo == null: 
		return null
	if nodo is AnimatedSprite2D: 
		return nodo
	return nodo.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
