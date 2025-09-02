package modchart.engine.events.types;

import flixel.math.FlxMath;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.tweens.FlxEase;

class DoEaseEvent extends Event {
    public var beatLength:Float;
    public var ease:EaseFunction;

    var entryPerc:Float;
    var elapsed:Float = 0;
    var totalDuration:Float;

    public function new(mod:String, len:Float, target:Float, ease:EaseFunction, player:Int, parent:EventManager) {
        this.name = mod;
        this.player = player;

        this.beatLength = len;
        this.ease = ease != null ? ease : FlxEase.linear;
        this.target = target;

        // duration in seconds (same math as EaseEvent but immediate)
        var beatDuration:Float = (backend.Conductor.stepCrochet * 0.001) * 4;
        this.totalDuration = len * beatDuration;

        // snapshot of current value at creation
        this.entryPerc = ModchartUtil.findEntryFrom(this);

        super(0, (_) -> {}, parent, true);

        type = EASE;
    }

    override function update(elapsedTime:Float) {
        if (fired) return;

        elapsed += elapsedTime;

        if (elapsed < totalDuration) {
            var progress = FlxMath.bound(elapsed / totalDuration, 0, 1);
            var out = FlxMath.lerp(entryPerc, target, ease(progress));

            setModPercent(name, out, player);
            fired = false;
        } else {
            fired = true;
            // ensure it finishes at exact target
            setModPercent(name, ease(1) * target, player);
        }
    }
}
