# GameManager.gd - Main Game Controller
extends Node2D

const STEP_TIME = 0.15
const STARTING_GRID_X = 5
const STARTING_GRID_Y = 5

var snakes: Array[Snake] = []
var step_timer = 0.0
var game_over = false

func _ready():
	# Find all Snake nodes in the scene
	collect_snakes()
	
	# Initialize snakes with different starting positions and controls
	if snakes.size() >= 1:
		snakes[0].initialize(
			"Player 1", 
			Vector2i(STARTING_GRID_X, STARTING_GRID_Y), 
			Color.BLUE,
			{"up": "ui_up", "down": "ui_down", "left": "ui_left", "right": "ui_right"},
			self
		)
	
	if snakes.size() >= 2:
		snakes[1].initialize(
			"Player 2", 
			Vector2i(STARTING_GRID_X + 10, STARTING_GRID_Y), 
			Color.BLUE_VIOLET,
			{"up": "p2_up", "down": "p2_down", "left": "p2_left", "right": "p2_right"},
			self
		)
	
	# Initialize additional snakes with default controls if more exist
	for i in range(2, snakes.size()):
		snakes[i].initialize(
			"Player " + str(i + 1),
			Vector2i(STARTING_GRID_X + (i * 5), STARTING_GRID_Y + (i * 2)),
			Color(randf(), randf(), randf()),  # Random color
			{"up": "", "down": "", "left": "", "right": ""},  # No controls - AI could go here
			self
		)

func collect_snakes():
	snakes.clear()
	# Recursively find all Snake nodes
	find_snakes_recursive(self)

func find_snakes_recursive(node: Node):
	if node is Snake:
		snakes.append(node)
	
	for child in node.get_children():
		find_snakes_recursive(child)

func _process(delta):
	if game_over:
		return
	
	# Handle input for all snakes
	for snake in snakes:
		snake.handle_input()

func _physics_process(delta):
	if game_over:
		return
		
	step_timer += delta
	if step_timer >= STEP_TIME:
		step_timer = 0.0
		move_all_snakes()

func move_all_snakes():
	for snake in snakes:
		if snake.is_alive:
			snake.move_step()
	
	check_game_over()

func check_collision_for_snake(checking_snake: Snake, head_pos: Vector2) -> Dictionary:
	# Check collision with all snakes
	for snake in snakes:
		if not snake.is_alive:
			continue
			
		# For self, skip the first position (head's previous position)
		var start_index = 1 if snake == checking_snake else 0
		
		# Check against position history
		var history = snake.get_position_history()
		for i in range(start_index, history.size()):
			if history[i] == head_pos:
				print(checking_snake.player_name, " collision detected at position: ", head_pos, " with ", snake.player_name, " at history index: ", i)
				return {"collision_index": i, "target_snake": snake}
	
	return {"collision_index": -1, "target_snake": null}

func check_game_over():
	var alive_snakes = 0
	var winner = null
	
	for snake in snakes:
		if snake.is_alive:
			alive_snakes += 1
			winner = snake
	
	# Only end game if there are multiple snakes and only one (or none) remains alive
	# OR if there's only one snake and it died
	if snakes.size() > 1 and alive_snakes <= 1:
		game_over = true
		print("Game Over!")
		if alive_snakes == 1:
			print("Winner: ", winner.player_name)
		else:
			print("It's a tie!")
	elif snakes.size() == 1 and alive_snakes == 0:
		game_over = true
		print("Game Over!")
		print("Snake died!")

func add_snake(snake: Snake):
	snakes.append(snake)
	
func remove_snake(snake: Snake):
	snakes.erase(snake)
