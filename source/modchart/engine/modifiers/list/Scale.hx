package modchart.engine.modifiers.list;

import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.VisualParameters;

class Scale extends Modifier {
    public function new(pf) {
        super(pf);

        setPercent('scale', 1, -1);
        setPercent('scaleX', 1, -1);
        setPercent('scaleY', 1, -1);
        
        setPercent('squish', 0, -1);
        setPercent('stretch', 0, -1);
    }

    private inline function lerp(a:Float, b:Float, c:Float):Float {
        return a + (b - a) * c;
    }

    private inline function applyScale(vis:VisualParameters, params:ModifierParameters, axis:String, realAxis:String) {
        var receptorName = Std.string(params.lane);
        var player = params.player;

        var scale = 1.0;
        
        scale *= getPercent('scale' + axis, player) + getPercent('scale' + axis + receptorName, player);
        scale *= 1 - (getPercent('tiny' + axis, player) + getPercent('tiny' + axis + receptorName, player)) * 0.5;

        switch (realAxis) {
            case 'x':
                vis.scaleX *= scale;
            case 'y':
                vis.scaleY *= scale;
            default:
                vis.scaleX *= scale;
                vis.scaleY *= scale;
        }
    }

    override public function visuals(data:VisualParameters, params:ModifierParameters) {
        var player = params.player;
        var lane = Std.string(params.lane);

        applyScale(data, params, '', '');
        applyScale(data, params, 'x', 'x');
        applyScale(data, params, 'y', 'y');

		var stretchVal = getPercent("stretch", player) + getPercent("stretch" + lane, player);
        var squishVal = getPercent("squish", player) + getPercent("squish" + lane, player);

        var stretchX = lerp(1, 0.5, stretchVal);
        var stretchY = lerp(1, 2.0, stretchVal);

        var squishX = lerp(1, 2.0, squishVal);
        var squishY = lerp(1, 0.5, squishVal);

        data.scaleX *= (squishX * stretchX);
        data.scaleY *= (squishY * stretchY);

        return data;
    }

    override public function shouldRun(params:ModifierParameters):Bool
        return true;
}