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
	

func evaluate(command: String, env:ReplEnv) -> Array:
	if command == '':
		return [false, '']
	
	var expressions:Array[ReplExpression]
	var tokenizer = ReplTokenizer.new()
	var tokenize_result = tokenizer.tokenize(command)
	if tokenize_result[0]:  # return error
		return tokenize_result
		
	var mode = EvalMode.OPEN
	var tokens = tokenize_result[1]
	while tokens.size() > 0:
		var token = tokens.pop_front()
		if mode == EvalMode.OPEN:
			if token.content in '\t \r\n':
				continue
			elif token.content == 'var':
				mode = EvalMode.DECLARE_VAR
			elif tokens.size() > 0 and assignment_operators.has(tokens[0].content):
				mode = EvalMode.ASSIGN_VAR
				tokens.push_front(token)
			else:
				# delegate and return
				tokens.push_front(token)
				expressions.append(ReplExpression.REDelegated.new(tokens))
				tokens = []
		elif mode == EvalMode.DECLARE_VAR:
			expressions.append(ReplExpression.REDeclaration.new(token.content))
			if len(tokens) == 0:
				continue
			mode = EvalMode.ASSIGN_VAR
			tokens.push_front(token)
		elif mode == EvalMode.ASSIGN_VAR:
			var varname = token.content
			var operator = tokens.pop_front()
			if tokens.size() == 0:
				return [false, 'Missing right side of assignment expression']
			#if eval_result[0]:
				#return [true, "Failed to evaluate expression: {expression}\n  Error: {error}".format({
					#'expression': expression,
					#'error': eval_result[0],
				#})]
			expressions.append(
				ReplExpression.REAssignment.new(
					ReplPreAssign.new(varname),
					operator.ttype,
					ReplExpression.REDelegated.new(tokens)
				)
			)
			# no support for multiline statements yet
			break
	
	var last_result = [false, '']
	for expression in expressions:
		if last_result[0]:  # propagate errors
			return last_result
		last_result = expression.evaluate(env)
	
	return last_result
