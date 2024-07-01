extends GutTest

@onready var parser := preload('res://addons/repl/repl_parser.gd').new()

func before_each():
	pass

func after_each():
	pass

func before_all():
	pass

func after_all():
	pass

var evaluate_params = [
	[
		['6 / 3'],
		[false, 2]
	],
	[
		['6*3'],
		[false, 18]
	],
	[
		['6 +3'],
		[false, 9]
	],
	[
		['6- 3'],
		[false, 3]
	],
	[
		[
			'var test = 3',
		],
		[false, 'Variable assigned']
	],
	[
		[
			'var test = 3',
			'test + 4'
		],
		[false, 7]
	],
	[
		[
			'var test = "a"',
			'test + "b"'
		],
		[false, 'ab']
	],
	# TODO: protect against double var declarations
	#[
		#[
			#'var test = 3',
			#'var test = 4',
		#]
		#[true, 'var test already declared)']
	#],
	# TODO: Expression.evaluate() doesn't return triple quoted strings as strings >.>
	#[
		#[
			#'var test = """a"""',
			#'test + "b"'
		#],
		#[false, 'ab']
	#]
	# TODO: crash if a new variable is assigned without var
	#[
		#[
			#'undeclared_variable = 3'
		#],
		#[true, 'attempted assignment to uninitialized variable `uninitialized_variable` (use var)']
	#]
]

func test_evaluate(params=use_parameters(evaluate_params)):
	var env = ReplEnv.new()
	var inputs = params[0]
	var expected_output = params[1]
	var output = [false, 'no action']
	for input in inputs:
		output = parser.evaluate(input, env)
	assert_eq_deep(output, expected_output)
