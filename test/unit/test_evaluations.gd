extends GutTest

@onready var control := preload('res://addons/repl/control.gd').new()

func before_each():
	pass

func after_each():
	pass

func before_all():
	pass

func after_all():
	control.queue_free()

var evaluate_params = [
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
	# Expression.evaluate() doesn't return triple quoted strings as strings >.>
	#[
		#[
			#'var test = """a"""',
			#'test + "b"'
		#],
		#[false, 'ab']
	#]
]

func test_evaluate(params=use_parameters(evaluate_params)):
	var env = ReplEnv.new()
	var inputs = params[0]
	var expected_output = params[1]
	var output = [false, 'no action']
	for input in inputs:
		output = control.evaluate(input, env)
	assert_eq_deep(output, expected_output)
