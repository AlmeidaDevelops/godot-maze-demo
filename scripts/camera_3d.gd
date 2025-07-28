extends Camera3D

# Configuración de movimiento
@export var speed: float = 5.0
@export var fast_speed: float = 15.0
@export var mouse_sensitivity: float = 0.002
@export var smooth_movement: bool = true
@export var smooth_factor: float = 10.0

# Variables internas
var velocity: Vector3 = Vector3.ZERO
var mouse_locked: bool = false

# Rotación de la cámara
var pitch: float = 0.0
var yaw: float = 0.0

func _ready() -> void:
	# Capturar el mouse al inicio (opcional)
	capture_mouse()

func _input(event: InputEvent) -> void:
	# Alternar captura del mouse con ESC
	if event.is_action_pressed("ui_cancel"):
		toggle_mouse_capture()
	
	# Movimiento del mouse para rotar la cámara
	if event is InputEventMouseMotion and mouse_locked:
		handle_mouse_look(event.relative)

func _process(delta: float) -> void:
	if mouse_locked:
		handle_movement(delta)

func handle_mouse_look(relative_motion: Vector2) -> void:
	# Actualizar yaw (rotación horizontal) y pitch (rotación vertical)
	yaw -= relative_motion.x * mouse_sensitivity
	pitch -= relative_motion.y * mouse_sensitivity
	
	# Limitar el pitch para evitar que la cámara se voltee completamente
	pitch = clamp(pitch, -PI/2 + 0.01, PI/2 - 0.01)
	
	# Aplicar la rotación
	transform.basis = Basis()
	rotate_object_local(Vector3.UP, yaw)
	rotate_object_local(Vector3.RIGHT, pitch)

func handle_movement(delta: float) -> void:
	var input_vector = Vector3.ZERO
	var current_speed = speed
	
	# Verificar si se presiona Accept para velocidad rápida
	if Input.is_action_pressed("ui_accept"):
		current_speed = fast_speed
	
	# Movimiento con las flechas direccionales
	if Input.is_action_pressed("ui_up"):
		input_vector -= transform.basis.z  # Adelante
	if Input.is_action_pressed("ui_down"):
		input_vector += transform.basis.z   # Atrás
	if Input.is_action_pressed("ui_left"):
		input_vector -= transform.basis.x   # Izquierda
	if Input.is_action_pressed("ui_right"):
		input_vector += transform.basis.x   # Derecha
	
	# Movimiento vertical usando Page Up/Down o Select/Cancel
	if Input.is_action_pressed("ui_page_up"):
		input_vector += Vector3.UP
	if Input.is_action_pressed("ui_page_down"):
		input_vector += Vector3.DOWN
	
	# Normalizar el vector de entrada para evitar movimiento más rápido en diagonal
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	
	# Aplicar movimiento
	if smooth_movement:
		# Movimiento suave con interpolación
		velocity = velocity.lerp(input_vector * current_speed, smooth_factor * delta)
		global_translate(velocity * delta)
	else:
		# Movimiento directo
		global_translate(input_vector * current_speed * delta)

func capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_locked = true

func release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_locked = false

func toggle_mouse_capture() -> void:
	if mouse_locked:
		release_mouse()
	else:
		capture_mouse()

# Función para resetear la posición y rotación de la cámara
func reset_camera() -> void:
	global_position = Vector3.ZERO
	pitch = 0.0
	yaw = 0.0
	transform.basis = Basis()
	velocity = Vector3.ZERO
