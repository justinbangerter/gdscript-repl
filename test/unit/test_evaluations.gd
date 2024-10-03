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
	[
		[
			'ClassDB.class_exists("ClassDB")'
		],
		[false, true]
	],
	[
		[
			'var x = load("res://icon.svg")'
		],
		[false, "Variable assigned"]
	],
	[
		[
			'range(0, 10, 2)'
		],
		[false, [0, 2, 4, 6, 8]]
	],
	[
		[
			'var x = [1, 2, 3]',
			'x'
		],
		[false, [1, 2, 3]]
	],
	[
		[
			'var x = {}',
			'x["test"] = 3',
			'x["test"]'
		],
		[false, 3]
	],
	[
		[
			'var x = {}',
			'x["test"] = {}',
			'x["test"]["asdf"] = 3',
			'x["test"]["asdf"]'
		],
		[false, 3]
	],
	[
		[
			'var x = {"b": 3}',
			'var y = {"a": "b"}',
			'x[y["a"]]',
		],
		[false, 3]
	],
	[
		[
			'var x = {"a": 3}',
			'x["a"] += 3',
			'x["a"]',
		],
		[false, 6]
	],
	# walrus operator (type inference)
	[
		[
			'var y := 1',
			'y',
		],
		[false, 1]
	],
	# global singletons
	[
		[
			'Input',
		],
		[false, Input]
	],
	# global enums and constants
	[
		[
			'OK'
		],
		[false, 0]
	],
	[
		[
			'TYPE_NIL'
		],
		[false, 0]
	],
	# TODO: if statement
	#[
		#[
			#'var sum = 0',
			#'if 3 > 1:',
			#'	sum = 6',
			#'sum'
		#],
		#[false, 6]
	#],
	# TODO: if statement
	#[
		#[
			#'var sum = 0',
			#'if 3 < 1:',
			#'	sum = 6',
			#'sum'
		#],
		#[false, 0]
	#],
	# TODO: elif
	#[
		#[
			#'var sum = 0',
			#'if 3 < 1:',
			#'	sum = 6',
			#'elif 3 > 2:
			#'	sum = 5',
			#'sum'
		#],
		#[false, 5]
	#],
	# TODO: else
	#[
		#[
			#'var sum = 0',
			#'if 3 < 1:',
			#'	sum = 6',
			#'else:
			#'	sum = 4',
			#'sum'
		#],
		#[false, 4]
	#],
	# TODO: if/elif/else
	#[
		#[
			#'var sum = 0',
			#'if 3 < 1:',
			#'	sum = 6',
			#'elif false:
			#'	sum = 5',
			#'else:',
			#'	sum = 4',
			#'sum'
		#],
		#[false, 4]
	#],
	# TODO: For loop with number
	#[
		#[
			#'var sum = 0',
			#'for num in 4:',
			#'	sum += num',
			#'sum'
		#],
		#[false, 6]
	#],
	# TODO: For loop with array
	#[
		#[
			#'var sum = ""',
			#'for num in ["a","b","c","d"]:',
			#'	sum += num',
			#'sum'
		#],
		#[false, 'abcd']
	#],
	# TODO: While loop
	#[
		#[
			#'var sum = 0',
			#'while sum < 3:',
			#'	sum += 1',
			#'sum'
		#],
		#[false, 2]
	#],
	# TODO: break
	#[
		#[
			#'var sum = 0',
			#'while true',
			#'	sum += 1',
			#'	break',
			#'sum'
		#],
		#[false, 1]
	#],
	# TODO: continue
	#[
		#[
			#'var sum = 0',
			#'while true',
			#'	sum += 1',
			#'	if sum < 3:',
			#'		continue',
			#'	break',
			#'sum'
		#],
		#[false, 2]
	#],
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
	# TODO: write tests for all the new functions in the main environment
]

func test_evaluate(params=use_parameters(evaluate_params)):
	var env = ReplEnv.new()
	var inputs = params[0]
	var expected_output = params[1]
	var output = [false, 'no action']
	for input in inputs:
		output = parser.evaluate(input, env)
	assert_eq_deep(output, expected_output)
