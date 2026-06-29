extends CharacterBody2D
class_name Player

const SPEED = 200.0
const JUMP_VELOCITY = -300.0
const CLIMB_SPEED = 100.0 # Velocidad al subir y bajar la escalera

@onready var sonido_salto: AudioStreamPlayer = $SonidoSalto
@onready var sonido_muerte: AudioStreamPlayer = $SonidoMuerte
@onready var sonido_recojer: AudioStreamPlayer = $SonidoRecojer
@onready var sonido_error: AudioStreamPlayer = $Error
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Obtiene la gravedad de la configuración de Godot
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Variable que define si estamos controlando una pieza
var pieza_controlada: Node2D = null

# Variables que definen si estamos en una escalera
var esta_en_escalera: bool = false
var escalando: bool = false

func _ready() -> void:
	# Añadimos al grupo "Player" para los sistemas globales
	add_to_group("Player")
	
	# Si ya existía una posición guardada al iniciar la escena, aparecer ahí
	var current_scene_path := get_tree().current_scene.scene_file_path
	if PlayerState.has_position(current_scene_path):
		global_position = PlayerState.get_position(current_scene_path)

func _physics_process(delta):
	# --- ESCUCHAR LA TECLA K PARA REINICIAR EL MUNDO ---
	if Input.is_action_just_pressed("reiniciar_checkpoint"):
		reiniciar_a_checkpoint(true) # True = Regresa piezas y monedas a su lugar
		return

	# === MODO TELEQUINESIS (Jugador IDLE) ===
	if pieza_controlada != null:
		if not is_on_floor():
			velocity.y += gravity * delta
			sprite.play("jump") # Si levita en el aire mientras mueve una pieza
		else:
			sprite.play("idle")
		
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return

	# === MODO ESCALERA (Movimiento Vertical) ===
	if esta_en_escalera:
		if Input.is_action_pressed("Up") or Input.is_action_pressed("Down"):
			escalando = true

	if escalando:
		var dir_horizontal = Input.get_axis("Left", "Right")
		if dir_horizontal != 0:
			velocity.x = dir_horizontal * SPEED
			sprite.flip_h = dir_horizontal < 0
		else:
			velocity.x = 0
		
		var dir_vertical = 0
		if Input.is_action_pressed("Up"):
			
			dir_vertical -= 1
		if Input.is_action_pressed("Down"):
			dir_vertical += 1
			
		if dir_vertical != 0:
			velocity.y = dir_vertical * CLIMB_SPEED
			sprite.play("walk") # O "climb" si tienes una animación específica en el futuro
		else:
			velocity.y = 0
			sprite.play("idle")
			
		# Salto desde la escalera
		if Input.is_action_just_pressed("Jump"):
			escalando = false
			velocity.y = JUMP_VELOCITY
			sprite.play("jump") # Cambia a animación de salto inmediatamente
			if dir_horizontal != 0:
				velocity.x = dir_horizontal * SPEED
		
		if not esta_en_escalera and dir_vertical == 0:
			escalando = false
			
		if dir_horizontal != 0 and not esta_en_escalera:
			escalando = false
		
		move_and_slide()
		return

	# === MODO NORMAL (Controles del Jugador) ===
	if not is_on_floor():
		velocity.y += gravity * delta

	

	if Input.is_action_just_pressed("Jump"):
		# El jugador puede saltar si está en el suelo O si el salto infinito global está activado
		if is_on_floor() or ScriptGlobal.salto_infinito_permitido:
			velocity.y = JUMP_VELOCITY
			if has_node("SonidoSalto"):
				$SonidoSalto.play()

	# Movimiento horizontal y lógica de animaciones combinada
	var direction = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# --- CONTROLADOR CENTRAL DE ANIMACIONES ESTÁNDAR ---
	if not is_on_floor():
		sprite.play("jump") # Prioridad absoluta: si está en el aire, muestra jump
	else:
		if direction != 0:
			sprite.play("walk")
		else:
			sprite.play("idle")

	move_and_slide()

# Detecta cuando presionas la tecla de interactuar
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interactuar"):
		if pieza_controlada == null:
			buscar_y_controlar_pieza()


# Busca la pieza más cercana en la cueva
func buscar_y_controlar_pieza():
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
		sonido_recojer.play()
		return
	
	var mapa = get_tree().get_first_node_in_group("CapaPiezas") as TileMapLayer
	if mapa:
		var pos_local_jugador = mapa.to_local(global_position)
		var pos_mapa_jugador = mapa.local_to_map(pos_local_jugador)
		
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				var celda_revisar = pos_mapa_jugador + Vector2i(dx, dy)
				var pieza_revivida = ScriptGlobal.intentar_recuperar_pieza(celda_revisar)
				
				if pieza_revivida:
					escalando = false
					pieza_controlada = pieza_revivida
					await get_tree().process_frame
					pieza_revivida.activar_control(self)
					sonido_recojer.play()
					return
		if pieza_controlada == null:
			sonido_error.play()

func recuperar_control():
	pieza_controlada = null

func set_en_escalera(valor: bool) -> void:
	esta_en_escalera = valor
	if not valor and velocity.y == 0:
		escalando = false

# --- FUNCIONES DEL SISTEMA DE CHECKPOINTS ---

func morir() -> void:
	var menu_pausa = get_tree().current_scene.get_node_or_null("MenuPausa")
	
	if menu_pausa and menu_pausa.has_method("mostrar_pantalla_muerte"):
		# Si existe el menú, disparamos la pantalla roja de Game Over
		menu_pausa.mostrar_pantalla_muerte()
	else:
		# Sistema de respaldo por si olvidaste poner el menú en algún nivel
		reiniciar_a_checkpoint(false)

func reiniciar_a_checkpoint(restaurar_mundo: bool) -> void:
	var current_scene_path := get_tree().current_scene.scene_file_path
	
	if pieza_controlada != null:
		if pieza_controlada.has_method("desactivar_control"):
			pieza_controlada.desactivar_control()
		pieza_controlada = null
	
	if PlayerState.has_position(current_scene_path):
		global_position = PlayerState.get_position(current_scene_path)
		if restaurar_mundo:
			get_tree().call_group("Reseteables", "cargar_estado_de_checkpoint")
	else:
		get_tree().reload_current_scene()
		return

	escalando = false
	velocity = Vector2.ZERO
