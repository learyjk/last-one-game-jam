# Snake.gd - Individual Snake Script
extends Node2D
class_name Snake

const GRID_SIZE = 32
const DEFAULT_LENGTH = 20
const SHRINK_INTERVAL = 5
const HISTORY_BUFFER = 5

var segment_scene = preload("res://scenes/segment.tscn")
var direction = Vector2.RIGHT
var next_direction = direction
var head_grid_position: Vector2i
var position_history: Array[Vector2] = []
var segments: Array[Node2D] = []
var steps_taken = 0
var shrink_counter = 0
var is_alive = true
var player_name = ""
var snake_color = Color.WHITE

# Input actions for this snake
var input_up = ""
var input_down = ""
var input_left = ""
var input_right = ""

@onready var head := $Head
@onready var segment_container := $SegmentContainer

# Reference to the game manager (for collision checking)
var game_manager = null

func initialize(name: String, start_pos: Vector2i, color: Color, controls: Dictionary, manager = null):
	player_name = name
	head_grid_position = start_pos
	snake_color = color
	game_manager = manager
	
	# Set up controls
	input_up = controls.get("up", "")
	input_down = controls.get("down", "")
	input_left = controls.get("left", "")
	input_right = controls.get("right", "")
	
	# Set visual appearance
	head.position = Vector2(head_grid_position) * GRID_SIZE
	head.modulate = color
	position_history.append(head.position)
	
	# Create initial segments
	for i in range(DEFAULT_LENGTH):
		var seg = segment_scene.instantiate()
		seg.modulate = color
		segment_container.add_child(seg)
		segments.append(seg)

func handle_input():
	if not is_alive:
		return
		
	if input_up != "" and Input.is_action_just_pressed(input_up) and direction != Vector2.DOWN:
		next_direction = Vector2.UP
	elif input_down != "" and Input.is_action_just_pressed(input_down) and direction != Vector2.UP:
		next_direction = Vector2.DOWN
	elif input_left != "" and Input.is_action_just_pressed(input_left) and direction != Vector2.RIGHT:
		next_direction = Vector2.LEFT
	elif input_right != "" and Input.is_action_just_pressed(input_right) and direction != Vector2.LEFT:
		next_direction = Vector2.RIGHT

func move_step():
	if not is_alive:
		return
		
	direction = next_direction
	
	# Move to next grid position
	head_grid_position += Vector2i(direction)
	var new_position = Vector2(head_grid_position) * GRID_SIZE
	
	# Check for collisions with all snakes (via game manager)
	var collision_data = null
	if game_manager:
		collision_data = game_manager.check_collision_for_snake(self, new_position)
	
	# Update head position
	head.position = new_position
	
	# Add new position to history
	position_history.insert(0, new_position)
	
	print(player_name, " - Head grid position: ", head_grid_position)
	
	# Handle collision - chop off tail after collision point
	if collision_data and collision_data.collision_index != -1:
		if collision_data.target_snake == self:
			# Self collision - chop own tail
			chop_tail_at_collision(collision_data.collision_index)
		else:
			# Hit another snake - chop their tail
			collision_data.target_snake.chop_tail_at_collision(collision_data.collision_index)
			print(player_name, " sliced ", collision_data.target_snake.player_name, "'s tail!")
	
	# Move segments to previous positions
	for i in range(segments.size()):
		var index = i + 1
		if index < position_history.size():
			segments[i].position = position_history[index]
	
	# Trim history to prevent unlimited growth
	if position_history.size() > segments.size() + HISTORY_BUFFER:
		position_history.resize(segments.size() + HISTORY_BUFFER)
	
	steps_taken += 1
	shrink_counter += 1
	
	# Shrink tail every SHRINK_INTERVAL steps
	if shrink_counter >= SHRINK_INTERVAL:
		shrink_counter = 0
		shrink_tail()
	
	# Check if this snake died
	check_death()

func chop_tail_at_collision(collision_index: int):
	print(player_name, " - Chopping tail at collision index: ", collision_index)
	
	# Calculate how many segments to keep
	var segments_to_keep = collision_index - 1
	segments_to_keep = max(0, segments_to_keep)
	
	# Remove excess segments from the scene
	var segments_to_remove = segments.size() - segments_to_keep
	for i in range(segments_to_remove):
		if segments.size() > 0:
			var segment_to_remove = segments.pop_back()
			segment_to_remove.queue_free()
	
	# Trim position history to match
	if position_history.size() > segments_to_keep + 1:
		position_history.resize(segments_to_keep + 1)
	
	print(player_name, " - Snake length after chopping: ", segments.size())

func shrink_tail():
	if segments.size() > 0:
		print(player_name, " - Shrinking tail. Current length: ", segments.size())
		var segment_to_remove = segments.pop_back()
		segment_to_remove.queue_free()
		
		# Also trim position history to match
		if position_history.size() > segments.size() + 1:
			position_history.resize(segments.size() + 1)
		
		print(player_name, " - New length after shrinking: ", segments.size())

func check_death():
	if segments.size() == 0:
		print(player_name, " - DIED - Snake has no tail left!")
		is_alive = false
		head.modulate = Color.GRAY  # Gray out dead snake

func get_current_position() -> Vector2:
	return head.position

func get_position_history() -> Array[Vector2]:
	return position_history
