package;

import flixel.FlxGame;
import haxe.CallStack;
import haxe.Exception;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.objects.debug.FunkinSoundTray;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import openfl.events.UncaughtErrorEvent;
import funkin.states.handlers.CrashHandlerState;
import funkin.states.MainMenuState;
import flixel.system.frontEnds.SoundFrontEnd;
import openfl.Lib;

class FunkinGame extends FlxGame {
	override function create(_):Void {
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
		#end

		_customSoundTray = FunkinSoundTray;

		super.create(_);

		#if FLX_SOUND_SYSTEM
		untyped FlxG.sound = new FunkinSoundFrontEnd();
		#end
	}

	static function onCriticalError(message:String):Void
	{
		throw Std.string(message);
	}
	
	static function onUncaughtError(event:UncaughtErrorEvent)
	{
		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
		
		var curFlxState:String = 'N/A';
		
		if (FlxG.state != null)
		{
			final cl = Type.getClass(FlxG.state);
			if (cl != null) curFlxState = (Type.getClassName(cl) ?? 'N/A');
			FlxG.state.persistentUpdate = FlxG.state.persistentDraw = false;
		}
		
		var message:String = Std.string(event.error);
		
		if (Std.isOfType(event.error, Error))
		{
			message = cast(event.error, Error).message;
		}
		else if (Std.isOfType(event.error, ErrorEvent))
		{
			message = cast(event.error, ErrorEvent).text;
		}
		
		var stackMessage:String = '';
		
		for (stackItem in haxe.CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case Method(classname, method):
					stackMessage += 'Function($classname.$method)';
				case CFunction:
					stackMessage += 'Function ';
				case Module(m):
					stackMessage += 'Module($m)';
				case LocalFunction(v):
					stackMessage += 'LocalFunction($v)';
				case FilePos(s, file, line, column):
					stackMessage += file + " (line " + line + ")";
			}
			
			stackMessage += '\n';
		}
		
		event.preventDefault();
		event.stopPropagation();
		event.stopImmediatePropagation();
		
		final callstackMessage = stackMessage.trim().length == 0 ? ' N/A' : '\n$stackMessage';
		
		var fullReport = '$curFlxState\n\nException caught: $message\n\nCallstack:$callstackMessage';
		
		FlxG.switchState(() -> new CrashHandlerState(fullReport, () -> FlxG.switchState(() -> new MainMenuState())));
	}
}

class FunkinSoundFrontEnd extends SoundFrontEnd
{
	override function changeVolume(Amount:Float) // This somehow fixes volume not saving?
	{
		muted = false;
		volume += Amount;
		showSoundTray(Amount > 0);
	}
}