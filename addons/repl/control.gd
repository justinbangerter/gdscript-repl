extends Control

@onready var command_input := %InputLineEdit
@onready var command_output := %OutputRichLabel

@onready var _env := ReplEnv.new()
@onready var _history:Array[String] = []
@onready var _future:Array[String] = []

func _ready():
	command_output.add_text('>>> ')
	command_input.grab_focus()


func evaluate_from_input():
	command_output.add_text(command_input.text + '\n')
	var result = evaluate(command_input.text, _env)
	if result[0]: #error
		command_output.add_text(result[1] + '\n')
	else:
		command_output.add_text(result[1] + '\n')
		_history.append(command_input.text)
		command_input.clear()
	command_output.add_text('>>> ')
	command_output.scroll_to_line(command_output.get_line_count())


func tokenize(instruction: String) -> Array[String]:
	var length = instruction.length()
	var index = 0
	var tokens:Array[String] = []
	var token = ''
	while index < length:
		var character = instruction[index]
		if character in ' \t\n[](){}:.':
			tokens.append(token)
			tokens.append(character)
			token = ''
		elif character == '=':
			if token in '<>!+-=':
				token += character
				tokens.append(token)
				token = ''
			else:
				tokens.append(token)
				token = character
		elif character in '<>!+-':
			tokens.append(token)
			token = character
		else:
			token += character
		index += 1
		
	if token != '':
		tokens.append(token)
		token = ''
	return tokens
	

func evaluate(command: String, env:ReplEnv) -> Array:
	# guarantee key/value order alignment
	var env_keys = env.vars.keys()
	var env_values = []
	for _key in env_keys:
		env_values.append(env.vars[_key])
	
	var expression = Expression.new()
	var error = expression.parse(command, env_keys)
	if error != OK:
		return [true, 'failed to parse:\n' + expression.get_error_text()]
	
	var result = expression.execute(env_values, env)
	if expression.has_execute_failed():
		return [true, 'failed to execute:\n' + expression.get_error_text()]
	return [false, str(result)]


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


func _on_tree_exited():
	_history = []
	_future = []
	_env.queue_free()


func _on_eval_button_pressed():
	evaluate_from_input()
