@tool
extends Control

@onready var command_input := %InputLineEdit
@onready var command_output := %OutputRichLabel

@onready var _env := ReplEnv.new()
@onready var _parser := ReplParser.new()
@onready var _history:Array[String] = []
@onready var _future:Array[String] = []

func _ready():
	command_output.add_text('>>> ')
	command_input.grab_focus()


func _on_tree_exited():
	_history = []
	_future = []
	


func evaluate_from_input():
	command_output.add_text(command_input.text + '\n')
	if command_input.text != '':
		var result = _parser.evaluate(command_input.text, _env)
		command_output.add_text(str(result[1]) + '\n')
		if not result[0]:  # no errors
			_history.append(command_input.text)
			command_input.clear()
	command_output.add_text('>>> ')
	command_output.scroll_to_line(command_output.get_line_count())


func shift_input_stack(input:LineEdit, from_stack:Array[String], to_stack:Array[String]) -> void:
	# move strings: from_stack -> input -> to_stack
	if input.text.length() > 0:
		to_stack.append(input.text)
	if from_stack.size() > 0:
		input.text = from_stack.pop_back()
	else:
		input.text = ''
	

func _on_input_line_edit_gui_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			evaluate_from_input()
		elif event.pressed and event.keycode == KEY_TAB:
			get_viewport().set_input_as_handled()
		elif event.pressed and event.keycode == KEY_UP:
			shift_input_stack(command_input, _history, _future)
		elif event.pressed and event.keycode == KEY_DOWN:
			shift_input_stack(command_input, _future, _history)


func _on_eval_button_pressed():
	evaluate_from_input()
