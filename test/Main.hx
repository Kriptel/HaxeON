package;

import haxe.Hxon;
import haxe.Json;
import sys.io.File;

function main()
{
	var obj:Dynamic = {
		test: {a: 123}
	}

	Sys.println(Json.stringify(Hxon.parse(File.getContent('test.hxon'), obj), '  '));
}
