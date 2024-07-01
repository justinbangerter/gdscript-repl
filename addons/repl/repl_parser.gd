class_name ReplParser
extends Resource

## Handles parsing and evaluation of text

const assignment_operators = [
	'=', '+=', '-=', '*=', '/=', '**=', '%=', '&=', '|=', '^=', '<<=', '>>='
]
const whitespace_chars = ' \t\r'  # newline handled as special case
const number_chars = '1234567890.'
const operator_chars = '!=<>:+-*/'
const bracket_chars = '()[]{}'

enum ParseMode {
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

enum EvalMode {
	OPEN = 0,
	DECLARE_VAR = 1,
	ASSIGN_VAR = 2,
}


func tokenize(instruction: String) -> Array:
	## On failure, returns [true, "error message"]
	## On success, returns [false, ['\t', '\t', 'list', 'of', 'tokens']]
	## Leading whitespace is preserved, but inner whitespace is discarded
	
	var error = false
	var mode = ParseMode.EMPTY
	var tokens:Array[String] = []
	var token = ''
	
	var word_regex = RegEx.new()
	word_regex.compile("[a-zA-Z_][a-zA-Z_0-9]*")

	var index = 0
	while index < instruction.length():
		if mode == ParseMode.EMPTY:
			token += instruction[index]
		elif mode == ParseMode.NEWLINE:
			tokens.append(token)
			token = instruction[index]
		elif mode == ParseMode.LEADING_WHITESPACE:
			tokens.append(token)
			token = instruction[index]
		elif mode == ParseMode.INNER_WHITESPACE:
			if instruction[index] not in whitespace_chars:
				token = instruction[index]
		elif mode == ParseMode.NUMBER:
			if instruction[index] in number_chars:
				token += instruction[index]
			elif word_regex.search(instruction[index]):
				token += instruction[index]
				error = true
			else:
				tokens.append(token)
				token = instruction[index]
		elif mode == ParseMode.WORD:
			if instruction[index] in number_chars or word_regex.search(instruction[index]):
				token += instruction[index]
			else:
				tokens.append(token)
				token = instruction[index]
		elif mode == ParseMode.OPERATOR:
			if token.length() > 1:
				tokens.append(token)
				token = instruction[index]
			elif instruction[index] in operator_chars:
				token += instruction[index]
			else:
				tokens.append(token)
				token = instruction[index]
		elif mode == ParseMode.BRACKET:
			tokens.append(token)
			token = instruction[index]
		elif mode == ParseMode.STRING_SQ:
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
				mode = ParseMode.END_STRING
			if mode == ParseMode.STRING_SQ:
				return [true, "Unterminated single quote"]
			tokens.append(token)
			token = ''
		elif mode == ParseMode.STRING_DQ:
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
				mode = ParseMode.END_STRING
			if mode == ParseMode.STRING_DQ:
				return [true, "Unterminated double quote"]
			tokens.append(token)
			token = ''
		elif mode == ParseMode.STRING_TSQ:
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
				mode = ParseMode.END_STRING
			if mode == ParseMode.STRING_TSQ:
				return [true, "Unterminated triple single quote"]
			tokens.append(token)
			token = ''
		elif mode == ParseMode.STRING_TDQ:
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
				mode = ParseMode.END_STRING
			if mode == ParseMode.STRING_TDQ:
				return [true, "Unterminated triple double quote"]
			tokens.append(token)
			token = ''
		else:
			assert(false, "Unhandled parser mode: " + str(mode))
		
		if index >= instruction.length():
			break
		
		if instruction[index] in whitespace_chars:
			if mode == ParseMode.NEWLINE:
				mode = ParseMode.LEADING_WHITESPACE
			elif mode == ParseMode.LEADING_WHITESPACE:
				mode = ParseMode.LEADING_WHITESPACE
			elif mode == ParseMode.EMPTY:
				mode = ParseMode.LEADING_WHITESPACE
			else:
				mode = ParseMode.INNER_WHITESPACE
		elif word_regex.search(instruction[index]):
			mode = ParseMode.WORD
		elif instruction[index] in number_chars:
			if mode == ParseMode.WORD:
				mode = ParseMode.WORD
			else:
				mode = ParseMode.NUMBER
		elif instruction[index] in operator_chars:
			mode = ParseMode.OPERATOR
		elif instruction[index] in bracket_chars:
			mode = ParseMode.BRACKET
		elif instruction[index] == '\n':
			mode = ParseMode.NEWLINE
		elif instruction[index] == "'":
			if index + 2 < instruction.length() and instruction.substr(index, 3) == "'''":
				mode = ParseMode.STRING_TSQ
			else:
				mode = ParseMode.STRING_SQ
		elif instruction[index] == '"':
			if index + 2 < instruction.length() and instruction.substr(index, 3) == '"""':
				mode = ParseMode.STRING_TDQ
			else:
				mode = ParseMode.STRING_DQ
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
