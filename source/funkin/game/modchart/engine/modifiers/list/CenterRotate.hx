package funkin.game.modchart.engine.modifiers.list;

import flixel.FlxG;
import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.util.ModchartUtil;

class CenterRotate extends Rotate {
	override public function getOrigin(curPos:Vector3, params:ModifierParameters):Vector3 {
		return new Vector3(FlxG.width * 0.5, HEIGHT * 0.5);
	}

	override public function getRotateName():String
		return 'centerRotate';

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
