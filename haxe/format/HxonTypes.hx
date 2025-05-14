package haxe.format;

interface ISerializable
{
	function serialize():String;
}

class ContextValue implements ISerializable
{
	public var value:Dynamic;

	var _valuePath:String;

	public function new(valuePath:Array<String>, value:Dynamic)
	{
		_valuePath = valuePath.join('.');

		this.value = value;
	}

	public function serialize():String
	{
		return '* context.$_valuePath';
	}

	public function toString():String
	{
		return '(ContextValue){ value: $value }';
	}
}
