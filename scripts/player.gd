extends CharacterBody2D
class_name Player

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const CLIMB_SPEED = 100.0 # Velocidad al subir y bajar la escalera

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Obtiene la gravedad de la configuración de Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variable que define si estamos controlando una pieza
var pieza_controlada: Node2D = null

# Variables que definen si estamos en una escalera
var esta_en_escalera: bool = false
var escalando: bool = false

func _ready() -> void:
	add_to_group("jugador")

func _physics_process(delta):
	# === MODO TELEQUINESIS (Jugador IDLE) ===
	if pieza_controlada != null:
		# Si activaste el poder en el aire, el personaje debe caer al suelo
		if not is_on_floor():
			velocity.y += gravity * delta
		
		# Frena el movimiento horizontal poco a poco
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		
		sprite.play("IDLE")
		return # Detiene la ejecución para que no lea los controles normales

	# === MODO ESCALERA (Movimiento Vertical) ===
	if esta_en_escalera:
		# Detecta si el jugador quiere empezar a subir o bajar con tus inputs
		if Input.is_action_pressed("Up") or Input.is_action_pressed("Down"):
			escalando = true

	if escalando:
		# Permite movimiento horizontal en la escalera
		var dir_horizontal = Input.get_axis("Left", "Right")
		if dir_horizontal != 0:
			velocity.x = dir_horizontal * SPEED
		else:
			velocity.x = 0
		
		# Movimiento vertical en la escalera usando tus inputs mapeados
		var dir_vertical = 0
		if Input.is_action_pressed("Up"):
			dir_vertical -= 1
		if Input.is_action_pressed("Down"):
			dir_vertical += 1
			
		if dir_vertical != 0:
			velocity.y = dir_vertical * CLIMB_SPEED
		else:
			# Forzamos una velocidad casi nula pero estable para que no fluctúe en los bordes
			velocity.y = 0
			
		# Permite saltar en cualquier dirección estando en la escalera
		if Input.is_action_just_pressed("Jump"):
			escalando = false
			velocity.y = JUMP_VELOCITY
			if dir_horizontal != 0:
				velocity.x = dir_horizontal * SPEED
		
		# Margen de seguridad para pasar entre celdas o soltarse a los lados
		if not esta_en_escalera and dir_vertical == 0:
			escalando = false
			
		if dir_horizontal != 0 and not esta_en_escalera:
			escalando = false
		
		move_and_slide()
		return # Detiene la ejecución para ignorar las físicas normales

	# === MODO NORMAL (Controles del Jugador) ===
	if not is_on_floor():
		velocity.y += gravity * delta

	# Salto del jugador
	if Input.is_action_just_pressed("Jump"):
		velocity.y = JUMP_VELOCITY

	# Movimiento horizontal
	var direction = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
		sprite.play("Walk")
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		sprite.play("IDLE")

	move_and_slide()

# Detecta cuando presionas la tecla de interactuar
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		if pieza_controlada == null:
			buscar_y_controlar_pieza()

# Busca la pieza más cercana en la cueva
func buscar_y_controlar_pieza():
	# 1. Buscar piezas físicas sueltas
	var piezas = get_tree().get_nodes_in_group("Piezas")
	var pieza_mas_cercana = null
	var distancia_minima = 100.0

	for pieza in piezas:
		var dist = global_position.distance_to(pieza.global_position)
		if dist < distancia_minima:
			distancia_minima = dist
			pieza_mas_cercana = pieza

	if pieza_mas_cercana != null:
		escalando = false
		pieza_controlada = pieza_mas_cercana
		pieza_mas_cercana.activar_control(self)
		return
		
	# 2. Si no hay piezas físicas, intentar arrancar una del mapa
	var mapa = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
	if mapa:
		var pos_local_jugador = mapa.to_local(global_position)
		var pos_mapa_jugador = mapa.local_to_map(pos_local_jugador)
		
		# Escanear un rango de 2 celdas alrededor del jugador
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var celda_revisar = pos_mapa_jugador + Vector2i(dx, dy)
				var pieza_revivida = ScriptGlobal.intentar_recuperar_pieza(celda_revisar)
				
				if pieza_revivida:
					escalando = false
					pieza_controlada = pieza_revivida
					# Esperamos a que Godot la dibuje para no causar un bug de físicas
					await get_tree().process_frame
					pieza_revivida.activar_control(self)
					return

# Esta función es llamada por la pieza JUSTO después de colocarse
func recuperar_control():
	pieza_controlada = null

# Cambia el estado de la escalera desde el Area2D
func set_en_escalera(valor: bool) -> void:
	esta_en_escalera = valor
	if not valor and velocity.y == 0:
		escalando = false
