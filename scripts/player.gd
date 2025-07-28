extends CharacterBody3D

# Movement constants
const MOVEMENT_SPEED: float = 5.0
const ROTATION_SPEED: float = 5.0
const FRICTION_FACTOR: float = 10.0

# Input action names
const INPUT_STRAFE_LEFT: StringName = &"strafe_left"
const INPUT_STRAFE_RIGHT: StringName = &"strafe_right"
const INPUT_MOVE_FORWARD: StringName = &"move_forward"
const INPUT_MOVE_BACKWARD: StringName = &"move_backward"
const INPUT_LOOK_LEFT: StringName = &"look_left"
const INPUT_LOOK_RIGHT: StringName = &"look_right"

# Player group identifier
const PLAYER_GROUP: StringName = &"player"

# Initialize player
func _ready() -> void:
	_setup_player()

# Setup initial player configuration
func _setup_player() -> void:
	add_to_group(PLAYER_GROUP)

# Handle physics and movement
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_rotation(delta)
	_apply_movement()

# Apply gravity when not on floor
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# Handle player movement input
func _handle_movement(delta: float) -> void:
	var movement_input: Vector2 = _get_movement_input()
	var movement_direction: Vector3 = _calculate_movement_direction(movement_input)
	
	if movement_direction.length() > 0:
		_apply_movement_velocity(movement_direction)
	else:
		_apply_friction(delta)

# Get normalized movement input
func _get_movement_input() -> Vector2:
	return Input.get_vector(
		INPUT_STRAFE_LEFT,
		INPUT_STRAFE_RIGHT,
		INPUT_MOVE_FORWARD,
		INPUT_MOVE_BACKWARD
	)

# Calculate world-space movement direction
func _calculate_movement_direction(input_direction: Vector2) -> Vector3:
	var local_direction: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y)
	return (transform.basis * local_direction).normalized()

# Apply movement velocity
func _apply_movement_velocity(direction: Vector3) -> void:
	velocity.x = direction.x * MOVEMENT_SPEED
	velocity.z = direction.z * MOVEMENT_SPEED

# Apply friction when not moving
func _apply_friction(delta: float) -> void:
	var friction_speed: float = MOVEMENT_SPEED * FRICTION_FACTOR * delta
	velocity.x = move_toward(velocity.x, 0.0, friction_speed)
	velocity.z = move_toward(velocity.z, 0.0, friction_speed)

# Handle player rotation input
func _handle_rotation(delta: float) -> void:
	var rotation_input: float = _get_rotation_input()
	if abs(rotation_input) > 0.0:
		_apply_rotation(rotation_input, delta)

# Get rotation input from user actions
func _get_rotation_input() -> float:
	var rotation_value: float = 0.0
	
	if Input.is_action_pressed(INPUT_LOOK_LEFT):
		rotation_value += 1.0
	
	if Input.is_action_pressed(INPUT_LOOK_RIGHT):
		rotation_value -= 1.0
	
	return rotation_value

# Apply rotation to player
func _apply_rotation(rotation_input: float, delta: float) -> void:
	rotate_y(rotation_input * ROTATION_SPEED * delta)

# Apply final movement
func _apply_movement() -> void:
	move_and_slide()
