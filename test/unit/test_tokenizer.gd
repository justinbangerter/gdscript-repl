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
		[true, 'Error at (1, 3): Invalid numeric notation.']
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
		'true && true',
		[false, ['true', '&&', 'true']]
	],
	[
		'false || true',
		[false, ['false', '||', 'true']]
	],
	[
		'!false',
		[false, ['!', 'false']]
	],
	[
		'a |= true',
		[false, ['a', '|=', 'true']]
	],
	[
		'a &= true',
		[false, ['a', '&=', 'true']]
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
	],
	[
		'var x = load("res://icon.svg")',
		[false, ['var', 'x', '=', 'load', '(', '"res://icon.svg"', ')']]
	],
	[
		'0b010101',
		[false, ['0b010101']]
	],
	[
		'0xDEADBEEF',
		[false, ['0xDEADBEEF']]
	],
	[
		'0',
		[false, ['0']]
	],
	[
		'0E10',
		[false, ['0E10']]
	],
	[
		'var x = 0',
		[false, ['var', 'x', '=', '0']]
	],
	[
		'var x = [1, 2, 3]',
		[false, ['var', 'x', '=', '[', '1', ',', '2', ',', '3', ']']]
	],
	[
		'var x = Area2D.new()',
		[false, ['var', 'x', '=', 'Area2D', '.', 'new', '(', ')']]
	],
]

func test_tokenize(params=use_parameters(tokenize_params)):
	var tokens = parser.tokenize(params[0])
	assert_eq_deep(tokens, params[1])
