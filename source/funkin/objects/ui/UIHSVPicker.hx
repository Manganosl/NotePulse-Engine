package funkin.objects.ui;

import openfl.display.BitmapData;
import flixel.util.FlxSpriteUtil;

class UIHSVPicker extends FlxSpriteGroup {
	public var bg:FlxSprite;
	public var bgBorder:FlxSprite;
	public var preview:FlxSprite;

	var panelBG:FlxSprite;
	var panelBorder:FlxSprite;

	var svSquare:FlxSprite;
	var svSquareBorder:FlxSprite;
	var hueBar:FlxSprite;
	var hueBarBorder:FlxSprite;

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

    var hexLabel:FlxText;
    var hexField:UIInputText;

	public function new(x:Float,y:Float)
	{
		super(x,y);

		bgBorder = new FlxSprite(-1, -1).makeGraphic(1, 1, FlxColor.WHITE);
		bgBorder.color = 0xFF3A3F52;
		bgBorder.alpha = 0.55;
		bgBorder.scale.set(buttonSize + 2, buttonSize + 2);
		bgBorder.updateHitbox();
		add(bgBorder);

		bg = new FlxSprite().makeGraphic(buttonSize,buttonSize,FlxColor.WHITE);
		bg.color = 0xFF1C1F27;
		bg.alpha = 0.78;
		add(bg);

		preview = new FlxSprite(2,2).makeGraphic(buttonSize-4,buttonSize-4,FlxColor.WHITE);
		add(preview);

		createBox();
		updateColor();
	}

	function createBox(){
		panelBorder = new FlxSprite(-1, (bg.height + 1)).makeGraphic(1, 1, FlxColor.WHITE);
		panelBorder.color = 0xFF3A3F52;
		panelBorder.alpha = 0.55;
		panelBorder.scale.set((svSize + 8) + 2, (svSize + hueHeight + 56) + 2);
		panelBorder.updateHitbox();
		panelBorder.visible = false;
		add(panelBorder);

		panelBG = new FlxSprite(0, (bg.height + 2)).makeGraphic((svSize + 8), (svSize + hueHeight + 56), FlxColor.WHITE);
		panelBG.color = 0xFF1C1F27;
		panelBG.alpha = 0.78;
		panelBG.visible = false;
		add(panelBG);

		svSquareBorder = new FlxSprite(3, (bg.height + 5)).makeGraphic(1, 1, FlxColor.WHITE);
		svSquareBorder.color = 0xFF3A3F52;
		svSquareBorder.alpha = 0.6;
		svSquareBorder.scale.set(svSize + 2, svSize + 2);
		svSquareBorder.updateHitbox();
		svSquareBorder.visible = false;
		add(svSquareBorder);

		svSquare = new FlxSprite(4, (bg.height + 6));
		svSquare.visible = false;
		add(svSquare);

		hueBarBorder = new FlxSprite(3, (bg.height + svSize + 7)).makeGraphic(1, 1, FlxColor.WHITE);
		hueBarBorder.color = 0xFF3A3F52;
		hueBarBorder.alpha = 0.6;
		hueBarBorder.scale.set(svSize + 2, hueHeight + 2);
		hueBarBorder.updateHitbox();
		hueBarBorder.visible = false;
		add(hueBarBorder);

		hueBar = new FlxSprite(4, (bg.height + svSize + 8));
		hueBar.visible = false;
		add(hueBar);

        hexLabel = new FlxText(4, (hueBar.y + hueHeight + 6), Std.int(panelBG.width - 8), 'HEX', 8);
        hexLabel.color = 0xFFF1F1F5;
        hexLabel.visible = false;
        add(hexLabel);

        hexField = new UIInputText(4, (hexLabel.y + hexLabel.height + 2), Std.int(panelBG.width * 0.9));
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
		svCursor.makeGraphic(14,14,FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawCircle(svCursor, 7, 7, 5, FlxColor.TRANSPARENT, {thickness: 3, color: 0xFF14161C});
		FlxSpriteUtil.drawCircle(svCursor, 7, 7, 5, FlxColor.TRANSPARENT, {thickness: 1.5, color: FlxColor.WHITE});
		svCursor.visible = false;
		add(svCursor);

		hueCursor = new FlxSprite();
		hueCursor.makeGraphic(4, hueHeight + 6, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRect(hueCursor, 0, 0, 4, hueHeight + 6, 0xFF14161C);
		FlxSpriteUtil.drawRect(hueCursor, 1, 1, 2, hueHeight + 4, FlxColor.WHITE);
		hueCursor.visible = false;
		add(hueCursor);

		generateHueBar();
		updateSVSquare();
	}

	override function update(elapsed:Float){
		super.update(elapsed);

		var mouse = FlxG.mouse.getPositionInCameraView(camera);

		if(FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg, camera))
			toggleMenu();

		if(!isOpen) return;

		if(FlxG.mouse.justPressed && !FlxG.mouse.overlaps(panelBG, camera) && !FlxG.mouse.overlaps(bg, camera)){
			closeMenu();
			return;
		}

		if(FlxG.mouse.justPressed){
			if(FlxG.mouse.overlaps(svSquare, camera))
				dragSV = true;

			if(FlxG.mouse.overlaps(hueBar, camera))
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
        panelBorder.visible = panelBG.visible = svSquareBorder.visible = svSquare.visible
			= hueBarBorder.visible = hueBar.visible = svCursor.visible = hueCursor.visible
			= hexLabel.visible = hexField.visible = isOpen;

        if(isOpen) updateCursors();
    }

    function closeMenu() {
        isOpen = false;
        panelBorder.visible = panelBG.visible = svSquareBorder.visible = svSquare.visible
			= hueBarBorder.visible = hueBar.visible = svCursor.visible = hueCursor.visible
			= hexLabel.visible = hexField.visible = false;

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

		hueCursor.x = hueBar.x + hue * hueBar.width - hueCursor.width/2;
		hueCursor.y = hueBar.y - 3;
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

        var color:FlxColor = FlxColor.fromString('#' + hex);
        hue = color.hue / 360;
        sat = color.saturation;
        val = color.brightness;
                
        updateSVSquare();
        updateColor(true);
        updateCursors();
	}
}