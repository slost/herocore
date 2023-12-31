extends Character
class_name Monster

@export_category("Stats")

@export var move_behavior:MOVE_TYPE = MOVE_TYPE.NONE
@export var speed = 300
@export var is_look_at_player: bool = false

@export_category("Node")
@export var debugger: Node
@export var spr: Node

@onready var player = Global.player

enum STATE {
	IDLE,
	CHASE,
	ATTACK
}

enum MOVE_TYPE {
	NONE,
	DIRECT,
	ROUNDED, # เดินแบบวงกลมล้อมผู้เล่น
	ROUNDED_TO_PLYER, # เดินแบบวงกลมล้อมผู้เล่นก่อน จากนั้นจะค่อย ๆ ขยับเข้าใกล้ผู้เล่นแบบวงกลม
	ROUNDED_CLOSE_PLYER,  # ค่อย ๆ ขยับเข้าใกล้ผู้เล่นแบบวงกลม
	
	ROUNDED_THEN_RUSH,
	WALK_THEN_STOP,
	
}

var delta : float
var angle = 0
var current_state : int
var distance : float
var distance_offset : float
var offset : Vector2
var radius

# ใช้จับเวลาว่ากำลังวิ่งอยู่ในระยะวงกลมเป็นเวลาที่กำหนดหรือหรือไม่
var round_move_timer_init = 10
var round_move_timer = round_move_timer_init 

var error_distance = 5 # ค่าความคลาดเคลื่อนที่ยอมรับได้ (สำหรับการเช็คว่าวิ่งอยู่ในระยะวงกลม)
var rate_close_player = 20 # อัตราการเดินเข้าใกล้ผู้เล่น (สำหรับการเช็คเดินเข้าใกล้แบบวงกลม)

# ใช้จับเวลาว่าเดินแล้วหยุด เพื่อเปลี่ยนสถานะ
var move_timer_init = 3
var move_timer = move_timer_init 
var stop_timer_init = 3
var stop_timer = stop_timer_init 

func ready_character():
	scale = Vector2(8, 8)
	if Global.is_alpha_mode:
		$Line2D.default_color.a = 0.5
	z_index = 2
	current_state = STATE.CHASE
	radius = speed
	Global.boss = self
	print(Global.boss)


func _process(_delta) -> void:
	if DialogManger.is_dialog_active:
		return
	delta = _delta
	distance = global_transform.origin.distance_to(player.global_transform.origin)
	var offset_x = cos(angle) * radius
	var offset_y = sin(angle) * radius
	offset = player.global_position - Vector2(offset_x, offset_y)
	distance_offset = global_position.distance_to(offset)
	process_state()
	update_debugger_text()
	move_and_slide()
	if is_look_at_player:
		spr.rotation = position.angle_to_point(player.global_position) - deg_to_rad(90)
			
			
func process_state():
	match current_state:
		STATE.IDLE:
			update_idle_state()
		STATE.CHASE:
			match move_behavior:
				MOVE_TYPE.DIRECT, MOVE_TYPE.WALK_THEN_STOP:
					move_direct()
				MOVE_TYPE.ROUNDED, MOVE_TYPE.ROUNDED_TO_PLYER, MOVE_TYPE.ROUNDED_CLOSE_PLYER, MOVE_TYPE.ROUNDED_THEN_RUSH:
					move_round()

func update_idle_state():
	velocity = Vector2.ZERO
	if move_behavior == MOVE_TYPE.WALK_THEN_STOP:
		if stop_timer > 0:
			stop_timer -= delta
		else:
			stop_timer = stop_timer_init
			current_state = STATE.CHASE

func move_direct():
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * stats.base_speed * 10
	
	if move_behavior == MOVE_TYPE.WALK_THEN_STOP:
		if move_timer > 0:
			move_timer -= delta
		else:
			move_timer = move_timer_init
			current_state = STATE.IDLE
			return

func move_round():
	# ทำให้เดินเข้าไปใกล้ ๆ ผู้เล่น สำหรับ ROUNDED_CLOSE_PLYER
	if move_behavior == MOVE_TYPE.ROUNDED_CLOSE_PLYER:
		if radius > 0:
			radius = max(radius - delta * rate_close_player, 0)
	else:
		radius = speed
	
	angle += delta
	var offset_x = cos(angle) * radius
	var offset_y = sin(angle) * radius
	offset = player.global_position - Vector2(offset_x, offset_y)
	var direction = (offset - global_position).normalized()
	#distance_offset = global_position.distance_to(offset)
	velocity = direction * speed
	
	# เช็คว่าเดินเป็นวงกลมแล้วยัง แล้วจะอัเดตสถานะการเดินเป็นเดินเข้าใกล้
	if move_behavior == MOVE_TYPE.ROUNDED_TO_PLYER || move_behavior == MOVE_TYPE.ROUNDED_THEN_RUSH:
		if round_move_timer > 0:
			if distance >= ( radius - error_distance ) && distance <= ( radius + error_distance ):
				round_move_timer -= delta
			else:
				round_move_timer = round_move_timer_init
		else:
			match move_behavior:
				MOVE_TYPE.ROUNDED_TO_PLYER:
					move_behavior = MOVE_TYPE.ROUNDED_CLOSE_PLYER
				MOVE_TYPE.ROUNDED_THEN_RUSH:
					velocity = Vector2.ZERO
					move_behavior = MOVE_TYPE.DIRECT
					return
	# เช็คว่าผู้เล่นเดินหนีออกจากระยะ ให้กลับไปสถานะเดินวงกลมล้อมใหม่
	if move_behavior == MOVE_TYPE.ROUNDED_CLOSE_PLYER || move_behavior == MOVE_TYPE.ROUNDED_THEN_RUSH:
		if distance >= ( radius + error_distance ):
			# ผู้เล่นวิ่งหนีไปไกลแล้ว รีเซ็ตสถานะ + ตัวแปร
			move_behavior = MOVE_TYPE.ROUNDED_TO_PLYER
			round_move_timer = round_move_timer_init
			radius = speed
	
func update_debugger_text() -> void:
	debugger.clear()
	debugger.append_text("[center]")
	debugger.append_text("[b]%s[/b]" % name)
	debugger.append_text("[b]%s/%s[/b]" % [hp, max_hp])
	debugger.append_text("\nState: " + str(current_state))
	debugger.append_text("\nDistance: " + str(round(distance)))
	debugger.append_text("\nround_move_timer: " + str(round(round_move_timer)))
