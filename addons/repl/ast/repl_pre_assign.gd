class_name ReplPreAssign
extends Resource

## command object for assigning a value in the environment

var identifier:String

func _init(identifier:String):
	self.identifier = identifier

func assign(value, env:ReplEnv):
	env.vars[identifier] = value

func access(env:ReplEnv):
	# pull the value from the environment in case it needs to be transformed
	# before reassignment
	return env.vars[identifier]
