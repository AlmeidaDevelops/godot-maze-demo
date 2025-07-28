extends Node3D

# Game configuration constants
const MAX_LEVEL: int = 5
const STARTING_LEVEL: int = 0

# Scene resources
@export var maze_scene: PackedScene = preload("res://scenes/maze.tscn")

# Game state
var current_level: int = STARTING_LEVEL
var current_maze: Node3D = null

# Signals
signal game_completed
signal level_changed(new_level: int)
signal collectable_collected

# Initialize game
func _ready() -> void:
	start_game()

# Start the game from the first level
func start_game() -> void:
	current_level = STARTING_LEVEL
	generate_new_maze()

# Generate and setup a new maze for the current level
func generate_new_maze() -> void:
	cleanup_current_maze()
	
	if is_game_completed():
		handle_game_completion()
		return
	
	create_maze_instance()
	setup_maze_connections()
	
	level_changed.emit(current_level)
	print("Starting level ", current_level)

# Remove current maze from scene if it exists
func cleanup_current_maze() -> void:
	if current_maze and is_instance_valid(current_maze):
		current_maze.queue_free()
		current_maze = null

# Check if player has completed all levels
func is_game_completed() -> bool:
	return current_level > MAX_LEVEL

# Handle game completion
func handle_game_completion() -> void:
	print("🎉 Game completed! All ", MAX_LEVEL, " levels finished!")
	game_completed.emit()

# Create new maze instance
func create_maze_instance() -> void:
	if not maze_scene:
		push_error("Maze scene not loaded. Cannot create maze instance.")
		return
	
	current_maze = maze_scene.instantiate()
	add_child(current_maze)
	
	# Initialize maze with current level
	if current_maze.has_method("initialize"):
		current_maze.initialize(current_level)
	else:
		push_error("Maze scene doesn't have initialize method")

# Setup connections for maze signals
func setup_maze_connections() -> void:
	if current_maze and current_maze.has_signal("level_completed"):
		current_maze.level_completed.connect(_on_level_completed)
	else:
		push_error("Maze doesn't have level_completed signal")
	
	# Conectar señal de coleccionables correctamente
	if current_maze and current_maze.has_signal("collectable_collected"):
		current_maze.collectable_collected.connect(_on_collectable_collected_in_maze)

# Handle collectable collection in maze
func _on_collectable_collected_in_maze() -> void:
	collectable_collected.emit()

# Handle level completion
func _on_level_completed() -> void:
	print("✅ Level ", current_level, " completed!")
	advance_to_next_level()

# Advance to the next level
func advance_to_next_level() -> void:
	current_level += 1
	generate_new_maze()

# Get current level (public getter)
func get_current_level() -> int:
	return current_level

# Get maximum level (public getter)
func get_max_level() -> int:
	return MAX_LEVEL

# Get collectables info from current maze
func get_collectables_info() -> Dictionary:
	if current_maze and is_instance_valid(current_maze):
		var collected: int = current_maze.collected if "collected" in current_maze else 0
		var total: int = current_maze.total_collectables if "total_collectables" in current_maze else 0
		return {"collected": collected, "total": total}
	return {"collected": 0, "total": 0}

# Get current collected count
func get_collected_count() -> int:
	if current_maze and is_instance_valid(current_maze):
		return current_maze.collected if "collected" in current_maze else 0
	return 0

# Get total collectables count
func get_total_collectables() -> int:
	if current_maze and is_instance_valid(current_maze):
		return current_maze.total_collectables if "total_collectables" in current_maze else 0
	return 0

# Check if game is completed (public method)
func is_game_completed_public() -> bool:
	return is_game_completed()

# Restart game from level 1
func restart_game() -> void:
	print("Restarting game...")
	start_game()

# Skip to specific level (for testing/debugging)
func skip_to_level(level: int) -> void:
	if level < 0 or level > MAX_LEVEL:
		push_error("Invalid level: ", level, ". Must be between 1 and ", MAX_LEVEL)
		return
		
	current_level = level
	generate_new_maze()
	print("Skipped to level ", level)
