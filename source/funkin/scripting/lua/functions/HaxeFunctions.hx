package funkin.scripting.lua.functions;

import hscript.Interp;

import funkin.scripting.lua.FunkinLua;
import funkin.scripting.LuaUtils;
import funkin.scripting.FunkinScript;

class HaxeFunctions extends FunkinScript {
	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	#else
	public var parentLua:Dynamic;
	#end

	#if LUA_ALLOWED
	override public function new(?parent:FunkinLua)
	#else
	override public function new(?parent:Dynamic)
	#end
	{
		super(null, null, false, false); //legally forced to put this by the haxe gods

		#if HSCRIPT_ALLOWED
		if(parser == null) this.initParser();
		if(interp == null) this.initInterp();

		if(FlxG.state is PlayState) this.setParent(PlayState.instance);
		else this.setParent(LuaUtils.getHScriptParent());

		for(key => value in FunkinScript.classes) interp.variables.set(key, value);

		interp.variables.set('this', this);
		interp.variables.set('Alphabet', funkin.objects.Alphabet);
		interp.variables.set('CustomSubstate', funkin.scripting.CustomSubstate);

		FunkinScript.addHScriptExtras(interp, LuaUtils.isPlayStateScript(interp.scriptObject));

		if(parent != null) {
			this.parentLua = parent;
			interp.variables.set('parentLua', #if LUA_ALLOWED parent #else null #end);
			interp.variables.set('scriptName', #if LUA_ALLOWED parent.scriptName #else null #end);
		}
		#end
	}

	#if HSCRIPT_ALLOWED
	override function initInterp() {
		interp = new Interp();
		interp.importFailedCallback = this.onImportFailed;
	}

	public function execute(codeToRun:String):Dynamic {
		if(parser == null) initParser();
		parser.line = 1;

		return interp.execute(parser.parseString(codeToRun, (parentLua != null ? '${parentLua.scriptName}:runHaxeCode' : 'hscript')));
	}

	public function destroy() {
		expr = null;
		interp = null;
		parser = null;
	}
	#end

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		if(funk == null) return;

		funk.addLocalCallback("runHaxeCode", function(codeToRun:String):Dynamic {
			var returnVal:Dynamic = null;
			#if HSCRIPT_ALLOWED
			try {
				returnVal = funk.hscript.execute(codeToRun);
				return (LuaUtils.isLuaSupported(returnVal) ? returnVal : null);
			} catch(e:Dynamic) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - $e', false, false, FlxColor.RED);
			}
			#else
			FunkinLua.luaTrace("runHaxeCode: FunkinScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
			return returnVal;
		});

		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			#if HSCRIPT_ALLOWED
			if(!funk.hscript.variables.exists(funcToRun)) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - Function "${funcToRun}" does not exist!', false, false, FlxColor.RED);
				return null;
			}

			try {
				return funk.hscript.call(funcToRun, funcArgs);
			} catch(e:Dynamic) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - $e', false, false, FlxColor.RED);
			}
			#else
			FunkinLua.luaTrace("runHaxeFunction: FunkinScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			return null;
		});

		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			#if HSCRIPT_ALLOWED
			if(funk.hscript == null) return;

			var str:String = '';
			if(libPackage.length > 0) str = libPackage + '.';
			else if(libName == null) libName = '';

			var classObj:Dynamic = Type.resolveClass(str + libName);
			if(classObj == null) classObj = LuaUtils.getMacroAbstractClass(str + libName); //If the class doesn't exist, then it checks for an hscript generated abstract class
			if(classObj == null) classObj = Type.resolveEnum(str + libName); //If the class STILL doesn't exist, then it checks for an enum

			try {
				if(classObj != null)
					funk.hscript.variables.set(libName, classObj);
				else
					FunkinLua.luaTrace("addHaxeLibrary: Library \"" + (str + libName) + "\" does not exist!", false, false, FlxColor.RED);

			} catch(e:Dynamic) {
				FunkinLua.luaTrace('${funk.scriptName}:${funk.lastCalledFunction} - $e', false, false, FlxColor.RED);
			}
			FunkinLua.luaTrace("addHaxeLibrary is deprecated! Import classes using the \"import\" keyword instead!", false, true);

			#else
			FunkinLua.luaTrace("addHaxeLibrary: FunkinScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end
		});
	}
	#end
}