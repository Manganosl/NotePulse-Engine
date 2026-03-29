package funkin.game.modchart.backend.util;

import funkin.objects.StrumNote;
import funkin.game.modchart.backend.math.Vector3;

/**
 * Normal FlxSkewedSprite with variables to contain modchart-specific data.
 * These variables can be accessed with the `@:privateAccess`.
 */
class ModchartableSprite extends FlxSkewedSprite {
    private var parentArrow:StrumNote = null;
    private var babySprite:ModchartableSprite = null;

    private var modchartIsRating:Bool = false;

	private var modchartNotOnScreen:Array<Bool> = [];
	private var modchartCachedModPos:Array<Vector3> = [];
}