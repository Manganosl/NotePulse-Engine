package backend.extraUtils;

import sys.FileSystem;
import lime.app.Application;
import backend.Paths;

@:keep class NdllUtil {
	public static var os(get, never):String;
	inline public static function get_os():String {
		return CoolUtil.getBuildTarget();
	}

	public static function getFunction(ndllPath:String, name:String, args:Int):Dynamic {
		var finalPath = Paths.ndll("ndlls/"+ndllPath);
		var func:Dynamic = _getNdllFunc(finalPath, name, args);
		trace(finalPath);

		return Reflect.makeVarArgs(function(a:Array<Dynamic>) {
			return backend.extraUtils.MacroUtil.generateReflectionLike(25, "func", "a");
		});
	}

	public static function _getNdllFunc(ndll:String, name:String, args:Int):Dynamic {
		if (!FileSystem.exists(ndll)) {
			trace('getFunction: ndll "${ndll}" doesn\'t exist!');
			return noop;
		}
		var func = lime.system.CFFI.load('./${ndll}', name, args);

		if (func != null) return func;

		trace('getFunction: There was an error getting the ndll\'s functions! {ndll: ${ndll}, function: ${name}, argument count: ${args}}');
		return noop;
	}

	@:dox(hide) @:noCompletion static function noop() {}
}