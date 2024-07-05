class_name ReplEnv
extends Resource

# handles eval calls
var eval_script = GDScript.new()

const type_names = {
	TYPE_NIL: 'null',
	TYPE_BOOL: 'bool',
	TYPE_INT: 'int',
	TYPE_FLOAT: 'float',
	TYPE_STRING: 'String',
	TYPE_VECTOR2: 'Vector2',
	TYPE_VECTOR2I: 'Vector2i',
	TYPE_RECT2: 'Rect2',
	TYPE_RECT2I: 'Rect2i',
	TYPE_VECTOR3: 'Vector3',
	TYPE_VECTOR3I: 'Vector3i',
	TYPE_TRANSFORM2D: 'Transform2D',
	TYPE_VECTOR4: 'Vector4',
	TYPE_VECTOR4I: 'Vector4i',
	TYPE_PLANE: 'Plane',
	TYPE_QUATERNION: 'Quaternion',
	TYPE_AABB: 'AABB',
	TYPE_BASIS: 'Basis',
	TYPE_TRANSFORM3D: 'Transform3D',
	TYPE_PROJECTION: 'Projection',
	TYPE_COLOR: 'Color',
	TYPE_STRING_NAME: 'StringName',
	TYPE_NODE_PATH: 'NodePath',
	TYPE_RID: 'RID',
	TYPE_OBJECT: 'Object',
	TYPE_CALLABLE: 'Callable',
	TYPE_SIGNAL: 'Signal',
	TYPE_DICTIONARY: 'Dictionary',
	TYPE_ARRAY: 'Array',
	TYPE_PACKED_BYTE_ARRAY: 'PackedByteArray',
	TYPE_PACKED_INT32_ARRAY: 'PackedInt32Array',
	TYPE_PACKED_INT64_ARRAY: 'PackedInt64Array',
	TYPE_PACKED_FLOAT32_ARRAY: 'PackedFloat32Array',
	TYPE_PACKED_FLOAT64_ARRAY: 'PackedFloat64Array',
	TYPE_PACKED_STRING_ARRAY: 'PackedStringArray',
	TYPE_PACKED_VECTOR2_ARRAY: 'PackedVector2Array',
	TYPE_PACKED_VECTOR3_ARRAY: 'PackedVector3Array',
	TYPE_PACKED_COLOR_ARRAY: 'PackedColorArray'
}

var vars

## These classes can't be loaded in eval and cause problems.
var forbidden_classes = {
	'GDScriptNativeClass': null,
	'GDScriptFunctionState': null,
	'GodotPhysicsDirectSpaceState2D': null,
	'SceneCacheInterface': null,
	'SceneReplicationInterface': null,
	'SceneRPCInterface': null,
	'ThemeContext': null,
}

func _init(_vars={}):
	vars = _vars
	for clazz in ClassDB.get_class_list():
		if clazz in vars:
			continue
		if clazz in forbidden_classes:
			continue
		var result = eval_label(clazz)
		if result[0]:  # error
			print('failed to load: ' + clazz)
			continue
		vars[clazz] = result[1]


func type_name(val):
	var name = type_names[typeof(val)]
	if name == 'Object':
		return val.get_class()
	return name

func eval_label(label:String):
	## load a script into memory just to get the Type/Enum/whatever
	var contents = "static func eval(): return %s" % label
	eval_script.set_source_code(contents)
	var error := eval_script.reload()
	var result
	if(error == OK):
		result = [false, eval_script.eval()]
	else:
		var msg = "Identifier '%s' not declared in the current scope." % label
		result = [true, msg]
	eval_script.get_rid()
	return result
