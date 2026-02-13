package modchart.engine.modifiers.list;

import flixel.FlxG;
import flixel.math.FlxMath;
import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;
import modchart.backend.util.ModchartUtil;

class Stealth extends Modifier {
    public function new(pf) {
        super(pf);

        setPercent('alpha', 1, -1);

        setPercent('suddenStart', 5, -1);
        setPercent('suddenEnd', 3, -1);
        setPercent('suddenGlow', 1, -1);

        setPercent('hiddenStart', 5, -1);
        setPercent('hiddenEnd', 3, -1);
        setPercent('hiddenGlow', 1, -1);
    }

    private inline function computeSudden(data:VisualParameters, params:ModifierParameters) {
        final player = params.player;
        final laneStr = Std.string(params.lane);

        // Sudden per-strum logic
        final sudden = getPercent('sudden', player) + getPercent('sudden' + laneStr, player);

        if (sudden == 0)
            return;

        final start = (getPercent('suddenStart', player) + getPercent('suddenStart' + laneStr, player)) * 100;
        final end = (getPercent('suddenEnd', player) + getPercent('suddenEnd' + laneStr, player)) * 100;
        final glow = getPercent('suddenGlow', player) + getPercent('suddenGlow' + laneStr, player);

        final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 1, 0);

        if (glow != 0)
            data.glow += Math.max(0, (1 - alpha) * sudden * 2) * glow;
        data.alpha *= alpha * sudden;
    }

    private inline function computeHidden(data:VisualParameters, params:ModifierParameters) {
        final player = params.player;
        final laneStr = Std.string(params.lane);

        // Hidden per-strum logic
        final hidden = getPercent('hidden', player) + getPercent('hidden' + laneStr, player);

        if (hidden == 0)
            return;

        final start = (getPercent('hiddenStart', player) + getPercent('hiddenStart' + laneStr, player)) * 100;
        final end = (getPercent('hiddenEnd', player) + getPercent('hiddenEnd' + laneStr, player)) * 100;
        final glow = getPercent('hiddenGlow', player) + getPercent('hiddenGlow' + laneStr, player);

        final alpha = FlxMath.remapToRange(FlxMath.bound(params.distance, end, start), end, start, 0, 1);

        if (glow != 0)
            data.glow += Math.max(0, (1 - alpha) * hidden * 2) * glow;
        data.alpha *= alpha * hidden;
    }

    override public function visuals(data:VisualParameters, params:ModifierParameters) {
        final player = params.player;
        final lane = params.lane;
        final laneStr = Std.string(lane);

        final vMod = params.isTapArrow ? 'stealth' : 'dark';
        final visibility = getPercent(vMod, player) + getPercent(vMod + laneStr, player);
        data.alpha = ((getPercent('alpha', player) + getPercent('alpha' + laneStr, player)) * (1 - ((Math.max(0.5, visibility) - 0.5) * 2)));
        data.glow += visibility * 2;

        // sudden & hidden
        if (params.isTapArrow) // non receptor
        {
            computeSudden(data, params);
            computeHidden(data, params);
        }

        return data;
    }

    override public function shouldRun(params:ModifierParameters):Bool
        return true;
}
