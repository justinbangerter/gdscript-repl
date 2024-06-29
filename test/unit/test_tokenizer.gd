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

var tokenize_params = [
	[
		'asdf',
		[false, ['asdf']]
	],
	[
		'asdf test 1234',
		[false, ['asdf', 'test', '1234']]
	],
	[
		'asdf  test 	1234',
		[false, ['asdf', 'test', '1234']]
	],
	[
		'1==2',
		[false, ['1', '==', '2']]
	],
	[
		'1 != 2',
		[false, ['1', '!=', '2']]
	],
	[
		'asdf_23 + asdf',
		[false, ['asdf_23', '+', 'asdf']]
	],
	[
		'test[value]',
		[false, ['test', '[', 'value', ']']]
	],
	[
		'[]{}({})',
		[false, ['[', ']', '{', '}', '(', '{', '}', ')']]
	],
	[
		'asdf \n\n	 asdf',
		[false, ['asdf', '\n', '\n', '\t', ' ', 'asdf']]
	],
	[
		'   asdf test',
		[false, [' ', ' ', ' ', 'asdf', 'test']]
	],
	[
		'84asdf',
		[true, ['84asdf']]
	],
	[
		'',
		[false, []]
	],
	[
		'\n',
		[false, ['\n']]
	],
	[
		"var ab = 'cd'",
		[false, ['var', 'ab', '=', "'cd'"]]
	],
	[
		'var ab = "cd"',
		[false, ['var', 'ab', '=', '"cd"']]
	],
	[
		"'''ab''' ",
		[false, ["'''ab'''"]]
	],
	[
		"'''ab''' test",
		[false, ["'''ab'''", 'test']]
	],
	[
		"var ab = '''cd'''",
		[false, ['var', 'ab', '=', "'''cd'''"]]
	],
	[
		'var ab = """cd"""',
		[false, ['var', 'ab', '=', '"""cd"""']]
	],
	[
		"var ab = 'cd' + 'ef'",
		[false, ['var', 'ab', '=', "'cd'", '+', "'ef'"]]
	],
	[
		'var ab = "cd" + "ef"',
		[false, ['var', 'ab', '=', '"cd"', '+', '"ef"']]
	],
	[
		"var ab = '''cd''' + '''ef'''",
		[false, ['var', 'ab', '=', "'''cd'''", '+', "'''ef'''"]]
	],
	[
		'var ab = """cd""" + """ef"""',
		[false, ['var', 'ab', '=', '"""cd"""', '+', '"""ef"""']]
	],
	[
		'var test = """a"""',
		[false, ['var', 'test', '=', '"""a"""']]
	]
]

func test_tokenize(params=use_parameters(tokenize_params)):
	var tokens = control.tokenize(params[0])
	assert_eq_deep(tokens, params[1])
