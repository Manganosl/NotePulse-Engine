package modchart.engine.events.types;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;

class DoEaseEvent extends Event {
	public var beatLength:Float;
	public var ease:EaseFunction;

	var entryPerc:Null<Float> = null;
	var elapsed:Float = 0;
	var totalDuration:Float;

	public function new(mod:String, beatLength:Float, target:Float, ease:EaseFunction, player:Int, parent:EventManager) {
		this.name = mod;
		this.player = player;

		this.beatLength = beatLength;
		this.ease = ease != null ? ease : FlxEase.linear;
		this.target = target;

		var beatDuration:Float = (backend.Conductor.stepCrochet * 0.001) * 4;
		this.totalDuration = beatLength * beatDuration;

		super(0, (_) -> {}, parent, true);

		type = EASE;
	}

	override function update(elapsedTime:Float) {
		if (fired)
			return;

		if (entryPerc == null)
			entryPerc = ModchartUtil.findEntryFrom(this);

		elapsed += elapsedTime;

		var progress = FlxMath.bound(elapsed / totalDuration, 0, 1);

		var out = FlxMath.lerp(entryPerc, target, ease(progress));
		setModPercent(name, out, player);

		if (progress >= 1) {
			fired = true;
			setModPercent(name, ease(1) * target, player);
		}
	}
}