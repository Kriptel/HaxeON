package;

import haxe.Hxon;
import haxe.Json;
import sys.io.File;

function main()
{
	Sys.print(Json.stringify(Hxon.parse(File.getContent('test.hxon')), '  '));
}
