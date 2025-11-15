package objects;

import backend.animation.PsychAnimationController;

import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;

import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;

import backend.Song;
import backend.Section;
import states.stages.objects.TankmenBG;

typedef CharacterFile = {
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
	var vocals_file:String;
	@:optional var _editor_isPlayer:Null<Bool>;
}

typedef AnimArray = {
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSkewedSprite
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
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var noNoteAnim:Bool = false;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var hasMissAnimations:Bool = false;
	public var vocalsFile:String = '';

	//Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var editorIsPlayer:Null<Bool> = null;

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animation = new PsychAnimationController(this);

		animOffsets = new Map<String, Array<Dynamic>>();
		curCharacter = character;
		this.isPlayer = isPlayer;
		switch (curCharacter)
		{
			//case 'your character name in case you want to hardcode them instead':

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
						loadCharacterFile(Json.parse(xmlToJsonString(File.getContent(path))));
						#else
						loadCharacterFile(Json.parse(xmlToJsonString(Assets.getText(path))));
						#end
					}
				}
				catch(e:Dynamic)
				{
					Log.error('Error loading character file of "$character": $e');
				}
		}

		if(animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		// buildGhosts() removed — ghosts are created on-demand now
		dance();

		switch(curCharacter)
		{
			case 'pico-speaker':
				skipDance = true;
				loadMappedAnims();
				playAnim("shoot1");
		}
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
				loadCharacterFile(Json.parse(xmlToJsonString(File.getContent(path))));
				#else
				loadCharacterFile(Json.parse(xmlToJsonString(Assets.getText(path))));
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

	public function loadCharacterFile(json:Dynamic)
	{
		isAnimateAtlas = false;

		#if flxanimate
		var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT, null, true);
		if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
			isAnimateAtlas = true;
		#end

		scale.set(1, 1);
		updateHitbox();

		if(!isAnimateAtlas)
		{
			frames = Paths.getMultiAtlas(json.image.split(','));
		}
		#if flxanimate
		else
		{
			atlas = new FlxAnimate();
			atlas.showPivot = false;
			try
			{
				Paths.loadAnimateAtlas(atlas, json.image);
			}
			catch(e:Dynamic)
			{
				Log.warn('Could not load atlas ${json.image}: $e');
			}
		}
		#end

		imageFile = json.image;
		jsonScale = json.scale;
		if(json.scale != 1) {
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
		if(animationsArray != null && animationsArray.length > 0) {
			for (anim in animationsArray) {
				var animAnim:String = '' + anim.anim;
				var animName:String = '' + anim.name;
				var animFps:Int = anim.fps;
				var animLoop:Bool = !!anim.loop; //Bruh
				var animIndices:Array<Int> = anim.indices;

				if(!isAnimateAtlas)
				{
					if(animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);
				}
				#if flxanimate
				else
				{
					if(animIndices != null && animIndices.length > 0)
						atlas.anim.addBySymbolIndices(animAnim, animName, animIndices, animFps, animLoop);
					else
						atlas.anim.addBySymbol(animAnim, animName, animFps, animLoop);
				}
				#end

				if(anim.offsets != null && anim.offsets.length > 1) addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				else addOffset(anim.anim, 0, 0);
			}
		}
		#if flxanimate
		if(isAnimateAtlas) copyAtlasValues();
		#end
		//trace('Loaded file to character ' + curCharacter);
	}

	override function update(elapsed:Float)
	{
		if(isAnimateAtlas) atlas.update(elapsed);

		if(debugMode || (!isAnimateAtlas && animation.curAnim == null) || (isAnimateAtlas && atlas.anim.curSymbol == null))
		{
			super.update(elapsed);
			return;
		}

		if(heyTimer > 0)
		{
			var rate:Float = (PlayState.instance != null ? PlayState.instance.playbackRate : 1.0);
			heyTimer -= elapsed * rate;
			if(heyTimer <= 0)
			{
				var anim:String = getAnimationName();
				if(specialAnim && (anim == 'hey' || anim == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if(specialAnim && isAnimationFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimationName().endsWith('miss') && isAnimationFinished())
		{
			dance();
			finishAnimation();
		}

		switch(curCharacter)
		{
			case 'pico-speaker':
				if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
				{
					var noteData:Int = 1;
					if(animationNotes[0][1] > 2) noteData = 3;

					noteData += FlxG.random.int(0, 1);
					playAnim('shoot' + noteData, true);
					animationNotes.shift();
				}
				if(isAnimationFinished()) playAnim(getAnimationName(), false, false, animation.curAnim.frames.length - 3);
		}

		if (getAnimationName().startsWith('sing')) holdTimer += elapsed;
		else if(isPlayer) holdTimer = 0;

		if (!isPlayer && holdTimer >= Conductor.stepCrochet * (0.0011 #if FLX_PITCH / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1) #end) * singDuration)
		{
			dance();
			holdTimer = 0;
		}

		var name:String = getAnimationName();
		if(isAnimationFinished() && animOffsets.exists('$name-loop'))
			playAnim('$name-loop');

		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
				ghost.update(elapsed);
		}

		super.update(elapsed);
	}

	inline public function isAnimationNull():Bool
		return !isAnimateAtlas ? (animation.curAnim == null) : (atlas.anim.curSymbol == null);

	inline public function getAnimationName():String
	{
		var name:String = '';
		@:privateAccess
		if(!isAnimationNull()) name = !isAnimateAtlas ? animation.curAnim.name : atlas.anim.lastPlayedAnim;
		return (name != null) ? name : '';
	}

	public function isAnimationFinished():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.finished : atlas.anim.finished;
	}

	public function finishAnimation():Void
	{
		if(isAnimationNull()) return;

		if(!isAnimateAtlas) animation.curAnim.finish();
		else atlas.anim.curFrame = atlas.anim.length - 1;
	}

	public var animPaused(get, set):Bool;
	private function get_animPaused():Bool
	{
		if(isAnimationNull()) return false;
		return !isAnimateAtlas ? animation.curAnim.paused : atlas.anim.isPlaying;
	}
	private function set_animPaused(value:Bool):Bool
	{
		if(isAnimationNull()) return value;
		if(!isAnimateAtlas) animation.curAnim.paused = value;
		else
		{
			if(value) atlas.anim.pause();
			else atlas.anim.resume();
		} 

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
			if(danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if(animOffsets.exists('idle' + idleSuffix)) {
					playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;
		if(!isAnimateAtlas) animation.play(AnimName, Force, Reversed, Frame);
		else atlas.anim.play(AnimName, Force, Reversed, Frame);

		if (animOffsets.exists(AnimName))
		{
			var daOffset = animOffsets.get(AnimName);
			offset.set(daOffset[0], daOffset[1]);
		}
		//else offset.set(0, 0);

		if (curCharacter.startsWith('gf-') || curCharacter == 'gf')
		{
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
			for (section in noteData) {
				for (songNotes in section.sectionNotes) {
					animationNotes.push(songNotes);
				}
			}
			TankmenBG.animationNotes = animationNotes;
			animationNotes.sort(sortAnims);
		}
		catch(e:Dynamic) {}
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;
	private var settingCharacterUp:Bool = true;
	public function recalculateDanceIdle() {
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animOffsets.exists('danceLeft' + idleSuffix) && animOffsets.exists('danceRight' + idleSuffix));

		if(settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if(lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if(danceIdle)
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
		animation.addByPrefix(name, anim, 24, false);
	}

	// Atlas support
	// special thanks ne_eo for the references, you're the goat!!
	public var isAnimateAtlas:Bool = false;
	#if flxanimate
	public var atlas:FlxAnimate;
	public override function draw()
	{
		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
			{
				if (ghost.visible) ghost.draw();
			}
		}

		if(isAnimateAtlas)
		{
			copyAtlasValues();
			atlas.draw();
			return;
		}
		super.draw();
	}

	public function copyAtlasValues()
	{
		@:privateAccess
		{
			atlas.cameras = cameras;
			atlas.scrollFactor = scrollFactor;
			atlas.scale = scale;
			atlas.offset = offset;
			atlas.origin = origin;
			atlas.x = x;
			atlas.y = y;
			atlas.angle = angle;
			atlas.alpha = alpha;
			atlas.visible = visible;
			atlas.flipX = flipX;
			atlas.flipY = flipY;
			atlas.shader = shader;
			atlas.antialiasing = antialiasing;
			atlas.colorTransform = colorTransform;
			atlas.color = color;
		}
	}
	#end

	public function playGhostAnim(ghostID = 0, animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		var ghost:FlxSprite = new FlxSprite();
		ghost.scale.copyFrom(scale);
		ghost.frames = frames;
		ghost.animation.copyFrom(animation);
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

		if (animOffsets.exists(animName))
		{
			var daOffset = animOffsets.get(animName);
			ghost.offset.set(daOffset[0], daOffset[1]);
		}

		final direction:String = animName.substring(4).split('-')[0];

		inline function resolveDir(xDir:Bool = false):Float
		{
			var output:Float = 0;
			switch (direction)
			{
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

		var twn:FlxTween = FlxTween.tween(ghost, {alpha: 0, x: moveX, y: moveY}, 0.75,
		{
			onComplete: (completedTween) ->
			{
				var idx = doubleGhosts.indexOf(ghost);
				if (idx >= 0)
				{
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

	public static function xmlToJsonString(xmlText:String):String {
	    var find = (tag:String, txt:String) -> {
	        var reTag = new EReg("<" + tag + ">([\\s\\S]*?)<\\/" + tag + ">", "i");
	        if (reTag.match(txt)) return reTag.matched(1);
	        var reAttr = new EReg(tag + '\\s*=\\s*"([^"]+)"', 'i');
	        if (reAttr.match(txt)) return reAttr.matched(1);
	        var reAttr2 = new EReg(tag + "\\s*=\\s*'([^']+)'", 'i');
	        if (reAttr2.match(txt)) return reAttr2.matched(1);
	        return null;
	    };

	    var esc = (s:String) -> if (s == null) "" else StringTools.replace(s, "\"", "\\\"");

	    var image = null;
	    if (find('sprite', xmlText) != null) image = find('sprite', xmlText);
	    else if (find('image', xmlText) != null) image = find('image', xmlText);
	    else image = '';

	    var scale = find('scale', xmlText);
	    var posx = find('x', xmlText);
	    var posy = find('y', xmlText);
	    var camx = find('camx', xmlText);
	    var camy = find('camy', xmlText);
	    var icon = find('icon', xmlText) != null ? find('icon', xmlText) : find('healthicon', xmlText);
	    var holdTime = find('hold', xmlText) != null ? find('hold', xmlText) : find('holdtime', xmlText);
	    var flipX = find('flip_x', xmlText);
	    var antialiasing = find('antialiasing', xmlText);
	    var healthbar = find('healthbar', xmlText);
	    var vocals = find('vocals', xmlText) != null ? find('vocals', xmlText) : find('vocals_file', xmlText);
	    var editorPlayer = find('_editor_isPlayer', xmlText);

	    var hcolors:Array<Int> = null;
	    if (healthbar != null) {
	        var parts = StringTools.replace(healthbar, " ", "").split(',');
	        if (parts.length >= 3) {
	            try {
	                hcolors = [ Std.parseInt(parts[0]), Std.parseInt(parts[1]), Std.parseInt(parts[2]) ];
	            } catch (e:Dynamic) {
	                hcolors = null;
	            }
	        }
	    }

	    var obj = new StringBuf();
	    obj.add("{");
	    obj.add('\"image\":\"characters/' + esc(image) + '\"');

	    if (scale != null) {
	        obj.add(',\"scale\":' + scale);
	    } else {
			obj.add(',\"scale\":1');
		}

	    if (posx != null || posy != null) {
	        var px = posx != null ? posx : "0";
	        var py = posy != null ? posy : "0";
	        obj.add(',\"position\":[' + px + ',' + py + ']');
	    } else {
			obj.add(',\"position\":[0,0]');
		}

	    if (camx != null || camy != null) {
	        var cx = camx != null ? camx : "0";
	        var cy = camy != null ? camy : "0";
	        obj.add(',\"camera_position\":[' + cx + ',' + cy + ']');
	    } else {
			obj.add(',\"camera_position\":[0,0]');
		}

	    if (icon != null) {
	        obj.add(',\"healthicon\":\"' + esc(icon) + '\"');
	    } else {
			obj.add(',\"healthicon\":\"face\"');
		}

	    if (holdTime != null) {
	        obj.add(',\"sing_duration\":' + holdTime);
	    } else {
			obj.add(',\"sing_duration\":4');
		}

	    if (flipX != null) {
	        var flipVal = (StringTools.ltrim(flipX).toLowerCase() == "true" || flipX == "1") ? "true" : "false";
	        obj.add(',\"flip_x\":' + flipVal);
	    } else {
			obj.add(',\"flip_x\":false');
		}

	    if (antialiasing != null) {
	        var aaVal = (StringTools.ltrim(antialiasing).toLowerCase() == "true" || antialiasing == "1") ? "false" : "true";
	        obj.add(',\"no_antialiasing\":' + aaVal);
	    } else {
			obj.add(',\"no_antialiasing\": false');
		}

	    if (hcolors != null) {
	        obj.add(',\"healthbar_colors\":[' + hcolors[0] + ',' + hcolors[1] + ',' + hcolors[2] + ']');
	    } else {
			obj.add(',\"healthbar_colors\":[0,0,0]');
		}

	    if (vocals != null) obj.add(',\"vocals_file\":\"' + esc(vocals) + '\"');
	    else obj.add(',\"vocals_file\":\"\"');

	    if (editorPlayer != null) {
	        var edVal = (StringTools.ltrim(editorPlayer).toLowerCase() == "true" || editorPlayer == "1") ? "true" : "false";
	        obj.add(',\"_editor_isPlayer\":' + edVal);
	    } else {
	        obj.add(',\"_editor_isPlayer\":false');
	    }
		var animsArr = new Array<String>();

		var animBlock = find("animations", xmlText);
		var scanText = if (animBlock != null) animBlock else xmlText;

		var idx = 0;
		while (true) {
	    	var start = scanText.indexOf("<anim", idx);
	    	if (start == -1) break;

	    	var openEnd = scanText.indexOf(">", start);
	    	if (openEnd == -1) break;

	    	var openTag = scanText.substring(start, openEnd + 1);
	    	var closeTagIdx = -1;
	    	var contentInside = "";
	    	if (!StringTools.endsWith(openTag, "/>")) {
	    	    var closeTag = "</anim>";
	    	    var searchFrom = openEnd + 1;
	    	    closeTagIdx = scanText.indexOf(closeTag, searchFrom);
	    	    if (closeTagIdx != -1) {
	    	        contentInside = scanText.substring(searchFrom, closeTagIdx);
	    	        idx = closeTagIdx + closeTag.length;
	    	    } else {
	    	        idx = openEnd + 1;
	    	    }
			} else {
	    	    idx = openEnd + 1;
	    	}

	    	var getAttr = (tag:String, attr:String) -> {
	    	    var re = new EReg(attr + '\\s*=\\s*"(.*?)"', 'i');
	    	    if (re.match(tag)) return re.matched(1);
	    	    var re2 = new EReg(attr + "\\s*=\\s*'(.*?)'", 'i');
	    	    if (re2.match(tag)) return re2.matched(1);
	    	    return null;
	    	};

	    	var nameAttr    = getAttr(openTag, "anim");
	    	var animAttr    = getAttr(openTag, "name");
	    	var loopAttr    = getAttr(openTag, "loop");
	    	var fpsAttr     = getAttr(openTag, "fps");
	    	var xAttr       = getAttr(openTag, "x");
	    	var yAttr       = getAttr(openTag, "y");
	    	var indicesAttr = getAttr(openTag, "indices");

	    	if ((indicesAttr == null || indicesAttr == "") && contentInside != null && contentInside != "") {
	    	    var inner = StringTools.trim(contentInside);
	    	    var digitsRe = new EReg("^[0-9,\\s\\-]+$", "");
	    	    if (inner != "" && digitsRe.match(inner)) {
	    	        indicesAttr = inner;
	    	    }
	    	}

	    	var esc = (s:String) -> if (s == null) "" else StringTools.replace(s, "\"", "\\\"");

	    	var animObj = new StringBuf();
	    	animObj.add("{");
	    	animObj.add('"name":"' + esc(nameAttr) + '",');
	    	animObj.add('"anim":"' + esc(animAttr) + '"');

	    	if (loopAttr != null) animObj.add(',"loop":' + (loopAttr.toLowerCase() == "true" ? "true" : "false"));
			else animObj.add(',"loop":false');
	    	if (fpsAttr != null && fpsAttr != "") animObj.add(',"fps":' + fpsAttr);
			else animObj.add(',"fps":24');

	    	if (xAttr != null || yAttr != null) {
	    	    var ox = if (xAttr != null && xAttr != "") xAttr else "0";
	    	    var oy = if (yAttr != null && yAttr != "") yAttr else "0";
	    	    animObj.add(',"offsets":[' + ox + ',' + oy + ']');
	    	} else {
				animObj.add(',"offsets":[0,0]');
			}

	    	if (indicesAttr != null && indicesAttr != "") {
	    	    var norm:String = StringTools.replace(indicesAttr, "\"", "");
	    	    norm = StringTools.replace(norm, "'", "");
	    	    norm = StringTools.trim(norm);
				if(norm.contains("..")){
					var temp = CoolUtil.expandRange(norm);
					norm = temp.join(",");
				}
	    	    animObj.add(',"indices":[' + norm + ']');
	    	} else {
				animObj.add(',"indices":[]');
			}

	    	animObj.add("}");
	    	animsArr.push(animObj.toString());
		}

		obj.add(',"animations":[' + animsArr.join(",") + ']');

	    obj.add("}");
	    return obj.toString();
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
		destroyAtlas();
	}

	public function destroyAtlas()
	{
		if (atlas != null)
			atlas = FlxDestroyUtil.destroy(atlas);
	}
}