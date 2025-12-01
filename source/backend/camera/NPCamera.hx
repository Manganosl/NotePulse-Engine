package backend.camera;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxPoint;
import openfl.geom.Matrix;

class NPCamera extends FlxCamera
{
    public var betterShake:Bool = true;
    public var betterShakeHardness:Float = 1;
    public var betterShakeFadeTime:Float = 0.1;
    public var useScrollForShake:Bool = false;

    public var fxShakeIntensity:Float = 0;
    public var fxShakeDuration:Float = -1000;
    public var fxShakeI:Float = -999999;

    public var skew:FlxPoint = new FlxPoint();

    private var lastScrollOffset:FlxPoint = new FlxPoint();
    private var viewOffset:FlxPoint = new FlxPoint();

    private var mat:Matrix = new Matrix();

    public function new(x:Int = 0, y:Int = 0, w:Int = 0, h:Int = 0)
    {
        super(x, y, w, h);
    }

    public inline function startShake(intensity:Float, duration:Float)
    {
        fxShakeIntensity = intensity;
        fxShakeDuration  = duration;
    }

    override function update(elapsed:Float)
    {
        scroll.x -= lastScrollOffset.x;
        scroll.y -= lastScrollOffset.y;

        lastScrollOffset.set(0,0);

        super.update(elapsed);

        var cool = betterShake ? -betterShakeFadeTime : 0;

        fxShakeDuration = fxShakeDuration > cool
            ? fxShakeDuration - elapsed
            : cool;

        viewOffset.set(x, y);
        skew.set(0, 0);

        if (fxShakeDuration > cool)
            applyFancyShake(elapsed, cool);

        applyMatrix();
        applyScroll();
    }

    private function applyFancyShake(dt:Float, cool:Float)
    {
        var sX = fxShakeIntensity * width;
        var sY = fxShakeIntensity * height;

        var rX = 0.0;
        var rY = 0.0;
        var rAngle = 0.0;
        var rSkewX = 0.0;
        var rSkewY = 0.0;

        if (betterShake)
        {
            var w = (fxShakeDuration / -cool) + 1;
            var ww  = clamp(w, 0, 1) * (-betterShakeHardness + 1);
            var www = clamp(w, 0, 1) * betterShakeHardness;

            fxShakeI += clamp((fxShakeIntensity * 7) + .75, 0, 10)
                * dt * clamp(w, 0, 1.5);

            rX = Math.cos(fxShakeI * 97) * sX * ww;
            rY = Math.sin(fxShakeI * 86) * sY * ww;

            rAngle = Math.sin(fxShakeI * 62)
                * clamp(fxShakeIntensity * 66, -60, 60)
                * ww;

            rSkewX = Math.cos(fxShakeI * 54)
                * clamp(fxShakeIntensity * 12, -4, 4)
                * ww;

            rSkewY = Math.sin(fxShakeI * 51)
                * clamp(fxShakeIntensity * 12, -1.5, 1.5)
                * ww;

            if (betterShakeHardness > 0)
            {
                rX += Math.cos(fxShakeI * 165) * sX * www;
                rY += Math.cos(fxShakeI * 132) * sY * www;

                rAngle += Math.sin(fxShakeI * 111)
                    * clamp(fxShakeIntensity * 66, -60, 60)
                    * www;

                rSkewX += Math.sin(fxShakeI * 123)
                    * clamp(fxShakeIntensity * 12, -4, 4)
                    * www;

                rSkewY += Math.cos(fxShakeI * 101)
                    * clamp(fxShakeIntensity * 12, -1.5, 1.5)
                    * www;
            }
        }
        else
        {
            rX = FlxG.random.float(-sX, sX);
            rY = FlxG.random.float(-sY, sY);
        }

        if (useScrollForShake)
        {
            lastScrollOffset.set(rX, rY);
        }
        else
        {
            viewOffset.add(rX * zoom, rY * zoom);
        }

        angle += rAngle;
        skew.add(rSkewX, rSkewY);
    }

    private function applyMatrix()
    {
        if (flashSprite == null) return;

        var scaleModeX = FlxG.scaleMode.scale.x;
        var scaleModeY = FlxG.scaleMode.scale.y;

        var w = width  * scaleX;
        var h = height * scaleY;

        var aW = w * 0.5;
        var aH = h * 0.5;

        mat.identity();

        mat.translate(-aW, -aH);
        mat.scale(scaleX, scaleY);
        mat.rotate(angle * Math.PI / 180);
        applySkew(mat, skew.x, skew.y);
        mat.translate(aW, aH);

        mat.translate(viewOffset.x, viewOffset.y);
        mat.scale(scaleModeX, scaleModeY);

        flashSprite.transform.matrix = mat;

        _flashOffset.x = (width * 0.5) * scaleModeX * initialZoom - (x * scaleModeX);
        _flashOffset.y = (height * 0.5) * scaleModeY * initialZoom - (y * scaleModeY);
    }

    private inline function applyScroll()
    {
        scroll.x += lastScrollOffset.x;
        scroll.y += lastScrollOffset.y;
    }

    private static inline function applySkew(mat:Matrix, x:Float, y:Float)
    {
        var skb = Math.tan(y * Math.PI / 180);
        var skc = Math.tan(x * Math.PI / 180);

        mat.b += mat.a * skb;
        mat.c += mat.d * skc;
    }

    private static inline function clamp(v:Float, min:Float, max:Float):Float
        return Math.max(min, Math.min(max, v));
}
