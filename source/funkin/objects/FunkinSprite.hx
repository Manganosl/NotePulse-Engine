package funkin.objects;

import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import animate.FlxAnimate;

// Original 3D code from https://github.com/dotaxel/Flixel-3DSprites/blob/main/source/flixel/FlxSprite3D.hx
class FunkinSprite extends FlxAnimate {
    public var angle3D:Vector3D = new Vector3D();

    public var matrixExposed:Bool = false;

    public var transformMatrix(default, null):Matrix = new Matrix();

	/**
	 * Skew offset mainly added for SkewModifier on modchart but can be used for other purposes.
	 */
    public var skewOffset(default, null):FlxPoint = FlxPoint.get();

    @:noCompletion private var __angle3D:Vector3D = new Vector3D();

    @:noCompletion private static var __rotationMatrix:Matrix3D = new Matrix3D();
    @:noCompletion private static var __basisX:Vector3D = new Vector3D();
    @:noCompletion private static var __basisY:Vector3D = new Vector3D();
    @:noCompletion private static var __skewMatrix:FlxMatrix = new FlxMatrix();

    override function prepareDrawMatrix(matrix:FlxMatrix, camera:FlxCamera):Void
    {
        final doStageMatrix:Bool = (isAnimate && applyStageMatrix);

        if (doStageMatrix)
        {
            if (postStageMatrixApply)
            {
                matrix.translate(timeline._bounds.x, timeline._bounds.y);
            }
            else
            {
                matrix.concat(library.matrix);
                matrix.translate(timeline._bounds.x * library.matrix.a, timeline._bounds.y * library.matrix.d);
            }
        }

        matrix.translate(-origin.x, -origin.y);
        matrix.scale(scale.x, scale.y);

        if (matrixExposed)
            matrix.concat(transformMatrix);
        else
            matrix.concat(update3DSkewMatrix());

        if (doStageMatrix && postStageMatrixApply)
            matrix.concat(library.matrix);

        getScreenPosition(_point, camera);
        _point.x += origin.x - offset.x;
        _point.y += origin.y - offset.y;

        if (__shouldDoZoomFactor())
        {
            matrix.translate(-camera.width / 2, -camera.height / 2);

            var requestedZoom = (camera.zoom >= 0 ? Math.max : Math.min)(FlxMath.lerp(1, camera.zoom, zoomFactor), 0);
            var diff = requestedZoom / camera.zoom;
            matrix.scale(diff, diff);
            matrix.translate(camera.width / 2, camera.height / 2);
        }

        matrix.translate(_point.x, _point.y);

        if (isPixelPerfectRender(camera))
            preparePixelPerfectMatrix(matrix);
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

            __skewMatrix.setTo(
                a + skewX * b, b + skewY * a,
                c + skewX * d, d + skewY * c,
                0, 0
            );
        }
        else
        {
            __skewMatrix.setTo(a, b, c, d, 0, 0);
        }

        return __skewMatrix;
    }

    override public function isSimpleRender(?camera:FlxCamera):Bool
    {
        return super.isSimpleRender(camera)
            && !matrixExposed
            && angle3D.x == 0 && angle3D.y == 0 && angle3D.z == 0
            && skew.x == 0 && skew.y == 0
            && skewOffset.x == 0 && skewOffset.y == 0;
    }

    override function destroy():Void
    {
        super.destroy();
        skewOffset = FlxDestroyUtil.put(skewOffset);
    }
}