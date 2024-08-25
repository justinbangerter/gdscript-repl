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
	
	var tokenizer = ReplTokenizer.new()
	var tokenize_result = tokenizer.tokenize(command)
	var mode = EvalMode.OPEN
	if !tokenize_result[0]:  # no error
		var full_tokens = tokenize_result[1]
		var tokens = []
		for token in full_tokens:
			tokens.append(token.content)
			
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
