extends Node2D

const GRID_SIZE = 32
const STEP_TIME = 0.15
const DEFAULT_LENGTH = 10

@onready var head := $Head
@onready var segment_container := $SegmentContainer

var segment_scene = preload("res://scenes/segment.tscn")
var direction = Vector2.RIGHT
var next_direction = direction
var head_grid_position: Vector2i
var position_history: Array[Vector2] = []
var segments: Array[Node2D] = []
var step_timer = 0.0
var steps_taken = 0

func _ready():
	head_grid_position = Vector2i(5, 5)  # Start at grid position (5,5)
	head.position = Vector2(head_grid_position) * GRID_SIZE  # Convert to world position
	position_history.append(head.position)

func _process(delta):
	handle_input()

func _physics_process(delta):
	step_timer += delta
	if step_timer >= STEP_TIME:
		step_timer = 0.0
		move_step()

func handle_input():
	if Input.is_action_just_pressed("ui_up") and direction != Vector2.DOWN:
		next_direction = Vector2.UP
	elif Input.is_action_just_pressed("ui_down") and direction != Vector2.UP:
		next_direction = Vector2.DOWN
	elif Input.is_action_just_pressed("ui_left") and direction != Vector2.RIGHT:
		next_direction = Vector2.LEFT
	elif Input.is_action_just_pressed("ui_right") and direction != Vector2.LEFT:
		next_direction = Vector2.RIGHT

func move_step():
	direction = next_direction
	
	# Move to next grid position
	head_grid_position += Vector2i(direction)
	var new_position = Vector2(head_grid_position) * GRID_SIZE
	
	# Update head position
	head.position = new_position
	
	# Add new position to history
	position_history.insert(0, new_position)
	
	print("After insert, position_history: ", position_history)
	print("Head grid position: ", head_grid_position)
	print("New position: ", new_position)
	
	# Spawn segments one at a time
	if steps_taken < DEFAULT_LENGTH:
		var seg = segment_scene.instantiate()
		segment_container.add_child(seg)
		segments.append(seg)
	
	# Move segments to previous positions
	for i in range(segments.size()):
		var index = i + 1
		if index < position_history.size():
			print("Segment ", i, " set to ", position_history[index])
			segments[i].position = position_history[index]
	
	# Trim history to prevent unlimited growth
	if position_history.size() > segments.size() + 5:
		position_history.resize(segments.size() + 5)
	
	steps_taken += 1
