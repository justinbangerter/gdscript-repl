extends GutTest

@onready var parser := preload('res://addons/repl/repl_parser.gd').new()
@onready var tokenizer := preload('res://addons/repl/repl_tokenizer.gd').new()

var tokenize_params = [
	[
		'a = b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'!b',
		[
			false,
			[
				ReplToken.TokenType.TK_OP_NOT,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a != b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_NOT_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a + b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_ADD,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a += b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_ADD_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a - b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_SUB,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a -= b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_SUB_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a / b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_DIV,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a /= b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_DIV_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a % b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_MOD,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a %= b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_MOD_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a ^ b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_BIT_XOR,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a ^= b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_BIT_XOR_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a = b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a == b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_EQUAL_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
	[
		'a := b',
		[
			false,
			[
				ReplToken.TokenType.TK_IDENTIFIER,
				ReplToken.TokenType.TK_OP_COLON_EQUAL,
				ReplToken.TokenType.TK_IDENTIFIER,
			]
		]
	],
]


func test_tokenize(params=use_parameters(tokenize_params)):
	var tokens = tokenizer.tokenize(params[0])
	if tokens[0]:  # error
		assert_eq_deep(tokens, params[1])
		return
	
	# unpack the tokens to strings. This makes it easier to write the tests.
	var unpacked_tokens = []
	for token in tokens[1]:
		unpacked_tokens.append(token.ttype)
	assert_eq_deep([tokens[0], unpacked_tokens], params[1])
