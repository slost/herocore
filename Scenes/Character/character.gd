extends CharacterBody2D
class_name Character

# export
@export var data: Resource = preload("res://Database/Character/player.tres")
@export var inv: Node
@export var animSpr: Node

# onready
@onready var stats: Dictionary = data.stats

var move_speed: float
var sub_bar: int = 1
@onready var bars = Global.bars_init


func _ready() -> void:
	animSpr.play("move_down")
	# scale = Vector2(data.stats.size_scale, data.stats.size_scale)
	scale = Global.SCALE_VEC
	z_index = 2


# การควบคุม
func get_input() -> void:
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not inv.has_node("FreeMovement"):
		if abs(input_direction.x) > abs(input_direction.y):
			input_direction.y = 0
		else:
			input_direction.x = 0
	velocity = input_direction * move_speed


		
var bar_counter = 1
	
func _physics_process(_delta) -> void:
	move_speed = Lib.get_character_speed(stats.base_speed, scale)
	bars = Lib.process_bars(bars)
	var bars_id = 0
	if bar_counter <= Global.bars[bars_id]:
		pass
		bar_counter += 1
	move_and_slide()