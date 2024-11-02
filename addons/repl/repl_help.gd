class_name ReplHelp
extends Resource

## provides help text in the REPL

static func help(tokens:Array):
	if len(tokens) == 2:
		return [OK, """
		History:
			When you execute a command, it is recorded as history.
			Use the up/down arrows to move through the command history.
		
		Inserting files:
			Click the "File" button and navigate to your resource.
			The file path will be inserted into the prompt at the cursor position when you click "Open."
		
		Additional help (run `/help <category>`):
			utils: list of built-in utils for the REPL
			cookbook: miscellaneous examples"""]
	match tokens[2].content:
		'utils':
			return [OK, """Utils:
			
		type_name(obj): Get the type of a variable as a string
			type_name(3)  # int
			"""]
		'cookbook':
			return [OK, """Cookbook:
		Pretty-print a dictionary or array:
			JSON.stringify(arr, "\\t")  # the second arg defines how to indent the string.
		
		Loading class files:
			var my_class = load("res://path/to/my/script.gd")
			my_class.static_method()
			my_class.new().instance_method()
		
		List methods/properties/signals on an object:
			JSON.stringify(obj.get_method_list(), "\\t")
			also works with get_property_list, get_signal_list, etc..
			https://docs.godotengine.org/en/stable/classes/class_object.html
		
		# Interacting with the editor
		
		Get the currently selected nodes in the scene tree:
			EditorInterface.get_selection().get_selected_nodes()
			"""]
		_:
			return [FAILED, """Unrecognized help section""" % tokens[2].content]
