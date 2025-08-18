package debug;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;
import debug.Memory;
import flixel.util.FlxStringUtil;

class MemoryCounter extends Sprite {
	public var memoryText:TextField;
	public var memoryPeakText:TextField;

	public var memoryPeak:Float = 0;

	public function new() {
		super();

		memoryText = new TextField();
		memoryPeakText = new TextField();

		for(label in [memoryText, memoryPeakText]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, 12, -1);
			label.selectable = false;
			addChild(label);
		}
		memoryPeakText.alpha = 0.5;
	}

	public var memory(get, never):Float;
	inline function get_memory():Float
		return Memory.gay();

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		super.__enterFrame(t);

		if (memoryPeak < memory) memoryPeak = memory;
		memoryText.text = FlxStringUtil.formatBytes(memory);
		memoryPeakText.text = ' / ${FlxStringUtil.formatBytes(memoryPeak)}';

		memoryPeakText.x = memoryText.x + memoryText.width;
	}
}
