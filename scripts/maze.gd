extends Node3D

# Constants
const BASE_SIZE: int = 5
const SIZE_MULTIPLIER: int = 2

# Exported variables
@export var level: int = 1

# Scene resources
@export var player_scene: PackedScene = preload("res://scenes/player.tscn")
@export var collectable_scene: PackedScene = preload("res://scenes/collectable.tscn")
@export var wall_scene: PackedScene = preload("res://scenes/wall.tscn")
@export var column_scene: PackedScene = preload("res://scenes/column.tscn")
@export var path_scene: PackedScene = preload("res://scenes/path.tscn")

# Game state
var total_collectables: int = 0
var collected: int = 0

# Signals
signal level_completed
signal collectable_collected

# Cell types enumeration
enum CellType {
	PATH,
	HORIZONTAL_WALL,
	VERTICAL_WALL,
	FIXED_COLUMN,
	SPAWN_PLAYER,
	SPAWN_COLLECTABLE
}

# Maze generation data structure
class MazeData:
	var real_width: int
	var real_height: int
	var logical_core_width: int
	var logical_core_height: int
	var maze_paths: Array[Array]
	var removed_walls: Array
	var player_spawn: Vector2i
	var collectables_spawn: Array[Vector2i]
	
	func _init(width: int, height: int, core_width: int, core_height: int):
		real_width = width
		real_height = height
		logical_core_width = core_width
		logical_core_height = core_height
		maze_paths = []
		removed_walls = []
		player_spawn = Vector2i(-1, -1)
		collectables_spawn = []

# Generate odd size based on level
func _generate_odd_size(current_level: int) -> int:
	return SIZE_MULTIPLIER * current_level + BASE_SIZE

# Depth-First Search maze generation algorithm
func _generate_maze_dfs(logical_x: int, logical_y: int, logical_core_width: int, 
					   logical_core_height: int, maze_paths: Array[Array], 
					   removed_walls: Array, rng: RandomNumberGenerator) -> void:
	maze_paths[logical_y][logical_x] = true
	
	var directions: Array[Vector2i] = [
		Vector2i(0, -1),  # North
		Vector2i(0, 1),   # South
		Vector2i(-1, 0),  # West
		Vector2i(1, 0)    # East
	]
	
	directions.shuffle()
	
	for direction in directions:
		var next_x: int = logical_x + direction.x
		var next_y: int = logical_y + direction.y
		
		if _is_valid_cell(next_x, next_y, logical_core_width, logical_core_height) and \
		   not maze_paths[next_y][next_x]:
			
			var current_cell: Vector2i = Vector2i(logical_x, logical_y)
			var next_cell: Vector2i = Vector2i(next_x, next_y)
			
			# Sort cells for consistency
			var wall_pair: Array = _get_sorted_wall_pair(current_cell, next_cell)
			removed_walls.append(wall_pair)
			
			_generate_maze_dfs(next_x, next_y, logical_core_width, logical_core_height, 
							  maze_paths, removed_walls, rng)

# Check if cell coordinates are valid
func _is_valid_cell(x: int, y: int, width: int, height: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

# Get sorted wall pair for consistency
func _get_sorted_wall_pair(cell1: Vector2i, cell2: Vector2i) -> Array:
	if cell1.x < cell2.x or (cell1.x == cell2.x and cell1.y < cell2.y):
		return [cell1, cell2]
	else:
		return [cell2, cell1]

# Create maze structure
func _create_maze(logical_core_width: int, logical_core_height: int, 
				 rng: RandomNumberGenerator) -> Dictionary:
	var maze_paths: Array[Array] = []
	
	# Initialize maze paths array
	for i in logical_core_height:
		var row: Array[bool] = []
		for j in logical_core_width:
			row.append(false)
		maze_paths.append(row)
	
	var removed_walls: Array = []
	
	# Start DFS from origin
	_generate_maze_dfs(0, 0, logical_core_width, logical_core_height, 
					  maze_paths, removed_walls, rng)
	
	return {
		"maze_paths": maze_paths,
		"removed_walls": removed_walls
	}

# Determine cell type based on coordinates and maze state
func _get_cell_type(real_x: int, real_y: int, maze_data: MazeData) -> CellType:
	var current_coords: Vector2i = Vector2i(real_x, real_y)
	
	# Check spawn points first
	if current_coords == maze_data.player_spawn:
		return CellType.SPAWN_PLAYER
	
	if current_coords in maze_data.collectables_spawn:
		return CellType.SPAWN_COLLECTABLE
	
	# Path cells (odd coordinates)
	if real_x % 2 == 1 and real_y % 2 == 1:
		return CellType.PATH
	
	# Fixed columns (even coordinates)
	if real_x % 2 == 0 and real_y % 2 == 0:
		return CellType.FIXED_COLUMN
	
	# Walls
	return _determine_wall_type(real_x, real_y, maze_data)

# Determine if position is a wall and what type
func _determine_wall_type(real_x: int, real_y: int, maze_data: MazeData) -> CellType:
	var wall_info: Dictionary = _get_wall_info(real_x, real_y)
	var cell1: Vector2i = wall_info.cell1
	var cell2: Vector2i = wall_info.cell2
	var wall_type: CellType = wall_info.wall_type
	
	# Check if it's a border wall
	if _is_border_wall(cell1, cell2, maze_data):
		return wall_type
	
	# Check if wall was removed during maze generation
	if _is_wall_removed(cell1, cell2, maze_data.removed_walls):
		return CellType.PATH
	
	return wall_type

# Get wall information based on real coordinates
func _get_wall_info(real_x: int, real_y: int) -> Dictionary:
	var cell1: Vector2i
	var cell2: Vector2i
	var wall_type: CellType
	
	if real_x % 2 == 1 and real_y % 2 == 0:  # Horizontal wall
		cell1 = Vector2i((real_x - 1) / 2, (real_y - 1) / 2)
		cell2 = Vector2i((real_x - 1) / 2, (real_y + 1) / 2)
		wall_type = CellType.HORIZONTAL_WALL
	else:  # Vertical wall
		cell1 = Vector2i((real_x - 1) / 2, (real_y - 1) / 2)
		cell2 = Vector2i((real_x + 1) / 2, (real_y - 1) / 2)
		wall_type = CellType.VERTICAL_WALL
	
	return {
		"cell1": cell1,
		"cell2": cell2,
		"wall_type": wall_type
	}

# Check if wall is at the border of the maze
func _is_border_wall(cell1: Vector2i, cell2: Vector2i, maze_data: MazeData) -> bool:
	return not (_is_valid_cell(cell1.x, cell1.y, maze_data.logical_core_width, maze_data.logical_core_height) and \
				_is_valid_cell(cell2.x, cell2.y, maze_data.logical_core_width, maze_data.logical_core_height))

# Check if wall was removed during maze generation
func _is_wall_removed(cell1: Vector2i, cell2: Vector2i, removed_walls: Array) -> bool:
	for wall in removed_walls:
		if (wall[0] == cell1 and wall[1] == cell2) or (wall[0] == cell2 and wall[1] == cell1):
			return true
	return false

# Select spawn points for player and collectables
func _select_spawn_points(maze_paths: Array[Array], real_width: int, real_height: int, 
						 current_level: int, rng: RandomNumberGenerator) -> Dictionary:
	var possible_spawns: Array[Vector2i] = _get_possible_spawn_points(maze_paths, real_width, real_height)
	
	if possible_spawns.is_empty():
		return {"player_spawn": Vector2i(-1, -1), "collectables_spawn": []}
	
	# Select player spawn
	var player_spawn: Vector2i = possible_spawns[rng.randi_range(0, possible_spawns.size() - 1)]
	
	# Remove player spawn from available positions
	var remaining_spawns: Array[Vector2i] = possible_spawns.filter(func(spawn): return spawn != player_spawn)
	
	# Select collectable spawns
	var num_collectables: int = min(current_level + 1, remaining_spawns.size())
	var collectables_spawn: Array[Vector2i] = []
	
	for i in num_collectables:
		if not remaining_spawns.is_empty():
			var index: int = rng.randi_range(0, remaining_spawns.size() - 1)
			collectables_spawn.append(remaining_spawns[index])
			remaining_spawns.remove_at(index)
	
	return {
		"player_spawn": player_spawn,
		"collectables_spawn": collectables_spawn
	}

# Get all possible spawn points in the maze
func _get_possible_spawn_points(maze_paths: Array[Array], real_width: int, real_height: int) -> Array[Vector2i]:
	var possible_spawns: Array[Vector2i] = []
	
	for real_y in range(1, real_height - 1, 2):
		for real_x in range(1, real_width - 1, 2):
			var logical_y: int = (real_y - 1) / 2
			var logical_x: int = (real_x - 1) / 2
			if maze_paths[logical_y][logical_x]:
				possible_spawns.append(Vector2i(real_x, real_y))
	
	return possible_spawns

# Main maze generation function
func _generate_complete_maze(current_level: int, seed_value: int) -> MazeData:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	
	# Calculate dimensions
	var real_width: int = _generate_odd_size(current_level)
	var real_height: int = _generate_odd_size(current_level)
	var logical_core_width: int = (real_width - 1) / 2
	var logical_core_height: int = (real_height - 1) / 2
	
	# Create maze data structure
	var maze_data: MazeData = MazeData.new(real_width, real_height, logical_core_width, logical_core_height)
	
	# Generate maze structure
	var maze_result: Dictionary = _create_maze(logical_core_width, logical_core_height, rng)
	maze_data.maze_paths = maze_result.maze_paths
	maze_data.removed_walls = maze_result.removed_walls
	
	# Select spawn points
	var spawn_data: Dictionary = _select_spawn_points(maze_data.maze_paths, real_width, real_height, current_level, rng)
	maze_data.player_spawn = spawn_data.player_spawn
	maze_data.collectables_spawn = spawn_data.collectables_spawn
	
	return maze_data

# Debug maze to console
func _debug_maze_to_console(maze_data: MazeData) -> void:
	print("=== MAZE DEBUG ===")
	print("Size: ", maze_data.real_width, "x", maze_data.real_height)
	print("Player Spawn: ", maze_data.player_spawn)
	print("Collectable Spawns: ", maze_data.collectables_spawn)
	print("Removed Walls: ", maze_data.removed_walls.size())
	print()
	print("Legend: . = Path, P = Player, C = Collectable, - = H Wall, | = V Wall, + = Column")
	
	for real_y in maze_data.real_height:
		var row: String = ""
		for real_x in maze_data.real_width:
			var cell_type: CellType = _get_cell_type(real_x, real_y, maze_data)
			row += _get_debug_symbol(cell_type) + " "
		print(row)

# Get debug symbol for cell type
func _get_debug_symbol(cell_type: CellType) -> String:
	match cell_type:
		CellType.PATH:
			return "."
		CellType.SPAWN_PLAYER:
			return "P"
		CellType.SPAWN_COLLECTABLE:
			return "C"
		CellType.HORIZONTAL_WALL:
			return "-"
		CellType.VERTICAL_WALL:
			return "|"
		CellType.FIXED_COLUMN:
			return "+"
		_:
			return "?"

# Instantiate maze objects in the scene
func _instantiate_maze(maze_data: MazeData) -> void:
	_create_floor(maze_data)
	_create_maze_objects(maze_data)

# Create floor for the entire maze
func _create_floor(maze_data: MazeData) -> void:
	if not path_scene:
		return
	
	var floor: Node3D = path_scene.instantiate()
	floor.scale = Vector3(maze_data.real_width * 2, 1, maze_data.real_height * 2)
	floor.position = Vector3((maze_data.real_width - 1), 0, (maze_data.real_height - 1))
	add_child(floor)

# Create all maze objects (walls, columns, player, collectables)
func _create_maze_objects(maze_data: MazeData) -> void:
	for real_y in maze_data.real_height:
		for real_x in maze_data.real_width:
			var cell_type: CellType = _get_cell_type(real_x, real_y, maze_data)
			var instance: Node3D = _create_cell_instance(cell_type)
			
			if instance:
				instance.position = Vector3(real_x * 2, 0, real_y * 2)
				add_child(instance)

# Create instance based on cell type
func _create_cell_instance(cell_type: CellType) -> Node3D:
	match cell_type:
		CellType.FIXED_COLUMN:
			return _create_column()
		CellType.HORIZONTAL_WALL:
			return _create_horizontal_wall()
		CellType.VERTICAL_WALL:
			return _create_vertical_wall()
		CellType.SPAWN_PLAYER:
			return _create_player()
		CellType.SPAWN_COLLECTABLE:
			return _create_collectable()
		_:
			return null

# Create column instance
func _create_column() -> Node3D:
	if column_scene:
		return column_scene.instantiate()
	return null

# Create horizontal wall instance
func _create_horizontal_wall() -> Node3D:
	if wall_scene:
		var wall: Node3D = wall_scene.instantiate()
		wall.rotate_y(deg_to_rad(90))
		return wall
	return null

# Create vertical wall instance
func _create_vertical_wall() -> Node3D:
	if wall_scene:
		return wall_scene.instantiate()
	return null

# Create player instance
func _create_player() -> Node3D:
	if player_scene:
		return player_scene.instantiate()
	return null

# Create collectable instance
func _create_collectable() -> Node3D:
	if collectable_scene:
		var collectable: Node3D = collectable_scene.instantiate()
		total_collectables += 1
		collectable.collected.connect(_on_collectable_collected)
		return collectable
	return null

# Handle collectable collection
func _on_collectable_collected() -> void:
	collected += 1
	collectable_collected.emit()  # SOLO ESTA LÍNEA ES NUEVA - para que el UI se entere
	print("Collected ", collected, " of ", total_collectables)
	
	if collected >= total_collectables:
		print("✅ Level completed!")
		level_completed.emit()

# Initialize maze with given level
func initialize(maze_level: int) -> void:
	# Reset counters
	collected = 0
	total_collectables = 0
	
	# Generate and instantiate maze
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var maze_data: MazeData = _generate_complete_maze(maze_level, rng.seed)
	_instantiate_maze(maze_data)
