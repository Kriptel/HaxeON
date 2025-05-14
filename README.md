## HaxeON
Simplified JSON format

see [`example`](./test/test.hxon)
```hxon
{
	a: 1,
	"b": 1.1
	c: true,
	d: *context.test.a
	array: [1,2,3]
	struct {
		a: 1
		"b": 1.2
	}
	map[]: {
		a: null
		b: 1,
		c: true
		d: **context.test.a
	}
}
```

### Features
- Context value

	Variable from the context object. 
	
	One asterisk (`*`) creates an extra layer to preserve the reference during serialization. 
	
	Two asterisks (`**`) create an "abstract" layer that is not preserved during deserialization.

	```haxe
	var data:String = '
	{
		a: *context.с
		b: **context.c
	}';

	var obj:Dynamic = {
		c: 12
	}
	trace(Hxon.parse(data, obj)); // { a: (ContextValue){ value: 12 }, b: 12 }
	```

- Custom object serialization
	```haxe
	class Value implements ISerializable
	{
		public var value:String;

		public function new(value:String) {
			this.value = value;
		}

		public function serialize():String {
			return '{a: $value}';
		}
	}
	```
- Idents / map keys:
	- "a"
	- 'a'
	- a