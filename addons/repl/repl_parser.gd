class_name ReplParser
extends Resource

## Handles parsing and evaluation of text

const assignment_operators = [
	'=', '+=', '-=', '*=', '/=', '**=', '%=', '&=', '|=', '^=', '<<=', '>>='
]

enum EvalMode {
	OPEN = 0,
	DECLARE_VAR = 1,
	ASSIGN_VAR = 2,
}

func msg_error_at(instruction, index):
	## Get a message that says there's an error in the instruction at the given index
	## the message will have the line and column number
	var line = 1
	var char = 1
	var i = 0
	while i < index:
		if instruction[i] in '\r\n':
			line += 1
			char = 1
		else:
			char += 1
		i += 1
	return ('Error at (%s, %s)' % [line, char])
			


func tokenize(instruction: String) -> Array:
	## On failure, returns [true, "error message"]
	## On success, returns [false, ['\t', '\t', 'list', 'of', 'tokens']]
	## Leading whitespace is preserved, but inner whitespace is discarded
	var tokens:Array[String] = []
	
	var alphabetical = RegEx.create_from_string("[a-zA-Z]")
	var word_start_chars = RegEx.create_from_string("[a-zA-Z_]")
	var word_end_chars = RegEx.create_from_string("[a-zA-Z_0-9]")

	var index = 0
	while index < instruction.length():
		if word_start_chars.search(instruction[index]):
			var token = instruction[index]
			index += 1
			while index < instruction.length() and word_end_chars.search(instruction[index]):
				token += instruction[index]
				index += 1
			tokens.append(token)
		elif index < instruction.length() and instruction[index] in '1234567890.':
			var token = instruction[index]
			index += 1
			if token == '0' and index < instruction.length() and instruction[index] == 'b':
				token += instruction[index]
				index += 1
				while index < instruction.length() and instruction[index] in '01':
					token += instruction[index]
					index += 1
				if index < instruction.length() and alphabetical.search(instruction[index]):
					return [
						true,
						msg_error_at(instruction, index) + ': Invalid numeric notation.'
					]
				tokens.append(token)
			elif token == '0' and index < instruction.length() and instruction[index] == 'x':
				token += instruction[index]
				index += 1
				while index < instruction.length() and instruction[index] in '01234567890abcdefABCDEF':
					token += instruction[index]
					index += 1
				if index < instruction.length() and alphabetical.search(instruction[index]):
					return [
						true,
						msg_error_at(instruction, index) + ': Invalid numeric notation.'
					]
				tokens.append(token)
			elif token == '.' and index < instruction.length() and word_start_chars.search(instruction[index]):
				# found a period, but it's a method invocation
				tokens.append(token)
			else:
				var e_ct = 0
				while index < instruction.length() and instruction[index] in '1234567890.E':
					if instruction[index] == 'E':
						e_ct += 1
					token += instruction[index]
					index += 1
				if index < instruction.length() and alphabetical.search(instruction[index]):
					return [
						true,
						msg_error_at(instruction, index) + ': Invalid numeric notation.'
					]
				if e_ct > 1:
					return [false, "Too many E's in " + token ]
				tokens.append(token)
				
		elif instruction[index] in '*<>':
			# could be *, *=, or **=
			# or >, >=, or >>=
			# or <, <=, or <<=
			var token = instruction[index]
			index += 1
			if index < instruction.length() and instruction[index] == token:
				token += instruction[index]
				index += 1
			if index < instruction.length() and instruction[index] == '=':
				token += instruction[index]
				index += 1
			tokens.append(token)
		elif instruction[index] in '|&':
			var token = instruction[index]
			index += 1
			if index < instruction.length() and instruction[index] == token:
				token += instruction[index]
				index += 1
			elif index < instruction.length() and instruction[index] == '=':
				token += instruction[index]
				index += 1
			tokens.append(token)
		elif instruction[index] in '!+-/%^=':
			# could be ! or !=
			var token = instruction[index]
			index += 1
			if index < instruction.length() and instruction[index] == '=':
				token += instruction[index]
				index += 1
			tokens.append(token)
		elif instruction[index] in ':()[]{} \t\r\n,':
			var token = instruction[index]
			tokens.append(token)
			index += 1
		elif instruction[index] == "'":
			if index + 2 < instruction.length() and instruction.substr(index, 3) == "'''":
				# triple single quoted string
				var token = "'''"
				index += 3
				while index + 2 < instruction.length() and instruction.substr(index, 3) != "'''":
					if instruction[index] == '\\':
						token += instruction[index]
						index += 1
					token += instruction[index]
					index += 1
				token += "'''"
				index += 3
				tokens.append(token)
			else:
				# normal single quoted string
				var token = instruction[index]
				index += 1
				while index < instruction.length() and instruction[index] != "'":
					if instruction[index] == '\\':
						token += instruction[index]
						index += 1
					token += instruction[index]
					index += 1
				token += instruction[index]
				index += 1
				tokens.append(token)
		elif instruction[index] == '"':
			if index + 2 < instruction.length() and instruction.substr(index, 3) == '"""':
				# triple double quoted string
				var token = '"""'
				index += 3
				while index + 2 < instruction.length() and instruction.substr(index, 3) != '"""':
					if instruction[index] == '\\':
						token += instruction[index]
						index += 1
					token += instruction[index]
					index += 1
				token += '"""'
				index += 3
				tokens.append(token)
			else:
				# normal double quoted string
				var token = instruction[index]
				index += 1
				while index < instruction.length() and instruction[index] != '"':
					if instruction[index] == '\\':
						token += instruction[index]
						index += 1
					token += instruction[index]
					index += 1
				token += instruction[index]
				index += 1
				tokens.append(token)
		else:
			var err = """failed to parse:
				tokens: {tokens}
				character: {character}
				instruction: {instruction}
			""".format({
				'tokens': tokens,
				'character': instruction[index],
				'instruction': instruction,
			})
			return [true, err]
	
	var final_tokens = []
	var is_leading_whitespace = true
	for token in tokens:
		var is_newline = token in '\r\n'
		var is_whitespace = token in ' \t'
		
		if is_leading_whitespace:
			if not is_whitespace and not is_newline:
				is_leading_whitespace = false
			final_tokens.append(token)
		else:
			if is_newline:
				is_leading_whitespace = true
			if is_whitespace:
				continue
			final_tokens.append(token)
	
	return [false, final_tokens]


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
	
	var mode = EvalMode.OPEN
	if !tokenize_result[0]:  # no error
		var tokens = tokenize_result[1]
		while tokens.size() > 0:
			var token = tokens.pop_front()
			if mode == EvalMode.OPEN:
				if token in '\t \r\n':
					continue
				elif token == 'var':
					mode = EvalMode.DECLARE_VAR
				elif tokens.size() > 0 and tokens[0] in assignment_operators:
					mode = EvalMode.ASSIGN_VAR
					tokens.push_front(token)
			elif mode == EvalMode.DECLARE_VAR:
				env.vars[token] = null
				if tokens.size() == 0:
					return [false, 'var declared: ' + token]
				else: # push varname to front again for assignment
					mode = EvalMode.ASSIGN_VAR
					tokens.push_front(token)
			elif mode == EvalMode.ASSIGN_VAR:
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
	
	# if the tokenizer failed, try delegating evaluation to godot to get a standard error message
	return _delegate_evaluation(command, env)
