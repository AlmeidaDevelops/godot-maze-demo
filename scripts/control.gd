extends Control

# UI Node references
@onready var level_label: Label = $level
@onready var collectables_label: Label = $collectables
@onready var controls_label: Label = $controls
@onready var end_label: Label = $end

# Game manager reference
var game_manager: Node3D

# UI text templates
const LEVEL_TEXT_TEMPLATE: String = "🎯 Level %d/%d"
const COLLECTABLES_TEXT_TEMPLATE: String = "💎 Collected: %d/%d"
const CONTROLS_TEXT: String = """🎮 Controls:
WASD - Move
← → - Turn
Collect all gems to advance!"""
const GAME_COMPLETED_TEXT: String = """🎉 Congratulations! 🎉
You completed all levels!

🏆 GAME FINISHED! 🏆

Press R to restart"""

func _ready() -> void:
	_setup_ui()
	_find_game_manager()

# Setup initial UI configuration
func _setup_ui() -> void:
	_setup_controls_label()
	_hide_end_screen()
	_setup_initial_labels()

# Setup the controls label (always visible, never changes)
func _setup_controls_label() -> void:
	if controls_label:
		controls_label.text = CONTROLS_TEXT
		controls_label.visible = true

# Hide the end screen initially
func _hide_end_screen() -> void:
	if end_label:
		end_label.visible = false

# Setup initial label states
func _setup_initial_labels() -> void:
	_update_level_display(1, 5)
	_update_collectables_display(0, 0)

# Find and connect to game manager
func _find_game_manager() -> void:
	# Try to find game manager in parent nodes
	var parent: Node = get_parent()
	while parent:
		if parent.has_method("get_current_level"):
			game_manager = parent
			_connect_game_manager_signals()
			_update_ui_from_game_manager()
			break
		parent = parent.get_parent()
	
	if not game_manager:
		push_warning("Game manager not found. UI will use default values.")

# Connect to game manager signals
func _connect_game_manager_signals() -> void:
	if game_manager.has_signal("level_changed"):
		game_manager.level_changed.connect(_on_level_changed)
	
	if game_manager.has_signal("game_completed"):
		game_manager.game_completed.connect(_on_game_completed)
	
	if game_manager.has_signal("collectable_collected"):
		game_manager.collectable_collected.connect(_on_collectable_collected)
		print("Connected to GameManager collectable_collected signal")

# Update UI from current game manager state
func _update_ui_from_game_manager() -> void:
	if game_manager:
		var current_level: int = game_manager.get_current_level()
		var max_level: int = game_manager.get_max_level()
		_update_level_display(current_level, max_level)
		_update_collectables_from_game_manager()

# Handle input for restarting game
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_R and event.pressed:
		if end_label and end_label.visible and game_manager:
			if game_manager.has_method("restart_game"):
				game_manager.restart_game()
				_hide_end_screen()

# Update level display
func _update_level_display(display_level: int, max_level: int) -> void:
	if level_label:
		level_label.text = LEVEL_TEXT_TEMPLATE % [display_level, max_level]

# Update collectables display
func _update_collectables_display(collected: int, total: int) -> void:
	if collectables_label:
		collectables_label.text = COLLECTABLES_TEXT_TEMPLATE % [collected, total]

# Handle level change
func _on_level_changed(new_level: int) -> void:
	var max_level: int = game_manager.get_max_level() if game_manager else 5
	_update_level_display(new_level, max_level)
	_update_collectables_display(0, 0)  # Reset collectables for new level
	
	# Wait a frame for maze to be created, then update collectables
	await get_tree().process_frame
	_update_collectables_from_game_manager()

# Update collectables from GameManager (MÉTODO SIMPLIFICADO)
func _update_collectables_from_game_manager() -> void:
	if game_manager and game_manager.has_method("get_collectables_info"):
		var info: Dictionary = game_manager.get_collectables_info()
		_update_collectables_display(info.collected, info.total)
		print("Updated collectables: ", info.collected, "/", info.total)
	else:
		print("GameManager not found or missing get_collectables_info method")

# Handle collectable collection
func _on_collectable_collected() -> void:
	print("Collectable collected signal received in UI")
	_update_collectables_from_game_manager()

# Handle game completion
func _on_game_completed() -> void:
	_show_end_screen()

# Show the end screen
func _show_end_screen() -> void:
	if end_label:
		end_label.text = GAME_COMPLETED_TEXT
		end_label.visible = true
