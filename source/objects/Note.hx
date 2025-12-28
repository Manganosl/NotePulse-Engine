package objects;

import backend.ExtraKeysHandler;
import backend.animation.PsychAnimationController;
import backend.NoteTypesConfig;

import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;

import objects.StrumNote;

import flixel.math.FlxRect;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	useGlobalShader:Bool,
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

class Note extends FlxSkewedSprite
{
	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;

	public var strum:StrumNote = null;
	public var row:Int = 0;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;
	public var gfStrum:Bool = false;
	public var strumSet:Int = 0;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = [];
	public var parent:Note;
	public var blockHit:Bool = false;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var lowPriority:Bool = false;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var swagWidthUnscaled:Float = 160;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static var defaultNoteSkin(default, never):String = 'noteSkins/NOTE_assets';

	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: !PlayState.isPixelStage,
		useGlobalShader: false,
		useRGBShader: (PlayState.SONG != null) ? !(PlayState.SONG.disableNoteRGB == true) : true,
		r: -1,
		g: -1,
		b: -1,
		a: ClientPrefs.data.splashAlpha
	};

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0;
	public var ratingDisabled:Bool = false;
	public var column:Int = 0;

	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000;

	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	public var hitsound:String = 'hitsound';

	public var characters:Array<Character> = null;

	private function set_multSpeed(value:Float):Float {
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}

	public function resizeByRatio(ratio:Float)
	{
		if(isSustainNote && animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	private function set_texture(value:String):String {
		if(texture != value) reloadNote(value);
		texture = value;
		return value;
	}

	public function defaultRGB()
	{
		var mania = 3;
		if (PlayState.SONG != null) mania = PlayState.SONG.mania;
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[getIndex(mania, noteData)];
		if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[getIndex(mania, noteData)];
		if (noteData > -1)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	private function set_noteType(value:String):String {
		noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
		defaultRGB();
		if(noteData > -1 && noteType != value) {
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';
					lowPriority = true;
					missHealth = isSustainNote ? 0.25 : 0.1;
					hitCausesMiss = true;
					hitsound = 'cancelMenu';
					hitsoundChartEditor = false;
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
			}
			if (value != null && value.length > 1) NoteTypesConfig.applyNoteTypeData(this, value);
			if (hitsound != 'hitsound' && ClientPrefs.data.hitsoundVolume > 0) Paths.sound(hitsound);
			noteType = value;
		}
		return value;
	}

	public function getIndex(mania:Int, note:Int):Int {
		return ExtraKeysHandler.instance.data.keys[mania].notes[note];
	}

	public function getAnimSet(index:Int):EKAnimation {
		return ExtraKeysHandler.instance.data.animations[index];
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?createdFrom:Dynamic = null)
	{
		super();
		animation = new PsychAnimationController(this);
		antialiasing = ClientPrefs.data.antialiasing;
		if(createdFrom == null) createdFrom = PlayState.instance;
		if (prevNote == null)
			prevNote = this;
		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.moves = false;
		x += (ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		y -= 2000;
		this.strumTime = strumTime;
		if(!inEditor) this.strumTime += ClientPrefs.data.noteOffset;
		this.noteData = noteData;
		if(noteData > -1) {
			texture = '';
			rgbShader = new RGBShaderReference(this, initializeGlobalRGBShader(noteData));
			if(PlayState.SONG != null && PlayState.SONG.disableNoteRGB) rgbShader.enabled = false;
			x += swagWidth * (noteData);
			if(!isSustainNote) {
				var animToPlay:String = '';
				var mania = 3;
				if (PlayState.SONG != null) mania = PlayState.SONG.mania;
				animToPlay = getAnimSet(getIndex(mania, noteData)).note;
				animation.play(animToPlay + 'Scroll');
			}
		}
		if(prevNote != null)
			prevNote.nextNote = this;
		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;
			offsetX += width / 2;
			copyAngle = false;
			var mania = 3;
			if (PlayState.SONG != null) mania = PlayState.SONG.mania;
			var animToPlay = getAnimSet(getIndex(mania, noteData)).note;
			animation.play(animToPlay + 'holdend');
			updateHitbox();
			offsetX -= width / 2;
			if (PlayState.isPixelStage){
				offsetX += 30;
			}
			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(animToPlay + 'hold');
				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;
				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height);
				}
				prevNote.updateHitbox();
			}
			if(PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
			earlyHitMult = 0;
			isSustainEnd = true;
		}
		else if(!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
		x += offsetX;
	}

	public static function initializeGlobalRGBShader(noteData:Int)
	{
		if(globalRgbShaders[noteData] == null)
		{
			var newRGB:RGBPalette = new RGBPalette();
			globalRgbShaders[noteData] = newRGB;
			var mania = 3;
			if (PlayState.SONG != null) mania = PlayState.SONG.mania;
			var arr:Array<FlxColor> = (!PlayState.isPixelStage) ? ClientPrefs.data.arrowRGB[ExtraKeysHandler.instance.data.keys[mania].notes[noteData]] : ClientPrefs.data.arrowRGBPixel[ExtraKeysHandler.instance.data.keys[mania].notes[noteData]];
			if (noteData > -1)
			{
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		return globalRgbShaders[noteData];
	}

	var _lastNoteOffX:Float = 0;
	static var _lastValidChecked:String;
	public var originalHeight:Float = 6;
	public var correctionOffset:Float = 0;
	public function reloadNote(texture:String = '', postfix:String = '')
	{
		if(texture == null) texture = '';
		if(postfix == null) postfix = '';
		var skin:String = texture + postfix;
		if(texture.length < 1) {
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1)
				skin = defaultNoteSkin + postfix;
		}
		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}
		var skinPixel:String = skin;
		var lastScaleY:Float = scale.y;
		var skinPostfix:String = getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		var path:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		if(customSkin == _lastValidChecked || Paths.fileExists('images/' + path + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else skinPostfix = '';
		if(PlayState.isPixelStage) {
			if(isSustainNote) {
				var graphic = Paths.image('pixelUI/' + skinPixel + 'ENDS' + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / getPixelColumns()), Math.floor(graphic.height / 2));
				originalHeight = graphic.height / 2;
			} else {
				var graphic = Paths.image('pixelUI/' + skinPixel + skinPostfix);
				loadGraphic(graphic, true, Math.floor(graphic.width / getPixelColumns()), Math.floor(graphic.height / 5));
			}
			var mania = 3;
			if (PlayState.SONG != null) mania = PlayState.SONG.mania;
			setGraphicSize((width * (ExtraKeysHandler.instance.data.pixelScales[mania] + 0.3)) * PlayState.daPixelZoom);
			loadPixelNoteAnims();
			antialiasing = false;
			if(isSustainNote) {
				offsetX += _lastNoteOffX;
				_lastNoteOffX = (width - 7) * (PlayState.daPixelZoom / 2);
				offsetX -= _lastNoteOffX;
			}
		} else {
			frames = Paths.getSparrowAtlas(skin);
			loadNoteAnims();
			if(!isSustainNote)
			{
				centerOffsets();
				centerOrigin();
			}
		}
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		updateHitbox();
		if(animName != null)
			animation.play(animName, true);
	}

	public static function getNoteSkinPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.noteSkin != ClientPrefs.defaultData.noteSkin)
			skin = '-' + ClientPrefs.data.noteSkin.trim().toLowerCase().replace(' ', '_');
		return skin;
	}

	function loadNoteAnims() {
		var mania = 3;
		if (PlayState.SONG != null) mania = PlayState.SONG.mania;
		var noteAnim = getAnimSet(getIndex(mania, noteData)).note;
		if (isSustainNote)
		{
			attemptToAddAnimationByPrefix('purpleholdend', 'pruple end hold', 24, true);
			animation.addByPrefix(noteAnim + 'holdend', noteAnim + ' hold end', 24, true);
			animation.addByPrefix(noteAnim + 'hold', noteAnim + ' hold piece', 24, true);
		}
		else animation.addByPrefix(noteAnim + 'Scroll', noteAnim + '0');
		setGraphicSize(width * ExtraKeysHandler.instance.data.scales[mania]);
		updateHitbox();
	}

	function loadPixelNoteAnims() {
		var mania = 3;
		if (PlayState.SONG != null) mania = PlayState.SONG.mania;
		var noteAnimStr = getAnimSet(getIndex(mania, noteData)).note;
		var noteAnimInt = getAnimSet(getIndex(mania, noteData)).pixel;
		var cols = Note.getPixelColumns();

		if (isSustainNote) {
			animation.add(noteAnimStr + 'holdend', [noteAnimInt + cols], 24, true);
			animation.add(noteAnimStr + 'hold', [noteAnimInt], 24, true);
		} else {
			animation.add(noteAnimStr + 'Scroll', [noteAnimInt + cols], 24, true);
		}
	}

	function attemptToAddAnimationByPrefix(name:String, prefix:String, framerate:Float = 24, doLoop:Bool = true)
	{
		var animFrames = [];
		@:privateAccess
		animation.findByPrefix(animFrames, prefix);
		if(animFrames.length < 1) return;
		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	public static function getDistance(time:Float, speed:Float) {
		return (0.45 * time * speed);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(strum == null) return;
		if (strum.playable)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit)
				tooLate = true;
		}
		else
		{
			canBeHit = false;
			if (strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult))
			{
				if((isSustainNote && prevNote.wasGoodHit) || strumTime <= Conductor.songPosition)
					wasGoodHit = true;
			}
		}
		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}

	override public function destroy()
	{
		super.destroy();
		_lastValidChecked = '';
	}

	private var realDirection:Float = 0;
	public function followStrumNote(strum:StrumNote, fakeCrochet:Float, songSpeed:Float = 1)
	{
		this.strum = strum;
		var mania = 3;
		if (PlayState.SONG != null) mania = PlayState.SONG.mania;
		var Mscale = ExtraKeysHandler.instance.data.scales[mania];
		if (PlayState.isPixelStage) Mscale = ExtraKeysHandler.instance.data.pixelScales[mania];
		var sWidth = Note.swagWidthUnscaled * Mscale;
		var strumX:Float = strum.x;
		var strumY:Float = strum.y;
		var strumAngle:Float = strum.angle;
		var strumAlpha:Float = strum.alpha;
		realDirection = strum.direction + (!strum.downScroll ? 180 : 0);
		distance = (0.45 * (Conductor.songPosition - strumTime) * songSpeed * multSpeed * strum.noteSpeed);
		var angleDir = realDirection * Math.PI / 180;
		if (copyAngle)
			angle = strumAngle + offsetAngle;
		else if(isSustainNote){
			angle = realDirection - 90 + offsetAngle;
		}
		if(copyAlpha)
			alpha = strumAlpha * multAlpha;
		if(copyX)
			x = strumX + offsetX + Math.cos(angleDir) * distance;
		if(copyY)
			y = strumY + offsetY + correctionOffset + Math.sin(angleDir) * distance;
		if (isSustainNote)
			updateSustain(songSpeed * multSpeed * strum.noteSpeed);
	}

	public var extraOffsetX:Float = 0;
	public function updateSustain(noteSpeed:Float = 1)
	{
		if (!isSustainEnd)
		{
			scale.y = getDistance(sustainLength, noteSpeed) / frameHeight;
			updateHitbox();
		}
		origin.set(frameWidth * .5, 0);
		offset.set();
		var angleDir = realDirection * Math.PI / 180;
		if(prevNote != null){
			if(!prevNote.isSustainNote)
				extraOffsetX = ExtraKeysHandler.calculateWidth(prevNote.width);
			else
				extraOffsetX = prevNote.extraOffsetX;
		}
		x = strum.x + offsetX + (extraOffsetX * (PlayState.isPixelStage ? -1 : 1)) + Math.cos(angleDir) * distance;
		angle += 180;
	}

	public function clipToStrumNote(strum:StrumNote)
	{
		this.strum = strum;
		var mania = 3;
		if (PlayState.SONG != null) mania = PlayState.SONG.mania;
		var Mscale = ExtraKeysHandler.instance.data.scales[mania];
		if (PlayState.isPixelStage) Mscale = ExtraKeysHandler.instance.data.pixelScales[mania];
		var sWidth = Note.swagWidthUnscaled * Mscale;

		if (isSustainNote && (mustPress || !ignoreNote) && wasGoodHit)
		{
			var clipDistance:Float = Math.max(distance - (strum.downScroll ? (strum.height/2) : 0), 0);
			clipRect ??= new FlxRect(0, 0, frameWidth);
			clipRect.y = clipDistance / scale.y;
			clipRect.height = frameHeight - clipRect.y;

			clipRect = clipRect;
		}
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;
		if (frames != null)
			frame = frames.frames[animation.frameIndex];
		return rect;
	}

	public static inline function getPixelColumns():Int {
		return (PlayState.SONG != null && PlayState.SONG.pixel4kTexture) ? 4 : 6;
	}
}