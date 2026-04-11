package funkin.game.modchart.engine.modifiers.list;

import funkin.game.modchart.backend.core.ArrowData;
import funkin.game.modchart.backend.core.ModifierParameters;

class Transform extends Modifier {
	var xID = 0;
	var yID = 0;
	var zID = 0;

	var xOID = 0;
	var yOID = 0;
	var zOID = 0;

	// Per-lane IDs to avoid Std.string(lane) allocations.
	var xLaneIDs:Array<Int>;
	var yLaneIDs:Array<Int>;
	var zLaneIDs:Array<Int>;

	public function new(pf) {
		super(pf);

		xID = (findID('x') + findID('transformx'));
		yID = (findID('y') + findID('transformy'));
		zID = (findID('z') + findID('transformz'));

		xOID = findID('xoffset');
		yOID = findID('yoffset');
		zOID = findID('zoffset');

		xLaneIDs = [for (l in 0...16) (findID('x' + l) + findID('transform' + l + 'x'))];
		yLaneIDs = [for (l in 0...16) (findID('y' + l) + findID('transform' + l + 'y'))];
		zLaneIDs = [for (l in 0...16) (findID('z' + l) + findID('transform' + l + 'z'))];
	}

	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;
		var lane = params.lane;

		curPos.x += getUnsafe(xID, player) + getUnsafe(xOID, player) + getUnsafe(xLaneIDs[lane], player);
		curPos.y += getUnsafe(yID, player) + getUnsafe(yOID, player) + getUnsafe(yLaneIDs[lane], player);
		curPos.z += getUnsafe(zID, player) + getUnsafe(zOID, player) + getUnsafe(zLaneIDs[lane], player);

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}