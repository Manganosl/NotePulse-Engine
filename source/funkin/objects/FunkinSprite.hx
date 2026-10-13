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
import flixel.FlxCamera;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import funkin.objects.notes.NoteSilhouette;

// Original 3D code from https://github.com/dotaxel/Flixel-3DSprites/blob/main/source/flixel/FlxSprite3D.hx
// Depth effect from KadeDev's ModEngine
class FunkinSprite extends FlxAnimate {
    public var angle3D:Vector3D = new Vector3D();

    public var matrixExposed:Bool = false;

    public var transformMatrix(default, null):Matrix = new Matrix();

	/**
	 * Skew offset mainly added for SkewModifier on modchart but can be used for other purposes.
	 */
    public var skewOffset(default, null):FlxPoint = FlxPoint.get();

    /**
     * Thickness of the fake 3D body.
     */
    public var extrusion:Float = 20;

    /**
     * Brightness of the side wall.
     */
    public var extrusionShade:Float = 0.5;

    /**
     * Projected direction of the depth axis.
     */
    public var extrusionDepth(default, null):FlxPoint = FlxPoint.get();

    @:noCompletion private var __angle3D:Vector3D = new Vector3D();
    @:noCompletion private var __lastDepthX:Float = 1;
    @:noCompletion private var __lastDepthY:Float = 0;

    @:noCompletion private static var __wallVerts:DrawData<Float> = new DrawData<Float>();
    @:noCompletion private static var __wallUVs:DrawData<Float> = new DrawData<Float>();
    @:noCompletion private static var __wallIndices:DrawData<Int> = new DrawData<Int>();
    @:noCompletion private static var __wallColors:DrawData<Int> = new DrawData<Int>();
    @:noCompletion private static var __depthX:Float = 0;
    @:noCompletion private static var __wallDX:Float = 0;
    @:noCompletion private static var __wallDY:Float = 0;
    @:noCompletion private static var __backFacing:Bool = false;
    @:noCompletion private static var __depthY:Float = 0;

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

        if(matrixExposed){
            matrix.concat(transformMatrix);
            if(skew.x != 0 || skew.y != 0 || skewOffset.x != 0 || skewOffset.y != 0){
                __skewMatrix.setTo(1, Math.tan((skew.y + skewOffset.y) * FlxAngle.TO_RAD), Math.tan((skew.x + skewOffset.x) * FlxAngle.TO_RAD), 1, 0, 0);
                matrix.concat(__skewMatrix);
            }
        }
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

        if (extrusion != 0 && visible && alpha > 0 && !isAnimate)
        {
            drawExtrusion(camera, matrix);
            if (__backFacing)
                matrix.translate(__wallDX, __wallDY);
        }
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

    private function updateExtrusionDepth():Bool
    {
        if (matrixExposed)
        {
            if (extrusionDepth.x != 0 || extrusionDepth.y != 0)
            {
                __depthX = extrusionDepth.x;
                __depthY = extrusionDepth.y;
            }
            else
            {
                final a = transformMatrix.a, b = transformMatrix.b, c = transformMatrix.c, d = transformMatrix.d;
                final zx2 = 1 - a * a - c * c;
                final zy2 = 1 - b * b - d * d;
                var zx:Float = zx2 > 0 ? Math.sqrt(zx2) : 0;
                var zy:Float = zy2 > 0 ? Math.sqrt(zy2) : 0;
                if (a * b + c * d > 0)
                    zy = -zy;
                if (zx * __lastDepthX + zy * __lastDepthY < 0)
                {
                    zx = -zx;
                    zy = -zy;
                }
                __lastDepthX = zx;
                __lastDepthY = zy;
                __depthX = zx;
                __depthY = zy;
            }
        }
        else
        {
            final ax = angle3D.x, ay = angle3D.y, az = angle + angle3D.z;
            if (ax == 0 && ay == 0 && az == 0)
                return false;

            __rotationMatrix.identity();
            __rotationMatrix.appendRotation(az, Vector3D.Z_AXIS);
            __rotationMatrix.appendRotation(ay, Vector3D.Y_AXIS);
            __rotationMatrix.appendRotation(ax, Vector3D.X_AXIS);

            final depth = __rotationMatrix.transformVector(Vector3D.Z_AXIS);
            __depthX = depth.x;
            __depthY = depth.y;
        }

        return __depthX != 0 || __depthY != 0;
    }

    private function drawExtrusion(camera:FlxCamera, drawMatrix:FlxMatrix):Void
    {
        __backFacing = false;

        if (_frame == null || _frame.parent == null)
            return;

        final outline:NoteSilhouette = NoteSilhouette.of(_frame);
        if (outline == null || !outline.ok || outline.count < 3)
            return;

        if (!updateExtrusionDepth())
            return;

        final m:FlxMatrix = drawMatrix;

        final n:Int = outline.count;
        final fw:Float = _frame.frame.width;
        final fh:Float = _frame.frame.height;
        final ox:Float = _frame.offset.x;
        final oy:Float = _frame.offset.y;

        final uv = _frame.uv;
        final spanU:Float = uv.width - uv.x;
        final spanV:Float = uv.height - uv.y;

        final reach:Float = extrusion * (Math.abs(scale.x) + Math.abs(scale.y)) * 0.5;
        final dx:Float = __depthX * reach;
        final dy:Float = __depthY * reach;

        m.translate(-dx * 0.5, -dy * 0.5);

        final face:Matrix = matrixExposed ? transformMatrix : __skewMatrix;
        __backFacing = face.a * face.d - face.b * face.c < 0;
        __wallDX = dx;
        __wallDY = dy;

        final shade:Float = extrusionShade < 0 ? 0 : (extrusionShade > 1 ? 1 : extrusionShade);
        final back:Int = __shadeColor(shade);
        final edge:Int = __shadeColor(1 - (1 - shade) * 0.35);

        final vertexCount:Int = n * 2 + 1;
        __wallVerts.length = vertexCount * 2;
        __wallUVs.length = vertexCount * 2;
        __wallColors.length = vertexCount;
        __wallIndices.length = n * 9;

        for (i in 0...n)
        {
            final nx:Float = outline.px[i];
            final ny:Float = outline.py[i];
            final lx:Float = nx * fw + ox;
            final ly:Float = ny * fh + oy;
            final sx:Float = m.a * lx + m.c * ly + m.tx;
            final sy:Float = m.b * lx + m.d * ly + m.ty;
            final u:Float = uv.x + spanU * nx;
            final v:Float = uv.y + spanV * ny;

            final f:Int = i * 2;
            final b:Int = f + 1;

            __wallVerts[f * 2] = sx;
            __wallVerts[f * 2 + 1] = sy;
            __wallVerts[b * 2] = sx + dx;
            __wallVerts[b * 2 + 1] = sy + dy;

            __wallUVs[f * 2] = u;
            __wallUVs[f * 2 + 1] = v;
            __wallUVs[b * 2] = u;
            __wallUVs[b * 2 + 1] = v;

            __wallColors[f] = edge;
            __wallColors[b] = back;
        }

        {
            final c:Int = n * 2;
            final lx:Float = outline.midX * fw + ox;
            final ly:Float = outline.midY * fh + oy;
            __wallVerts[c * 2] = m.a * lx + m.c * ly + m.tx + dx;
            __wallVerts[c * 2 + 1] = m.b * lx + m.d * ly + m.ty + dy;
            __wallUVs[c * 2] = uv.x + spanU * outline.midX;
            __wallUVs[c * 2 + 1] = uv.y + spanV * outline.midY;
            __wallColors[c] = back;
        }

        var k:Int = 0;
        for (i in 0...n)
        {
            final j:Int = (i + 1) % n;
            final fi:Int = i * 2, bi:Int = fi + 1, fj:Int = j * 2, bj:Int = fj + 1;

            __wallIndices[k++] = fi;
            __wallIndices[k++] = bi;
            __wallIndices[k++] = fj;
            __wallIndices[k++] = bi;
            __wallIndices[k++] = bj;
            __wallIndices[k++] = fj;

            __wallIndices[k++] = n * 2;
            __wallIndices[k++] = bi;
            __wallIndices[k++] = bj;
        }

        camera.drawTriangles(_frame.parent, __wallVerts, __wallIndices, __wallUVs, __wallColors, null, blend, false, antialiasing, colorTransform, shader);
    }

    @:noCompletion private static inline function __shadeColor(shade:Float):Int
    {
        final c:Int = Std.int(shade * 255);
        return 0xFF000000 | (c << 16) | (c << 8) | c;
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
        extrusionDepth = FlxDestroyUtil.put(extrusionDepth);
    }
}