extends Node
class_name Skill

@onready var caster: Node = $"../../.." # ผู้ใช้สกิล
@onready var item: Node = $".." # ไอเทมที่ใช้สกิล

# ศัตรูที่ถูกโจมตี
var hostile: Node
var target: Node

# ซีนกระสุน
@onready var projectile_scene = load("res://Scenes/Skills/projectile.tscn")

var bars = [1, 1, 1, 1.0]

# เทิร์นปัจจุบัน
var current_turn: Turn
var can_spawn = true


func _ready() -> void:
	set_hostile()


# กำหนดค่าศัตรูให้กระสุน
func set_hostile() -> void:
	if caster == Global.player:
		target = Global.boss
	else:
		target = Global.player


func _process(_delta) -> void:
	if DialogManger.is_dialog_active:
		return
	set_hostile()
	if Global.turn_queue.size() > 0:
		current_turn = Global.turn_queue[0]
		if item.type == 2:
			if current_turn.data.character == caster:
				process_skill()
		if item.type == 4:
			if current_turn.data.character != caster:
				process_skill()
		if item.type == 6:
			process_skill()


# ไปเขียนใน SkillSingle และ SkillSet แทน
func process_skill():
	pass


func spawn_skill(_data: SkillDB, _proj_stats: ProjectileStats) -> void:
	var pattern = _data.pattern.instantiate()
	var pattern_data = Lib.get_pattern_data(pattern)
	# ใส่ข้อมูลกระสุนจากในแต่ละไทล์
	for tile in pattern_data["direction"]:
		if _data.sound_when_spawn:
			tile["sound"] = _data.sound_when_spawn
			tile["scale_multiplier"] = _proj_stats.scale_multiplier
			tile["spawn_location"] = _data.spawn_location
		if pattern_data["direction"].size() == 1:
			tile["db"] = 10
		else:
			tile["db"] = 0
		tile["sprite"] = _data.sprite
		spawn_projectile(tile, _proj_stats)


# สปอนซีนกระสุนจาก data ที่ได้จากแพทเทิร์น
func spawn_projectile(_data: Dictionary, _proj_stats: ProjectileStats) -> void:
	var proj = projectile_scene.instantiate()
	proj.sprite = _data.sprite
	proj.caster = caster
	var spawn_location = caster.global_position
	if _data.spawn_location:
		if _data.spawn_location != "Caster":
			spawn_location = target.global_position
	proj.global_position = spawn_location + \
		(caster.scale * _data.position * Global.TILE_RES)
	proj.direction = get_projectile_direction(_data.direction)
	proj.stats = _proj_stats.get_stats()
	proj.scale_multiplier = _data.scale_multiplier

	$"..".add_child(proj)


# หาทิศทางที่กระสุนจะไป
func get_projectile_direction(_direction: String) -> Vector2:
	if Lib.get_direction(_direction) is Vector2:
		return Lib.get_direction(_direction)
	match _direction:
		"closest_enemy":
			if target:
				return (target.position - caster.global_position).normalized()
	return Vector2.ZERO


# สร้าง AudioStreamPlayer2D ในโหนด MusicHanlder
func spawn_sound(_sound_path: String, _db: float) -> void:
	var sound = Sound.new()
	if caster == Global.player:
		sound.bus = "Player"
	else:
		sound.bus = "Monster"
	sound.global_position = caster.global_position
	sound.volume_db += _db
	sound.stream = load(_sound_path) 
	Global.musicH.add_child(sound)


# ตรงกับจังหวะที่กำหนดหรือไม่
func match_beat(_beat_test: String) -> bool:	
	match _beat_test:
		# bars[0]
		"%1": 
			return caster.bars[0] % 1 == 0
		"%2":
			return caster.bars[0] % 2 == 0
		"%4", "1 verse":
			return caster.bars[0] % 4 == 1
		"%8", "2 verse":
			return caster.bars[0] % 8 == 1
		"%16", "4 verse":
			return caster.bars[0] % 16 == 1
		"%32", "8 verse":
			return caster.bars[0] % 32 == 1
		# bars[1]
		".1":
			return caster.bars[1] == 1
		".2":
			return caster.bars[1] == 2
		".3":
			return caster.bars[1] == 3
		".4":
			return caster.bars[1] == 4
		".%1":
			return caster.bars[1] % 1 == 0
		".%2":
			return caster.bars[1] % 2 == 0
		# bars[2]
		"..1":
			return caster.bars[2] == 1
		"..2":
			return caster.bars[2] == 2
		"..3":
			return caster.bars[2] == 3
		"..4":
			return caster.bars[2] == 4
		"..%1":
			return caster.bars[2] % 1 == 0
		"..%2":
			return caster.bars[2] % 2 == 0
	return false
