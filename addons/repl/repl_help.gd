class_name ReplHelp
extends Resource

## provides help text in the REPL

static func help(tokens:Array):
	if len(tokens) == 2:
		return [OK, """
		View history:
			When you execute a command, it is recorded in history.
			Use the up/down arrows to move through the command history.
		
		Insert files:
			Click the "File" button and navigate to your resource.
			The file path will be inserted into the prompt at the cursor position when you click "Open."
			
		Run scripts on startup:
			Add the path to your script in res://addons/repl/autoloads.txt
			Restart your editor, and it should be available. Check for warnings in the `Output` tab.
		
		Additional help (run `/help <category>`):
			utils: list of built-in utils for the REPL
			cookbook: miscellaneous examples"""]
	match tokens[2].content:
		'utils':
			return [OK, """Utils:
		
		dir(obj): List the properties, methods, and signals of an object
		
		pprint(obj): pretty-print an object, dictionary, or array
			pprint(dir(obj))
			
		type_name(obj): Get the type of a variable as a string
			typeof([])  # 28
			type_name([])  # array
			type_names[28] # array (uses a lookup table to match the enum)
			"""]
		'cookbook':
			return [OK, """Cookbook:
		
		Loading class files:
			var my_class = load("res://path/to/my/script.gd")
			var class_name = my_class.get_class()
			my_class.static_method()
			my_class.new().instance_method()
		
		Get the currently selected nodes in the scene tree:
			EditorInterface.get_selection().get_selected_nodes()
			"""]
		_:
			return [FAILED, """Unrecognized help section""" % tokens[2].content]
