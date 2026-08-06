package funkin.objects;

import flixel.animation.FlxAnimationController;
import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import funkin.data.Song;
import funkin.data.Section;
import animate.FlxAnimate;
import funkin.backend.parsers.CodenameParser;
import haxe.Json;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:flixel.util.typeLimit.OneOfTwo<String, Array<String>>;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional
	var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	@:optional
	var isFrameLabel:Bool;
}

enum CharacterSpriteType
{
	SPRITE;
	MULTI_ATLAS;
	TEXTURE_ATLAS;
}

class Character extends FlxAnimate
{
	/**
	 * In case a character is missing, it will use this on its place
	**/
	public static final DEFAULT_CHARACTER:String = 'bf';

	/**
	 * how much the ghost anims move when played
	 */
	public var ghostDisplacement:Float = 60;
	
	/**
	 *	if enabled, ghosts will show on double notes for the character
	 */
	public var ghostsEnabled:Bool = true;
	
	/**
	 * Array of all ghosts (now holds on-demand created ghosts)
	 */
	public var doubleGhosts:Array<FlxSprite> = [];
	
	/**
	 * Array of all ghosts tweens (parallel to doubleGhosts)
	 */
	public var ghostTweenGrp:Array<FlxTween> = [];
	
	/**
	 * Alpha that the ghosts doubles appear at
	 */
	public var ghostAlpha:Float = 0.75;
	
	/**
	 * Last hit row index
	 */
	public var mostRecentRow:Int = 0; // for ghost anims n shit

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var isMultiAtlas:Bool = false; // for psychlua smh
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var noNoteAnim:Bool = false;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;
	public var isAnimateAtlas:Bool = false;

	public var spriteType:CharacterSpriteType = SPRITE;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':

			default:
				var characterPath:String = 'characters/$curCharacter.json';
				var isJSON:Bool = true;
				var path:String = Paths.getPath(characterPath, TEXT, null, true);
				#if MODS_ALLOWED
				if (!FileSystem.exists(path))
				#else
				if (!Assets.exists(path))
				#end
				{
					characterPath = 'characters/$curCharacter.xml';
					isJSON = false;
					path = Paths.getPath(characterPath, TEXT, null, true);
					#if MODS_ALLOWED
					if (!FileSystem.exists(path))
					#else
					if (!Assets.exists(path))
					#end
					{
						path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
						color = FlxColor.BLACK;
						alpha = 0.6;
					}
				}

				try
				{
					if(isJSON){
						#if MODS_ALLOWED
						loadCharacterFile(Json.parse(File.getContent(path)));
						#else
						loadCharacterFile(Json.parse(Assets.getText(path)));
						#end
					} else {
						#if MODS_ALLOWED
						loadCharacterFile(Json.parse(CodenameParser.characterParse(File.getContent(path))));
						#else
						loadCharacterFile(Json.parse(CodenameParser.characterParse(Assets.getText(path))));
						#end
					}
				}
				catch(e:Dynamic)
				{
					Log.error('Error loading character file of "$character": $e');
				}
		}

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		recalculateDanceIdle();
		dance();
	}

	override public function isOnScreen(?camera:FlxCamera):Bool
	{
		if (spriteType == MULTI_ATLAS)
			return true; // flixel is stoobid

		if (camera == null)
			camera = FlxG.camera;

		return camera.containsRect(getScreenBounds(_rect, camera));
	}

	public function loadCharacterFile(json:Dynamic)
	{
		scale.set(1, 1);
		updateHitbox();

		if (!(json.image is String))
		{
			spriteType = MULTI_ATLAS;
			isAnimateAtlas = false;
			isMultiAtlas = true;
			frames = Paths.getAtlas(json.image[0]);
			final split:Array<String> = json.image;
			if (frames != null)
				for (imgFile in split)
				{
					final daAtlas = Paths.getAtlas(imgFile);
					if (daAtlas != null)
						cast(frames, flixel.graphics.frames.FlxAtlasFrames).addAtlas(daAtlas);
				}
			imageFile = json.image[0];
		}
		else
		{
			if (!Paths.fileExists('images/${haxe.io.Path.withExtension(json.image.split(',')[0], 'png')}', IMAGE))
			{
				spriteType = TEXTURE_ATLAS;
				isAnimateAtlas = true;
				isMultiAtlas = false;
				frames = Paths.getTextureAtlas(json.image);
			}
			else
			{
				spriteType = SPRITE;
				isMultiAtlas = isAnimateAtlas = false;
				frames = Paths.getMultiAtlas(json.image.split(','));
			}
			imageFile = json.image;
		}

		jsonScale = json.scale;
		if (json.scale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}

		// positioning
		positionArray = json.position;
		cameraPosition = json.camera_position;

		// data
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		flipX = (json.flip_x != isPlayer);
		healthColorArray = (json.healthbar_colors != null && json.healthbar_colors.length > 2) ? json.healthbar_colors : [161, 161, 161];
		vocalsFile = json.vocals_file != null ? json.vocals_file : '';
		originalFlipX = (json.flip_x == true);
		editorIsPlayer = json._editor_isPlayer;

		// antialiasing
		noAntialiasing = (json.no_antialiasing == true);
		antialiasing = ClientPrefs.data.antialiasing ? !noAntialiasing : false;

		// animations
		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; // bruh?
				var animIndices:Array<Int> = anim.indices;

				switch (spriteType)
				{
					case TEXTURE_ATLAS:
						if (anim.isFrameLabel)
						{
							if (animIndices != null && animIndices.length > 0)
								this.anim.addByFrameLabelIndices(animAnim, animName, animIndices, animFps, animLoop);
							else
								this.anim.addByFrameLabel(animAnim, animName, animFps, animLoop);
						}
						else
						{
							if (animIndices != null && animIndices.length > 0)
								this.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
							else
								this.anim.addBySymbol(animAnim, animName, animFps, animLoop);
						}
					default:
						if (animIndices != null && animIndices.length > 0)
							this.anim.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						else
							this.anim.addByPrefix(animAnim, animName, animFps, animLoop);
				}

				if (anim.offsets != null && anim.offsets.length > 1)
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else
					addOffset(anim.anim, 0, 0);
			}
		}
		// trace('Loaded file to character ' + curCharacter);
	}

	public function changeCharacter(character:String)
	{
		animationsArray = [];
		animOffsets = [];
		curCharacter = character;
		var characterPath:String = 'characters/$character.json';
		var isJSON:Bool = true;
		var path:String = Paths.getPath(characterPath, TEXT);
		#if MODS_ALLOWED
		if (!FileSystem.exists(path))
		#else
		if (!Assets.exists(path))
		#end
		{
			characterPath = 'characters/$character.xml';
			isJSON = false;
			path = Paths.getPath(characterPath, TEXT);
			#if MODS_ALLOWED
			if (!FileSystem.exists(path))
			#else
			if (!Assets.exists(path))
			#end
			{
				path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER + '.json');
			}
		}

		try
		{
			if(isJSON){
				#if MODS_ALLOWED
				loadCharacterFile(Json.parse(File.getContent(path)));
				#else
				loadCharacterFile(Json.parse(Assets.getText(path)));
				#end
			} else {
				#if MODS_ALLOWED
				loadCharacterFile(Json.parse(CodenameParser.characterParse(File.getContent(path))));
				#else
				loadCharacterFile(Json.parse(CodenameParser.characterParse(Assets.getText(path))));
				#end
			}
		}
		catch(e:Dynamic)
		{
			Log.error('Error loading character file of "$character": $e');
		}

		skipDance = false;
		hasMissAnimations = hasAnimation('singLEFTmiss') || hasAnimation('singDOWNmiss') || hasAnimation('singUPmiss') || hasAnimation('singRIGHTmiss');
		recalculateDanceIdle();
		dance();
	}

	public function hasAnimation(anim:String):Bool
	{
		return animOffsets.exists(anim);
	}

	override function update(elapsed:Float)
	{
		if (debugMode || isAnimationNull())
		{
			super.update(elapsed);
			return;
		}

		if (heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if (heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if (specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		if (getAnimationName().startsWith('sing'))
			holdTimer += elapsed;

		if (holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if (isAnimationFinished() && animOffsets.exists('$name-loop'))
			playAnim('$name-loop');

		if (ghostsEnabled){
			for (ghost in doubleGhosts)
				ghost.update(elapsed);
		}

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return anim.curAnim == null;

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if (!isAnimationNull())
			name = anim.curAnim.name;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if (isAnimationNull())
			return false;
		return anim.curAnim.finished;
	}

	public function finishAnimation():Void
	{
		if (isAnimationNull())
			return;

		anim.curAnim.finish();
	}

	public var animPaused(get, set):Bool;

	private function get_animPaused():Bool
	{
		if (isAnimationNull())
			return false;
		return anim.curAnim.paused;
	}

	private function set_animPaused(value:Bool):Bool
	{
		if (isAnimationNull())
			return value;

		anim.curAnim.paused = value;

		return value;
	}

	public var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animOffsets.exists('idle' + idleSuffix))
			{
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName)){
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf'){
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	function loadMappedAnims():Void
	{
		try
		{
			var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
			for (section in noteData)
			{
				for (songNotes in section.sectionNotes)
				{
					animationNotes.push(songNotes);
				}
			}
			animationNotes.sort(sortAnims);
		}
		catch (e:Dynamic)
		{
		}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.exists('danceLeft' + idleSuffix) && animOffsets.exists('danceRight' + idleSuffix));

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		if (spriteType == TEXTURE_ATLAS)
			this.anim.addBySymbol(name, name, 24, false);
		else
			this.anim.addByPrefix(name, anim, 24, false);
	}

	public override function draw(){
		if (ghostsEnabled){
			for (ghost in doubleGhosts){
				if (ghost.visible) ghost.draw();
			}
		}
		super.draw();
	}

	public function playGhostAnim(ghostID = 0, animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0){
		var ghost:FlxAnimate = new FlxAnimate();
		ghost.scale.copyFrom(scale);
		ghost.frames = frames;
		setupGhostAnims(ghost);
		ghost.antialiasing = antialiasing;
		ghost.x = x;
		ghost.y = y;
		ghost.shader = shader;
		ghost.cameras = cameras;
		ghost.scrollFactor.x = scrollFactor.x;
		ghost.scrollFactor.y = scrollFactor.y;
		ghost.flipX = flipX;
		ghost.flipY = flipY;
		ghost.alpha = alpha * ghostAlpha;
		ghost.visible = true;
		ghost.color = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);

		ghost.animation.play(animName, force, reversed, frame);

		if (animOffsets.exists(animName)){
			var daOffset = animOffsets.get(animName);
			ghost.offset.set(daOffset[0], daOffset[1]);
		}

		final direction:String = animName.substring(4).split('-')[0];

		inline function resolveDir(xDir:Bool = false):Float {
			var output:Float = 0;
			switch (direction){
				case 'UP':
					if (!xDir) output = -ghostDisplacement;
				case 'DOWN':
					if (!xDir) output = ghostDisplacement;
				case 'RIGHT':
					if (xDir) output = ghostDisplacement;
				case 'LEFT':
					if (xDir) output = -ghostDisplacement;
			}
			
			return output;
		}
		
		final moveX = x + resolveDir(true);
		final moveY = y + resolveDir(false);
		
		doubleGhosts.push(ghost);
		ghostTweenGrp.push(null);

		var myIndex:Int = doubleGhosts.length - 1;
		var twn:FlxTween = FlxTween.tween(ghost, {alpha: 0, x: moveX, y: moveY}, 0.75, {
			onComplete: (completedTween) -> {
				var idx = doubleGhosts.indexOf(ghost);
				if (idx >= 0){
					var oldTween = ghostTweenGrp[idx];
					if (oldTween != null) oldTween.cancel();
					ghostTweenGrp.splice(idx, 1);
					doubleGhosts.splice(idx, 1);
				}

				ghost.visible = false;
				FlxDestroyUtil.destroy(ghost);
			}
		});

		ghostTweenGrp[myIndex] = twn;
	}

	public function setupGhostAnims(target:FlxAnimate){
		if (animationsArray == null || animationsArray.length <= 0) return;

		for (anim in animationsArray){
			var animAnim:String = '' + anim.anim;
			var animName:String = '' + anim.name;
			var animFps:Int = anim.fps;
			var animLoop:Bool = !!anim.loop;
			var animIndices:Array<Int> = anim.indices;

			switch (spriteType){
				case TEXTURE_ATLAS:
					if (anim.isFrameLabel){
						if (animIndices != null && animIndices.length > 0)
							target.anim.addByFrameLabelIndices(animAnim, animName, animIndices, animFps, animLoop);
						else
							target.anim.addByFrameLabel(animAnim, animName, animFps, animLoop);
					} else {
						if (animIndices != null && animIndices.length > 0)
							target.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
						else
							target.anim.addBySymbol(animAnim, animName, animFps, animLoop);
					}
				default:
					if (animIndices != null && animIndices.length > 0)
						target.anim.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						target.anim.addByPrefix(animAnim, animName, animFps, animLoop);
			}
		}
	}

	public override function destroy()
	{
		if(ghostTweenGrp != null){
			for (t in ghostTweenGrp)
			{
				t?.cancel();
			}

		ghostTweenGrp = FlxDestroyUtil.destroyArray(ghostTweenGrp);
		doubleGhosts = FlxDestroyUtil.destroyArray(doubleGhosts);
		}

		super.destroy();
	}
}
