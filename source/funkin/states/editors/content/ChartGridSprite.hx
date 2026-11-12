package funkin.states.editors.content;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

class ChartGridSprite extends FlxSprite
{
	public var columns(default, null):Int = 0;
	public var cellSize(default, null):Int = 40;
	public var gridWidth(default, null):Float = 0;

		public var sectionTops:Array<Float> = [];

		public var beatHeight:Float = 160;

		public var stripes:Array<Int> = [];

		public var curSection:Int = 0;

	public var showBeatLines:Bool = true;

		public var vortexLineEnabled:Bool = false;

	public var sectionLineThickness:Float = 4;
	public var sectionLineColor:FlxColor = 0xFF000000;
	public var sectionMarkedColor:FlxColor = 0xFFFFC800;
	public var currentSectionColor:FlxColor = 0xFF8000FF;

			public var markProvider:Null<Int->Bool> = null;

	var line:FlxSprite;

	public function new(columns:Int, cellSize:Int, color1:FlxColor, color2:FlxColor, ?altColor1:FlxColor, ?altColor2:FlxColor)
	{
		super();
		this.columns = columns;
		this.cellSize = cellSize;
		this.gridWidth = columns * cellSize;
		active = false;

		scale.set(cellSize, cellSize);
		loadGrid(color1, color2, altColor1, altColor2);

		line = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		line.active = false;
	}

		public function loadGrid(color1:FlxColor, color2:FlxColor, ?altColor1:FlxColor, ?altColor2:FlxColor):Void
	{
		if(altColor1 == null) altColor1 = color1;
		if(altColor2 == null) altColor2 = color2;

		var bmp:BitmapData = new BitmapData(columns, 4, false, 0xFF000000);
		for (r in 0...4)
		{
			var c1:FlxColor = (r < 2) ? color1 : altColor1;
			var c2:FlxColor = (r < 2) ? color2 : altColor2;
			for (x in 0...columns)
				bmp.setPixel32(x, r, ((x + (r % 2)) % 2 == 0) ? c1 : c2);
		}

		loadGraphic(bmp, true, columns, 1);
		scale.set(cellSize, cellSize);
		updateHitbox();
	}

		public function sectionAtY(y:Float):Int
	{
		var n:Int = sectionTops.length - 1;
		if(n < 1) return 0;

		var lo:Int = 0;
		var hi:Int = n - 1;
		while(lo < hi)
		{
			var mid:Int = (lo + hi + 1) >> 1;
			if(sectionTops[mid] <= y) lo = mid;
			else hi = mid - 1;
		}
		return lo;
	}

	override function draw()
	{
		var n:Int = sectionTops.length - 1;
		if(!visible || alpha <= 0 || n < 1) return;

		line.scrollFactor.copyFrom(scrollFactor);
		line.cameras = cameras;

		var cam = camera;
		var viewH:Float = cam.height / cam.zoom;
		var viewTop:Float = cam.scroll.y + (cam.height - viewH) * 0.5;
		var viewBottom:Float = viewTop + viewH;

		var first:Int = sectionAtY(viewTop);
		var originalY:Float = y;

		var s:Int = first;
		while(s < n)
		{
			var top:Float = sectionTops[s];
			if(top >= viewBottom) break;

			var height:Float = sectionTops[s + 1] - top;
			var tileCount:Int = Math.ceil(height / cellSize - 0.0001);
			var tile:Int = (viewTop > top) ? Std.int(Math.floor((viewTop - top) / cellSize)) : 0;
			var palette:Int = (s % 2 == 0) ? 0 : 2;

			while(tile < tileCount)
			{
				var tileY:Float = top + tile * cellSize;
				if(tileY >= viewBottom) break;

				var tileH:Float = Math.min(cellSize, height - tile * cellSize);
				if(tileH > 0)
				{
					animation.frameIndex = palette + ((tile % 2 == 0) ? 1 : 0);
					scale.y = tileH;
					offset.y = -0.5 * (tileH - 1);
					y = tileY;
					super.draw();
				}
				tile++;
			}
			s++;
		}
		y = originalY;
		scale.y = cellSize;

		var lastSection:Int = s - 1;
		var gridTop:Float = Math.max(viewTop, sectionTops[0]);
		var gridBottom:Float = Math.min(viewBottom, sectionTops[n]);

		if(showBeatLines && beatHeight >= 8)
		{
			var beatColor:FlxColor = vortexLineEnabled ? 0xFF660000 : 0xFF000000;
			var beatAlpha:Float = vortexLineEnabled ? 1 : 0.22;

			for (sec in first...(lastSection + 1))
			{
				var top:Float = sectionTops[sec];
				var bottom:Float = sectionTops[sec + 1];
				var k:Int = (viewTop > top) ? Std.int(Math.max(1, Math.ceil((viewTop - top) / beatHeight))) : 1;
				while(true)
				{
					var ly:Float = top + k * beatHeight;
					if(ly >= bottom - 0.5 || ly > viewBottom) break;
					drawLine(x, ly - 0.5, gridWidth, 2, beatColor, beatAlpha);
					k++;
				}
			}
		}

		if(stripes != null && gridBottom > gridTop)
		{
			for (column in stripes)
			{
				var sx:Float = (column == 0) ? x : x + cellSize * column - 1;
				drawLine(sx, gridTop, 2, gridBottom - gridTop, FlxColor.BLACK, 1);
			}
		}

		for (sec in first...(lastSection + 1))
		{
			var top:Float = sectionTops[sec];

			if(sec == curSection)
				drawLine(x + gridWidth, top, 3, sectionTops[sec + 1] - top, currentSectionColor, 0.9);

			var marked:Bool = (markProvider != null && markProvider(sec));
			drawLine(x, top - sectionLineThickness * 0.5, gridWidth, sectionLineThickness, marked ? sectionMarkedColor : sectionLineColor, 0.85);
		}

		if(lastSection == n - 1 && sectionTops[n] <= viewBottom)
			drawLine(x, sectionTops[n] - sectionLineThickness * 0.5, gridWidth, sectionLineThickness, sectionLineColor, 0.85);
	}

	function drawLine(lx:Float, ly:Float, w:Float, h:Float, color:FlxColor, a:Float):Void
	{
		if(w <= 0 || h <= 0) return;

		line.scale.set(w, h);
		line.updateHitbox();
		line.setPosition(lx, ly);
		line.color = color;
		line.alpha = a * alpha;
		line.draw();
	}

	override function destroy()
	{
		line = FlxDestroyUtil.destroy(line);
		sectionTops = null;
		stripes = null;
		markProvider = null;
		super.destroy();
	}
}
