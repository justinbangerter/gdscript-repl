extends GutTest

static var expression_params = []

static func _static_init():
	# evaluation of variable access
	expression_params.append([
		ReplExpression.REDelegated.new([
			ReplToken.new(
				"test",
				ReplToken.TokenType.TK_IDENTIFIER
			)
		]),
		{"test": 3},
		[false, 3],
		{"test": 3},
	])
	
	# evaluation of assignment
	expression_params.append([
		ReplExpression.REAssignment.new(
			ReplPreAssign.new("test"),
			ReplToken.TokenType.TK_OP_EQUAL,
			ReplExpression.REDelegated.new([
				ReplToken.new(
					"5",
					ReplToken.TokenType.TK_CONSTANT
				)
			])
		),
		{},
		[false, "Variable assigned"],
		{"test": 5},
	])
	
	# evaluation of declaration
	expression_params.append([
		ReplExpression.REDeclaration.new("test"),
		{},
		[false, "var declared: test"],
		{"test": null},
	])
	
	# for the overloaded assignment operators, start with 10 and use 3
	var assignment_tests = [
		{
			"op_str": "*=",
			"ttype": ReplToken.TokenType.TK_OP_MUL_EQUAL,
			"result": 30,
		},
		{
			"op_str": "**=",
			"ttype": ReplToken.TokenType.TK_OP_POW_EQUAL,
			"result": 1000,
		},
		{
			"op_str": "<<=", #1010 -> 1010000
			"ttype": ReplToken.TokenType.TK_OP_SHIFT_LEFT_EQUAL,
			"result": 80,
		},
		{
			"op_str": ">>=", #1010 -> 1
			"ttype": ReplToken.TokenType.TK_OP_SHIFT_RIGHT_EQUAL,
			"result": 1,
		},
		{
			"op_str": "|=", #1010 or 11 -> 1011
			"ttype": ReplToken.TokenType.TK_OP_BIT_OR_EQUAL,
			"result": 11,
		},
		{
			"op_str": "&=", #1010 and 11 -> 10
			"ttype": ReplToken.TokenType.TK_OP_BIT_AND_EQUAL,
			"result": 2,
		},
		{
			"op_str": "^=", #1010 and 11 -> 1001
			"ttype": ReplToken.TokenType.TK_OP_BIT_XOR_EQUAL,
			"result": 9,
		},
		{
			"op_str": "+=",
			"ttype": ReplToken.TokenType.TK_OP_ADD_EQUAL,
			"result": 13,
		},
		{
			"op_str": "-=",
			"ttype": ReplToken.TokenType.TK_OP_SUB_EQUAL,
			"result": 7,
		},
		{
			"op_str": "/=",
			"ttype": ReplToken.TokenType.TK_OP_DIV_EQUAL,
			"result": 10/3,
		},
		{
			"op_str": "%=",
			"ttype": ReplToken.TokenType.TK_OP_MOD_EQUAL,
			"result": 1,
		},
	]
	for params in assignment_tests:
		expression_params.append([
			ReplExpression.REAssignment.new(
				ReplPreAssign.new("test"),
				params["ttype"],
				ReplExpression.REDelegated.new([
					ReplToken.new(
						"3",
						ReplToken.TokenType.TK_CONSTANT
					)
				])
			),
			{"test": 10},
			[false, "Variable assigned"],
			{"test": params["result"]},
		])
		
	
	

func test_expression(params=use_parameters(expression_params)):
	var expression = params[0]
	var vars = params[1]
	var result = params[2]
	var result_vars = params[3]
	var env = ReplEnv.new(vars)
	var output = expression.evaluate(env)
	assert_eq_deep(output, result)
	for key in result_vars:
		assert_eq_deep(env.vars[key], result_vars[key])
