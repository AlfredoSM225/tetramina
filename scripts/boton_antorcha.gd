extends StaticBody2D

# Variables exportadas para conectar en el Inspector de tu nivel principal
@export var puerta_objetivo: Node2D
@export var antorcha_sprite: Node2D # Flexible (acepta nodos o escenas instanciadas)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var pesos_encima: int = 0
var esta_presionado: bool = false

func _ready() -> void:
	# Estado inicial visual del botón usando tus nuevas animaciones
	sprite.play("A-Unpressed")
	
	# Asegura que la antorcha empiece apagada al iniciar el nivel si está asignada
	var anim_inicial = obtener_animated_sprite(antorcha_sprite)
	if anim_inicial:
		anim_inicial.play("apagada")

	# Conectamos las señales de la Area2D hija por código automáticamente
	if has_node("Area2D"):
		var area = $Area2D
		area.body_entered.connect(_on_area_2d_body_entered)
		area.body_exited.connect(_on_area_2d_body_exited)
	else:
		push_error("Error: No se encontró el nodo Area2D dentro de button_floor.")

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Detecta tanto al robot como a los bloques de Tetris que empujes
	if body.is_in_group("Player") or body.is_in_group("Piezas"):
		pesos_encima += 1
		evaluar_estado()

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("Piezas"):
		pesos_encima -= 1
		if pesos_encima < 0: 
			pesos_encima = 0
		evaluar_estado()

func evaluar_estado() -> void:
	var deberia_presionarse = pesos_encima > 0
	
	# Cambia de estado solo si es necesario para evitar reiniciar animaciones en bucle
	if deberia_presionarse != esta_presionado:
		esta_presionado = deberia_presionarse
		
		# Intentamos obtener el AnimatedSprite2D de la antorcha asignada
		var anim_antorcha = obtener_animated_sprite(antorcha_sprite)
		
		if esta_presionado:
			sprite.play("A-Pressed")
			if anim_antorcha:
				anim_antorcha.play("encendida")
			
			# Suma un botón al contador de la puerta del puzle
			if puerta_objetivo and puerta_objetivo.has_method("registrar_boton_encendido"):
				puerta_objetivo.registrar_boton_encendido()
		else:
			sprite.play("A-Unpressed")
			if anim_antorcha:
				anim_antorcha.play("apagada")
				
			# Resta un botón al contador de la puerta del puzle
			if puerta_objetivo and puerta_objetivo.has_method("registrar_boton_apagado"):
				puerta_objetivo.registrar_boton_apagado()

# Función auxiliar segura para extraer el AnimatedSprite2D sin importar cómo estructuraste la antorcha
func obtener_animated_sprite(nodo: Node2D) -> AnimatedSprite2D:
	if nodo == null:
		return null
	if nodo is AnimatedSprite2D:
		return nodo
	return nodo.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
