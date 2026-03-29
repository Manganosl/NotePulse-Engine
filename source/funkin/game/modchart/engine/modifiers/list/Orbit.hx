package funkin.game.modchart.engine.modifiers.list;

import funkin.game.modchart.backend.core.ModifierParameters;

class Orbit extends Modifier {
	override public function render(curPos:Vector3, params:ModifierParameters) {
		var player = params.player;

		var radiusX = getPercent("orbitX", player) + getPercent("orbitY", player) + getPercent("orbit", player);
		var radiusY = getPercent("orbitY", player) + getPercent("orbit", player);
		var radiusZ = getPercent("orbitX", player);

		if (radiusX == 0 && radiusY == 0)
			return curPos;

		var speed = getPercent("orbitSpeed", player);
		var offset = getPercent("orbitOffset", player);

		var time = params.songTime * 0.001;
		var ang = (time * ((speed * 1.2) + 1.2))
		        + (params.lane * ((offset * 1.8) + 0.4));

		var scalar = ARROW_SIZE * 0.4; 

		var xAdd = cos(ang) * radiusX * scalar;
		var yAdd = sin(ang) * radiusY * scalar;
		var zAdd = sin(ang) * radiusZ * scalar;

		curPos.x += xAdd;
		curPos.y += yAdd;
		curPos.z += zAdd;

		return curPos;
	}

	override public function shouldRun(params:ModifierParameters):Bool
		return true;
}
