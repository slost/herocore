extends MarginContainer

@onready var label = $MarginContainer/Label
@onready var timer = $LetterDisplayTimer
@onready var cursor_dialog = $NinePatchRect/ColorRect

const MAX_WIDTH = 256*2.5

var text = ""
var letter_index = 0

var letter_time = 0.03
var space_time = 0.06
var punctuation_time = 0.2

var fix_massagebox = false
var fix_size = Vector2(832, 192)

signal finsished_displaying()

func set_fix_massagebox():
	fix_massagebox = true

func display_text(text_to_display: String):
	text = text_to_display
	if fix_massagebox:
		custom_minimum_size = fix_size
		set_size(fix_size)
		reset_size()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	else:
		label.text = text_to_display
		await resized
		custom_minimum_size.x = min(size.x, MAX_WIDTH)
		if size.x > MAX_WIDTH:
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			await resized
			await resized
			custom_minimum_size.y = size.y
		global_position.x -= size.x / 2
		global_position.y -= size.y + 24
	
	label.text = ""
	_display_letter()

func _display_letter():
	label.text += text[letter_index]
	
	letter_index += 1
	if letter_index >= text.length():
		finsished_displaying.emit()
		return
	
	match text[letter_index]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)


func _on_letter_display_timer_timeout():
	_display_letter()

func show_cursor_dialog():
	cursor_dialog.visible = true
