package backend;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

// from Codename Engine, creds to them :D
class Macro {
	public static var compilerDefines(get, null):Map<String, Dynamic>;
	private static inline function get_compilerDefines() return __getDefines();
	private static macro function __getDefines() {
		#if display
		return macro $v{[]};
		#else
		return macro $v{Context.getDefines()};
		#end
	}
	
	//Adds any extra classes into the executable, no dce
	public static final addonClasses:Array<String> = [
		"backend", //Log.hx has no field "info"

		//Lime library
		"lime.app", "lime.graphics",
		"lime.math", "lime.media", "lime.net",
		"lime.system", "lime.text", "lime.ui", "lime.util",

		//Openfl library
		"openfl"
	];

	@:unreflective public static function compileMacros() {
		#if macro
		//doing this since using `#if 32bits` throws an error
		if(Context.defined("32bits"))
			Compiler.define("x86_BUILD", "1");

		if(Context.defined("hscript_improved_dev"))
			Compiler.define("hscript-improved", "1");

		for(classPackage in addonClasses) Compiler.include(classPackage);
		#end
	}
}