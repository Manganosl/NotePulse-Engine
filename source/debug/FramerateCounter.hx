package debug;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

class FramerateCounter extends Sprite {
	public var fpsNum:TextField;
	public var fpsLabel:TextField;
	public var lastFPS:Float = 0;
	@:noCompletion private var times:Array<Float>;
	var deltaTimeout:Float = 0.0;
	public var currentFPS(default, null):Int;

	public function new() {
		super();

		fpsNum = new TextField();
		fpsLabel = new TextField();

		times = [];

		for(label in [fpsNum, fpsLabel]) {
			label.autoSize = LEFT;
			label.x = 0;
			label.y = 0;
			label.text = "FPS";
			label.multiline = label.wordWrap = false;
			label.defaultTextFormat = new TextFormat(Framerate.fontName, label == fpsNum ? 18 : 12, -1);
			label.selectable = false;
			addChild(label);
		}
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		super.__enterFrame(t);

		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000) times.shift();
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50) {
			deltaTimeout += t;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;		
		deltaTimeout = 0.0;

		lastFPS = currentFPS;
		fpsNum.text = Std.string(Math.floor(lastFPS));
		fpsLabel.x = fpsNum.x + fpsNum.width;
		fpsLabel.y = (fpsNum.y + fpsNum.height) - fpsLabel.height;
	}
}
