package funkin.objects;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

// Original 3D code from https://github.com/dotaxel/Flixel-3DSprites/blob/main/source/flixel/FlxSprite3D.hx
class FunkinSprite extends FlxSkewedSprite {
	public var angle3D:Vector3D = new Vector3D();

	@:noCompletion private var __angle3D:Vector3D = new Vector3D();

	@:noCompletion private static var __rotationMatrix:Matrix3D = new Matrix3D();
	@:noCompletion private static var __basisX:Vector3D = new Vector3D();
	@:noCompletion private static var __basisY:Vector3D = new Vector3D();

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
			_matrix.concat(update3DSkewMatrix());
		}

		getScreenPosition(_point, camera).subtractPoint(offset);
		_point.addPoint(origin);
		if (isPixelPerfectRender(camera))
			_point.floor();

		if (__shouldDoZoomFactor())
		{
			_matrix.translate(-camera.width / 2, -camera.height / 2);

			var requestedZoom = (camera.zoom >= 0 ? Math.max : Math.min)(FlxMath.lerp(1, camera.zoom, zoomFactor), 0);
			var diff = requestedZoom / camera.zoom;
			_matrix.scale(diff, diff);
			_matrix.translate(camera.width / 2, camera.height / 2);
		}

		_matrix.translate(_point.x, _point.y);
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}


	private function update3DSkewMatrix():Matrix
	{
		__angle3D.setTo(angle3D.x, angle3D.y, angle + angle3D.z);

		var a = 1.0, b = 0.0, c = 0.0, d = 1.0;

		if (__angle3D.x != 0 || __angle3D.y != 0 || __angle3D.z != 0)
		{
			__rotationMatrix.identity();
			__rotationMatrix.appendRotation(__angle3D.z, Vector3D.Z_AXIS);
			__rotationMatrix.appendRotation(__angle3D.y, Vector3D.Y_AXIS);
			__rotationMatrix.appendRotation(__angle3D.x, Vector3D.X_AXIS);

			__basisX.setTo(1, 0, 0);
			__basisY.setTo(0, 1, 0);

			var rotX = __rotationMatrix.transformVector(__basisX);
			var rotY = __rotationMatrix.transformVector(__basisY);

			a = rotX.x;
			b = rotX.y;
			c = rotY.x;
			d = rotY.y;
		}

		if (skew.x != 0 || skew.y != 0 || skewOffset.x != 0 || skewOffset.y != 0)
		{
			var skewX = Math.tan((skew.x + skewOffset.x) * FlxAngle.TO_RAD);
			var skewY = Math.tan((skew.y + skewOffset.y) * FlxAngle.TO_RAD);

			_skewMatrix.setTo(
				a + skewX * b, b + skewY * a,
				c + skewX * d, d + skewY * c,
				0, 0
			);
		}
		else
		{
			_skewMatrix.setTo(a, b, c, d, 0, 0);
		}

		return _skewMatrix;
	}

	override public function isSimpleRender(?camera:FlxCamera):Bool
	{
		return super.isSimpleRender(camera) && angle3D.x == 0 && angle3D.y == 0 && angle3D.z == 0;
	}
}
