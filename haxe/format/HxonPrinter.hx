package haxe.format;

import haxe.ds.StringMap;

using StringTools;

class HxonPrinter
{
	var identChars:Array<Bool> = [];

	public function new()
	{
		for (char in 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_'.split(''))
			identChars[char.fastCodeAt(0)] = true;
	}

	public function print(o:Dynamic, cool:Bool = true):String
	{
		return _print(o, cool, 0);
	}

	function _print(o:Dynamic, cool:Bool, tabs:Int):String
	{
		var s:String = '';

		inline function addTabs(?offset:Int = 0)
			for (i in 0...tabs + offset)
				if (cool)
					s += '\t';

		inline function nextLine()
			s += cool ? '\n' : ' ';

		switch (Type.typeof(o))
		{
			case TObject:
				s += '{';

				for (field in Reflect.fields(o))
				{
					nextLine();

					addTabs(1);
					s += isIdent(field) ? field : '"$field"';

					var value:Dynamic = Reflect.field(o, field);

					if (value is StringMap)
						s += '[]';

					s += ': ' + _print(value, cool, tabs + 1);
				}
				nextLine();

				addTabs();
				s += '}';
			case TInt | TBool | TFloat:
				s += Std.string(o);
			case TClass(String):
				s += '"${Std.string(o)}"';
			case TClass(Array):
				var array:Array<Dynamic> = cast o;

				if (array.length > 0)
				{
					s += '[';

					nextLine();

					for (id => value in array)
					{
						addTabs(1);

						s += _print(value, cool, tabs + 1);

						if (id < array.length - 1)
							s += ',';

						nextLine();
					}

					addTabs();
					s += ']';
				}
				else
					s += '[]';
			case TClass(StringMap):
				var map:Map<String, Dynamic> = cast o;

				if ([for (i in map.keys()) i].length > 0)
				{
					s += '{';

					nextLine();

					for (key => value in map)
					{
						addTabs(1);
						s += key;

						if (value is StringMap)
							s += '[]';

						s += ': ' + _print(value, cool, tabs + 1);

						nextLine();
					}

					addTabs();
					s += '}';
				}
				else
					s += '{}';
			case TClass(_) | TNull | TEnum(_) | TFunction | TUnknown:
				s += 'null';
		}

		return s;
	}

	function isIdent(s:String):Bool
	{
		for (char in s)
		{
			if (!identChars[char])
				return false;
		}

		return true;
	}
}
