package funkin.psychlua;

#if sys
import sys.FileSystem;
#end

class GlobalHandler {
	#if(HSCRIPT_ALLOWED && MODS_ALLOWED)
	public static var globalHX:HScript;
	public static var globalHXActive:Bool = false;

	public static function loadGlobalHX(){
		if(globalHX != null) {
			GlobalHandler.destroyGlobalHX();
		}

		var input:String = Paths.mods('${Mods.currentModDirectory}/Global.hx');
		if (FileSystem.exists(input)) {
			globalHX = new HScript(input);
			globalHXActive = true;
			initGlobalHX();
			return;
		} else {
			Log.warn("Global.hx not found in mod directory!");
			globalHX = null;
			globalHXActive = false;
			return;
		}
	}

	public static function initGlobalHX(){
		if(globalHXActive && globalHX != null){
			FlxG.signals.focusGained.add(function(){
				if(globalHXActive) globalHX.call("onFocusGained", []);
			});
			
			FlxG.signals.focusLost.add(function(){
				if(globalHXActive) globalHX.call("onFocusLost", []);
			});

			FlxG.signals.gameResized.add(function(width:Int, height:Int){
				if(globalHXActive) globalHX.call("onGameResized", [width, height]);
			});

			FlxG.signals.postGameStart.add(function(){
				if(globalHXActive) globalHX.call("onGameStart", []);
			});

			FlxG.signals.preGameReset.add(function(){
				if(globalHXActive) globalHX.call("onGameReset", []);
			});

			FlxG.signals.postGameReset.add(function(){
				if(globalHXActive) globalHX.call("onGameResetPost", []);
			});

			FlxG.signals.preStateSwitch.add(function(){
				if(globalHXActive) globalHX.call("onStateSwitch", []);
			});

			FlxG.signals.postStateSwitch.add(function(){
				if(globalHXActive) globalHX.call("onStateSwitchPost", []);
			});

			FlxG.signals.preStateCreate.add(function(state:flixel.FlxState){
				if(globalHXActive) globalHX.call("onStateCreate", [state]);
			});

			FlxG.signals.preDraw.add(function(){
				if(globalHXActive) globalHX.call("onDraw", []);
			});

			FlxG.signals.postDraw.add(function(){
				if(globalHXActive) globalHX.call("onDrawPost", []);
			});

			FlxG.signals.preUpdate.add(function(){
				if(globalHXActive) globalHX.call("onUpdate", [FlxG.elapsed]);
			});

			FlxG.signals.postUpdate.add(function(){
				if(globalHXActive) globalHX.call("onUpdatePost", [FlxG.elapsed]);
			});

			globalHX.call("onCreatePost", []);
		}
	}

	public static function callGlobalHX(callback:String, args:Array<Dynamic>):Dynamic
		return (globalHX != null && globalHXActive) ? globalHX.call(callback, args) : null;

	public static function destroyGlobalHX(){
		if(globalHX != null && globalHXActive) {
			globalHX.call("onDestroy", []);
			globalHX.stop();
			globalHX = null;
			globalHXActive = false;
		}
	}

	public static function stopGlobalHX(){
		if(globalHX != null) {
			globalHX.stop();
			globalHX = null;
			globalHXActive = false;
		}
	}
	#else
	public static function loadGlobalHX(){}
	public static function initGlobalHX(){}
	public static function callGlobalHX(callback:String, args:Array<Dynamic>):Dynamic { return null; }
	public static function destroyGlobalHX(){}
	#end
}