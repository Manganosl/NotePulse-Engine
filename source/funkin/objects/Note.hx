package funkin.objects;

import funkin.backend.ExtraKeysHandler;
import funkin.backend.animation.PsychAnimationController;
import funkin.backend.NoteTypesConfig;

import funkin.game.shaders.RGBPalette;
import funkin.game.shaders.RGBPalette.RGBShaderReference;

import funkin.objects.StrumNote;
import funkin.objects.PlayField;

import flixel.math.FlxRect;

import funkin.game.modchart.backend.util.ModchartableSprite;

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
	useGlobalShader:Bool, //breaks r/g/b but makes it copy default colors for your custom note
	useRGBShader:Bool,
	antialiasing:Bool,
	r:FlxColor,
	g:FlxColor,
	b:FlxColor,
	a:Float
}

class Note extends ModchartableSprite {
	//This is needed for the hardcoded note types to appear on the Chart Editor,
	//It's also used for backwards compatibility with 0.1 - 0.3.2 charts.
	public static final defaultNoteTypes:Array<String> = [
		'', //Always leave this one empty pls
		'Alt Animation',
		'Hey!',
		'Hurt Note',
		'GF Sing',
		'No Animation'
	];

	static final QUANT_COLORS:Map<String, Array<FlxColor>> = [
		"R" => [0xFFFF0000, 0xFFFFFFFF, 0xFF800000],
		"B" => [0xFF0000FF, 0xFFFFFFFF, 0xFF000080], 
		"P" => [0xFFAA00AA, 0xFFFFFFFF, 0xFF550055],   
		"Y" => [0xFFFFFF00, 0xFFFFFFFF, 0xFF808000],   
		"K" => [0xFFFF00FF, 0xFFFFFFFF, 0xFF800080], 
		"O" => [0xFFFFA500, 0xFFFFFFFF, 0xFF804000],   
		"C" => [0xFF00FFFF, 0xFFFFFFFF, 0xFF008080], 
		"G" => [0xFF00FF00, 0xFFFFFFFF, 0xFF008000],  
		"T" => [0xFF008080, 0xFFFFFFFF, 0xFF004040]
	];

	static final BEAT_DIVS:Array<{div:Float, col:String}> = [
		{div: 192/4,  col: "R"},
		{div: 192/6,  col: "P"},
		{div: 192/8,  col: "B"},
		{div: 192/12, col: "P"},
		{div: 192/16, col: "Y"},
		{div: 192/24, col: "K"},
		{div: 192/32, col: "O"},
		{div: 192/48, col: "C"},
		{div: 192/64, col: "G"}
	];

	@:isVar public var strum(get, set):StrumNote = null;
	public var playField(default, set):PlayField = null;
	public var row:Int = 0;
	public var column:Int = 0; // Why both for the same thing? I'm dumb

	public var characters:Array<Character> = [];

	public var modchartVisible:Bool = true;
	public var followStrum:Bool = true;

	public var strumTime:Float = 0;
	public var noteData:Int = 0;

	public var mustPress:Bool = false;
	public var canBeHit:Bool = false;
	public var gfStrum:Bool = false;
	public var tooLate:Bool = false;

	public var wasGoodHit:Bool = false;
	public var missed:Bool = false;

	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;

	public var spawned:Bool = false;

	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	public var blockHit:Bool = false; // only works for player

	public var sustainLength:Float = 0;
	public var isSustainEnd:Bool = false;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var rgbShader:RGBShaderReference;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;
	
	public var character:Character = null;
	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var earlyHitMult:Float = 1;
	public var lateHitMult:Float = 1;
	public var hitPriority:Float = 1;
	public var lowPriority(get, set):Bool;

	public static var SUSTAIN_SIZE:Int = 44;
	public static var swagWidth:Float = 160 * 0.7;
	public static var swagWidthUnscaled:Float = 160;
	public static var dirArray:Array<String> = ['left', 'down', 'up', 'right'];
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
	public var offsetDirection:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hitHealth:Float = 0.02;
	public var missHealth:Float = 0.1;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;
	public var noteSplash:NoteSplash = null;
	
	public var loadedTexture:String = null;
	public var texture(default, set):String = null;

	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb
	
	public var playMissSound:Bool = false;
	public var hitsoundDisabled:Bool = false;
	public var hitsoundChartEditor:Bool = true;
	/**
	 * Forces the hitsound to be played even if the user's hitsound volume is set to 0
	**/
	public var hitsoundForce:Bool = false;
	public var hitsoundVolume(get, default):Float = 1.0;
	function get_hitsoundVolume():Float {
		if(ClientPrefs.data.hitsoundVolume > 0)
			return ClientPrefs.data.hitsoundVolume;
		return hitsoundForce ? hitsoundVolume : 0.0;
	}
	public var hitsound:String = 'hitsound';
	public var section:Int = 0;

	private function get_strum():StrumNote {
		if(playField == null) return null;
		return playField.members[noteData];
	}

	private function set_strum(value:StrumNote):StrumNote {
		if(playField == null) return null;
		playField = strum.parentField;
		noteData = strum.noteData;
		return value;
	}

	private function set_playField(value:PlayField):PlayField {
		if(playField != null)
			playField.notes.remove(this);
		value.notes.push(this);
		return playField = value;
	}

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
		if(texture != value) {
			texture = value;
			reloadNote(value);
		}
		return value;
	}
	
	function set_lowPriority(value:Bool):Bool {
		hitPriority = (value ? Math.NEGATIVE_INFINITY : 1);
		return value;
	}
	function get_lowPriority():Bool {
		return (hitPriority == Math.NEGATIVE_INFINITY);
	}

	inline function getQuantBeat(strumTime:Float):Int
	{
		var bpm:Float = Conductor.bpm;
		var newTime:Float = strumTime;

		for (change in Conductor.bpmChangeMap)
		{
			if (strumTime > change.songTime)
			{
				bpm = change.bpm;
				newTime = strumTime - change.songTime;
			}
		}

		var noteOffset:Float = ClientPrefs.data.noteOffset;
		var noteBeat:Float = (bpm * (newTime - noteOffset)) / 1000 / 60;
		return Math.round(noteBeat * 48);
	}

	function getQuantColor(strumTime:Float):Array<FlxColor>
	{
		var beat:Int = getQuantBeat(strumTime);
		var col:String = "T";

		for (entry in BEAT_DIVS)
		{
			if (beat % entry.div == 0)
			{
				col = entry.col;
				break;
			}
		}

		return QUANT_COLORS.get(col);
	}

	public function defaultRGB()
	{
		if(!PlayState.SONG.disableNoteRGB && ClientPrefs.data.quantNotes && noteData > -1)
		{
			if(isSustainNote && prevNote != null)
			{
				rgbShader.r = prevNote.rgbShader.r;
				rgbShader.g = prevNote.rgbShader.g;
				rgbShader.b = prevNote.rgbShader.b;
				return;
			}

			var arr = getQuantColor(strumTime);
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
			return;
		}

		var mania = 3;
		if (PlayState.SONG != null) mania = PlayState.SONG.mania;

		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[getIndex(mania, noteData)];
		if (PlayState.isPixelStage)
			arr = ClientPrefs.data.arrowRGBPixel[getIndex(mania, noteData)];

		if (noteData > -1)
		{
			rgbShader.r = arr[0];
			rgbShader.g = arr[1];
			rgbShader.b = arr[2];
		}
	}

	private function set_noteType(value:String):String {
		if(noteData > -1 && noteType != value) {
			noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes/noteSplashes';
			defaultRGB();
			
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					//reloadNote('HURTNOTE_assets');
					//this used to change the note texture to HURTNOTE_assets.png,
					//but i've changed it to something more optimized with the implementation of RGBPalette:

					// note colors
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;

					// splash data and colors
					noteSplashData.r = 0xFFFF0000;
					noteSplashData.g = 0xFF101010;
					noteSplashData.texture = 'noteSplashes/noteSplashes-electric';

					// gameplay data
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
			if (hitsound != 'hitsound' && hitsoundVolume > 0) Paths.sound(hitsound); //precache new sound for being idiot-proof
		}
		return noteType = value;
	}

	private var oldSY:Float;
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

		oldSY = scale.y;
		if(prevNote != null){
			prevNote.nextNote = this;
			if (prevNote.isSustainNote)
			{
				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05;
				if(createdFrom != null && createdFrom.songSpeed != null) prevNote.scale.y *= createdFrom.songSpeed;
				if(PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height);
					prevNote.scale.y *= 6;
				}
				prevNote.updateHitbox();
			}
		}

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;
			hitsoundDisabled = true;

			var mania = 3;
			if (PlayState.SONG != null) mania = PlayState.SONG.mania;
			var animToPlay = getAnimSet(getIndex(mania, noteData)).note;
			animation.play(animToPlay + 'holdend');
			updateHitbox();

			if (prevNote.isSustainNote) {
				prevNote.isSustainEnd = false;
				prevNote.animation.play(animToPlay + 'hold');
			}
			
			isSustainEnd = true;
			earlyHitMult = 0;
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
	public var originalHeight:Float = 6;
	static var _lastValidChecked:String;
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
		animation.findByPrefix(animFrames, prefix); // adds valid frames to animFrames
		if(animFrames.length < 1) return;

		animation.addByPrefix(name, prefix, framerate, doLoop);
	}

	private var currentStrumSpeed:Float = -99999999999999;  // Can't use null so fuck it
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if(strum == null) return;
		if(!strum.cpuControlled)
		{
			canBeHit = (strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * lateHitMult) &&
						strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult));
		}
		else
		{
			canBeHit = false;

			if (!wasGoodHit && strumTime <= Conductor.songPosition)
			{
				if(!isSustainNote || (prevNote.wasGoodHit && !ignoreNote))
					wasGoodHit = true;
			}
		}

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}

		if(currentStrumSpeed == -99999999999999) currentStrumSpeed = strum.noteSpeed;
		if(currentStrumSpeed != strum.noteSpeed){
			var ratio = strum.noteSpeed / currentStrumSpeed;
			currentStrumSpeed = strum.noteSpeed;
			resizeByRatio(ratio);
		}
	}

	private var lastDistance:Float = 0;
	public function followStrumNote(fakeCrochet:Float, songSpeed:Float = 1)
	{
		var noteSpeed:Float = songSpeed * multSpeed * strum.noteSpeed;
		var strumDir:Float = strum.direction + this.offsetDirection;
		
		distance = getDistance(strumTime - Conductor.songPosition, noteSpeed, strum);
		lastDistance = distance;
		var scrollMult:Int = (strum.downScroll ? -1 : 1);
		
		if(copyAlpha)
			alpha = strum.alpha * multAlpha;
		
		var angleDir:Float = strumDir * Math.PI / 180;
		if(copyX)
			x = strum.x + offsetX + Math.cos(angleDir) * distance;
		if(copyY)
			y = strum.y + offsetY + Math.sin(angleDir) * (followStrum ? distance : lastDistance) * scrollMult;
		if (copyAngle)
			angle = (isSustainNote ? strumDir - 90 : strum.angle) + offsetAngle;
		
		if (isSustainNote)
			updateSustain(noteSpeed);
	}
	
	public function updateSustain(noteSpeed:Float = 1) {
		if(!isSustainEnd && parent == null) {
			scale.y = getDistance(sustainLength, noteSpeed, strum) / frameHeight;
			updateHitbox();
		}
		if(isSustainEnd) {
			scale.y = oldSY;
		}
		origin.set(frameWidth * .5, 0);
		offset.set();
		
		flipX = strum.downScroll;
		x += (strum.width - frameWidth) * .5;
		y += strum.height * .5;
		if (strum.downScroll)
			angle = 180 - angle;
	}
	public static function getDistance(time:Float, speed:Float, daStrum:StrumNote) {
		return (0.45 * time * speed * daStrum.noteSpeed);
	}

	public function clipToStrumNote()
	{
		if ((mustPress || !ignoreNote) && wasGoodHit) {
			var clipDistance:Float = Math.max(-distance, 0);
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

	public function getIndex(mania:Int, note:Int):Int {
		return ExtraKeysHandler.instance.data.keys[mania].notes[note];
	}

	public function getAnimSet(index:Int):EKAnimation {
		return ExtraKeysHandler.instance.data.animations[index];
	}
}
