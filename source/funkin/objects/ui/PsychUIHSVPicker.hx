package funkin.objects.ui;

import openfl.display.BitmapData;
import flixel.util.FlxSpriteUtil;

class PsychUIHSVPicker extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var preview:FlxSprite;

	var panelBG:FlxSprite;

	var svSquare:FlxSprite;
	var hueBar:FlxSprite;

	var svCursor:FlxSprite;
	var hueCursor:FlxSprite;

	var dragSV:Bool = false;
	var dragHue:Bool = false;

	public var isOpen:Bool = false;

	public var hue:Float = 0;
	public var sat:Float = 1;
	public var val:Float = 1;

	public var value:Array<Int> = [255,255,255];
    public var onChange:Array<Int>->Void;

	var svSize:Int = 120;
	var hueHeight:Int = 16;
	var buttonSize:Int = 22;

	public function new(x:Float,y:Float)
	{
		super(x,y);

		bg = new FlxSprite().makeGraphic(buttonSize,buttonSize,FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		preview = new FlxSprite(2,2).makeGraphic(buttonSize-4,buttonSize-4,FlxColor.WHITE);
		add(preview);

		createBox();
		updateColor();
	}

	function createBox(){
		panelBG = new FlxSprite(0,bg.height+2).makeGraphic(svSize+8,svSize+hueHeight+12,FlxColor.BLACK);
		panelBG.alpha = 0.6;
		panelBG.visible = false;
		add(panelBG);

		svSquare = new FlxSprite(4,bg.height+6);
		svSquare.visible = false;
		add(svSquare);

		hueBar = new FlxSprite(4,bg.height+svSize+8);
		hueBar.visible = false;
		add(hueBar);

		svCursor = new FlxSprite();
		svCursor.makeGraphic(10,10,FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawCircle(svCursor, 4,4,4,FlxColor.WHITE);
		svCursor.visible = false;
		add(svCursor);

		hueCursor = new FlxSprite();
		hueCursor.makeGraphic(2,hueHeight+4,FlxColor.WHITE);
		hueCursor.visible = false;
		add(hueCursor);

		generateHueBar();
		updateSVSquare();
	}

	override function update(elapsed:Float){
		super.update(elapsed);

		var mouse = FlxG.mouse.getPositionInCameraView(camera);

		if(FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg))
			toggleMenu();

		if(!isOpen) return;

		if(FlxG.mouse.justPressed && !FlxG.mouse.overlaps(panelBG) && !FlxG.mouse.overlaps(bg)){
			closeMenu();
			return;
		}

		if(FlxG.mouse.justPressed){
			if(FlxG.mouse.overlaps(svSquare))
				dragSV = true;

			if(FlxG.mouse.overlaps(hueBar))
				dragHue = true;
		}

		if(FlxG.mouse.justReleased){
			dragSV = false;
			dragHue = false;
		}

		if(dragHue){
			var lx = mouse.x - hueBar.x;
			hue = FlxMath.bound(lx / hueBar.width,0,1);

			updateSVSquare();
			updateColor();
			updateCursors();
		}

		if(dragSV){
			var lx = mouse.x - svSquare.x;
			var ly = mouse.y - svSquare.y;

			sat = FlxMath.bound(lx / svSquare.width,0,1);
			val = 1 - FlxMath.bound(ly / svSquare.height,0,1);

			updateColor();
			updateCursors();
		}
	}

	function toggleMenu(){
		isOpen = !isOpen;

		panelBG.visible = isOpen;
		svSquare.visible = isOpen;
		hueBar.visible = isOpen;
		svCursor.visible = isOpen;
		hueCursor.visible = isOpen;

		updateCursors();
	}

	function closeMenu(){
		isOpen = false;

		panelBG.visible = false;
		svSquare.visible = false;
		hueBar.visible = false;
		svCursor.visible = false;
		hueCursor.visible = false;

		dragSV = false;
		dragHue = false;
	}

	function updateColor(){
		var rgb = CoolUtil.hsvToRgb(hue,sat,val);

		value = [rgb.r,rgb.g,rgb.b];
		preview.color = FlxColor.fromRGB(rgb.r,rgb.g,rgb.b);

        if(onChange != null)
            onChange(value);
	}

	function updateCursors(){
		svCursor.x = svSquare.x + sat * svSquare.width - svCursor.width/2;
		svCursor.y = svSquare.y + (1-val) * svSquare.height - svCursor.height/2;

		hueCursor.x = hueBar.x + hue * hueBar.width;
		hueCursor.y = hueBar.y - 2;
	}

	function generateHueBar(){
		var bmp = new BitmapData(svSize,hueHeight,false);

		for(x in 0...svSize){
			var h = x / svSize;
			var rgb = CoolUtil.hsvToRgb(h,1,1);
			var c = FlxColor.fromRGB(rgb.r,rgb.g,rgb.b);

			for(y in 0...hueHeight)
				bmp.setPixel(x,y,c);
		}

		hueBar.pixels = bmp;
		hueBar.dirty = true;
	}

	function updateSVSquare(){
		var bmp = new BitmapData(svSize,svSize,false);

		for(x in 0...svSize){
            for(y in 0...svSize){
                var s = x / svSize;
                var v = 1 - (y / svSize);

                var rgb = CoolUtil.hsvToRgb(hue,s,v);
                bmp.setPixel(x,y,FlxColor.fromRGB(rgb.r,rgb.g,rgb.b));
            }
        }

		svSquare.pixels = bmp;
		svSquare.dirty = true;
	}
}