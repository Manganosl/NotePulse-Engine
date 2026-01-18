package debug;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.filters.GlowFilter;

class FPSCounter extends Sprite
{
	var updating:Bool = true;

	var text:TextField;
	var underlay:Bitmap;

	var debugText:TextField;
	var debugUnderlay:Bitmap;
	public var showDebug:Bool = false;

	public var currentFPS(default, null):Int;
	public var memoryMegas(get, never):Float;
	public var memoryPeak:Float = 0;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10)
	{
		super();

		this.x = x;
		this.y = y;

		underlay = new Bitmap(new BitmapData(1, 1, true, 0x6F000000));
		addChild(underlay);

		text = new TextField();
		text.selectable = false;
		text.mouseEnabled = false;
		text.multiline = true;
		text.autoSize = LEFT;
		text.defaultTextFormat = new TextFormat("_sans", 14, 0xFFFFFFFF);
		text.filters = [ new GlowFilter(0x000000, 1, 1, 1, 4, 1) ];
		addChild(text);

		debugUnderlay = new Bitmap(new BitmapData(1, 1, true, 0x6F000000));
		debugUnderlay.visible = false;
		addChild(debugUnderlay);

		debugText = new TextField();
		debugText.selectable = false;
		debugText.mouseEnabled = false;
		debugText.multiline = true;
		debugText.autoSize = LEFT;
		debugText.visible = false;
		debugText.defaultTextFormat = new TextFormat("_sans", 12, 0xFFFFFFFF);
		debugText.filters = [ new GlowFilter(0x000000, 1, 1, 1, 4, 1) ];
		addChild(debugText);

		currentFPS = 0;
		times = [];

		FlxG.signals.postStateSwitch.add(() -> updateText = __updateTxt);
	}

	var deltaTimeout:Float = 0.0;

	override private function __enterFrame(deltaTime:Float):Void
	{
		if (FlxG.keys.justPressed.F3 && ClientPrefs.data.devMode)
		{
			showDebug = !showDebug;
			debugText.visible = showDebug;
			debugUnderlay.visible = showDebug;
			if (showDebug) updateDebugText();
		}

		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();

		if (deltaTimeout < 100)
		{
			deltaTimeout += deltaTime;
			return;
		}

		memoryPeak = Math.max(memoryPeak, memoryMegas);
		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;

		updateText();

		underlay.width = text.width + 4;
		underlay.height = text.height + 2;

		if (showDebug)
		{
			updateDebugText();
			debugText.x = text.x;
			debugText.y = text.y + text.height + 4;

			debugUnderlay.x = debugText.x;
			debugUnderlay.y = debugText.y;
			debugUnderlay.width = debugText.width + 4;
			debugUnderlay.height = debugText.height + 2;
		}

		deltaTimeout = 0.0;
	}

	dynamic function updateText():Void
	{
		__updateTxt();
	}

	function __updateTxt():Void
	{
		if (!updating) return;

		var ms:Float = currentFPS > 0 ? (1000 / currentFPS) : 0;

		text.text =
			'FPS: $currentFPS (${Std.int(ms)} ms)\n' +
			'MEM: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)} / ${flixel.util.FlxStringUtil.formatBytes(memoryPeak)}';

		text.textColor = 0xFFFFFFFF;

		if (currentFPS < FlxG.drawFramerate * 0.5)
			text.textColor = 0xFFFF5555;
	}

	function updateDebugText():Void
	{
		final state = FlxG.state;
		final beatState = Std.isOfType(state, MusicBeatState) ? cast(state, MusicBeatState) : null;
		final subState = state.subState;

		final luaCount = PlayState.instance?.luaArray?.length ?? 0;
		final hscriptCount = beatState?.hscriptArray?.length ?? 0;

		debugText.text =
			'State: ${Type.getClassName(Type.getClass(state))}\n' +
			'SubState: ${subState != null ? Type.getClassName(Type.getClass(subState)) : "None"}\n' +
			'State Objects: ${state.members.length}\n' +
			'FlxG Children: ${FlxG.game.numChildren}\n' +
			'Cameras: ${FlxG.cameras.list.length}\n' +
			'Lua Scripts: $luaCount\n' +
			'HScript Files: $hscriptCount\n';
	}

	inline function get_memoryMegas():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#elseif (openfl >= "9.4.0")
		return cast(openfl.system.System.totalMemoryNumber, UInt);
		#else
		return cast(openfl.system.System.totalMemory, UInt);
		#end
	}
}
