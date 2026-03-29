package funkin.game.modchart.engine.modifiers.list;

import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.core.VisualParameters;

class Scale extends Modifier {
    public function new(pf) {
        super(pf);

        setPercent('scale', 1, -1);
        setPercent('scaleX', 1, -1);
        setPercent('scaleY', 1, -1);
        
        setPercent('mini', 0, -1);
        setPercent('miniX', 0, -1);
        setPercent('miniY', 0, -1);

        setPercent('squish', 0, -1);
        setPercent('stretch', 0, -1);
    }

    private inline function lerp(a:Float, b:Float, c:Float):Float {
        return a + (b - a) * c;
    }

    override public function visuals(data:VisualParameters, params:ModifierParameters) {
        var player = params.player;
        var lane = Std.string(params.lane);

        var miniVal = getPercent('mini', player) + getPercent('mini' + lane, player);
        var miniX = getPercent('miniX', player) + getPercent('mini' + lane + 'X', player);
        var miniY = getPercent('miniY', player) + getPercent('mini' + lane + 'Y', player);

        var totalMiniX = (1 - miniVal) * (1 - miniX);
        var totalMiniY = (1 - miniVal) * (1 - miniY);

        var baseScaleX = getPercent('scale', player) + getPercent('scale' + lane, player);
        var baseScaleY = getPercent('scale', player) + getPercent('scale' + lane, player);
        
        baseScaleX *= getPercent('scaleX', player) + getPercent('scaleX' + lane, player);
        baseScaleY *= getPercent('scaleY', player) + getPercent('scaleY' + lane, player);

        var stretchVal = getPercent("stretch", player) + getPercent("stretch" + lane, player);
        var squishVal = getPercent("squish", player) + getPercent("squish" + lane, player);

        var squishX = lerp(1, 2.0, squishVal);
        var squishY = 1 / squishX;

        var stretchX = lerp(1, 0.5, stretchVal);
        var stretchY = 1 / stretchX;

        data.scaleX *= baseScaleX * totalMiniX * squishX * stretchX;
        data.scaleY *= baseScaleY * totalMiniY * squishY * stretchY;

        return data;
    }

    override public function shouldRun(params:ModifierParameters):Bool
        return true;
}