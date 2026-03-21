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
    public var onChange:Void->Void;

	var svSize:Int = 120;
	var hueHeight:Int = 16;
	var buttonSize:Int = 33;

    var hexField:PsychUIInputText;

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
		panelBG = new FlxSprite(0, (bg.height + 2)).makeGraphic((svSize + 8), (svSize + hueHeight + 50), FlxColor.BLACK);
		panelBG.alpha = 0.6;
		panelBG.visible = false;
		add(panelBG);

		svSquare = new FlxSprite(4, (bg.height + 6));
		svSquare.visible = false;
		add(svSquare);

		hueBar = new FlxSprite(4, (bg.height + svSize + 8));
		hueBar.visible = false;
		add(hueBar);

        hexField = new PsychUIInputText(4, (hueBar.y - 200), Std.int(panelBG.width * 0.9));
        hexField.filterMode = ONLY_HEXADECIMAL;
		hexField.visible = false;
        hexField.onChange = function(old:String, curString:String) {
            var color:FlxColor = FlxColor.fromString('#' + curString);
            hue = color.hue / 360;
            sat = color.saturation;
            val = color.brightness;
                
            updateSVSquare();
            updateColor(false);
            updateCursors();
        };
        add(hexField);

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

    function toggleMenu() {
        isOpen = !isOpen;
        panelBG.visible = svSquare.visible = hueBar.visible = svCursor.visible = hueCursor.visible = hexField.visible = isOpen;

        if(isOpen) updateCursors();
    }

    function closeMenu() {
        isOpen = false;
        panelBG.visible = svSquare.visible = hueBar.visible = svCursor.visible = hueCursor.visible = hexField.visible = false;

        dragSV = dragHue = false;
    }

    function updateColor(updateText:Bool = true) {
        var rgb = CoolUtil.hsvToRgb(hue, sat, val);
        var color:FlxColor = FlxColor.fromRGB(rgb.r, rgb.g, rgb.b);

        value = [rgb.r, rgb.g, rgb.b];
        preview.color = color;

        if(updateText)
            hexField.text = color.toHexString(false, false); 

        if(onChange != null)
            onChange();
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

	public function setColorFromHex(hex:String):Void {
		final lastValue = hexField.text;
		if(lastValue == hex) return;
		hexField.text = hex;

        var color:FlxColor = FlxColor.fromString('#' + hex);
        hue = color.hue / 360;
        sat = color.saturation;
        val = color.brightness;
                
        updateSVSquare();
        updateColor(true);
        updateCursors();
	}
}