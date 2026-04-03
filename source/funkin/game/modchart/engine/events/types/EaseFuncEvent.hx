package funkin.game.modchart.engine.events.types;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;

class EaseFuncEvent extends Event {
    public var startBeat:Float;
    public var endBeat:Float;
    public var beatLength:Float;
    public var ease:EaseFunction;
    
    public var easeCallback:(Event, Float, Float) -> Void;

    public function new(beat:Float, length:Float, easeCallback:(Event, Float, Float) -> Void, easeType:EaseFunction, parent:EventManager) {
        this.name = null;
        this.player = -1;

        super(beat, (_, beat) -> {}, parent, true);
        
        this.startBeat = beat;
        this.endBeat = beat + length;
        this.beatLength = length;
        this.easeCallback = easeCallback;

        this.target = 1;
        
        this.ease = easeType != null ? easeType : FlxEase.linear;

        type = EASE_FUNC;
    }

	var entryPerc:Float = 0;

	override function update(curBeat:Float) {
		if (fired)
			return;

		if (curBeat < endBeat) {
			var progress = (curBeat - startBeat) / (endBeat - startBeat);
			var out = FlxMath.lerp(entryPerc, target, ease(progress));
			easeCallback(this, out, curBeat);
            trace(this.type + " - " + out + " - " + curBeat);
			fired = false;
		} else if (curBeat >= endBeat) {
			fired = true;
			easeCallback(this, ease(1) * target, curBeat);
            trace(this.type + " - " + ease(1) * target + " - " + curBeat);
		}
	}
}