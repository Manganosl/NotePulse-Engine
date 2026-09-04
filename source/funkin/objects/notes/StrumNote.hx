package funkin.objects.notes;

import flixel.FlxBasic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import funkin.backend.InputFormatter;
import funkin.backend.ExtraKeysHandler;
import funkin.backend.animation.PsychAnimationController;

import funkin.objects.notes.PlayField;
import funkin.objects.notes.splashes.*;

import funkin.game.shaders.RGBPalette;
import funkin.game.shaders.RGBPalette.RGBShaderReference;

import funkin.objects.FunkinSprite;
import funkin.game.modchart.math.Vector3;

class StrumNote extends FunkinSprite {
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling
	
	public var zIndex:Float = 0;
	public var desiredZIndex:Float = 0;
	public var z:Float = 0;

	public var rgbShader:RGBShaderReference;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var cpuControlled(default, set):Bool = true;
	public var inControl(default, set):Bool = true;
	public var noteHitCallback:Note->Void;
	public var noteMissCallback:Note->Void;
	public var sustainReduce:Bool = true;
	public var trackedScale:Float = 0.7;
	private var player:Int;
	private var initialWidth:Float = 0;
	public var sustainSplash:SustainSplash;
	public var noteSpeed:Float = 1;

	public var parentField:PlayField = null;

	public var modPos:FlxPoint = new FlxPoint(0, 0);
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	private function set_cpuControlled(value:Bool){
		playAnim('static');
		resetAnim = 0;
		return cpuControlled = value;
	}

	private function set_inControl(value:Bool){
		playAnim('static');
		resetAnim = 0;
		return inControl = value;
	}

	public var useRGBShader:Bool = true;
	public function new(x:Float, y:Float, leData:Int, player:Int, ?field:PlayField) {
		if(field != null) this.parentField = field;
		animation = new PsychAnimationController(this);

		var mania = 3;
		if (PlayState.SONG != null) mania = (field != null ? field.keyCount - 1 : PlayState.SONG.mania);

		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData, mania));
		rgbShader.enabled = false;
		if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) useRGBShader = false;
		
		var arrowRGBIndex = getIndex(mania, leData);

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[arrowRGBIndex];

		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[arrowRGBIndex];
		
		@:bypassAccessor
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else skin = Note.defaultNoteSkin;

		var customSkin:String = skin + Note.getNoteSkinPostfix();
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;

		texture = skin; //Load texture and anims
		scrollFactor.set();
		sustainSplash = new SustainSplash(this);
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		if(PlayState.isPixelStage)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / Note.getPixelColumns();
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;

			initialWidth = width;

			setGraphicSize(width * PlayState.daPixelZoom);

			var mania = 3;
			if (PlayState.SONG != null) mania = parentField != null ? parentField.keyCount - 1 : PlayState.SONG.mania;

			var noteAnimInt = getAnimSet(getIndex(mania, noteData)).pixel;

			var cols = Note.getPixelColumns();

			animation.add('purple', [cols]);
			animation.add('blue', [cols + 1]);
			animation.add('green', [cols + 2]);
			animation.add('red', [cols + 3]);

			if (cols >= 6) {
				animation.add('rombus', [cols + 4]);
				animation.add('circle', [cols + 5]);
			}

			animation.add('static', [noteAnimInt]);
			animation.add('pressed', [noteAnimInt + cols, noteAnimInt + (cols * 2)], 12, false);
			animation.add('confirm', [noteAnimInt + (cols * 3), noteAnimInt + (cols * 4)], 24, false);
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');
			animation.addByPrefix('rombus', 'arrowROMBUS');
			animation.addByPrefix('circle', 'arrowCIRCLE');
			initialWidth = width;

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(width * trackedScale);

			var mania = 3;
			if (PlayState.SONG != null) mania = parentField != null ? parentField.keyCount - 1 : PlayState.SONG.mania;

			animation.addByPrefix('static', 'arrow${getAnimSet(getIndex(mania, noteData)).strum}');
			animation.addByPrefix('pressed', '${getAnimSet(getIndex(mania, noteData)).anim} press', 24, false);
			animation.addByPrefix('confirm', '${getAnimSet(getIndex(mania, noteData)).anim} confirm', 24, false);
		}
		defScale.copyFrom(scale);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function retryBound() {
		trackedScale = trackedScale * 0.85;
		setGraphicSize(initialWidth * (trackedScale * (PlayState.isPixelStage ? PlayState.daPixelZoom /** (1/ExtraKeysHandler.instance.data.pixelScales[PlayState.SONG.mania])) */: 1)));
		updateHitbox();
		defScale.copyFrom(scale);
		postAddedToGroup();
	}

	public function postAddedToGroup() {
		playAnim('static');
		var padding:Float = 0;
		var minPaddingStartThresh:Int = 4;
		if ((parentField != null ? parentField.keyCount - 1 : PlayState.SONG.mania) > minPaddingStartThresh) {
			padding = 4 * ((parentField != null ? parentField.keyCount - 1 : PlayState.SONG.mania) - minPaddingStartThresh);
			if (padding > 8) padding = 8;
		}
		ID = noteData;

		centerStrum(minPaddingStartThresh, padding);
		@:privateAccess sustainSplash.visible = false;
	}

	/**
	 * Please refrain from asking me what happens here
	 * @param maniaThresh I don't know
	 * @param padding I don't know
	 */
	public function centerStrum(maniaThresh:Int, padding:Float) {
		var sWidth = Note.swagWidthUnscaled;
		if (!ClientPrefs.data.middleScroll) {
			x = player == 0 ? 320 : 960;
			x += ((sWidth * trackedScale) - padding) * (-((parentField != null ? parentField.keyCount : PlayState.SONG.mania + 1) / 2) + noteData);
		} else {
			x = player == 0 ? 320 : 640;
			if (player == 0) {
				if (noteData > Math.floor(((parentField != null ? parentField.keyCount - 1 : PlayState.SONG.mania) / 2))) x = 960;
			}
			x += ((sWidth * trackedScale) - padding) * (-((parentField != null ? parentField.keyCount : PlayState.SONG.mania + 1) / 2) + noteData);
		}
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
				if(sustainSplash != null)
					if(sustainSplash.animation.curAnim != null)
						if (sustainSplash.animation.curAnim.name != "splash")
							sustainSplash.hide(true);
			}
		}
		if(sustainSplash != null)
			if(sustainSplash.animation != null && sustainSplash.animation.curAnim != null)
				if (sustainSplash.animation.curAnim.name != "splash" && animation != null && animation.curAnim != null && animation.curAnim.name == "static" && !cpuControlled)
					sustainSplash.hide(true);  // You may ask, why 2 times? Well, BPM changes fucks with everything and I dont know why

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		if(useRGBShader) rgbShader.enabled = (animation.curAnim != null && animation.curAnim.name != 'static');
	}

	public function getIndex(mania:Int, note:Int) {
		return ExtraKeysHandler.instance.data.keys[mania].notes[note];
	}

	public function getAnimSet(index:Int) {
		return ExtraKeysHandler.instance.data.animations[index];
	}

	override function set_camera(value:FlxCamera){
		sustainSplash.camera = value;
		return super.set_camera(value);
	}

	override function set_cameras(value:Array<FlxCamera>){
		sustainSplash.cameras = value;
		return super.set_cameras(value);
	}

	override function destroy(){
		defScale.put();
		sustainSplash.destroy();
		return super.destroy();
	}

	/**
	 * Returns the screen position of this object.
	 * For StrumNote, this uses `modPos` instead of the usual `x` and `y`
	 *
	 * @param   result  Optional arg for the returning point
	 * @param   camera  The desired "screen" coordinate space. If `null`, `FlxG.camera` is used.
	 * @return  The screen position of this object.
	 */
	override public function getScreenPosition(?result:FlxPoint, ?camera:FlxCamera):FlxPoint {
		if (result == null)
			result = FlxPoint.get();

		if (camera == null)
			camera = FlxG.camera;

		result.set(modPos.x, modPos.y);
		if (pixelPerfectPosition)
			result.floor();

		return result.subtract(camera.scroll.x * scrollFactor.x, camera.scroll.y * scrollFactor.y);
	}

	/**
	 * Calculates the smallest globally aligned bounding box that encompasses this sprite's graphic as it
	 * would be displayed. Honors scrollFactor, rotation, scale, offset and origin.
	 * For StrumNote, this uses `modPos` instead of the usual `x` and `y`
	 * @param newRect Optional output `FlxRect`, if `null`, a new one is created.
	 * @param camera  Optional camera used for scrollFactor, if null `FlxG.camera` is used.
	 * @return A globally aligned `FlxRect` that fully contains the input sprite.
	 * @since 4.11.0
	 */
	override public function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
    	if (camera == null)
    	    camera = FlxG.camera;

    	if (newRect == null)
        	newRect = FlxRect.get();

    	newRect.setPosition(modPos.x, modPos.y);
    	if (pixelPerfectPosition)
        	newRect.floor();

    	_scaledOrigin.set(origin.x * scale.x, origin.y * scale.y);

    	newRect.x += -Std.int(camera.scroll.x * scrollFactor.x) - offset.x + origin.x - _scaledOrigin.x;
    	newRect.y += -Std.int(camera.scroll.y * scrollFactor.y) - offset.y + origin.y - _scaledOrigin.y;

    	if (isPixelPerfectRender(camera))
        	newRect.floor();

    	newRect.setSize(frameWidth * Math.abs(scale.x), frameHeight * Math.abs(scale.y));
    	newRect = newRect.getRotatedBounds(angle, _scaledOrigin, newRect);

    	if (__shouldDoZoomFactor())
    	{
       		newRect.x -= camera.width / 2;
        	newRect.y -= camera.height / 2;

        	var ratio = (camera.zoom > 0 ? Math.max : Math.min)(0, FlxMath.lerp(1 / camera.zoom, 1, zoomFactor));

        	newRect.x *= ratio;
        	newRect.y *= ratio;
        	newRect.width *= ratio;
        	newRect.height *= ratio;

        	newRect.x += camera.width / 2;
     	    newRect.y += camera.height / 2;
    	}

    	return newRect;
	}
}

class StrumBoundaries {
	public static var minBoundaryOpponent:FlxPoint = new FlxPoint(30, 50);
	public static var maxBoundaryOpponent:FlxPoint = new FlxPoint(630, 160);

	public static function getMiddlePoint():FlxPoint {
		return new FlxPoint(Std.int(getBoundaryWidth().x/2),Std.int(getBoundaryWidth().y/2));
	}

	public static function getBoundaryWidth():FlxPoint {
		return new FlxPoint(Std.int((maxBoundaryOpponent.x - minBoundaryOpponent.x)),Std.int((maxBoundaryOpponent.y - minBoundaryOpponent.y)));
	}
}

class KeybindShowcase extends FlxTypedGroup<FlxBasic> {
	public var background:FlxSprite;
	public var keyText:FlxText;
	public var keyCodes:Array<Int>;
	public dynamic function onComplete():Void {}

	public function new(x:Float,y:Float,keyCodes:Array<Int>, camera:FlxCamera, strumHalved:Float, mania:Int) {
		super();

		this.keyCodes = keyCodes;

		var xOffset = x + strumHalved;
		
		var size = 20 - (mania - 3);

		keyText = new FlxText(xOffset + 4,y + 4, InputFormatter.getKeyName(keyCodes[0]));
		keyText.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		keyText.x -= keyText.width / 2;
		xOffset = keyText.x;

		background = new FlxSprite(xOffset-4,y);
		background.makeGraphic(Std.int(keyText.width + 8), Std.int(keyText.height + 8), 0xFF000000);
		background.alpha = 0.5;

		add(background);
		add(keyText);

		background.cameras = [camera];
		keyText.cameras = [camera];

		new FlxTimer().start(2, function(tmr:FlxTimer) {
			FlxTween.tween(keyText, {alpha: 0}, 0.5, {ease: FlxEase.linear, onComplete: function(t) {
				if (keyCodes.length > 1) {
					keyText.text = InputFormatter.getKeyName(keyCodes[1]);
				} else {
					keyText.text = '---';
				}

				FlxTween.tween(keyText, {alpha: 1}, 0.5);
	
				keyText.x = x + strumHalved + 4;
				keyText.x -= keyText.width / 2;
				xOffset = keyText.x;
				background.x = xOffset - 4;
				background.makeGraphic(Std.int(keyText.width + 8), Std.int(keyText.height + 8), 0xFF000000);
				new FlxTimer().start(2.5, function(tmr:FlxTimer) {
					FlxTween.tween(keyText, {alpha: 0}, 0.5, {ease: FlxEase.linear, onComplete: function(t) {
						onComplete();
					}});
				});
			}});
		});
	}
}