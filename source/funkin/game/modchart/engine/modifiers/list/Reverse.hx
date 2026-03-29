package funkin.game.modchart.engine.modifiers.list;

import flixel.FlxG;
import flixel.math.FlxMath;
import funkin.game.modchart.Manager;
import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.util.ModchartUtil;

// Default modifier
// Handles scroll speed, scroll angle and reverse modifiers
class Reverse extends Modifier {
    public function new(pf) {
        super(pf);
        setPercent('xmod', 1, -1);
    }

    public function getReverseValue(dir:Int, player:Int) {
        var kNum = getKeyCount();
        var val:Float = 0;

        if (dir >= (kNum >> 1))
            val += getPercent("split", player);

        if ((dir & 1) != 0)
            val += getPercent("alternate", player);

        var first = kNum * 0.25;
        if (dir >= first && dir <= kNum - 1 - first)
            val += getPercent("cross", player);

        val += getPercent('reverse', player) + getPercent('reverse$dir', player);

        if (getPercent("unboundedReverse", player) == 0) {
            val %= 2;
            if (val > 1)
                val = 2 - val;
        }

        if (ClientPrefs.data.downScroll)
            val = 1 - val;

        return val;
    }

    override public function render(curPos:Vector3, params:ModifierParameters) {
        var player = params.player;
        var initialY = Adapter.getDefaultReceptorY(params.lane, player) + ARROW_SIZEDIV2;
        var reversePerc = getReverseValue(params.lane, player);

        var shift = initialY + reversePerc * (HEIGHT - 2 * initialY);

        var centerPercent = getPercent('centered', player);
        shift += centerPercent * ((HEIGHT * 0.5) - ARROW_SIZEDIV2 - shift);

        var distance = params.distance * Adapter.getCurrentScrollSpeed();

        var scroll = new Vector3(0, distance * (1 - 2 * reversePerc));
        scroll = applyScrollMods(scroll, params);

        curPos.x += scroll.x;
        curPos.y = shift + scroll.y;
        curPos.z += scroll.z;

        return curPos;
    }

    function applyScrollMods(scroll:Vector3, params:ModifierParameters) {
        var player = params.player;
        var laneStr = '${params.lane}';

        scroll.y *= getPercent('xmod', player) + getPercent('xmod$laneStr', player);

        var angleX = getPercent('scrollAngleX', player) + getPercent('scrollAngleX$laneStr', player);
        var angleY = getPercent('scrollAngleY', player) + getPercent('scrollAngleY$laneStr', player);
        var angleZ = getPercent('scrollAngleZ', player) + getPercent('scrollAngleZ$laneStr', player);

        var shift = params.distance * 0.25 * (1 + getPercent('curvedScrollPeriod', player) + getPercent('curvedScrollPeriod$laneStr', player));

        angleX += shift * (getPercent('curvedScrollX', player) + getPercent('curvedScrollX$laneStr', player));
        angleY += shift * (getPercent('curvedScrollY', player) + getPercent('curvedScrollY$laneStr', player));
        angleZ += shift * (getPercent('curvedScrollZ', player) + getPercent('curvedScrollZ$laneStr', player));

        if (angleX == 0 && angleZ == 0)
            return scroll;

        return ModchartUtil.rotate3DVector(scroll, angleX, angleY, angleZ);
    }

    override public function shouldRun(params:ModifierParameters):Bool
        return true;
}