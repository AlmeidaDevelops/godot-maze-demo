extends Node3D

# Signals
signal collected

# Node references
@onready var detection_area: Area3D = $Area3D

# Initialize connections
func _ready() -> void:
	_setup_connections()

# Setup signal connections
func _setup_connections() -> void:
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
	else:
		push_error("Area3D node not found. Make sure the collectable has an Area3D child named 'Area3D'")

# Handle body entering the detection area
func _on_body_entered(body: Node3D) -> void:
	if _is_player(body):
		_collect_item()

# Check if the entering body is a player
func _is_player(body: Node3D) -> bool:
	return body.is_in_group("player")

# Handle item collection
func _collect_item() -> void:
	collected.emit()
	_destroy_collectable()

# Remove the collectable from the scene
func _destroy_collectable() -> void:
	queue_free()
