// All made by KadeDev
package funkin.objects.notes;

import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import haxe.ds.StringMap;
import openfl.display.BitmapData;

class NoteSilhouette
{
	public function new()
	{
		this.midY = 0.5;
		this.midX = 0.5;
		this.fillY = 0.5;
		this.fillX = 0.5;
		this.count = 0;
		this.ok = false;
		this.px = [];
		this.py = [];
	}

	public var ok(default, null):Bool;

	public var count(default, null):Int;

	public var px(default, null):Array<Float>;

	public var py(default, null):Array<Float>;

	public var fillX(default, null):Float;

	public var fillY(default, null):Float;

	public var midX(default, null):Float;

	public var midY(default, null):Float;

	function build(frame:FlxFrame):Void
	{
		if (frame.parent == null)
		{
			return;
		}
		var bitmap:BitmapData = frame.parent.bitmap;
		if (!NoteSilhouette.canRead(bitmap))
		{
			bitmap = NoteSilhouette.sheet(frame.parent.key);
		}
		if (NoteSilhouette.canRead(bitmap))
		{
			this.walk(frame, bitmap);
		}
		else
		{
			this.boxOutline();
		}
	}

	function walk(frame:FlxFrame, bitmap:BitmapData):Void
	{
		var rect:FlxRect = frame.frame;
		var w:Float = rect.width;
		var h:Float = rect.height;
		if (w < 2 || h < 2)
		{
			return;
		}
		var originX:Float = rect.x;
		var originY:Float = rect.y;
		if (!this.findMiddle(bitmap, originX, originY, w, h))
		{
			return;
		}
		var rays:Int = NoteSilhouette.RAYS < 6 ? 6 : NoteSilhouette.RAYS;
		var turn:Float = 6.283185307179586 / rays;
		var anchorX:Float = this.midX * w;
		var anchorY:Float = this.midY * h;
		{
			var _g:Int = 0;
			var _g1:Int = rays;
			while (_g < _g1)
			{
				var i:Int = _g++;
				var a:Float = turn * i;
				var dx:Float = Math.cos(a);
				var dy:Float = Math.sin(a);
				var reach:Float = NoteSilhouette.reachOf(dx, dy, anchorX, anchorY, w, h);
				var hit:Float = 0;
				var faint:Float = 0;
				{
					var _g2:Int = 1;
					while (_g2 < 161)
					{
						var step:Int = _g2++;
						var along:Float = reach * step / 160;
						var atX:Int = Std.int(originX + anchorX + dx * along);
						var atY:Int = Std.int(originY + anchorY + dy * along);
						if (atX < 0 || atY < 0 || atX >= bitmap.width || atY >= bitmap.height)
						{
							break;
						}
						var seen:Int = bitmap.getPixel32(atX, atY) >> 24 & 255;
						if (seen >= 24)
						{
							faint = along;
						}
						if (seen >= 128)
						{
							hit = along;
						}
					}
				}
				if (hit <= 0)
				{
					hit = faint;
				}
				if (hit <= 0)
				{
					hit = reach * 0.02;
				}
				this.px.push((anchorX + dx * hit) / w);
				this.py.push((anchorY + dy * hit) / h);
			}
		}
		this.findFill(bitmap, originX, originY, w, h, anchorX, anchorY);
		this.count = rays;
		this.ok = true;
	}

	function findFill(bitmap:BitmapData, originX:Float, originY:Float, w:Float, h:Float, anchorX:Float, anchorY:Float):Void
	{
		this.fillX = anchorX / w;
		this.fillY = anchorY / h;
		var best:Int = -1;
		var reach:Float = (w < h ? w : h) * 0.30;
		{
			var _g:Int = 0;
			while (_g < 5)
			{
				var ring:Int = _g++;
				var out:Float = reach * ring / 5;
				{
					var _g1:Int = 0;
					while (_g1 < 12)
					{
						var step:Int = _g1++;
						var a:Float = 6.283185307179586 * step / 12;
						var atX:Int = Std.int(originX + anchorX + Math.cos(a) * out);
						var atY:Int = Std.int(originY + anchorY + Math.sin(a) * out);
						if (atX < 0 || atY < 0 || atX >= bitmap.width || atY >= bitmap.height)
						{
							continue;
						}
						var pixel:Int = bitmap.getPixel32(atX, atY);
						if (pixel >> 24 & 255 < 250)
						{
							continue;
						}
						var r:Int = pixel >> 16 & 255;
						var g:Int = pixel >> 8 & 255;
						var b:Int = pixel & 255;
						var high:Int = r > g ? {
							if (r > b)
							{
								r;
							}
							else
							{
								b;
							}
						} : g > b ? g : b;
						var low:Int = r < g ? {
							if (r < b)
							{
								r;
							}
							else
							{
								b;
							}
						} : g < b ? g : b;
						var score:Int = (high - low) * 4 + (high + low >> 1);
						if (score > best)
						{
							best = score;
							this.fillX = (anchorX + Math.cos(a) * out) / w;
							this.fillY = (anchorY + Math.sin(a) * out) / h;
						}
						if (out == 0)
						{
							break;
						}
					}
				}
			}
		}
	}

	function boxOutline():Void
	{
		var rays:Int = NoteSilhouette.RAYS < 6 ? 6 : NoteSilhouette.RAYS;
		var turn:Float = 6.283185307179586 / rays;
		this.midX = 0.5;
		this.midY = 0.5;
		this.fillX = 0.5;
		this.fillY = 0.5;
		{
			var _g:Int = 0;
			var _g1:Int = rays;
			while (_g < _g1)
			{
				var i:Int = _g++;
				var a:Float = turn * i;
				var dx:Float = Math.cos(a);
				var dy:Float = Math.sin(a);
				var stepX:Float = dx == 0 ? 1e9 : Math.abs(0.5 / dx);
				var stepY:Float = dy == 0 ? 1e9 : Math.abs(0.5 / dy);
				var reach:Float = stepX < stepY ? stepX : stepY;
				this.px.push(0.5 + dx * reach);
				this.py.push(0.5 + dy * reach);
			}
		}
		this.count = rays;
		this.ok = true;
	}

	function findMiddle(bitmap:BitmapData, originX:Float, originY:Float, w:Float, h:Float):Bool
	{
		var stepX:Float = w > 96 ? w / 96 : 1;
		var stepY:Float = h > 96 ? h / 96 : 1;
		var sumX:Float = 0;
		var sumY:Float = 0;
		var seen:Int = 0;
		var softX:Float = 0;
		var softY:Float = 0;
		var soft:Int = 0;
		var y:Float = 0;
		while (y < h)
		{
			var x:Float = 0;
			while (x < w)
			{
				var atX:Int = Std.int(originX + x);
				var atY:Int = Std.int(originY + y);
				if (atX >= 0 && atY >= 0 && atX < bitmap.width && atY < bitmap.height)
				{
					var much:Int = bitmap.getPixel32(atX, atY) >> 24 & 255;
					if (much >= 24)
					{
						softX += x;
						softY += y;
						++soft;
					}
					if (much >= 128)
					{
						sumX += x;
						sumY += y;
						++seen;
					}
				}
				x += stepX;
			}
			y += stepY;
		}
		if (seen == 0)
		{
			sumX = softX;
			sumY = softY;
			seen = soft;
		}
		if (seen == 0)
		{
			return false;
		}
		this.midX = sumX / seen / w;
		this.midY = sumY / seen / h;
		return true;
	}

	static var RAYS:Int = 40;

	static var cache:StringMap<NoteSilhouette> = new StringMap<NoteSilhouette>();

	static var lastKey:String = null;

	static var lastFound:NoteSilhouette = null;

	public static function keyOf(frame:FlxFrame):String
	{
		if (frame == null || frame.parent == null)
		{
			return null;
		}
		var at:FlxRect = frame.frame;
		return frame.parent.key + "|" + at.x + "," + at.y + "," + at.width + "," + at.height;
	}

	public static function of(frame:FlxFrame):NoteSilhouette
	{
		if (frame == null)
		{
			return null;
		}
		var key:String = NoteSilhouette.keyOf(frame);
		if (key == null)
		{
			return null;
		}
		if (key == NoteSilhouette.lastKey)
		{
			return NoteSilhouette.lastFound;
		}
		var found:NoteSilhouette = NoteSilhouette.cache.get(key);
		if (found == null)
		{
			found = new NoteSilhouette();
			found.build(frame);
			NoteSilhouette.cache.set(key, found);
		}
		NoteSilhouette.lastKey = key;
		NoteSilhouette.lastFound = found;
		return found;
	}

	static var strips:StringMap<Float> = new StringMap<Float>();

	public static function trailWidth(graphic:FlxGraphic, uLeft:Float, uRight:Float):Float
	{
		if (graphic == null)
		{
			return 1;
		}
		var key:String = graphic.key + ":" + uLeft;
		var found:Dynamic = NoteSilhouette.strips.get(key);
		if (found != null)
		{
			return found;
		}
		var share:Float = 1;
		var bitmap:BitmapData = graphic.bitmap;
		if (NoteSilhouette.canRead(bitmap))
		{
			var fromX:Int = Std.int(uLeft * bitmap.width);
			var toX:Int = Std.int(uRight * bitmap.width);
			if (toX > bitmap.width)
			{
				toX = bitmap.width;
			}
			var span:Int = toX - fromX;
			if (span > 1)
			{
				var widest:Int = 0;
				{
					var _g:Int = 0;
					while (_g < 5)
					{
						var step:Int = _g++;
						var atY:Int = Std.int(bitmap.height * (0.15 + 0.14 * step));
						if (atY < 0 || atY >= bitmap.height)
						{
							continue;
						}
						var lowest:Int = -1;
						var highest:Int = -1;
						{
							var _g1:Int = 0;
							while (_g1 < span)
							{
								var x:Int = _g1++;
								if (bitmap.getPixel32(fromX + x, atY) >> 24 & 255 < 200)
								{
									continue;
								}
								if (lowest < 0)
								{
									lowest = x;
								}
								highest = x;
							}
						}
						if (lowest < 0)
						{
							continue;
						}
						var reach:Int = highest - lowest + 1;
						if (reach > widest)
						{
							widest = reach;
						}
					}
				}
				if (widest > 0)
				{
					share = widest / span;
				}
			}
		}
		if (share > 1)
		{
			share = 1;
		}
		if (share < 0.2)
		{
			share = 0.2;
		}
		NoteSilhouette.strips.set(key, share);
		return share;
	}

	static var profiles:StringMap<Array<Float>> = new StringMap<Array<Float>>();

	public static function stripProfile(graphic:FlxGraphic, uLeft:Float, uRight:Float):Array<Float>
	{
		var key:String = graphic == null ? "none" : graphic.key + ":p:" + uLeft;
		var found:Array<Float> = NoteSilhouette.profiles.get(key);
		if (found != null)
		{
			return found;
		}
		var out:Array<Float> = [];
		var bitmap:BitmapData = graphic == null ? null : graphic.bitmap;
		if (!NoteSilhouette.canRead(bitmap))
		{
			{
				var _g:Int = 0;
				while (_g < 32)
				{
					var i:Int = _g++;
					var along:Float = i / 31;
					var into:Float = along < 0.6 ? 0 : (along - 0.6) / 0.4;
					out.push(Math.sqrt(1 - into * into));
				}
			}
			NoteSilhouette.profiles.set(key, out);
			return out;
		}
		var fromX:Int = Std.int(uLeft * bitmap.width);
		var toX:Int = Std.int(uRight * bitmap.width);
		if (toX > bitmap.width)
		{
			toX = bitmap.width;
		}
		var span:Int = toX - fromX;
		if (span <= 1)
		{
			{
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
				out.push(1);
			}
			NoteSilhouette.profiles.set(key, out);
			return out;
		}
		var middle:Float = span * 0.5;
		{
			var _g1:Int = 0;
			while (_g1 < 32)
			{
				var i1:Int = _g1++;
				var atY:Int = Std.int((bitmap.height - 1) * i1 / 31);
				var reach:Float = 0;
				{
					var _g2:Int = 0;
					while (_g2 < span)
					{
						var x:Int = _g2++;
						if (bitmap.getPixel32(fromX + x, atY) >> 24 & 255 < 200)
						{
							continue;
						}
						var away:Float = x + 0.5 - middle;
						if (away < 0)
						{
							away = -away;
						}
						if (away > reach)
						{
							reach = away;
						}
					}
				}
				out.push(reach / middle);
			}
		}
		NoteSilhouette.profiles.set(key, out);
		return out;
	}

	public static function profileAt(profile:Array<Float>, v:Float):Float
	{
		if (profile == null || profile.length == 0)
		{
			return 1;
		}
		if (v <= 0)
		{
			return profile[0];
		}
		if (v >= 1)
		{
			return profile[profile.length - 1];
		}
		var along:Float = v * (profile.length - 1);
		var at:Int = Std.int(along);
		if (at >= profile.length - 1)
		{
			return profile[profile.length - 1];
		}
		var mix:Float = along - at;
		return profile[at] + (profile[at + 1] - profile[at]) * mix;
	}

	static var sheets:StringMap<BitmapData> = new StringMap<BitmapData>();

	public static function sheet(key:String):BitmapData
	{
		if (key == null || key == "")
		{
			return null;
		}
		var found:BitmapData = NoteSilhouette.sheets.get(key);
		if (found != null)
		{
			return found;
		}
		var got:BitmapData = NoteSilhouette.readable(key);
		if (got != null)
		{
			NoteSilhouette.sheets.set(key, got);
		}
		return got;
	}

	public static function warm(graphic:FlxGraphic):Void
	{
		if (graphic == null || NoteSilhouette.canRead(graphic.bitmap))
		{
			return;
		}
		NoteSilhouette.sheet(graphic.key);
	}

	public static function forget():Void
	{
		{
			var one:Dynamic = NoteSilhouette.sheets.iterator();
			while (one.hasNext())
			{
				var one1:BitmapData = one.next();
				if (one1 != null)
				{
					one1.dispose();
				}
			}
		}
		NoteSilhouette.sheets = new StringMap<BitmapData>();
		NoteSilhouette.strips = new StringMap<Float>();
		NoteSilhouette.profiles = new StringMap<Array<Float>>();
		NoteSilhouette.cache = new StringMap<NoteSilhouette>();
		NoteSilhouette.lastKey = null;
		NoteSilhouette.lastFound = null;
	}

	public static function readable(key:String):BitmapData
	{
		if (key == null || key == "")
		{
			return null;
		}
		try
		{
			var got:BitmapData = openfl.utils.Assets.getBitmapData(key, false);
			if (NoteSilhouette.canRead(got))
			{
				return got;
			}
		}
		catch (_g:Dynamic)
		{
			{
				null;
			}
		}
		return null;
	}

	public static function canRead(bitmap:BitmapData):Bool
	{
		if (bitmap == null || bitmap.width <= 0 || bitmap.height <= 0)
		{
			return false;
		}
		if (bitmap.readable)
		{
			return bitmap.image != null;
		}
		else
		{
			return false;
		}
		return false;
	}

	public static function reachOf(dx:Float, dy:Float, anchorX:Float, anchorY:Float, w:Float, h:Float):Float
	{
		var reach:Float = 1e9;
		if (dx > 0.0001)
		{
			reach = Math.min(1e9, (w - 1 - anchorX) / dx);
		}
		else
		{
			if (dx < -0.0001)
			{
				reach = Math.min(1e9, -anchorX / dx);
			}
		}
		if (dy > 0.0001)
		{
			reach = Math.min(reach, (h - 1 - anchorY) / dy);
		}
		else
		{
			if (dy < -0.0001)
			{
				reach = Math.min(reach, -anchorY / dy);
			}
		}
		if (reach < 1)
		{
			reach = 1;
		}
		return reach;
	}
}