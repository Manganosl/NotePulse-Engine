package funkin.game.modchart.engine.events.types;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;

class EaseFuncEvent extends Event {
    public var startBeat:Float;
    public var endBeat:Float;
    public var beatLength:Float;
    public var ease:EaseFunction;

    public function new(beat:Float, length:Float, callback:(Event, Float, Float) -> Void, easeType:EaseFunction, parent:EventManager) {
        this.startBeat = beat;
        this.endBeat = beat + length;
        this.beatLength = length;
        this.callback = callback;
        
        this.ease = easeType != null ? easeType : FlxEase.linear;

        this.type = REPEATER;

        super(beat, callback, parent, false);
    }

    var entryPerc:Null<Float> = null;
	override function update(curBeat:Float) {
		if (fired)
			return;

		if (curBeat < endBeat) {
			if (entryPerc == null)
				entryPerc = 0;

			var progress = (curBeat - startBeat) / (endBeat - startBeat);
			// maybe we should make it use bound?
			var out = FlxMath.lerp(entryPerc, target, ease(progress));
			callback(this, out, player);
			fired = false;
		} else if (curBeat >= endBeat) {
			fired = true;

			// we're using the ease function bc it may dont return 1
			callback(this, ease(1) * target, player);
		}
	}
}