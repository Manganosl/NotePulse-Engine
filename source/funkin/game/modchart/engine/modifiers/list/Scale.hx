package funkin.game.modchart.engine.modifiers.list;

import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;
import funkin.game.modchart.backend.core.VisualParameters;

class Scale extends Modifier {
	static final AXES_S = ['', 'x', 'y'];

	var scaleIDs:Array<Int>;
	var scaleLaneIDs:Array<Array<Int>>;
	var tinyIDs:Array<Int>;
	var tinyLaneIDs:Array<Array<Int>>;

	var squishID:Int;
	var squishLaneIDs:Array<Int>;
	var stretchID:Int;
	var stretchLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		setPercent('scale', 1, -1);
		setPercent('scaleX', 1, -1);
		setPercent('scaleY', 1, -1);
		setPercent('squish', 0, -1);
		setPercent('stretch', 0, -1);

		final maxKeys = 16;
		
		scaleIDs = [for (a in AXES_S) findID('scale' + a)];
		scaleLaneIDs = [for (a in AXES_S) [for (l in 0...maxKeys) findID('scale' + a + l)]];
		
		tinyIDs = [for (a in AXES_S) findID('tiny' + a)];
		tinyLaneIDs = [for (a in AXES_S) [for (l in 0...maxKeys) findID('tiny' + a + l)]];

		squishID = findID('squish');
		squishLaneIDs = [for (l in 0...maxKeys) findID('squish' + l)];
		
		stretchID = findID('stretch');
		stretchLaneIDs = [for (l in 0...maxKeys) findID('stretch' + l)];
	}

	private inline function lerp(a:Float, b:Float, c:Float):Float {
		return a + (b - a) * c;
	}

	override public function visuals(data:VisualParameters, params:ModifierParameters) {
		final lane = params.lane;
		final player = params.player;

		var baseScale = getUnsafe(scaleIDs[0], player);
		var scaleX = getUnsafe(scaleIDs[1], player);
		var scaleY = getUnsafe(scaleIDs[2], player);

		var tiny = getUnsafe(tinyIDs[0], player);
		var tinyX = getUnsafe(tinyIDs[1], player);
		var tinyY = getUnsafe(tinyIDs[2], player);

		var squish = getUnsafe(squishID, player);
		var stretch = getUnsafe(stretchID, player);

		if (Config.COLUMN_SPECIFIC_MODIFIERS) {
			baseScale += getUnsafe(scaleLaneIDs[0][lane], player);
			scaleX += getUnsafe(scaleLaneIDs[1][lane], player);
			scaleY += getUnsafe(scaleLaneIDs[2][lane], player);

			tiny += getUnsafe(tinyLaneIDs[0][lane], player);
			tinyX += getUnsafe(tinyLaneIDs[1][lane], player);
			tinyY += getUnsafe(tinyLaneIDs[2][lane], player);

			squish += getUnsafe(squishLaneIDs[lane], player);
			stretch += getUnsafe(stretchLaneIDs[lane], player);
		}

		var finalScaleX = baseScale * scaleX;
		var finalScaleY = baseScale * scaleY;

		finalScaleX *= (1 - tiny * 0.5) * (1 - tinyX * 0.5);
		finalScaleY *= (1 - tiny * 0.5) * (1 - tinyY * 0.5);

		var sX = lerp(1.0, 2.0, squish);
		var sY = 1.0 / sX;
		finalScaleX *= sX;
		finalScaleY *= sY;

		var stX = lerp(1.0, 0.5, stretch);
		var stY = 1.0 / stX;
		finalScaleX *= stX;
		finalScaleY *= stY;

		data.scaleX *= finalScaleX;
		data.scaleY *= finalScaleY;

		return data;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}