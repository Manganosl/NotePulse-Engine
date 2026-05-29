package flixel.addons.effects;

import openfl.geom.Matrix;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;

/**
 * @author Zaphod
 */
class FlxSkewedSprite extends FlxSprite
{
	public var skew(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Skew offset mainly added for SkewModifier on modchart but can be used for other purposes.
	 */
	public var skewOffset(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Tranformation matrix for this sprite.
	 * Used only when matrixExposed is set to true
	 */
	public var transformMatrix(default, null):Matrix = new Matrix();

	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = false;

	/**
	 * Internal helper matrix object. Used for rendering calculations when matrixExposed is set to false
	 */
	var _skewMatrix:Matrix = new Matrix();

	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		skew = FlxDestroyUtil.put(skew);
		skewOffset = FlxDestroyUtil.put(skewOffset);
		_skewMatrix = null;
		transformMatrix = null;

		super.destroy();
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (matrixExposed)
		{
			_matrix.concat(transformMatrix);
		}
		else
		{
			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}

			updateSkewMatrix();
			_matrix.concat(_skewMatrix);
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.addPoint(origin);
		if (isPixelPerfectRender(camera))
			_point.floor();

		if(__shouldDoZoomFactor()) {
			_matrix.translate(-camera.width / 2, -camera.height / 2);

			var requestedZoom = (camera.zoom >= 0 ? Math.max : Math.min)(FlxMath.lerp(1, camera.zoom, zoomFactor), 0);
			var diff = requestedZoom / camera.zoom;
			_matrix.scale(diff, diff);
			_matrix.translate(camera.width / 2, camera.height / 2);
		}

		_matrix.translate(_point.x, _point.y);
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	function updateSkewMatrix():Void
	{
		_skewMatrix.identity();

		if (skew.x != 0 || skew.y != 0 || skewOffset.x != 0 || skewOffset.y != 0)
		{
			_skewMatrix.b = Math.tan((skew.y + skewOffset.y) * FlxAngle.TO_RAD);
			_skewMatrix.c = Math.tan((skew.x + skewOffset.x) * FlxAngle.TO_RAD);
		}
	}

	override public function isSimpleRender(?camera:FlxCamera):Bool
	{
		if (FlxG.renderBlit)
		{
			return super.isSimpleRender(camera) && (skew.x == 0) && (skew.y == 0) && (skewOffset.x == 0) && (skewOffset.y == 0) && !matrixExposed;
		}
		else
		{
			return false;
		}
	}
}