import flixel.FlxGame;
import haxe.CallStack;
import haxe.Exception;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSignal.FlxTypedSignal;

class Funkin extends FlxGame
{
	public static var onGameCrash(default, null):FlxTypedSignal<(String,String)->Void> = new FlxTypedSignal<(String,String)->Void>();

	override function create(_):Void {
		try {super.create(_);} catch(e) {onCrash(e);}
	}

	override function update():Void {
		try {super.update();} catch(e) {onCrash(e);}
	}

	override function draw():Void {
		try {super.draw();} catch(e) {onCrash(e);}
	}

	override function onEnterFrame(_):Void {
		try {super.onEnterFrame(_);} catch(e) {onCrash(e);}
	}

	override function onFocus(_):Void {
		try {super.onFocus(_);} catch(e) {onCrash(e);}
	}

	override function onFocusLost(_):Void {
		try {super.onFocusLost(_);} catch(e) {onCrash(e);}
	}

	private final function onCrash(e:Exception):Void {
		var errMsg:String = "";
		for(stackItem in CallStack.exceptionStack(true)) {
			switch(stackItem) {
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					trace(stackItem);
			}
		}

		if(onGameCrash != null) {
			onGameCrash.dispatch(errMsg, e.message);
		}

		FlxTransitionableState.skipNextTransOut = true;
		FlxG.switchState(new states.handlers.CrashHandlerState(FlxG.state, errMsg, e.message));
	}
}