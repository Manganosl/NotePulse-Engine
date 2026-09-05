package funkin.game.modchart.math;

class MathUtil {
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
		return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

	inline public static function clamp(n:Float, l:Float, h:Float){
		if (n > h) n = h;
		if (n < l) n = l;
		return n;
	}

	inline public static function square(angle:Float){
		var fAngle = angle % (Math.PI * 2);
		return fAngle >= Math.PI ? -1.0 : 1.0;
	}

	inline public static function triangle(angle:Float){
		var fAngle:Float = angle % (Math.PI * 2.0);
		if(fAngle < 0.0)
			fAngle += Math.PI * 2.0;
		
		var result:Float = fAngle / Math.PI;
		if(result < 0.5)
			return 2.0 * result;
		else if(result < 1.5)
			return -2.0 * result + 2.0;
		else
			return 2.0 * result - 4.0;
	}

	inline public static function snap(f:Float, snap:Float):Float
		return snap == 0 ? f : Math.fround(f / snap) * snap;

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
		return Math.max(min, Math.min(max, value));

	inline public static function quantizeAlpha(f:Float, interval:Float)
		return Std.int((f + interval / 2) / interval) * interval;

	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint {
		var p = point == null ? FlxPoint.weak() : point;
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}
}