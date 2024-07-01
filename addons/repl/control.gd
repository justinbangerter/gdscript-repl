@tool
extends Control

@onready var command_input := %InputLineEdit
@onready var command_output := %OutputRichLabel

@onready var _env := ReplEnv.new()
@onready var _history:Array[String] = []
@onready var _future:Array[String] = []

const assignment_operators = [
	'=', '+=', '-=', '*=', '/=', '**=', '%=', '&=', '|=', '^=', '<<=', '>>='
]
	
const whitespace_chars = ' \t\r'
const number_chars = '1234567890.'
const operator_chars = '!=<>:+-*'
const bracket_chars = '()[]{}'

enum ParserMode {
	EMPTY = 0,
	NEWLINE = 1,
	LEADING_WHITESPACE = 2,
	INNER_WHITESPACE = 3,
	WORD = 4,
	NUMBER = 5,
	OPERATOR = 6,
	BRACKET = 7,
	STRING_SQ = 8,  # single quote
	STRING_DQ = 9,  # double quote
	STRING_TSQ = 10,  # triple single quote
	STRING_TDQ = 11,  # triple double quote
	END_STRING = 12,
}

func _ready():
	command_output.add_text('>>> ')
	command_input.grab_focus()


func _on_tree_exited():
	_history = []
	_future = []
	


func evaluate_from_input():
	command_output.add_text(command_input.text + '\n')
	if command_input.text != '':
		var result = evaluate(command_input.text, _env)
		command_output.add_text(str(result[1]) + '\n')
		if not result[0]:  # no errors
			_history.append(command_input.text)
			command_input.clear()
	command_output.add_text('>>> ')
	command_output.scroll_to_line(command_output.get_line_count())


func tokenize(instruction: String) -> Array:
	## On failure, returns [true, "error message"]
	## On success, returns [false, ['\t', '\t', 'list', 'of', 'tokens']]
	
	var error = false
	var mode = ParserMode.EMPTY
	var tokens:Array[String] = []
	var token = ''
	
	var word_regex = RegEx.new()
	word_regex.compile("[a-zA-Z_][a-zA-Z_0-9]*")

	var index = 0
	while index < instruction.length():
		if mode == ParserMode.EMPTY:
			token += instruction[index]
		elif mode == ParserMode.NEWLINE:
			tokens.append(token)
			token = instruction[index]
		elif mode == ParserMode.LEADING_WHITESPACE:
			tokens.append(token)
			token = instruction[index]
		elif mode == ParserMode.INNER_WHITESPACE:
			if instruction[index] not in whitespace_chars:
				token = instruction[index]
		elif mode == ParserMode.NUMBER:
			if instruction[index] in number_chars:
				token += instruction[index]
			elif word_regex.search(instruction[index]):
				token += instruction[index]
				error = true
			else:
				tokens.append(token)
				token = instruction[index]
		elif mode == ParserMode.WORD:
			if instruction[index] in number_chars or word_regex.search(instruction[index]):
				token += instruction[index]
			else:
				tokens.append(token)
				token = instruction[index]
		elif mode == ParserMode.OPERATOR:
			if token.length() > 1:
				tokens.append(token)
				token = instruction[index]
			elif instruction[index] in operator_chars:
				token += instruction[index]
			else:
				tokens.append(token)
				token = instruction[index]
		elif mode == ParserMode.BRACKET:
			tokens.append(token)
			token = instruction[index]
		elif mode == ParserMode.STRING_SQ:
			token += instruction[index]
			index += 1
			while index < instruction.length() and instruction[index] != "'":
				if instruction[index] == '\\':
					token += instruction[index]
					index += 1
				token += instruction[index]
				index += 1
			if index < instruction.length() and instruction[index] == "'":
				token += instruction[index]
				index += 1
				mode = ParserMode.END_STRING
			if mode == ParserMode.STRING_SQ:
				return [true, "Unterminated single quote"]
			tokens.append(token)
			token = ''
		elif mode == ParserMode.STRING_DQ:
			token += instruction[index]
			index += 1
			while index < instruction.length() and instruction[index] != '"':
				if instruction[index] == '\\':
					token += instruction[index]
					index += 1
				token += instruction[index]
				index += 1
			if index < instruction.length() and instruction[index] == '"':
				token += instruction[index]
				index += 1
				mode = ParserMode.END_STRING
			if mode == ParserMode.STRING_DQ:
				return [true, "Unterminated double quote"]
			tokens.append(token)
			token = ''
		elif mode == ParserMode.STRING_TSQ:
			token += instruction[index]
			index += 1
			token += instruction[index]
			index += 1
			token += instruction[index]
			index += 1
			while index + 2 < instruction.length() and instruction.substr(index, 3) != "'''":
				if instruction[index] == '\\':
					token += instruction[index]
					index += 1
				token += instruction[index]
				index += 1
			if index + 2 < instruction.length() and instruction.substr(index, 3) == "'''":
				token += "'''"
				index += 3
				mode = ParserMode.END_STRING
			if mode == ParserMode.STRING_TSQ:
				return [true, "Unterminated triple single quote"]
			tokens.append(token)
			token = ''
		elif mode == ParserMode.STRING_TDQ:
			token += instruction[index]
			index += 1
			token += instruction[index]
			index += 1
			token += instruction[index]
			index += 1
			while index + 2 < instruction.length() and instruction.substr(index, 3) != '"""':
				if instruction[index] == '\\':
					token += instruction[index]
					index += 1
				token += instruction[index]
				index += 1
			if index + 2 < instruction.length() and instruction.substr(index, 3) == '"""':
				token += '"""'
				index += 3
				mode = ParserMode.END_STRING
			if mode == ParserMode.STRING_TDQ:
				return [true, "Unterminated triple double quote"]
			tokens.append(token)
			token = ''
		else:
			assert(false, "Unhandled parser mode: " + str(mode))
		
		if index >= instruction.length():
			break
		
		if instruction[index] in whitespace_chars:
			if mode == ParserMode.NEWLINE:
				mode = ParserMode.LEADING_WHITESPACE
			elif mode == ParserMode.LEADING_WHITESPACE:
				mode = ParserMode.LEADING_WHITESPACE
			elif mode == ParserMode.EMPTY:
				mode = ParserMode.LEADING_WHITESPACE
			else:
				mode = ParserMode.INNER_WHITESPACE
		elif word_regex.search(instruction[index]):
			mode = ParserMode.WORD
		elif instruction[index] in number_chars:
			if mode == ParserMode.WORD:
				mode = ParserMode.WORD
			else:
				mode = ParserMode.NUMBER
		elif instruction[index] in operator_chars:
			mode = ParserMode.OPERATOR
		elif instruction[index] in bracket_chars:
			mode = ParserMode.BRACKET
		elif instruction[index] in '\n':
			mode = ParserMode.NEWLINE
		elif instruction[index] == "'":
			if index + 2 < instruction.length() and instruction.substr(index, 3) == "'''":
				mode = ParserMode.STRING_TSQ
			else:
				mode = ParserMode.STRING_SQ
		elif instruction[index] == '"':
			if index + 2 < instruction.length() and instruction.substr(index, 3) == '"""':
				mode = ParserMode.STRING_TDQ
			else:
				mode = ParserMode.STRING_DQ
		else:
			var err = """failed to detect mode:
				tokens: {tokens}
				token_in_progress: {token}
				character: {character}
				instruction: {instruction}
			""".format({
				'tokens': tokens,
				'token': token,
				'character': instruction[index],
				'instruction': instruction,
			})
			assert(false, err)
		index += 1
		
	if token != '':
		tokens.append(token)
		token = ''
	return [error, tokens]


func _delegate_evaluation(command: String, env: ReplEnv):
	## Delegate command evaluation to godot
	
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
	return [false, result]
	

func evaluate(command: String, env:ReplEnv) -> Array:
	if command == '':
		return [false, '']
	
	var tokenize_result = tokenize(command)
	# let the parse step below handle tokenizer errors the standard way
	var mode = 'opening'
	if !tokenize_result[0]:  # error
		var tokens = tokenize_result[1]
		while tokens.size() > 0:
			var token = tokens.pop_front()
			if mode == 'opening':
				if token in '\t \n':
					continue
				elif token == 'var':
					mode = 'declare_var'
				elif tokens.size() > 0 and tokens[0] in assignment_operators:
					mode = 'assignment'
					tokens.push_front(token)
			elif mode == 'declare_var':
				env.vars[token] = null
				if tokens.size() == 0:
					return [false, 'var declared: ' + token]
				else: # push varname to front again for assignment
					mode = 'assignment'
					tokens.push_front(token)
			elif mode == 'assignment':
				var varname = token
				var operator = tokens.pop_front()
				if operator not in assignment_operators:
					return [false, 'Unrecognized assignment operator: ' + operator]
				if tokens.size() == 0:
					return [false, 'Missing right side of assignment expression']
				var expression = ' '.join(tokens)
				var eval_result = _delegate_evaluation(expression, env)
				if eval_result[0]:
					return [true, "Failed to evaluate expression: {expression}\n  Error: {error}".format({
						'expression': expression,
						'error': eval_result[0],
					})]
				var value = eval_result[1]
				if operator == '=':
					env.vars[varname] = value
				elif operator == '+=':
					env.vars[varname] += value
				elif operator == '-=':
					env.vars[varname] -= value
				elif operator == '*=':
					env.vars[varname] *= value
				elif operator == '/=':
					env.vars[varname] /= value
				elif operator == '**=':
					env.vars[varname] **= value
				elif operator == '%=':
					env.vars[varname] %= value
				elif operator == '&=':
					env.vars[varname] &= value
				elif operator == '|=':
					env.vars[varname] |= value
				elif operator == '^=':
					env.vars[varname] ^= value
				elif operator == '<<=':
					env.vars[varname] <<= value
				elif operator == '>>=':
					env.vars[varname] >>= value
				else:
					return [true, 'Unrecognized assignment operator: ' + operator]
				return [false, 'Variable assigned']
				
	return _delegate_evaluation(command, env)


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


