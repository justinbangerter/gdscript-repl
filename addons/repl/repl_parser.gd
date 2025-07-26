class_name ReplParser
extends Resource

## Handles parsing and evaluation of text

# https://github.com/godotengine/godot/blob/b97110cd307e4d78e20bfafe5de6c082194b2cd6/modules/gdscript/gdscript_tokenizer.cpp#L44
const comparison_operators = {
	"<": null, #LESS,
	"<=": null, #LESS_EQUAL,
	">": null, #GREATER,
	">=": null, #GREATER_EQUAL,
	"==": null, #EQUAL_EQUAL,
	"!=": null, #BANG_EQUAL,
}

const logical_operators = {
	"and": null, #AND,
	"or": null, #OR,
	"not": null, #NOT,
	"&&": null, #AMPERSAND_AMPERSAND,
	"||": null, #PIPE_PIPE,
	"!": null, #BANG,
}

const bitwise_operators = {
	"&": null, #AMPERSAND,
	"|": null, #PIPE,
	"~": null, #TILDE,
	"^": null, #CARET,
	"<<": null, #LESS_LESS,
	">>": null, #GREATER_GREATER,
}

const math_operators = {
	"+": null, #PLUS,
	"-": null, #MINUS,
	"*": null, #STAR,
	"**": null, #STAR_STAR,
	"/": null, #SLASH,
	"%": null, #PERCENT,
}

const assignment_operators = {
	"=": null, #EQUAL,
	"+=": null, #PLUS_EQUAL,
	"-=": null, #MINUS_EQUAL,
	"*=": null, #STAR_EQUAL,
	"**=": null, #STAR_STAR_EQUAL,
	"/=": null, #SLASH_EQUAL,
	"%=": null, #PERCENT_EQUAL,
	"<<=": null, #LESS_LESS_EQUAL,
	">>=": null, #GREATER_GREATER_EQUAL,
	"&=": null, #AMPERSAND_EQUAL,
	"|=": null, #PIPE_EQUAL,
	"^=": null, #CARET_EQUAL,
	":=": null, #COLON_EQUAL,
}

const control_flow_names = {
	"if": null, #IF,
	"elif": null, #ELIF,
	"else": null, #ELSE,
	"for": null, #FOR,
	"while": null, #WHILE,
	"break": null, #BREAK,
	"continue": null, #CONTINUE,
	"pass": null, #PASS,
	"return": null, #RETURN,
	"match": null, #MATCH,
	"when": null, #WHEN,
}

const keywords = {
	"as": null, #AS,
	"assert": null, #ASSERT,
	"await": null, #AWAIT,
	"breakpoint": null, #BREAKPOINT,
	"class": null, #CLASS,
	"class_name": null, #CLASS_NAME,
	"const": null, #CONST,
	"enum": null, #ENUM,
	"extends": null, #EXTENDS,
	"func": null, #FUNC,
	"in": null, #IN,
	"is": null, #IS,
	"namespace": null, #NAMESPACE
	"preload": null, #PRELOAD,
	"self": null, #SELF,
	"signal": null, #SIGNAL,
	"static": null, #STATIC,
	"super": null, #SUPER,
	"trait": null, #TRAIT,
	"var": null, #VAR,
	"void": null, #VOID,
	"yield": null, #YIELD,
}

const punctuation = {
	"[": null, #BRACKET_OPEN,
	"]": null, #BRACKET_CLOSE,
	"{": null, #BRACE_OPEN,
	"}": null, #BRACE_CLOSE,
	"(": null, #PARENTHESIS_OPEN,
	")": null, #PARENTHESIS_CLOSE,
	",": null, #COMMA,
	";": null, #SEMICOLON,
	".": null, #PERIOD,
	"..": null, #PERIOD_PERIOD,
	":": null, #COLON,
	"$": null, #DOLLAR,
	"->": null, #FORWARD_ARROW,
	"_": null, #UNDERSCORE,
}

# https://github.com/godotengine/godot/blob/b97110cd307e4d78e20bfafe5de6c082194b2cd6/modules/gdscript/gdscript_tokenizer.cpp#L44
# The NaN value has been changed to match line 543 of the same file.
const constants = {
	"PI": null, #CONST_PI,
	"TAU": null, #CONST_TAU,
	"INF": null, #CONST_INF,
	"NAN": null, #CONST_NAN,
}

enum EvalMode {
	OPEN = 0,
	DECLARE_VAR = 1,
	ASSIGN_VAR = 2,
}

func delegate_evaluation(command: String, env: ReplEnv):
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

func build_expressions(tokens:Array) -> Array:
	## Currently only handles one liners
	## However, var assignments become two operations: declaration and assignment
	var mode = EvalMode.OPEN
	var expressions:Array[ReplExpression] = []
	while tokens.size() > 0:
		if mode == EvalMode.OPEN:
			if tokens[0].content in '\t \r\n':
				tokens.pop_front()
			elif tokens[0].content == 'var':
				mode = EvalMode.DECLARE_VAR
				tokens.pop_front()
			elif tokens.size() > 1 and assignment_operators.has(tokens[1].content):
				mode = EvalMode.ASSIGN_VAR
			elif tokens.size() > 1 and tokens[1].content == '[':
				# dictionary key or array. assignment or access?
				var tokens_left := []
				var tokens_right := []
				var assignment:ReplToken
				for token in tokens:
					if assignment_operators.has(token.content):
						if assignment == null:
							assignment = token
						else:
							return [true, "Multiple assignments in expression"]
					elif assignment:
						tokens_right.append(token)
					else:
						tokens_left.append(token)
						
				if assignment != null:
					# pull the key from the id first, in case this is nested
					#  for example x[0][test[1]] = 2
					#  The key would be test[1]
					#  The id would be x[0]
					var key_tokens := []
					tokens_left.pop_back()
					var brackets := 1
					while len(tokens_left) > 0 and brackets > 0:
						var token = tokens_left.pop_back()
						if token.content == ']':
							brackets += 1
						elif token.content == '[':
							brackets -= 1
						if brackets > 0:  # we don't care about the opening bracket
							key_tokens.append(token)
					
					var id_tokens = tokens_left
					
					expressions.append(
						ReplExpression.REAssignment.new(
							ReplPreAssign.DictionaryPreAssign.new(
								ReplExpression.REDelegated.new(id_tokens),
								ReplExpression.REDelegated.new(key_tokens),
							),
							assignment.ttype,
							ReplExpression.REDelegated.new(tokens_right)
						)
					)
					break
				else:
					# delegate and return the whole thing
					expressions.append(ReplExpression.REDelegated.new(tokens))
					tokens = []
			else:
				# delegate and return the whole thing
				expressions.append(ReplExpression.REDelegated.new(tokens))
				tokens = []
		elif mode == EvalMode.DECLARE_VAR:
			expressions.append(ReplExpression.REDeclaration.new(tokens[0].content))
			if len(tokens) == 1:
				continue
			mode = EvalMode.ASSIGN_VAR
		elif mode == EvalMode.ASSIGN_VAR:
			var varname = tokens.pop_front().content
			var operator = tokens.pop_front()
			if tokens.size() == 0:
				return [true, 'Missing right side of assignment expression']
			expressions.append(
				ReplExpression.REAssignment.new(
					ReplPreAssign.new(varname),
					operator.ttype,
					ReplExpression.REDelegated.new(tokens)
				)
			)
			# no support for multiline statements yet
			break
			
	return [false, expressions]

func evaluate(command: String, env:ReplEnv) -> Array:
	if command == '':
		return [false, '']
	
	var tokenizer = ReplTokenizer.new()
	var tokenize_result = tokenizer.tokenize(command)
	if tokenize_result[0]:  # return error
		return tokenize_result
		
	var tokens = tokenize_result[1]
	if len(tokens) and tokens[0].content == '/' and tokens[1].content == 'help':
		var help = ReplHelp.new()
		return help.help(tokens)
	# workaround: see https://github.com/godotengine/godot/issues/98481
	tokenizer.replace_triple_strings(tokens)
	
	var expression_result = build_expressions(tokens)
	if expression_result[0] != false:
		return expression_result
	
	var last_result = [false, '']
	for expression in expression_result[1]:
		if last_result[0]:  # propagate errors
			return last_result
		last_result = expression.evaluate(env)
	
	return last_result
