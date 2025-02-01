package haxe;

class Hxon
{
	inline public static function parse(s:String):Dynamic
	{
		return new haxe.format.HxonParser().parse(s);
	}

	inline public static function print(o:Dynamic, ?cool:Bool):String
	{
		return new haxe.format.HxonPrinter().print(o, cool);
	}
}
