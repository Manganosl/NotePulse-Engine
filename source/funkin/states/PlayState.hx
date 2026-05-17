package funkin.states;

import funkin.objects.notes.StrumNote.KeybindShowcase;
import funkin.backend.ExtraKeysHandler;
import funkin.data.Highscore;
import funkin.data.StageData;
import funkin.data.WeekData;
import funkin.data.Song;
import funkin.data.Section;
import funkin.game.Rating;
import lime.app.Application;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import funkin.objects.FunkinVideoSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

import funkin.game.cutscenes.DialogueBoxPsych;

import funkin.states.menus.StoryMenuState;
import funkin.states.editors.ChartingState;
import funkin.states.editors.CharacterEditorState;
import funkin.states.editors.ModchartEditor;
import funkin.states.scripted.ScriptedSubstate;

import funkin.substates.PauseSubState;
import funkin.substates.GameOverSubstate;

import funkin.scripting.objects.ModchartSprite.ModchartBackdrop;

import hxvlc.flixel.*;

import funkin.objects.notes.splashes.*;
import funkin.objects.notes.Note.EventNote;
import funkin.objects.notes.*;
import funkin.objects.*;

#if LUA_ALLOWED
import funkin.scripting.lua.*;
import funkin.scripting.*;
import funkin.scripting.objects.*;
#else
import funkin.scripting.LuaUtils;
import funkin.scripting.HScript;
#end

#if HSCRIPT_ALLOWED
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
#end

import funkin.game.modchart.*;

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public var modManager:ModManager;

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['L', 0.2], //From 0% to 19%
		['F', 0.4], //From 20% to 39%
		['D', 0.5], //From 40% to 49%
		['C', 0.6], //From 50% to 59%
		['B', 0.69], //From 60% to 68%
		['B+', 0.7], //69%
		['A', 0.8], //From 70% to 79%
		['A+', 0.9], //From 80% to 89%
		['S', 1], //From 90% to 99%
		['PFC', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	public var judgementCounter:FlxText;

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartBackdrops:Map<String, ModchartBackdrop> = new Map<String, ModchartBackdrop>();
	public var changeStrumAnimTimers:Map<Int, FlxTimer> = new Map<Int, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartNdlls:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var modchartCharacters:Map<String, Character> = new Map<String, Character>();
	#end

	public var baseHUDZoom:Float = 1;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;
	public static var curSShit:Float = 1;
	public static var curBShit:Float = 1;

	public var sickCount:Int = 0;
	public var marvCount:Int = 0;

	var noteRows:Array<Array<Array<Note>>> = [];

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public static var notesLength:Int = 0;
	public static var unspawnNotesLength:Int = 0;

	public var camFollow:FlxObject;

	public var camHitEnabled:Bool = true;
	public var camHitTarget:String = 'gf';
	public var camHitForcedX:Bool = false;
	public var camHitForcedY:Bool = false;
	public var camHitCurrentXTarget:String = 'gf';
	public var camHitCurrentYTarget:String = 'gf';
	public var camHitBothStyle:Int = 0;

	public var camHitDadOfs:Int = 20;
	public var camHitBfOfs:Int = 20;
	public var camHitGfOfs:Int = 20;

	public var camFollowBaseX:Float = 0;
	public var camFollowBaseY:Float = 0;

	public var camHitXExtra:Float = 0;
	public var camHitYExtra:Float = 0;

	var camHitLastMoveX:Float = 0;
	var camHitLastMoveY:Float = 0;

	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:PlayField;
	public var playerStrums:PlayField;
	public var gfStrums:PlayField;
	public var extraStrums:Array<PlayField> = [];

	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var grpSustainSplashes:FlxTypedGroup<SustainSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	private var healthLerp:Float = 1;
	public var combo:Int = 0;
	public static var isPlayerOpponent:Bool = false;
	public var camTween:FlxTween;
	var cameraZoomTween:FlxTween;

	public var healthBar:Bar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	public var noteMs:Array<Float> = [];
    public var noteTime:Array<Float> = [];

	var rsCheck:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var currentUsedZoom(default, set):String = "default";
	public var currentCamZoom:Float = 1.05;

	public var useBFZoom:Bool = false;
	public var useDadZoom:Bool = false;
	public var useGFZoom:Bool = false;

	public var defaultCamZoom(default, set):Float = 1.05;
	public var bfCamZoom(default, set):Float = 1.05;
	public var dadCamZoom(default, set):Float = 1.05;
	public var gfCamZoom(default, set):Float = 1.05;

	private var initialCrochet:Float = 0;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;
	public var realSongLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	public var comboGroup:FlxSpriteGroup;
	public var uiGroup:FlxSpriteGroup;
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	private var modManagerEvArray:Array<Dynamic> = []; // LEAVING HERE FOR NOW

	//// Sets ////

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		return health;
	}

	private function set_currentUsedZoom(value:String):String {
		currentUsedZoom = value;
		switch (currentUsedZoom) {
			case "default":
				currentCamZoom = defaultCamZoom;
			case "bf":
				currentCamZoom = bfCamZoom;
			case "dad":
				currentCamZoom = dadCamZoom;
			case "gf":
				currentCamZoom = gfCamZoom;
			default:
				currentCamZoom = defaultCamZoom;
		}
		return currentUsedZoom;
	}

	private function set_defaultCamZoom(value:Float):Float {
		defaultCamZoom = value;
		if(currentUsedZoom == "default")
			currentCamZoom = defaultCamZoom;
		return value;
	}

	private function set_bfCamZoom(value:Float):Float {
		bfCamZoom = value;
		if(currentUsedZoom == "bf" || (currentUsedZoom == "default" && useBFZoom))
			currentCamZoom = bfCamZoom;
		return value;
	}

	private function set_dadCamZoom(value:Float):Float {
		dadCamZoom = value;
		if(currentUsedZoom == "dad" || (currentUsedZoom == "default" && useDadZoom))
			currentCamZoom = dadCamZoom;
		return value;
	}

	private function set_gfCamZoom(value:Float):Float {
		gfCamZoom = value;
		if(currentUsedZoom == "gf" || (currentUsedZoom == "default" && useGFZoom))
			currentCamZoom = gfCamZoom;
		return value;
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				//for (note in notes.members) note.resizeByRatio(ratio);
				//for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				//for (note in notes.members) note.resizeByRatio(ratio);
				//for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	//// Overrides ////

	override public function create()
	{
		Paths.clearStoredMemory();

		startCallback = startCountdown;
		endCallback = endSong;

		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = [];
		for (i in 0...SONG.mania + 1){
			keysArray.push(SONG.mania + '_key_$i');
		}

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpSustainSplashes = new FlxTypedGroup<SustainSplash>();

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		Application.current.window.title = (chartingMode ? "* " : "") + 
		"NotePulse Engine | " + SONG.song + " - " + Difficulty.getString() + 
		" [x" + playbackRate + "]" + 
		(isPlayerOpponent ? " - Playing as Opponent" : "");

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		if(stageData.useBFZoom != null) useBFZoom = stageData.useBFZoom;
		if(stageData.useDadZoom != null) useDadZoom = stageData.useDadZoom;
		if(stageData.useGFZoom != null) useGFZoom = stageData.useGFZoom;

		defaultCamZoom = stageData.defaultZoom;
		if(useBFZoom && stageData.bfCamZoom != null)
			bfCamZoom = stageData.bfCamZoom;
		if(useDadZoom && stageData.dadCamZoom != null)
			dadCamZoom = stageData.dadCamZoom;
		if(useGFZoom && stageData.gfCamZoom != null)
			gfCamZoom = stageData.gfCamZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		noteMs = [];
		noteTime = [];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': new funkin.states.stages.StageWeek1(); //Week 1
			case 'spooky': new funkin.states.stages.Spooky(); //Week 2
			case 'philly': new funkin.states.stages.Philly(); //Week 3
			case 'limo': new funkin.states.stages.Limo(); //Week 4
			case 'mall': new funkin.states.stages.Mall(); //Week 5 - Cocoa, Eggnog
			case 'mallEvil': new funkin.states.stages.MallEvil(); //Week 5 - Winter Horrorland
			case 'school': new funkin.states.stages.School(); //Week 6 - Senpai, Roses
			case 'schoolEvil': new funkin.states.stages.SchoolEvil(); //Week 6 - Thorns
			case 'tank': new funkin.states.stages.Tank(); //Week 7 - Ugh, Guns, Stress
			case 'phillyStreets': new funkin.states.stages.PhillyStreets(); //Weekend 1 - Darnell, Lit up, 2Hot
			case 'phillyBlazin': new funkin.states.stages.PhillyBlazin(); //Weekend 1 - Blazin'
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		}
		else
		{
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}

		// "GLOBAL" SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		comboGroup = new FlxSpriteGroup();
		add(comboGroup);
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(noteGroup);
		uiGroup = new FlxSpriteGroup();

		if(ClientPrefs.data.judgecounter){
			judgementCounter = new FlxText(20, 0, 0, "", 18);
			judgementCounter.setFormat(Paths.font("vcr.ttf"), 18, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			judgementCounter.borderSize = 1;
			judgementCounter.borderQuality = 2;
			judgementCounter.scrollFactor.set();
			judgementCounter.cameras = [camHUD];
			judgementCounter.screenCenter(Y);
			judgementCounter.visible = ClientPrefs.data.judgecounter;
			uiGroup.add(judgementCounter);
		}

		Conductor.songPosition = -5000 / Conductor.songPosition;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001;

		opponentStrums = new PlayField();
		noteGroup.add(opponentStrums);
		playerStrums = new PlayField();
		noteGroup.add(playerStrums);
		if(SONG.lanes >= 3){
			gfStrums = new PlayField();
			for(lane in 0...(SONG.lanes-3)){
				extraStrums[lane] = new PlayField();
				noteGroup.add(extraStrums[lane]);
			}
		}

		generateSong(SONG.song);

		noteGroup.add(grpNoteSplashes);
		noteGroup.add(grpSustainSplashes);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = currentCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

			healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function(){
				healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
				return healthLerp;
			}, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		updateScore(false);
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll)
			botplayTxt.y = timeBar.y - 78;

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		if(ClientPrefs.data.ratingCam == "HUD" || ClientPrefs.data.ratingCam == "Bellow Note")
			comboGroup.cameras = [camHUD];
		else
			comboGroup.cameras = [camGame];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end

		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(CoolUtil.sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
			
		#end

		callOnScripts('preInitModchart');

		modManager = new ModManager(this);
		modManager.receptors = [for(i in PlayField.fields) i.members];
		modManager.registerDefaultModifiers();
		modManager.registerScriptedModifiers();
		for(func in modManagerEvArray) func();
		callOnScripts('initModchart');

		add(uiGroup);

		startCallback();
		RecalculateRating();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		setOnScripts('mania', SONG.mania);
		setOnScripts("isPlayerOpponent", isPlayerOpponent);
		
		stagesFunc(function(stage:BaseStage) stage.createPost());

		callOnScripts('onCreatePost');
		callOnScripts('postCreate');
		notesLength = notes.length;
		unspawnNotesLength = unspawnNotes.length;

		cacheCountdown();
		cachePopUpScore();

		super.create();
		Paths.clearUnusedMemory();

		if (songName != 'tutorial')
			camZooming = true;

		if(eventNotes.length < 1) checkEventNote();
	}

	override public function update(elapsed:Float)
	{
		if(!inCutscene && !paused && !freezeCamera)
			FlxG.camera.followLerp = 2.4 * cameraSpeed * playbackRate;
		else 
			FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
			}
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1') && ClientPrefs.data.devMode)
				openChartEditor();
			else if (controls.justPressed('debug_2') && ClientPrefs.data.devMode)
				openCharacterEditor();
			else if (FlxG.keys.justPressed.NINE && ClientPrefs.data.devMode)
				openModchartEditor();

		}

		if (healthBar.bounds.max != null && health > healthBar.bounds.max)
			health = healthBar.bounds.max;

		if (healthBar.bounds.min != null && health < healthBar.bounds.min)
			health = healthBar.bounds.min;

		updateIconsScale(elapsed);
		updateIconsPosition();

		if (startedCountdown && !paused)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(currentCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(baseHUDZoom, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
		}
		doDeathCheck();
		modManager.updateTimeline(curDecStep);
		modManager.update(elapsed);

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);
				notesLength = notes.length;
				unspawnNotesLength = unspawnNotes.length;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		for(field in PlayField.fields){
			field.forEachAlive(function(strum:StrumNote)
			{
				if(strum.alpha == 0 || strum.visible == false) return;

				var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, field.player, strum, [], strum.vec3Cache);
				modManager.updateObject(curDecBeat, strum, pos, field.player);
				strum.modPos.x = pos.x;
				strum.modPos.y = pos.y;
				strum.z = pos.z;
			});
		}
		strumLineNotes.sort(sortByOrderStrumNote);

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled)
					keysCheck();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.sort(sortByOrderNote);
						notes.forEachAlive(function(daNote:Note)
						{
							for(copy in daNote.copyingNotes)
								noteFollowStrum(copy);
							noteFollowStrum(daNote);

							if(!daNote.strum.cpuControlled)
							{
								if(daNote.strum.noteHitCallback != null && cpuControlled && !daNote.blockHit && daNote.strum.inControl && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition)){
									daNote.strum.noteHitCallback(daNote);
									notesLength = notes.length;
									unspawnNotesLength = unspawnNotes.length;
								}
							}
							else if (daNote.strum.noteHitCallback != null && daNote.wasGoodHit && !daNote.hitByOpponent && daNote.strum.inControl && !daNote.ignoreNote){
								daNote.strum.noteHitCallback(daNote);
								notesLength = notes.length;
								unspawnNotesLength = unspawnNotes.length;
							}

							if (daNote.isSustainNote && daNote.wasGoodHit && !daNote.strum.sustainSplash.updatedThisFrame) {
								if (daNote.isSustainEnd) {
									if(!cpuControlled && !daNote.strum.cpuControlled) daNote.strum.sustainSplash.hide(false);
								} else {
									daNote.strum.sustainSplash.show(daNote);
								}
							}

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.strum.noteMissCallback != null && !daNote.strum.cpuControlled && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									daNote.strum.noteMissCallback(daNote);

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		if (camHitEnabled && !isCameraOnForcedPos) {
			updateNoteHitCam();
		}
		curSShit = curStep;
		curBShit = curBeat;
		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);

		callOnScripts('onUpdatePost', [elapsed]);
	}

	public static function sortByOrderNote(wat:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	public static function sortByOrderStrumNote(wat:Int, Obj1:StrumNote, Obj2:StrumNote):Int
	{
		return FlxSort.byValues(FlxSort.DESCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	override function destroy() {
		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy', []);
				script.stop();
				script = null;
			}

		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		stagesFunc(function(stage:BaseStage) stage.destroy());

		if(vocals != null) vocals.stop();
		if(opponentVocals != null) opponentVocals.stop();

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.camera.setFilters([]);
		FlxG.animationTimeScale = 1;
		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		Note.globalRgbShaders = [];
		funkin.backend.NoteTypesConfig.clearNoteTypesData();
		instance = null;
		super.destroy();
	}

	//// Start | Countdown ////

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
        if (vocals != null && !vocals.playing) vocals.resume();
        if (opponentVocals != null && !opponentVocals.playing) opponentVocals.resume();

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		realSongLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private function generateSong(dataPath:String):Void {
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

        vocals = new FlxSound();
        opponentVocals = new FlxSound();
        try
        {
            if (songData.needsVoices)
            {
                var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
                var loadedPlayerVocals = (playerVocals != null && playerVocals.length > 0) ? playerVocals : Paths.voices(songData.song);
                if (loadedPlayerVocals != null)
                {
                    vocals.loadEmbedded(loadedPlayerVocals);
                    FlxG.sound.list.add(vocals);
                    vocals.persist = vocals.looped = true;
                    vocals.volume = 0.8;
                    vocals.play();
                    vocals.pause();
                }

                var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
                if (oppVocals != null && oppVocals.length > 0)
                {
                    opponentVocals.loadEmbedded(oppVocals);
                    FlxG.sound.list.add(opponentVocals);
                    opponentVocals.persist = opponentVocals.looped = true;
                    opponentVocals.volume = 0.8;
                    opponentVocals.play();
                    opponentVocals.pause();
                }
            }
        }
        catch (e:Dynamic) {}
 
        #if FLX_PITCH
        vocals.pitch = playbackRate;
        opponentVocals.pitch = playbackRate;
        #end

		inst = new FlxSound();
		try {
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch(e:Dynamic) {}
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName, false).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		while(noteRows.length != PlayField.fields.length)
			noteRows.push([]);

		initialCrochet = Conductor.crochet;
		var holdCrochet:Float = Math.max(Conductor.stepCrochet / PlayState.SONG.holdSubdivisions, 10);

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % (SONG.mania + 1));

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, this);
				swagNote.row = Conductor.secsToRow(daStrumTime);
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<(SONG.mania + 1)));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				final fieldID:Int = songNotes[4];
				swagNote.mustPress = (fieldID == 0 ? false : (fieldID == 1 ? true : false));
				swagNote.playField = PlayField.fields[fieldID];
				swagNote.gfStrum = (songNotes[4] == 2 ? true : false);
				if(swagNote.gfStrum) swagNote.mustPress = false;
				swagNote.characters = (fieldID == 0 ? [dad] : (fieldID == 1 ? [boyfriend] : [gf]));
				if(swagNote.gfNote) swagNote.characters = [gf];

				swagNote.scrollFactor.set();

				var rowArray = noteRows[fieldID];
				if (rowArray[swagNote.row] == null) rowArray[swagNote.row] = [];
				rowArray[swagNote.row].push(swagNote);
				unspawnNotes.push(swagNote);

				final susLength = (swagNote.sustainLength / holdCrochet);
				final floorSus:Int = Math.floor(susLength);

				if(floorSus > 0) {
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (holdCrochet * susNote), daNoteData, oldNote, true, false, this);
						sustainNote.sustainLength = holdCrochet;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.characters = swagNote.characters;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.gfStrum = swagNote.gfStrum;
						sustainNote.parent = swagNote;
						sustainNote.playField = swagNote.playField;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2;
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypes.contains(swagNote.noteType)) {
					noteTypes.push(swagNote.noteType);
				}
			}
		}
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(CoolUtil.sortByTime);
		generatedMusic = true;
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			for(i in 0...SONG.lanes)
				generateStaticArrows(i);
			for(i in 0...playerStrums.length){
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for(i in 0...opponentStrums.length){
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}
			if(gfStrums != null){
				for(i in 0...gfStrums.length){
					gfStrums.members[i].x = (opponentStrums.members[i].x + playerStrums.members[i].x) / 2;
					setOnScripts('defaultGfStrumX' + i, gfStrums.members[i].x);
					setOnScripts('defaultGfStrumY' + i, gfStrums.members[i].y);
				}
				for(strums in extraStrums){
					for(i in 0...strums.length){
						strums.members[i].x = gfStrums.members[i].x;
					}
				}
			}
			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.data.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.data.middleScroll && !note.mustPress)
							note.alpha *= 0.35;
					}
				});

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	//// Bars ////

    public function setSongTime(time:Float)
    {
        // Pause music while we reposition
        FlxG.sound.music.pause();

        // Set music time (account for Conductor offset) and restart
        FlxG.sound.music.time = time - Conductor.offset;
        #if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
        FlxG.sound.music.play();

        // Sync vocals by setting their playback position only. If they should be audible, resume them
        if (vocals != null)
        {
            if (vocals.length > FlxG.sound.music.time)
            {
                vocals.time = FlxG.sound.music.time;
                #if FLX_PITCH vocals.pitch = playbackRate; #end
                if (!vocals.playing) vocals.resume();
            }
            else
                vocals.pause();
        }

        if (opponentVocals != null)
        {
            if (opponentVocals.length > FlxG.sound.music.time)
            {
                opponentVocals.time = FlxG.sound.music.time;
                #if FLX_PITCH opponentVocals.pitch = playbackRate; #end
                if (!opponentVocals.playing) opponentVocals.resume();
            }
            else
                opponentVocals.pause();
        }

        Conductor.songPosition = time;
    }

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	//// Icons ////

	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	public dynamic function updateIconsPosition()
	{
		var iconOffset:Int = 26;
		iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
	}

	//// Video ////

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		final fileName = Paths.video(name);
		
		if (Paths.exists(fileName, BINARY))
		{
			inCutscene = true;
			var bg = new flixel.system.FlxBGSprite();
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);
			
			var vid = new FlxVideo();
			FlxG.addChildBelowMouse(vid);
			vid.onEndReached.add(() -> {
				remove(bg);
				startAndEnd();
				
				FlxG.removeChild(vid);
				vid.dispose();
			});
			vid.load(fileName);
			vid.play();
			return;
		}
		else startAndEnd();
		#else
		startAndEnd();
		#end
	}

	//// Events ////

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound

			case "Modchart Event":
				var info = event.value1.split(',');
				final daBeat:Float = Conductor.getBeat(event.strumTime);
				var ease = FlxEase.linear;
				if(info[4] != null) ease = LuaUtils.getTweenEaseByString(info[4]);
				switch(info[0]){
					case "Ease": 
						modManagerEvArray.push(function(){ modManager.ease(info[1], daBeat, Std.parseFloat(info[2]), Std.parseFloat(info[3]), ease, Std.parseInt(info[5]), Std.parseInt(info[6])); });
					case "Set": 
						modManagerEvArray.push(function(){ modManager.set(info[1], daBeat, Std.parseFloat(info[3]), Std.parseInt(info[5]), Std.parseInt(info[6])); });
				}
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != LuaUtils.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case "HScript Call":
				var args:Array<Dynamic> = [];
				if(value2 != null && value2 != '') {
					args = value2.split(',');
				}
				try {
					for (hscript in hscriptArray) {
						hscript.call(value1, args);

						if (hscript.variables.exists(value1)) {
							var func = hscript.variables.get(value1);
							if (func != null && Reflect.isFunction(func))
								Reflect.callMethod(null, func, args);
						}
					}

					if (HScript.staticVariables.exists(value1)) {
						var func = HScript.staticVariables.get(value1);
						if (func != null && Reflect.isFunction(func))
							Reflect.callMethod(null, func, args);
					}
				} catch(e) {
					addTextToDebug('ERROR on HScript Call event: ${e.toString()}', FlxColor.RED, false);
					Log.error('HScript Call event: ${e.toString().split(": ").slice(1).join(": ")}');
				}
			/*case 'Change Mania':
				var parsed = Std.parseInt(value1);
				if (Math.isNaN(parsed)) {
					Log.error('Change Mania event: value1 not a number => "' + value1 + '"');
					return;
				}

				var newMania:Int = parsed - 1;

				if (ExtraKeysHandler.instance != null && ExtraKeysHandler.instance.data != null) {
					var minMania = ExtraKeysHandler.instance.data.minKeys - 1;
					var maxMania = ExtraKeysHandler.instance.data.maxKeys - 1;
					if (newMania < minMania) newMania = minMania;
					if (newMania > maxMania) newMania = maxMania;
				}

				changeMania(newMania);
				return;*/
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Camera Zoom':
				FlxTween.cancelTweensOf(FlxG.camera, ['zoom']);
				
				var val1:Float = Std.parseFloat(value1);
				if (Math.isNaN(val1)) val1 = 1;
				
				var targetZoom = val1;
				if (value2 != '')
				{
					var split = value2.split(',');
					var duration:Float = 0;
					var leEase:String = 'linear';
					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) leEase = split[1].trim();
					if (Math.isNaN(duration)) duration = 0;
					
					if (duration > 0) FlxTween.tween(FlxG.camera, {zoom: targetZoom}, duration, {ease: FlxEase.circOut});
					else FlxG.camera.zoom = targetZoom;
				}
				defaultCamZoom = targetZoom;

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}
				changeCharacter(value2, charType);

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0.01)
						songSpeed = newValue;
					else
						if(songSpeedTween != null)
						{
							songSpeedTween.cancel();
							songSpeedTween = null;
						}
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], value2);
					} else {
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);
		
			case 'Focus Camera':
				// value1 format: posX[,posY[,ofsX[,ofsY]]]
				// pos can be: bf, boyfriend, gf, dad, both, bfgf, dadgf, any number for absolute
				if (value1 != null && value1.trim() != '') {
					var parts = value1.split(',');
					var posX = parts[0];
					var posY = (parts.length > 1) ? parts[1] : '';
					var offX = (parts.length > 2) ? parts[2] : '';
					var offY = (parts.length > 3) ? parts[3] : '';

					if (posX == 'bfgf') { posX = 'both'; camHitBothStyle = 1; }
					else if (posX == 'dadgf') { posX = 'both'; camHitBothStyle = 2; }

					if (posX != '.' && posX != '' ) {
						var lower = posX.toLowerCase();
						if (lower == 'bf' || lower == 'boyfriend' || lower == 'gf' || lower == 'dad' || lower == 'both') {
							camHitCurrentXTarget = lower;
							camHitForcedX = true;
						} else {
							// numeric absolute X
							var nx = Std.parseFloat(posX);
							if (!Math.isNaN(nx)) {
								camFollow.x = nx;
								camHitCurrentXTarget = 'event';
								camHitForcedX = true;
							} else camHitForcedX = false;
						}
					} else camHitForcedX = false;

					if (posY != '.' && posY != '' ) {
						var lowerY = posY.toLowerCase();
						if (lowerY == 'bf' || lowerY == 'boyfriend' || lowerY == 'gf' || lowerY == 'dad' || lowerY == 'both') {
							camHitCurrentYTarget = lowerY;
							camHitForcedY = true;
						} else {
							var ny = Std.parseFloat(posY);
							if (!Math.isNaN(ny)) {
								camFollow.y = ny;
								camHitCurrentYTarget = 'event';
								camHitForcedY = true;
							} else camHitForcedY = false;
						}
					} else camHitForcedY = false;

					if (offX != null && offX != '') camHitXExtra = Std.parseFloat(offX);
					else camHitXExtra = 0;
					if (offY != null && offY != '') camHitYExtra = Std.parseFloat(offY);
					else camHitYExtra = 0;
				} else {
					camHitBothStyle = 0;
					camHitForcedX = false;
					camHitForcedY = false;
					camHitXExtra = 0;
					camHitYExtra = 0;
					camHitCurrentXTarget = '';
					camHitCurrentYTarget = '';
				}

			case 'Set Cam Ofs':
				var who = value1 != null ? value1.toLowerCase().trim() : 'all';
				var ofsParsed = (value2 != null && value2.trim() != '') ? Std.parseInt(value2) : 0;
				if (value2 == '0') {
					camHitLastMoveX = 0; camHitLastMoveY = 0;
				}
				switch (who) {
					case 'bf' | 'boyfriend': camHitBfOfs = ofsParsed;
					case 'dad': camHitDadOfs = ofsParsed;
					case 'gf' | 'girlfriend': camHitGfOfs = ofsParsed;
					case 'all': 
						camHitBfOfs = ofsParsed;
						camHitDadOfs = ofsParsed;
						camHitGfOfs = ofsParsed;
				}
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	//// End | Exit | Death ////

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || (!isPlayerOpponent ? (health <= 0) : (health >= 2))) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop) {
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				dad.stunned = true;
				deathCounter++;

				paused = true;

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				#if LUA_ALLOWED
				modchartTimers.clear();
				modchartTweens.clear();
				#end

				if (GameOverSubstate.deathDelay > 0)
				{
					gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_)
					{
						vocals.stop();
						opponentVocals.stop();
						FlxG.sound.music.stop();
						openSubState(new GameOverSubstate());
						gameOverTimer = null;
					});
				}
				else
				{
					vocals.stop();
					opponentVocals.stop();
					FlxG.sound.music.stop();
					openSubState(new GameOverSubstate());
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		FlxTransitionableState.skipNextTransIn = true;

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
			if (songMisses == 0) Highscore.saveFC(SONG.song, storyDifficulty);
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					FlxG.sound.playMusic(Paths.music('freakyMenu-'+ClientPrefs.data.menuMusic));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					cancelMusicFadeTween();

					MusicBeatState.switchState(new funkin.states.menus.StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					Log.info('LOADING NEXT SONG');
					Log.info(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					cancelMusicFadeTween();
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				Log.hxTrace('WENT BACK TO FREEPLAY??');
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
                    rsCheck = true;
					if(!cpuControlled) openSubState(new funkin.substates.ResultsScreen(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
					else {
						Mods.loadTopMod();
						MusicBeatState.switchState(new funkin.states.menus.FreeplayState());
						FlxG.sound.playMusic(Paths.music('freakyMenu-'+ClientPrefs.data.menuMusic), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
					}
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	//// Hits ////

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if (SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			var timeSub:Float = Conductor.songPosition - Conductor.offset;
			var syncTime:Float = 20 * playbackRate;
			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime ||
			(vocals.length > 0 && Math.abs(vocals.time - timeSub) > syncTime) ||
			(opponentVocals.length > 0 && Math.abs(opponentVocals.time - timeSub) > syncTime))
			{
				resyncVocals();
			}
		}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	//// Scripts ////

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			for (script in hscriptArray) {
				if(script.scriptName == scriptFile) {
					doPush = false;
					break;
				}
			}

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		#if LUA_ALLOWED
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(modchartCharacters.exists(tag)) return modchartCharacters.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(modchartBackdrops.exists(tag)) return modchartBackdrops.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}

	//// Menus ////

	override function openSubState(subState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(subState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished && twn != CustomFadeTransition.transitionTween) twn.active = false);

			#if VIDEOS_ALLOWED
			FunkinVideoSprite.forEachAlive((video) -> if (video.tiedToGame) video.pause());
			#end
		}

		super.openSubState(subState);
	}

	override function closeSubState()
	{
		super.closeSubState();
		
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			#if VIDEOS_ALLOWED
			FunkinVideoSprite.forEachAlive((video) -> if (video.tiedToGame) video.resume());
			#end

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if(!cpuControlled)
		{
			for(field in PlayField.fields)
				for (note in field.members)
					if(!note.cpuControlled && note.animation.curAnim != null && note.animation.curAnim.name != 'static'){
						note.playAnim('static');
						note.resetAnim = 0;
					}
		}
		if(Mods.modPack != null && Mods.modPack.pauseSubState != null && Mods.modPack.pauseSubState.length > 0){
			openSubState(new ScriptedSubstate(Mods.modPack.pauseSubState));
		} else openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		chartingMode = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	function openModchartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new ModchartEditor());
	}

	//// Characters ////
	
	public function changeCharacter(charName:String, charType:Int){
				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != charName) {
							if(!boyfriendMap.exists(charName)) {
								addCharacterToList(charName, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(charName);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != charName) {
							if(!dadMap.exists(charName)) {
								addCharacterToList(charName, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(charName);
							if(!dad.curCharacter.startsWith('gf') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != charName)
							{
								if(!gfMap.exists(charName)) {
									addCharacterToList(charName, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(charName);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();
	}

	public function getCharPosX(tag:String):Float {
		switch(tag) {
			case 'bf' | 'boyfriend':
				return boyfriend.getMidpoint().x - 150 - (boyfriend.cameraPosition[0] - boyfriendCameraOffset[0]);
			case 'gf':
				return gf != null ? (gf.getMidpoint().x + (gf.cameraPosition[0] + girlfriendCameraOffset[0])) : camFollow.x;
			case 'dad':
				return dad.getMidpoint().x + 150 + (dad.cameraPosition[0] + opponentCameraOffset[0]);
		}
		return camFollow.x;
	}

	public function getCharPosY(tag:String):Float {
		switch(tag) {
			case 'bf' | 'boyfriend':
				return boyfriend.getMidpoint().y - 100 + (boyfriend.cameraPosition[1] + boyfriendCameraOffset[1]);
			case 'gf':
				return gf != null ? (gf.getMidpoint().y + (gf.cameraPosition[1] + girlfriendCameraOffset[1])) : camFollow.y;
			case 'dad':
				return dad.getMidpoint().y - 100 + (dad.cameraPosition[1] + opponentCameraOffset[1]);
		}
		return camFollow.y;
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();

		var characters = [boyfriend, dad];
		if(modchartCharacters != null){
			for(char in characters){
				if(char != boyfriend && char != dad) characters.push(char);
			}
		}
		for(char in characters)
			if (char != null && beat % char.danceEveryNumBeats == 0 && !char.getAnimationName().startsWith('sing') && !char.stunned)
				char.dance();
	}

	//// Strums | Notes ////

	public function noteFollowStrum(daNote:Note){
		var pN:Int = daNote.playField.player;
		var pos = modManager.getPos(daNote.strumTime, modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed),
			daNote.strumTime - Conductor.songPosition, curDecBeat, daNote.noteData, pN, daNote, [], daNote.vec3Cache);

    	daNote.distance = modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed);

		if(daNote.alpha == 0 || daNote.visible == false) return;

		modManager.updateObject(curDecBeat, daNote, pos, pN);

		pos.x += daNote.offsetX;
		if(daNote.isSustainNote) pos.x += daNote.parent.width/2 - daNote.width/2;
		pos.y += daNote.offsetY;
		if(daNote.isSustainNote) pos.y += daNote.parent.height/2;
		daNote.x = pos.x;
		daNote.y = pos.y;
		daNote.z = pos.z;
		if (daNote.isSustainNote){
			var holdCrochet:Float = Math.max(((initialCrochet + 8) / 4) / PlayState.SONG.holdSubdivisions, 10);
			var futureSongPos = Conductor.songPosition + holdCrochet;
			var diff = daNote.strumTime - futureSongPos;
			var vDiff = modManager.getVisPos(futureSongPos, daNote.strumTime, songSpeed);

			var nextPos = modManager.getPos(daNote.strumTime, vDiff, diff, Conductor.getStep(futureSongPos) / 4, daNote.noteData, pN, daNote, [], daNote.vec3Cache);
								
			nextPos.x += daNote.offsetX;
			if(daNote.isSustainNote) nextPos.x += daNote.parent.width/2 - daNote.width/2;
			nextPos.y += daNote.offsetY;
			if(daNote.isSustainNote) nextPos.y += daNote.parent.height/2;

			var diffX = (nextPos.x - pos.x);
			var diffY = (nextPos.y - pos.y);
			var diffZ = (nextPos.z - pos.z);

			var rad = Math.atan2(diffY, diffX);
			var deg = rad * (180 / Math.PI);
			daNote.mAngle = (deg != 0) ? (deg + 90) : 0;

			var visualDist = Math.sqrt(diffX * diffX + diffY * diffY + diffZ * diffZ);

			daNote.rgbShader.angleX = Math.atan2(diffY, diffZ) + (Math.PI / 2);

			if(daNote.frameHeight != 0) {
				if(!daNote.isSustainEnd){
					daNote.scale.y = (visualDist / daNote.frameHeight);
				} else {
					daNote.scale.y = 1;
				}
			}

			daNote.clip(daNote.playField.members[daNote.noteData], (diffY < 0));
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int, ?doIntro = true):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = 50; // Now we invert reverse mod

		var playField:PlayField = null;
		switch (player)
		{
			case 0: playField = opponentStrums;
			case 1: playField = playerStrums;
			case 2: playField = gfStrums;
			default: playField = extraStrums[player-3];
		}

		@:privateAccess playField.stateGeneration = this.generateStaticArrows;
		var i:Int = 0;
		for (babyArrow in playField.members)
		{
			if (babyArrow == null) continue;

			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			babyArrow.x = strumLineX;
			babyArrow.y = strumLineY;
			babyArrow.downScroll = ClientPrefs.data.downScroll;

			if (!isStoryMode && !skipArrowStartTween && doIntro)
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: targetAlpha}, 1, {
					ease: FlxEase.circOut,
					startDelay: 0.5 + (0.2 * i)
				});
			}
			else
				babyArrow.alpha = targetAlpha;

			if (player == 0){
				babyArrow.cpuControlled = !isPlayerOpponent;
				if(!isPlayerOpponent) babyArrow.noteHitCallback = opponentNoteHit;
				else {
					babyArrow.noteHitCallback = goodNoteHit;
					babyArrow.noteMissCallback = noteMiss;
				}
			} else if (player == 1){
				babyArrow.cpuControlled = isPlayerOpponent;
				if(!isPlayerOpponent) {
					babyArrow.noteHitCallback = goodNoteHit;
					babyArrow.noteMissCallback = noteMiss;
				} else babyArrow.noteHitCallback = opponentNoteHit;
			} else {
				babyArrow.cpuControlled = true;
				babyArrow.noteHitCallback = opponentNoteHit;
			}

			grpSustainSplashes.add(babyArrow.sustainSplash);
			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();

			i++;
		}

		if (ClientPrefs.data.keybindShowcase) {
			var source = !isPlayerOpponent ? playerStrums : opponentStrums;
			if(playField != source) return;
			var keyLength = source.members.length;

			for (i in 0...keyLength)
			{
				var ref = source.members[i];
				if (ref == null) continue;

				var keyShowcase = new KeybindShowcase(
					ref.x,
					ClientPrefs.data.downScroll ? ref.y - 30 : ref.y + ref.height + 5,
					ClientPrefs.keyBinds.get(keysArray[i]),
					camHUD,
					ref.width / 2,
					SONG.mania
				);

				keyShowcase.onComplete = function() {
					remove(keyShowcase);
				};

				add(keyShowcase);
			}
		}
	}

	function strumPlayAnim(strum:StrumNote, time:Float) {
		if(strum != null) {
			strum.playAnim('confirm', true);
			strum.resetAnim = time;
		}
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	//// Splash ////

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			if(note.strum != null)
				spawnNoteSplash(note.strum.modPos.x, note.strum.modPos.y, note.noteData, note, note.strum);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null, ?strum:StrumNote) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = strum;
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	//// Note hit | Note miss ////

	public static var isSongFC:Bool = true;
	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		if(isSongFC) isSongFC = false;
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.noteData, daNote);
		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		final susMult:Float = (note.isSustainNote ? 1 / PlayState.SONG.holdSubdivisions : 1);
		var subtract:Float = 0.05;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -Tahir
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

        if (!note.isSustainNote){
		    noteMs.push(167);
		    noteTime.push(note.strumTime);
		}

		var lastCombo:Int = combo;
		combo = 0;

		if(!isPlayerOpponent) health -= subtract * healthLoss * susMult; else health += subtract * healthLoss * susMult;
		if(!practiceMode) songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var chars:Array<Character> = [];
		if(note != null){
			for(char in note.characters){
				if(char == null) continue;
				if(char == boyfriend || boyfriendGroup.members.contains(char)) chars.push(boyfriend);
				else if(char == dad || dadGroup.members.contains(char)) chars.push(dad);
				else if(char == gf || gfGroup.members.contains(char)) chars.push(gf);
				else chars.push(char);
			}
		} else {
			chars = isPlayerOpponent ? [dad] : [boyfriend];
		}
		for(char in chars){	
			if((note != null && (note.gfNote || note.gfStrum)) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

			if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations && !char.noNoteAnim)
			{
				var suffix:String = '';
				if(note != null) suffix = note.animSuffix;

				var animToPlay:String = singAnimation(direction) + 'miss' + suffix;
				char.playAnim(animToPlay, true);

				if(char != gf && lastCombo > 5 && gf != null && gf.animOffsets.exists('sad'))
				{
					gf.playAnim('sad');
					gf.specialAnim = true;
				}
			}
		}
		vocals.volume = 0;
	}

	// OVERRIDE THIS IN HXSCRIPT OR SMTH
	// you can use it to handle extra animations like this
	// PlayState.instance.singAnimation = function (data:Int) {
	// 	return 'sing' + ['LEFT', 'DOWN', 'UP', 'RIGHT', 'FRONT', 'LEFT2', 'DOWN2', 'UP2', 'RIGHT2'][data];
	// }
	public dynamic function singAnimation(noteData:Int):String {
		return 'sing' + ExtraKeysHandler.instance.data.animations[ExtraKeysHandler.instance.data.keys[SONG.mania].notes[noteData]].sing;
	}

	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHitPre', [note]);

		if (songName != 'tutorial')
			camZooming = true;

		var chars:Array<Character> = [];
		for(char in note.characters){
			if(char == null) continue;
			if(char == boyfriend || boyfriendGroup.members.contains(char)) chars.push(boyfriend);
			else if(char == dad || dadGroup.members.contains(char)) chars.push(dad);
			else if(char == gf || gfGroup.members.contains(char)) chars.push(gf);
			else chars.push(char);
		}
		for(char in chars){
			if(char == null) continue;
			if(!char.noNoteAnim && note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
				char.playAnim('hey', true);
				char.specialAnim = true;
				char.heyTimer = 0.6;
			} else if(!note.noAnimation) {
				var altAnim:String = note.animSuffix;

				if (SONG.notes[curSection] != null)
					if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
						altAnim = '-alt';

				var animToPlay:String = singAnimation(note.noteData) + altAnim;
				if (char != null && !char.noNoteAnim)
				{
					char.holdTimer = 0;
				
					var fullAnim:String = animToPlay;
				
					if (char.ghostsEnabled
						&& !note.isSustainNote
						&& noteRows[(note.playField.player)][note.row] != null
						&& noteRows[(note.playField.player)][note.row].length > 1
						&& note.noteType != "Ghost Note")
					{
						var chord = noteRows[(note.playField.player)][note.row];
						var animNote = chord[0];
						var realAnim:String = singAnimation(Std.int(Math.abs(animNote.noteData))) + (altAnim == null ? "" : altAnim);

						if (char.mostRecentRow != note.row) char.playAnim(realAnim, true);
					
						if (note.nextNote != null && note.prevNote != null)
						{
							var shouldPlayGhost:Bool = true;
							try {
								var hookResult = callOnHScript('onGhostAnim', [fullAnim, note]);
								if (hookResult == LuaUtils.Function_StopHScript) shouldPlayGhost = false;
							} catch(e:Dynamic) {}
						
							if (note != animNote && !note.nextNote.isSustainNote && shouldPlayGhost)
							{
								char.playGhostAnim(chord.indexOf(note), fullAnim, true);
							}
							else if (note.nextNote.isSustainNote)
							{
								char.playAnim(realAnim, true);
								char.playGhostAnim(chord.indexOf(note), fullAnim, true);
							}
						}

						char.mostRecentRow = note.row;
					}
					else
					{
						if (note.noteType != "Ghost Note") char.playAnim(fullAnim, true);
						else char.playGhostAnim(note.noteData, fullAnim, true);
					}
				}
			}
		}

		if(opponentVocals.length <= 0) vocals.volume = 1;
		strumPlayAnim(note.strum, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;
		note.strum.rgbShader.r = note.rgbShader.r;
		note.strum.rgbShader.g = note.rgbShader.g;
		note.strum.rgbShader.b = note.rgbShader.b;
		
		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = (!isPlayerOpponent && !note.gfStrum) ? callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]) : callOnLuas('goodNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) (!isPlayerOpponent ? callOnHScript('opponentNoteHit', [note]) : callOnHScript('goodNoteHit', [note]));

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit) return;
		if(cpuControlled && note.ignoreNote) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = (!isPlayerOpponent && !note.gfStrum) ? callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]) : callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) (!isPlayerOpponent ? callOnHScript('goodNoteHitPre', [note]) : callOnHScript('opponentNoteHitPre', [note]));

		note.wasGoodHit = true;

		if (ClientPrefs.data.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), ClientPrefs.data.hitsoundVolume);

		var chars:Array<Character> = [];
		for(char in note.characters){
			if(char == null) continue;
			if(char == boyfriend || boyfriendGroup.members.contains(char)) chars.push(boyfriend);
			else if(char == dad || dadGroup.members.contains(char)) chars.push(dad);
			else if(char == gf || gfGroup.members.contains(char)) chars.push(gf);
			else chars.push(char);
		}
		for(char in chars){
			if(char != null){
				if(note.hitCausesMiss) {
					if(!note.noMissAnimation) {
						switch(note.noteType) {
							case 'Hurt Note': 
								if(char.animOffsets.exists('hurt') && !char.noNoteAnim) {
									char.playAnim('hurt', true);
									char.specialAnim = true;
								}
						}
					}

					if(note.strum.noteMissCallback != null) note.strum.noteMissCallback(note);
					if(!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
					if(!note.isSustainNote) invalidateNote(note);
					return;
				}

				if(!note.noAnimation && !char.noNoteAnim) {
					var animToPlay:String = singAnimation(note.noteData);
					var animCheck:String = 'hey';
					if(note.gfNote || note.gfStrum)
					{
						char = gf;
						animCheck = 'cheer';
					}

					if (char != null)
					{
						char.holdTimer = 0;

						var fullAnim:String = animToPlay + note.animSuffix;

						if (char.ghostsEnabled
							&& !note.isSustainNote
							&& noteRows[(note.playField.player)][note.row] != null
							&& noteRows[(note.playField.player)][note.row].length > 1
							&& note.noteType != "Ghost Note")
						{
							var chord = noteRows[(note.playField.player)][note.row];
							var animNote = chord[0];
							var realAnim:String = singAnimation(Std.int(Math.abs(animNote.noteData))) + note.animSuffix;

							if (char.mostRecentRow != note.row) char.playAnim(realAnim, true);

							if (note.nextNote != null && note.prevNote != null)
							{
								var shouldPlayGhost:Bool = true;
								try {
									var hookResult = callOnHScript('onGhostAnim', [fullAnim, note]);
									if (hookResult == LuaUtils.Function_StopHScript) shouldPlayGhost = false;
								} catch(e:Dynamic) {}
							
								if (note != animNote && !note.nextNote.isSustainNote && shouldPlayGhost)
								{
									char.playGhostAnim(chord.indexOf(note), fullAnim, true);
								}
								else if (note.nextNote.isSustainNote)
								{
									char.playAnim(realAnim, true);
									char.playGhostAnim(chord.indexOf(note), fullAnim, true);
								}
							}
						
							char.mostRecentRow = note.row;
						}
						else
						{
							if (note.noteType != "Ghost Note")
								char.playAnim(fullAnim, true);
							else
								char.playGhostAnim(note.noteData, fullAnim, true);
						}

						if (note.noteType == 'Hey!') {
							if (char.animOffsets.exists(animCheck)) {
								char.playAnim(animCheck, true);
								char.specialAnim = true;
								char.heyTimer = 0.6;
							}
						}
					}
				}
			}
		}
		if(!cpuControlled)
		{
			var spr = note.strum;
			if(spr != null) spr.playAnim('confirm', true);
			note.strum.rgbShader.r = note.rgbShader.r;
			note.strum.rgbShader.g = note.rgbShader.g;
			note.strum.rgbShader.b = note.rgbShader.b;
		}
		else {
			strumPlayAnim(note.strum, Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			note.strum.rgbShader.r = note.rgbShader.r;
			note.strum.rgbShader.g = note.rgbShader.g;
			note.strum.rgbShader.b = note.rgbShader.b;
		}
		vocals.volume = 1;

		if (!note.isSustainNote && !cpuControlled)
		{
			combo++;
			if(combo > 9999) combo = 9999;
			popUpScore(note);

			var noteDiff:Float = (Conductor.songPosition - note.strumTime + ClientPrefs.data.ratingOffset) / playbackRate;
			noteMs.push((noteDiff));
			noteTime.push(note.strumTime);
		}
		final susMult:Float = (note.isSustainNote ? 1 / PlayState.SONG.holdSubdivisions : 1);
		var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
		if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
		if (gainHealth && !isPlayerOpponent) health += note.hitHealth * healthGain * susMult;
		if (gainHealth && isPlayerOpponent) health -= note.hitHealth * healthGain * susMult;

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = (!isPlayerOpponent && !note.gfStrum) ? callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]) : callOnLuas('opponentNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) (!isPlayerOpponent ? callOnHScript('goodNoteHit', [note]) : callOnHScript('opponentNoteHit', [note]));

		if(!note.isSustainNote) invalidateNote(note);
	}

	//// Keys ////

	private function onKeyPress(event:KeyboardEvent):Void {
		var eventKey:FlxKey = event.keyCode;
		if (!controls.controllerMode) {
			#if debug
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end
			if (FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(eventKey, -1);
		}
	}

	private function keyPressed(eventKey:FlxKey, ?controllerKey:Int = -1) {
		if (cpuControlled || paused || inCutscene || !generatedMusic || endingSong) return;

		var scriptKey:Int = (controllerKey > -1) ? controllerKey : getKeyFromEvent(keysArray, eventKey);
		var ret:Dynamic = callOnScripts('onKeyPressPre', [scriptKey]);
		if (ret == LuaUtils.Function_Stop) return;

		var lastTime:Float = Conductor.songPosition;
		if (Conductor.songPosition >= 0 && !startingSong && FlxG.sound.music?.playing)
			Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var notesToHit:Array<Note> = [];
		var fieldsProcessed:Int = 0;
		var keysChecked:Array<Int> = [];

		for (field in PlayField.fields) {
			var fieldKey:Int = (controllerKey > -1) ? controllerKey : getKeyFromEvent(field.keysArray, eventKey);
			if (fieldKey < 0 || fieldKey >= field.keyCount) continue;

			fieldsProcessed++;
			keysChecked.push(fieldKey);
			var highestNote:Note = null;

			for (n in notes) {
				if (n != null && n.playField == field && !n.isSustainNote && n.noteData == fieldKey && n.canBeHit && !n.strum.cpuControlled && n.strum.inControl && !n.tooLate && !n.wasGoodHit && !n.blockHit) {
					if (highestNote == null || n.hitPriority > highestNote.hitPriority || (n.hitPriority == highestNote.hitPriority && n.strumTime < highestNote.strumTime))
						highestNote = n;
				}
			}

			if (highestNote != null) notesToHit.push(highestNote);
		}

		if (notesToHit.length > 0) {
			for (note in notesToHit) {
				goodNoteHit(note);
			}
		} else if (fieldsProcessed > 0) {
			for (i in 0...PlayField.fields.length) {
				var field = PlayField.fields[i];
				var fKey = (controllerKey > -1) ? controllerKey : getKeyFromEvent(field.keysArray, eventKey);
				
				if (fKey >= 0 && fKey < field.members.length) {
					var strum:StrumNote = field.members[fKey];
					if (strum != null && !strum.cpuControlled && strum.animation.curAnim.name != 'confirm') {
						strum.playAnim("pressed", true);
						strum.resetAnim = 0;
					}
				}
			}

			if (ClientPrefs.data.ghostTapping) {
				callOnScripts('onGhostTap', [scriptKey]);
			} else {
				noteMissPress(scriptKey);
			}
		}

		Conductor.songPosition = lastTime;
		callOnScripts('onKeyPress', [scriptKey]);
	}

	private function onKeyRelease(event:KeyboardEvent):Void {
		var eventKey:FlxKey = event.keyCode;
		if (!controls.controllerMode) keyReleased(eventKey, -1);
	}

	private function keyReleased(eventKey:FlxKey, ?controllerKey:Int = -1) {
		if (cpuControlled || !startedCountdown || paused) return;

		var scriptKey:Int = (controllerKey > -1) ? controllerKey : getKeyFromEvent(keysArray, eventKey);
		var ret:Dynamic = callOnScripts('onKeyReleasePre', [scriptKey]);
		if (ret == LuaUtils.Function_Stop) return;

		for (field in PlayField.fields) {
			if (field == null) continue;
			var fieldKey:Int = (controllerKey > -1) ? controllerKey : getKeyFromEvent(field.keysArray, eventKey);
			
			if (fieldKey >= 0 && fieldKey < field.members.length) {
				var strum:StrumNote = field.members[fieldKey];
				if (strum != null && !strum.cpuControlled && strum.inControl) {
					strum.playAnim("static", true);
					strum.resetAnim = 0;
					if (strum.sustainSplash.animation.curAnim.name != "splash")
						strum.sustainSplash.hide(true);
				}
			}
		}

		callOnScripts('onKeyRelease', [scriptKey]);
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int {
		if (key != NONE && arr != null) {
			for (i in 0...arr.length) {
				var noteKeys:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				if (noteKeys != null) {
					for (noteKey in noteKeys) {
						if (key == noteKey) return i;
					}
				}
			}
		}
		return -1;
	}

	private function keysCheck():Void {
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];

		for (key in keysArray) {
			holdArray.push(controls.pressed(key));
			if (controls.controllerMode) {
				pressArray.push(controls.justPressed(key));
				releaseArray.push(controls.justReleased(key));
			}
		}

		if (controls.controllerMode && pressArray.contains(true)) {
			for (i in 0...pressArray.length) {
				if (pressArray[i]) keyPressed(NONE, i);
			}
		}

		if (startedCountdown && !inCutscene && generatedMusic) {
			if (notes.length > 0) {
				for (n in notes) {
					var fieldKey:Int = n.noteData;
					var isHolding:Bool = false;
					
					if (controls.controllerMode) {
						isHolding = controls.pressed(keysArray[fieldKey]);
					} else {
						var bindName:String = n.playField.keysArray[fieldKey];
						isHolding = controls.pressed(bindName);
					}

					var canHit:Bool = (n != null && n.strum.inControl && n.canBeHit
						&& !n.strum.cpuControlled && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote && isHolding) {
						n.strum.noteHitCallback(n);
					}
				}
			}
		}

		if (controls.controllerMode && releaseArray.contains(true)) {
			for (i in 0...releaseArray.length) {
				if (releaseArray[i]) keyReleased(NONE, i);
			}
		}
	}

	//// Ratings | Score ////

	public dynamic function updateScore(miss:Bool = false)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		var percent:Float = 0;
		if(totalPlayed != 0)
		{
			percent = CoolUtil.floorDecimal(ratingPercent * 100, 2);
		}

		var format:FlxTextFormat = new FlxTextFormat(FlxColor.GRAY);

		if (ratingName == "PFC")
			format = new FlxTextFormat(FlxColor.YELLOW);
		else if (songMisses == 0 && songScore != 0)
		{
			format = new FlxTextFormat(FlxColor.YELLOW);
			ratingName = "FC";
		}
		else if (ratingName == "S")
			format = new FlxTextFormat(FlxColor.CYAN);
		else if (ratingName == "A+" || ratingName == "A")
			format = new FlxTextFormat(FlxColor.GREEN);
		else if (ratingName == "B+" || ratingName == "B")
			format = new FlxTextFormat(FlxColor.LIME);
		else if (ratingName == "C" || ratingName == "D")
			format = new FlxTextFormat(FlxColor.LIME);
		else if (ratingName == "F" || ratingName == "L")
			format = new FlxTextFormat(FlxColor.BROWN);
		else if (ratingName != "FC")
			format = new FlxTextFormat(FlxColor.GRAY);

		var marker = new FlxTextFormatMarkerPair(format, "**");

		var tempScore:String = 'Score: ${songScore}'
		+ (!instakillOnMiss ? '        Misses: ${songMisses}' : "")
		+ '        Rating: (${percent}%) **- [${ratingName}]**';
		scoreTxt.text = '${tempScore}\n';
		scoreTxt.applyMarkup(scoreTxt.text,[marker]);

		if (!miss && !cpuControlled)
			doScoreBop();

		if(ClientPrefs.data.judgecounter) judgementCounter.text = 'Note Hits: ${songHits}\nCombo: ${combo}\n\nEpic: ${ratingsData[0].hits}\nSick: ${ratingsData[1].hits}\nGood: ${ratingsData[2].hits}\nBad: ${ratingsData[3].hits}\nShit: ${ratingsData[4].hits}\nMiss: ${songMisses}';

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = "";
		if(songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function RecalculateRating(badHit:Bool = false) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
			Paths.image(uiPrefix + rating.image + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset;
		var absNoteDiff:Float = Math.abs(noteDiff / playbackRate);
		vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0) {
			for (spr in comboGroup) {
				spr.destroy();
				comboGroup.remove(spr);
			}
		}

		var camMode:String = ClientPrefs.data.ratingCam;
		var ratingCamArr:Array<FlxCamera> = (camMode == "Game") ? [camGame] : [camHUD];

		var placement:Float = FlxG.width * 0.35;
		var baseX:Float = placement - 40;
		var baseY:Float = FlxG.height / 2 - 60;

		var linkStrum:StrumNote = note.strum;

		if (camMode == "Game") {
			if (isPlayerOpponent) {
				baseX = dad.getMidpoint().x + dad.width/1.5;
				baseY = dad.getMidpoint().y - dad.height/1.2;
			} else {
				baseX = boyfriend.getMidpoint().x - boyfriend.width/1.5;
				baseY = boyfriend.getMidpoint().y - boyfriend.height/1.2;
			}
		} else if (camMode == "Bellow Note") {
			ratingCamArr = [camHUD];
			baseX = linkStrum.modPos.x;
			baseY = linkStrum.modPos.y + (linkStrum.downScroll ? -10 : linkStrum.height + 10);
		}

		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		var score:Int = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;

		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}

		var scaX:Float = (linkStrum.scale.x*0.6)+0.085;
		var scaY:Float = (linkStrum.scale.y*0.6)+0.085;

		var rating:FlxSkewedSprite = new FlxSkewedSprite();
		rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
		rating.x = baseX;
		rating.y = baseY;
		rating.cameras = ratingCamArr;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);

		if(camMode == "HUD") {
			rating.x += ClientPrefs.data.comboOffset[0];
			rating.y -= ClientPrefs.data.comboOffset[1];
		}
		rating.antialiasing = antialias;

		var earlyLateSpr:AttachedSprite = null;
		var earlyLateType:String = null;
		var earlyLateThreshold:Float = 20;

		if (absNoteDiff > earlyLateThreshold && daRating.image != "epic"){
			if (noteDiff < 0) earlyLateType = "late"; else earlyLateType = "early";

			earlyLateSpr = new AttachedSprite();
			earlyLateSpr.loadGraphic(Paths.image(earlyLateType));
			earlyLateSpr.copyAlpha = false;
			earlyLateSpr.sprTracker = rating;
			earlyLateSpr.cameras = ratingCamArr;
			earlyLateSpr.antialiasing = ClientPrefs.data.antialiasing;
			earlyLateSpr.alpha = 1;
			if(ClientPrefs.data.ratingCam == "Bellow Note"){
				earlyLateSpr.scale.set(scaX/(PlayState.isPixelStage ? daPixelZoom : 1), scaY/(PlayState.isPixelStage ? daPixelZoom : 1));
			}
			comboGroup.add(earlyLateSpr);

			FlxTween.tween(earlyLateSpr, {alpha: 0}, 0.5 / playbackRate, {
				onComplete: function(twn:FlxTween) earlyLateSpr.destroy()
			});
		}

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
		comboSpr.x = baseX + 40;
		comboSpr.y = baseY + 60;
		comboSpr.cameras = ratingCamArr;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.extraData["linkStrum"] = linkStrum;

		if(ClientPrefs.data.ratingCam == "Bellow Note"){
			comboSpr.scale.set(scaX, scaY);
		}

		if(camMode == "HUD") {
			comboSpr.x += ClientPrefs.data.comboOffset[0];
			comboSpr.y -= ClientPrefs.data.comboOffset[1];
		}

		comboSpr.antialiasing = antialias;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

		if (!PlayState.isPixelStage)
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		if(ClientPrefs.data.ratingCam == "Bellow Note"){
			rating.scale.set(scaX/(PlayState.isPixelStage ? daPixelZoom : 1), scaY/(PlayState.isPixelStage ? daPixelZoom : 1));
		}

		rating.updateHitbox();
		comboSpr.updateHitbox();

		if (camMode == "Bellow Note") {
			rating.x = linkStrum.modPos.x + (linkStrum.width - rating.width) * 0.5;
			rating.y = linkStrum.modPos.y + (linkStrum.downScroll ? -25 : linkStrum.height + 10);
			comboSpr.x = rating.x + 40;
			comboSpr.y = rating.y + 60;
			if(PlayState.isPixelStage) rating.x -= rating.width/2;
		}

		comboGroup.add(rating);

		var seperatedScore:Array<Int> = [];
		if(combo >= 1000) seperatedScore.push(Math.floor(combo / 1000) % 10);
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo) comboGroup.add(comboSpr);

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));

			if(camMode == "HUD") {
				numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
				numScore.y = baseY + 140 - ClientPrefs.data.comboOffset[3];
			} else {
				numScore.x = baseX + (43 * daLoop) - 90;
				numScore.y = baseY + 140;
			}

			if (camMode == "Bellow Note") {
				numScore.x = rating.x + (43 * daLoop) - 50;
				numScore.y = rating.y + 80;
			}

			numScore.cameras = ratingCamArr;
			numScore.antialiasing = antialias;

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			if(ClientPrefs.data.ratingCam == "Bellow Note"){
				numScore.scale.set(scaX, scaY);
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;

			if(showComboNum && ClientPrefs.data.ratingCam != "Bellow Note") comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween) numScore.destroy(),
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}

		comboSpr.x = (camMode == "Bellow Note") ? (rating.x + 50 + (43 * Math.max(0, seperatedScore.length - 1))) : (xThing + 50);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});

		if (!PlayState.isPixelStage)
		{
			rating.antialiasing = ClientPrefs.data.antialiasing;
			FlxTween.cancelTweensOf(rating, ['scale.x', 'scale.y']);
			FlxTween.tween(rating.scale, {x: rating.scale.x-0.085, y: rating.scale.y-0.085}, 0.5, {ease: FlxEase.expoOut});
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * 6 * 0.85));
		}
		rating.updateHitbox();
	}

	//// Camera ////

	var camFollowTarget:String = 'dad'; // 'dad' | 'boyfriend' | 'gf'

	inline function detectSectionTarget():String {
		if (SONG.notes[curSection] != null) {
			if (gf != null && (SONG.notes[curSection].gfSection || SONG.notes[curSection].focusGF)) return 'gf';
			return (SONG.notes[curSection].mustHitSection != true) ? 'dad' : 'boyfriend';
		}
		return camHitTarget;
	}

	function snapCamToPos(x:Float = 0, y:Float = 0, lockPos:Bool = false):Void {
		camFollow.setPosition(x, y);
		FlxG.camera.snapToTarget();
		if (lockPos) isCameraOnForcedPos = true;
		else isCameraOnForcedPos = false;
	}

	public function setCharacterCameraPos(x:Float = 0, y:Float = 0, char:Null<Character>):Void
	{
		if (char == null) return;

		final midpoint = char.getMidpoint();
		final offsets = char.isPlayer ? boyfriendCameraOffset : opponentCameraOffset;

		var target:FlxPoint = new FlxPoint(x, y);

		target.set(midpoint.x, midpoint.y);
		target.y += -100 + char.cameraPosition[1] + offsets[1];

		if (char.isPlayer)
		{
			target.x -= 100 + char.cameraPosition[0];
		}
		else
		{
			target.x += 100 + char.cameraPosition[0];
		}

		target.x += offsets[0];

		midpoint.put();
	}

	public function getCharacterCameraPos(char:Null<Character>):FlxPoint {
		if (char == null) return FlxPoint.weak();
		
		final desiredPos = char.getMidpoint();
		
		final offsets = char.isPlayer ? boyfriendCameraOffset : opponentCameraOffset;
		
		desiredPos.y += -100 + char.cameraPosition[1] + offsets[1];
		
		if (char.isPlayer)
		{
			desiredPos.x -= 100 + char.cameraPosition[0];
		}
		else
		{
			desiredPos.x += 100 + char.cameraPosition[0];
		}
		
		desiredPos.x += offsets[0];
		
		return desiredPos;
	}

	function updateNoteHitCam():Void {
		var sectionTarget = detectSectionTarget();
		if(sectionTarget != camHitTarget) camHitTarget = sectionTarget;

		var ofs:Int = 0;
		switch(camHitTarget) {
			case 'boyfriend': ofs = camHitBfOfs;
			case 'gf': ofs = camHitGfOfs;
			case 'dad': ofs = camHitDadOfs;
			default: ofs = 0;
		}

		var anim = switch(camHitTarget) {
			case 'boyfriend': boyfriend.getAnimationName();
			case 'gf': gf != null ? gf.getAnimationName() : '';
			case 'dad': dad.getAnimationName();
			default: '';
		}

		var moveX:Float = 0;
		var moveY:Float = 0;
		if (ofs != 0 && anim != null) {
			if (StringTools.contains(anim, 'singLEFT')) moveX = -ofs;
			else if (StringTools.contains(anim, 'singRIGHT')) moveX = ofs;
			else if (StringTools.contains(anim, 'singUP')) moveY = -ofs;
			else if (StringTools.contains(anim, 'singDOWN')) moveY = ofs;
		}

		updateCameraBase();

		var baseX:Float = camFollowBaseX;
		var baseY:Float = camFollowBaseY;

		if (camHitForcedX) {
			switch(camHitCurrentXTarget) {
				case 'bf' | 'boyfriend' | 'gf' | 'dad':
					baseX = getCharPosX(camHitCurrentXTarget.toLowerCase());
				case 'both':
					var p1 = 'dad'; var p2 = 'bf';
					if (camHitBothStyle == 1) { p1 = 'gf'; p2 = 'bf'; }
					else if (camHitBothStyle == 2) { p1 = 'gf'; p2 = 'dad'; }
					var x1 = getCharPosX(p1); var x2 = getCharPosX(p2);
					baseX = x1 + (x2 - x1) / 2;
				case 'event':
			}
		}
		if (camHitForcedY) {
			switch(camHitCurrentYTarget) {
				case 'bf' | 'boyfriend' | 'gf' | 'dad':
					baseY = getCharPosY(camHitCurrentYTarget.toLowerCase());
				case 'both':
					var p1 = 'dad'; var p2 = 'bf';
					if (camHitBothStyle == 1) { p1 = 'gf'; p2 = 'bf'; }
					else if (camHitBothStyle == 2) { p1 = 'gf'; p2 = 'dad'; }
					var y1 = getCharPosY(p1); var y2 = getCharPosY(p2);
					baseY = y1 + (y2 - y1) / 2;
				case 'event':
			}
		}

		camFollow.x = baseX + moveX + camHitXExtra;
		camFollow.y = baseY + moveY + camHitYExtra;

		camHitLastMoveX = moveX;
		camHitLastMoveY = moveY;
	}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && (SONG.notes[sec].gfSection || SONG.notes[sec].focusGF))
		{
			camFollowTarget = 'gf';

			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			camFollowBaseX = camFollow.x;
			camFollowBaseY = camFollow.y;

			if(useGFZoom) currentUsedZoom = "gf";
			else currentUsedZoom = "default";

			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		camFollowTarget = isDad ? 'dad' : 'boyfriend';

		moveCamera(isDad);
		callOnScripts('onMoveCamera', [camFollowTarget]);
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			camFollowBaseX = camFollow.x;
			camFollowBaseY = camFollow.y;

			if(useDadZoom) currentUsedZoom = "dad";
			else currentUsedZoom = "default";
			tweenCamIn();
		}
		else
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			camFollowBaseX = camFollow.x;
			camFollowBaseY = camFollow.y;

			if(useBFZoom) currentUsedZoom = "bf";
			else currentUsedZoom = "default";

			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function updateCameraBase():Void {
		switch(camFollowTarget) {
			case 'dad':
				camFollowBaseX = dad.getMidpoint().x + 150
					+ dad.cameraPosition[0] + opponentCameraOffset[0];
				camFollowBaseY = dad.getMidpoint().y - 100
					+ dad.cameraPosition[1] + opponentCameraOffset[1];

			case 'boyfriend':
				camFollowBaseX = boyfriend.getMidpoint().x - 100
					- boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
				camFollowBaseY = boyfriend.getMidpoint().y - 100
					+ boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			case 'gf':
				if (gf != null) {
					camFollowBaseX = gf.getMidpoint().x
						+ gf.cameraPosition[0] + girlfriendCameraOffset[0];
					camFollowBaseY = gf.getMidpoint().y
						+ gf.cameraPosition[1] + girlfriendCameraOffset[1];
				}
		}
	}

	public function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	//// Vocals | Inst ////

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = Conductor.songPosition;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
		}
		if(!vocals.playing) vocals.resume();
		if(!opponentVocals.playing) opponentVocals.resume();
	}

	//// Discord ////

	public var autoUpdateRPC:Bool = true;
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		super.onFocusLost();
	}

	//// Dialogue ////

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	//// Helpers ////

	public static function prepareForSong(songName:String, difficulty:Int = 1, isStoryMode:Bool = false):Null<haxe.Exception> {
		try {
			final formattedSong = Paths.formatToSongPath(songName);
			var poop = Highscore.formatSong(formattedSong, difficulty);
			PlayState.SONG = Song.loadFromJson(poop, formattedSong);
			PlayState.isStoryMode = isStoryMode;
			
			return null;
		}
		catch (e)
		{
			return e;
		}
	}

	//// Add ////

	#if HSCRIPT_ALLOWED
	override public function insert(pos:Int, obj:flixel.FlxBasic):flixel.FlxBasic {   // Just why...
		super.insert(pos, obj);
		return obj;
	}
	#end

	public function addBehindGF(obj:FlxBasic)
		insert(members.indexOf(gfGroup), obj);

	public function addBehindBF(obj:FlxBasic)
		insert(members.indexOf(boyfriendGroup), obj);
	
	public function addBehindDad(obj:FlxBasic)
		insert(members.indexOf(dadGroup), obj);

}