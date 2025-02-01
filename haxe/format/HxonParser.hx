package haxe.format;

using StringTools;

private enum Token
{
	TInt(i:Int);
	TFloat(f:Float);
	TString(s:String);
	TIdent(id:String);
	TStructOpen; // {
	TStructClose; // }
	TTableOpen; // [
	TTableClose; // ]
	TDoubleDot; // :
	TComma; // ,
	TMinus; // -
	TEof;
}

class HxonParser
{
	var identChars:Array<Bool> = [];

	public function new()
	{
		for (char in 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_'.split(''))
			identChars[char.fastCodeAt(0)] = true;
	}

	var input:String;
	var pos:Int = 0;

	public function parse(s:String):Dynamic
	{
		this.input = s;
		this.pos = 0;

		switch (token())
		{
			case TStructOpen:
				return parseStruct();
			case TTableOpen:
				var tk = token();
				if (tk == TTableClose)
				{
					switch (token())
					{
						case TStructOpen:
							return parseMap();
						case TEof:
							return [];
						case tk:
							trace(tk);
					}
				}

				return parseArray();
			case tk:
				unexpected(tk);
		}

		return null;
	}

	function parseStruct():Dynamic
	{
		var struct:Dynamic = {};

		while (true)
		{
			switch (token())
			{
				case TStructClose:
					break;
				case TIdent(id) | TString(id):
					switch (token())
					{
						case TDoubleDot:
							Reflect.setField(struct, id, getValue());
						case TStructOpen:
							Reflect.setField(struct, id, parseStruct());
						case TTableOpen:
							ensure(TTableClose);
							ensure(TDoubleDot);

							switch (token())
							{
								case TTableOpen:
									Reflect.setField(struct, id, parseArray());
								case TStructOpen:
									Reflect.setField(struct, id, parseMap());
								case tk:
									unexpected(tk);
							}
						case tk:
							unexpected(tk);
					}
				case tk:
					unexpected(tk);
			}
		}

		return struct;
	}

	function parseArray():Array<Dynamic>
	{
		var array:Array<Dynamic> = [];

		while (true)
		{
			switch (token())
			{
				case TTableClose:
					break;
				case TComma:
					unexpected(TComma);
				case tk:
					this.nextToken = tk;
			}

			array.push(getValue());

			switch (token())
			{
				case TTableClose:
					break;
				case TComma:
				case tk:
					unexpected(tk);
			}
		}

		return array;
	}

	function parseMap():Map<String, Dynamic>
	{
		var map:Map<String, Dynamic> = [];

		while (true)
		{
			switch (token())
			{
				case TIdent(id) | TString(id):
					map[id] = switch (token())
					{
						case TDoubleDot:
							getValue();
						case TStructOpen:
							parseStruct();
						case TTableOpen:
							ensure(TTableClose);
							ensure(TDoubleDot);
							ensure(TStructOpen);
							parseMap();
						case tk:
							unexpected(tk);
							null;
					}
				case TStructClose:
					break;
				case tk:
					unexpected(tk);
			}
		}

		return map;
	}

	function getValue():Dynamic
	{
		var tk = token();
		return switch (tk)
		{
			case TInt(i):
				i;
			case TFloat(f):
				f;
			case TIdent(id):
				switch (id)
				{
					case 'true':
						true;
					case 'false':
						false;
					case 'null':
						null;
					default:
						throw unexpected(tk);
				}
			case TString(s):
				s;
			case TTableOpen:
				parseArray();
			case TStructOpen:
				parseStruct();
			case TMinus:
				-getValue();
			case tk:
				throw unexpected(tk);
		}
	}

	inline function unexpected(tk:Token)
	{
		throw 'unexpected $tk at line $line ("${input.substring(pos - 5, pos + 5)}")';
	}

	@:noCompletion var char:Int = -1;
	@:noCompletion var nextToken:Token = null;

	var line:Int = 1;

	function token():Token
	{
		if (nextToken != null)
		{
			var tk:Token = nextToken;
			nextToken = null;
			return tk;
		}

		while (true)
		{
			var char:Int;

			if (this.char != -1)
			{
				char = this.char;
				this.char = -1;
			}
			else
				char = readChar();

			switch (char)
			{
				case ' '.code, '\t'.code, '\r'.code:

				case '\n'.code:
					line++;

				case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57: // 0-9
					var n:Int = char - 48;

					while (true)
					{
						var char = readChar();
						switch (char)
						{
							case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
								n *= 10;
								n += char - 48;
							case '.'.code:
								var n:Float = n;

								var i:Float = 1.;

								while (true)
								{
									var char = readChar();
									switch (char)
									{
										case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
											i *= 10;
											n = n + (char - 48) / i;

										default:
											this.char = char;
											break;
									}
								}

								return TFloat(n);
							default:
								this.char = char;
								break;
						}
					}

					return TInt(n);
				case '.'.code:
					var n:Float = 0.;

					var i:Float = 1.;

					while (true)
					{
						var char = readChar();
						switch (char)
						{
							case 48, 49, 50, 51, 52, 53, 54, 55, 56, 57:
								i *= 10;
								n = n + (char - 48) / i;
							default:
								this.char = char;
								break;
						}
					}

					return TFloat(n);
				case '{'.code:
					return TStructOpen;
				case '}'.code:
					return TStructClose;
				case '['.code:
					return TTableOpen;
				case ']'.code:
					return TTableClose;
				case ':'.code:
					return TDoubleDot;
				case '"'.code, "'".code:
					return TString(readString(char));
				case ",".code:
					return TComma;
				case "-".code:
					return TMinus;
				case _ if (StringTools.isEof(char)):
					return TEof;
				default:
					if (identChars[char])
					{
						var id:String = String.fromCharCode(char);
						while (true)
						{
							var char:Int = readChar();
							if (identChars[char])
								id += String.fromCharCode(char);
							else
							{
								this.char = char;
								break;
							}
						}

						return TIdent(id);
					}
					throw 'unexpected character "${String.fromCharCode(char)}"';
			}
		}
		return null;
	}

	function readString(c:Int):String
	{
		var s = '';
		while (true)
		{
			var char = readChar();
			if (c == char)
				break;

			s += String.fromCharCode(char);
		}

		return s;
	}

	inline function ensure(tk:Token):Void
	{
		var t = token();
		if (t != tk)
			unexpected(tk);
	}

	inline function readChar():Int
		return input.fastCodeAt(pos++);
}
