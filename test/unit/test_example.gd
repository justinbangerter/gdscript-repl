extends GutTest

@onready var control := preload('res://addons/repl/control.gd')

func before_each():
	pass

func after_each():
	pass

func before_all():
	control = load('res://addons/repl/control.gd')

func after_all():
	queue_free()

func test_assert_eq_number_not_equal():
	var tokens = control.new().tokenize('asdf')
	assert_eq(tokens, ['asdf'], "tokenize('asdf')")
