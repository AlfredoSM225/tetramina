extends CharacterBody2D
class_name Player

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
# Obtiene la gravedad de la configuración de Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variable que define si estamos controlando una pieza
var pieza_controlada: Node2D = null

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

	# === MODO NORMAL (Controles del Jugador) ===
	if not is_on_floor():
		velocity.y += gravity * delta

	# Salto del jugador
	if Input.is_action_just_pressed("Up"):
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
	# Obtiene todas las piezas del nivel (veremos esto en el script de la pieza)
	var piezas = get_tree().get_nodes_in_group("Piezas")
	var pieza_mas_cercana = null
	var distancia_minima = 100.0 # Rango de alcance del poder en píxeles

	for pieza in piezas:
		var dist = global_position.distance_to(pieza.global_position)
		if dist < distancia_minima:
			distancia_minima = dist
			pieza_mas_cercana = pieza

	# Si encontró una pieza cerca, le cedemos el control
	if pieza_mas_cercana != null:
		pieza_controlada = pieza_mas_cercana
		pieza_mas_cercana.activar_control(self)

# Esta función es llamada por la pieza JUSTO después de colocarse
func recuperar_control():
	pieza_controlada = null
