package funkin.game.modchart.math;

class MathUtil {
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float
		return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

	inline public static function clamp(n:Float, l:Float, h:Float){
		if (n > h) n = h;
		if (n < l) n = l;
		return n;
	}

	inline public static function square(angle:Float)
		return angle % (Math.PI * 2) >= Math.PI ? -1.0 : 1.0;

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
		var c = Math.cos(angle);
		var s = Math.sin(angle);
		p.set((x * c) - (y * s), (x * s) + (y * c));
		return p;
	}

	public static function rotatePos3D(pos:Vector3, ox:Float, oy:Float, oz:Float, xA:Float, yA:Float, zA:Float, zScale:Float):Void {
		var dx = pos.x - ox;
		var dy = pos.y - oy;
		var dz = (pos.z - oz) * zScale;

		var x1 = dx;
		var y1 = dy;
		if(zA != 0){
			var c = Math.cos(zA);
			var s = Math.sin(zA);
			x1 = (dx * c) - (dy * s);
			y1 = (dx * s) + (dy * c);
		}

		var a = dz;
		var b = y1;
		if(xA != 0){
			var c = Math.cos(xA);
			var s = Math.sin(xA);
			a = (dz * c) - (y1 * s);
			b = (dz * s) + (y1 * c);
		}

		var rx = x1;
		var rz = a;
		if(yA != 0){
			var c = Math.cos(yA);
			var s = Math.sin(yA);
			rx = (x1 * c) - (a * s);
			rz = (x1 * s) + (a * c);
		}

		pos.x = ox + rx;
		pos.y = oy + b;
		pos.z = oz + rz / zScale;
	}
}