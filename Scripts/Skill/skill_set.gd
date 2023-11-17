## ควบคุมการปล่อยสกิล
extends Node
class_name SkillSet

## สกิลที่จะมีในสกิลเซ็ตนี้
@export var skills: Array[Skill] = []
"""
Skill: resource = {
	projectile = กระสุนที่จะสปอน
	pattern = รูปแบบของกลุ่มกระสุน เช่น ไปซ้าย อยู่เฉย ๆ และตำแหน่งของกระสุนทั้งหมด
	beat = จังหวะเพลงที่จะสปอนแพทเทิร์นกระสุน
	sound = เสียงที่จะปล่อยตอนปล่อยกระสุน
	}
"""

@onready var player: Node = $"../.."
@onready var caster: Node = $"../.."


var bar_counter: int = 1
var hostile: Node
var patterns: Array = []
var current_turn: Turn

func set_hostile() -> void:
	if not caster == Global.player:
		hostile = Global.player
	else:
		hostile = Global.player # เดี๋ยวจะเปลี่ยนเป็น enemy

func _ready():
	caster = $"../.."
	set_hostile()

var bar_to_spawn: int = 3

var beat: Array = ["1","1", "1", "2"]

func _process(_delta) -> void:
	if Global.turn_queue.size() > 0:
		current_turn = Global.turn_queue[0]
	if current_turn.data.character == caster:
		if Global.bars[0] >= bar_counter:
			process_beat()
			bar_counter += 1
	else:
		bar_counter = Global.bars[0]


# ประมวลผลการสปอนจากบีท
func process_beat():
	for i in beat:
		if beat != null:
			if Global.bars[0] % beat.find(beat) == 0:
				spawn_skill_from_id(0)
		
		
# สปอนแพทเทิร์นกระสุนจาก id ของอาร์เรย์ใน skills
func spawn_skill_from_id(_id: int) -> void:
	var skill = skills[_id]
	var proj = skill.projectile
	var pattern = skill.pattern.instantiate()
	var pattern_data = Lib.get_pattern_data(pattern)
	print_debug(pattern_data)
	for tile in pattern_data["direction"]:
		spawn_projectile(proj, tile)
	

# สปอนกระสุนจากซีนกระสุน
func spawn_projectile(_projectile: PackedScene,_data: Dictionary) -> void:
	var proj = _projectile.instantiate()
	proj.global_position = caster.global_position + \
		(caster.scale * _data.position * Global.TILE_RES)
	proj.caster = caster
	$"..".add_child(proj)
	# print_debug("spawnned "  + str(proj.name) + str(proj.global_position))
	
"""
func spawn_projectile(_projectile: String, _params = null) -> void:
	var spawn_dist = _params.get("spawn_dist", 0) # ระยะห่างจากตำแหน่งสปอน
"""
		
