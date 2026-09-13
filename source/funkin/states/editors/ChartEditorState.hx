package funkin.states.editors;

import flixel.FlxSubState;
import flixel.util.FlxSave;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxStringUtil;
import flixel.util.FlxDestroyUtil;
import flixel.input.keyboard.FlxKey;
import funkin.backend.utils.WindowUtil;

import lime.utils.Assets;
import lime.media.AudioBuffer;
import lime.app.Application;

import flash.media.Sound;
import flash.geom.Rectangle;

import haxe.Json;
import haxe.Exception;
import haxe.io.Bytes;

import funkin.states.editors.ui.ChartEditorUI;

import funkin.states.editors.content.MetaNote;
import funkin.states.editors.content.Prompt;
import funkin.states.editors.content.*;

import funkin.data.Song;
import funkin.data.StageData;
import funkin.backend.Difficulty;
import funkin.data.Section;
import funkin.backend.ExtraKeysHandler;
import funkin.backend.parsers.CodenameParser;

import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import funkin.objects.Character;
import funkin.objects.HealthIcon;
import funkin.objects.notes.Note;
import funkin.objects.notes.StrumNote;

import openfl.net.FileFilter;

using DateTools;

typedef UndoStruct = {
	var action:UndoAction;
	var data:Dynamic;
}

enum abstract UndoAction(String)
{
	var ADD_NOTE = 'Add Note';
	var DELETE_NOTE = 'Delete Note';
	var MOVE_NOTE = 'Move Note';
	var SELECT_NOTE = 'Select Note';
}

enum abstract ChartingTheme(String)
{
	var LIGHT = 'light';
	var DARK = 'dark';
	var DEFAULT = 'default';
	var VSLICE = 'vslice';
	var CUSTOM = 'custom';
}

class ChartEditorState extends MusicBeatState {
	public static var chartPath:String = null;

	var _file:FileReference;

	var noteTypes:Array<String>;
	public static var noteTypeList:Array<String> = //Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
		[
			'',
			'Alt Animation',
			'Hey!',
			'Hurt Note',
			'GF Sing',
			'No Animation',
			'Ghost Note'
		];
	
		public static function parseJSON(data:String, path:String = null, extra:Dynamic = null):SwagSong {
		// Lightweight JSON parsing fallback -- returns a dynamic cast to SwagSong.
		return cast haxe.Json.parse(data);
	}

	public static function convert(from:Dynamic):Void {
		// Backwards-compat conversion helper. If the loaded object is a SwagSong-like structure,
		// set PlayState.SONG to it for editor usage.
		if(from != null) PlayState.SONG = cast from;
	}

	public static final defaultEvents:Array<Array<String>> =
	[
		['', "Nothing. Yep, that's right."], //Always leave this one empty pls
		['Dadbattle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		['Philly Glow', "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
		['Kill Henchmen', "For Mom's songs, don't use this please, i love them :("],
		['Add Camera Zoom', "Used on MILF on that one \"hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Alt Idle Animation', "Sets a specified postfix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New postfix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		['Play Sound', "Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"],
		['Modchart Event', "Please use the modchart tab"],
		//['Change Mania', "Input new amount of keys"],
		['HScript Call', "Call an HScript function\nValue 1: Function name\nValue 2: Args (comma separated)"]
	];
	
	public static var keysArray:Array<FlxKey> = [ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT]; //Used for Vortex Editor
	public static var SHOW_EVENT_COLUMN = true;
	public static var GRID_COLUMNS_PER_PLAYER = 4;
	public static var GRID_PLAYERS = 2;
	public static var GRID_SIZE = 40;
	final BACKUP_EXT = '.bkp';

	public var quantizations:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];
	public var quantColors:Array<FlxColor> = [
		0xFFDF0000,
		0xFF4040CF,
		0xFFAF00AF,
		0xFFFFAF00,
		0xFFFFFFFF,
		0xFFFFA0FF,
		0xFFFF6030,
		0xFF00CFCF,
		0xFF00CF00,
		0xFF9F9F9F,
		0xFF3F3F3F,
	];
	var curQuant(default, set):Int = 16;
	function set_curQuant(v:Int)
	{
		curQuant = v;
		updateVortexColor();
		return curQuant;
	}
	function updateVortexColor()
		vortexIndicator.color = quantColors[Std.int(FlxMath.bound(quantizations.indexOf(curQuant), 0, quantColors.length - 1))];

	var sectionFirstNoteID:Int = 0;
	var sectionFirstEventID:Int = 0;
	var curSec:Int = 0;
	
	var camUI:FlxCamera;

	var prevGridBg:ChartingGridSprite;
	var gridBg:ChartingGridSprite;
	var nextGridBg:ChartingGridSprite;
	var waveformSprite:FlxSprite;
	var scrollY:Float = 0;
	var easedScrollY:Float = 0;
	public static final SCROLL_EASE_DURATION:Float = 0.2;
	
	var zoomList:Array<Float> = [
		0.25,
		0.5,
		1,
		2,
		3,
		4,
		6,
		8,
		12,
		16,
		24
	];
	var curZoom:Float = 1;

	public var chartEditorSave:FlxSave;

	var mustHitIndicator:FlxSprite;
	var eventIcon:FlxSprite;
	var icons:Array<HealthIcon> = [];

	var events:Array<EventMetaNote> = [];
	var notes:Array<MetaNote> = [];

	var behindRenderedNotes:FlxTypedGroup<MetaNote> = new FlxTypedGroup<MetaNote>();
	var curRenderedNotes:FlxTypedGroup<MetaNote> = new FlxTypedGroup<MetaNote>();
	var movingNotes:FlxTypedGroup<MetaNote> = new FlxTypedGroup<MetaNote>();
	var eventLockOverlay:FlxSprite;
	var vortexIndicator:FlxSprite;
	var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	var dummyArrow:FlxSprite;
	var isMovingNotes:Bool = false;
	var movingNotesLastData:Int = 0;
	var movingNotesLastY:Float = 0;
	
	var vocals:FlxSound = new FlxSound();
	var opponentVocals:FlxSound = new FlxSound();

	var timeLine:FlxSprite;

	var selectionStart:FlxPoint = FlxPoint.get();
	var selectionBox:FlxSprite;

	var _shouldReset:Bool = true;
	public function new(?shouldReset:Bool = true)
	{
		this._shouldReset = shouldReset;
		super();
	}

	var bg:FlxSprite;
	var theme:ChartingTheme = DEFAULT;

	var copiedNotes:Array<Dynamic> = [];
	var copiedEvents:Array<Dynamic> = [];
	
	var _keysPressedBuffer:Array<Bool> = [];

	var tipBg:FlxSprite;
	var fullTipText:FlxText;
	
	var vortexEnabled:Bool = false;
	var waveformEnabled:Bool = false;

	var lockedEvents:Bool = false;

	var cachedCharacterList:Array<String> = [''];

	var UI:ChartEditorUI;

	override function create()
	{
		WindowUtil.preventClose = true;
		WindowUtil.onEditorClosing = function()
		{
			if(!UI.ignoreProgressCheckBox.checked){
				FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
				openSubState(new Prompt("Are you sure you want to close the game?\nAll unsaved chart data will be lost.", function(){
					WindowUtil.preventClose = false;
					Sys.exit(0);
				}));
			} else {
				WindowUtil.preventClose = false;
				Sys.exit(0);
			}
		};
		if(PlayState.SONG == null)
		{
			openNewChart();
		}
		GRID_COLUMNS_PER_PLAYER = PlayState.SONG.mania != null ? PlayState.SONG.mania+1 : 4;
		GRID_PLAYERS = PlayState.SONG.lanes;

		if(Difficulty.list.length < 1) Difficulty.resetList();
		_keysPressedBuffer.resize(keysArray.length);

		if(_shouldReset) Conductor.songPosition = 0;
		persistentUpdate = false;
		FlxG.mouse.visible = true;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		vocals.autoDestroy = false;
		vocals.looped = true;
		opponentVocals.autoDestroy = false;
		opponentVocals.looped = true;

		initPsychCamera();
		camUI = new FlxCamera();
		camUI.bgColor.alpha = 0;
		FlxG.cameras.add(camUI, false);

		chartEditorSave = new FlxSave();
		chartEditorSave.bind('chart_editor_data', CoolUtil.getSavePath());

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.zoomFactor = 0;
		bg.scrollFactor.set();
		add(bg);

		if(chartEditorSave.data.autoSave != null) autoSaveCap = chartEditorSave.data.autoSave;
		if(chartEditorSave.data.backupLimit != null) backupLimit = chartEditorSave.data.backupLimit;
		if(chartEditorSave.data.vortex != null) vortexEnabled = chartEditorSave.data.vortex;

		if(chartEditorSave.data.customBgColor == null) chartEditorSave.data.customBgColor = '303030';
		if(chartEditorSave.data.customGridColors == null || chartEditorSave.data.customGridColors.length < 2)
			chartEditorSave.data.customGridColors = ['DFDFDF', 'BFBFBF'];
		if(chartEditorSave.data.customNextGridColors == null || chartEditorSave.data.customNextGridColors.length < 2)
			chartEditorSave.data.customNextGridColors = ['5F5F5F', '4A4A4A'];
		
		changeTheme(chartEditorSave.data.theme != null ? chartEditorSave.data.theme : DEFAULT, false);

		UI = new ChartEditorUI(this);
		UI.cameras = [camUI];
		UI.scrollFactor.set();

		createGrids();
		
		selectionBox = new FlxSprite().makeGraphic(1, 1, FlxColor.CYAN);
		selectionBox.alpha = 0.4;
		selectionBox.blend = ADD;
		selectionBox.scrollFactor.set();
		selectionBox.cameras = [camUI];
		selectionBox.visible = false;
		add(selectionBox);

		updateJsonData();
		
		UI.createUI();

		loadMusic();
		UI.reloadNotesDropdowns();
		if(!_shouldReset)
		{
			vocals.time = opponentVocals.time = FlxG.sound.music.time = Conductor.songPosition - Conductor.offset;
			if(FlxG.sound.music.time >= vocals.length)
				vocals.pause();
			if(FlxG.sound.music.time >= opponentVocals.length)
				opponentVocals.pause();
		}

		reloadNotes();
		updateGridVisibility();

		// CHARACTERS FOR THE DROP DOWNS
		var gameOverCharacters:Array<String> = loadFileList('characters/', 'data/characterList.txt');
		var characterList:Array<String> = gameOverCharacters.filter((name:String) -> (!name.endsWith('-dead') && !name.endsWith('-death')));
		cachedCharacterList = characterList;
		for (dropDown in UI.characterDropdowns)
			if(dropDown != null) dropDown.list = cachedCharacterList;
		if(UI.lanesGfDropDown != null) UI.lanesGfDropDown.list = cachedCharacterList;

		gameOverCharacters.insert(0, '');
		gameOverCharacters.sort(function(a:String, b:String)
		{
			if((a == '' || a.endsWith('-dead') || a.endsWith('-death')) && !(b == '' || b.endsWith('-dead') || b.endsWith('-death'))) return -1; //Prioritize "-dead" or "-death" characters
			return 0;
		});
		UI.gameOverCharDropDown.list = gameOverCharacters;

		UI.stageDropDown.list = loadFileList('stages/', 'data/stageList.txt');
		onChartLoaded();

		var tipText:FlxText = new FlxText(FlxG.width - 220, FlxG.height - 30, 200, 'Press F1 for Help', 20);
		tipText.cameras = [camUI];
		tipText.setFormat(null, 16, FlxColor.WHITE, RIGHT);
		tipText.borderColor = FlxColor.BLACK;
		tipText.scrollFactor.set();
		tipText.borderSize = 1;
		tipText.active = false;
		add(tipText);

		tipBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		tipBg.cameras = [camUI];
		tipBg.scale.set(FlxG.width, FlxG.height);
		tipBg.updateHitbox();
		tipBg.scrollFactor.set();
		tipBg.visible = tipBg.active = false;
		tipBg.alpha = 0.6;
		add(tipBg);
		
		fullTipText = new FlxText(0, 0, FlxG.width - 200);
		fullTipText.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER);
		fullTipText.cameras = [camUI];
		fullTipText.scrollFactor.set();
		fullTipText.visible = fullTipText.active = false;
		fullTipText.text = [
			"W/S/Mouse Wheel - Move Conductor's Time",
			"A/D - Change Sections",
			"Q/E - Decrease/Increase Note Sustain Length",
			"Hold Shift/Alt to Increase/Decrease move by 4x",
			"",
			"F12 - Preview Chart",
			"Enter - Playtest Chart",
			"Space - Stop/Resume song",
			"",
			"Alt + Click - Select Note(s)",
			"Shift + Click - Select/Unselect Note(s)",
			"Right Click - Selection Box",
			"",
			"R - Reset Section",
			"Shift + R - Go Back to the Start of the Song",
			"Z/X - Zoom grid in/out",
			"I/O - Move grid left/right",
			"Left/Right - Change Snap",
			#if FLX_PITCH
			"Left Bracket / Right Bracket - Change Song Playback Rate",
			"ALT + Left Bracket / Right Bracket - Reset Song Playback Rate",
			#end
			"",
			"Ctrl + + - Zoom in camera",
			"Ctrl + - - Zoom out camera",
			"Ctrl + Z - Undo",
			"Ctrl + Y - Redo",
			"Ctrl + X - Cut Selected Notes",
			"Ctrl + C - Copy Selected Notes",
			"Ctrl + V - Paste Copied Notes",
			"Ctrl + A - Select all in current Section",
			"Ctrl + S - Quicksave",
		].join('\n');
		fullTipText.screenCenter();
		add(fullTipText);

		Application.current.window.title = "* NotePulse Engine | Charting " + 
		PlayState.SONG.song + " - " + Difficulty.getString();

		super.create();

		FlxTween.cancelTweensOf(Main.fpsVar);
		FlxTween.tween(Main.fpsVar, {alpha: 0.5}, 1, {ease: FlxEase.circOut});

		updateScrollY();
		easedScrollY = scrollY;
		FlxG.camera.scroll.y = easedScrollY;
	}

	var gridColors:Array<FlxColor>;
	var gridColorsOther:Array<FlxColor>;
	function changeTheme(changeTo:ChartingTheme, ?doSave:Bool = true)
	{
		var oldTheme:ChartingTheme = theme;
		theme = changeTo;
		chartEditorSave.data.theme = changeTo;
		if(doSave) chartEditorSave.flush();

		switch(theme)
		{
			case LIGHT:
				bg.color = 0xFFA0A0A0;
				gridColors = [0xFFDFDFDF, 0xFFBFBFBF];
				gridColorsOther = [0xFF5F5F5F, 0xFF4A4A4A];
			case DARK:
				bg.color = 0xFF222222;
				gridColors = [0xFF3F3F3F, 0xFF2F2F2F];
				gridColorsOther = [0xFF1F1F1F, 0xFF111111];
			case VSLICE:
				bg.color = 0xFF673AB7;
				gridColors = [0xFFD0D0D0, 0xFFAFAFAF];
				gridColorsOther = [0xFF595959, 0xFF464646];
			case CUSTOM:
				bg.color = CoolUtil.colorFromString(chartEditorSave.data.customBgColor);
				gridColors = [CoolUtil.colorFromString(chartEditorSave.data.customGridColors[0]), CoolUtil.colorFromString(chartEditorSave.data.customGridColors[1])];
				gridColorsOther = [CoolUtil.colorFromString(chartEditorSave.data.customNextGridColors[0]), CoolUtil.colorFromString(chartEditorSave.data.customNextGridColors[1])];
			default:
				bg.color = 0xFF303030;
				gridColors = [0xFFDFDFDF, 0xFFBFBFBF];
				gridColorsOther = [0xFF5F5F5F, 0xFF4A4A4A];
		}

		if(theme != oldTheme || theme == CUSTOM)
		{
			if(gridBg != null)
			{
				gridBg.loadGrid(gridColors[0], gridColors[1]);
				gridBg.vortexLineEnabled = vortexEnabled;
				gridBg.vortexLineSpace = GRID_SIZE * 4 * curZoom;
			}
			if(prevGridBg != null)
			{
				prevGridBg.loadGrid(gridColorsOther[0], gridColorsOther[1]);
				prevGridBg.vortexLineEnabled = vortexEnabled;
				prevGridBg.vortexLineSpace = GRID_SIZE * 4 * curZoom;
			}
			if(nextGridBg != null)
			{
				nextGridBg.loadGrid(gridColorsOther[0], gridColorsOther[1]);
				nextGridBg.vortexLineEnabled = vortexEnabled;
				nextGridBg.vortexLineSpace = GRID_SIZE * 4 * curZoom;
			}
		}
	}

	function openNewChart()
	{
		var song:SwagSong = {
				song: 'Test',
				notes: [],
				events: [],
				bpm: 150.0,
				mania: 3,
				needsVoices: true,
				lanes: 2,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				speed: 1,
				stage: 'stage'
			};
		Song.chartPath = null;
		loadChart(song);
	}

	function prepareReload(){
		updateJsonData();
		loadMusic();
		reloadNotes();
		onChartLoaded();
		createGrids();
		updateHeads(true);
		
		autoSaveTime = 0;
		Conductor.songPosition = 0;
		if(FlxG.sound.music != null) FlxG.sound.music.time = 0;
		curSec = 0;
		loadSection();
		forceDataUpdate = true;
	}

	function onChartLoaded()
	{
		if(PlayState.SONG == null) return;

		// SONG TAB
		UI.songNameInputText.text = PlayState.SONG.song;
		UI.allowVocalsCheckBox.checked = (PlayState.SONG.needsVoices != false); //If the song for some reason does not have this value, it will be set to true

		UI.bpmStepper.value = PlayState.SONG.bpm;
		UI.scrollSpeedStepper.value = PlayState.SONG.speed;
		UI.audioOffsetStepper.value = Reflect.hasField(PlayState.SONG, 'offset') ? Reflect.field(PlayState.SONG, 'offset') : 0;
		Conductor.offset = UI.audioOffsetStepper.value;

		if(UI.playerDropDown != null) UI.playerDropDown.selectedLabel = PlayState.SONG.player1;
		if(UI.opponentDropDown != null) UI.opponentDropDown.selectedLabel = PlayState.SONG.player2;
		if(UI.girlfriendDropDown != null) UI.girlfriendDropDown.selectedLabel = PlayState.SONG.gfVersion;
		if(UI.lanesGfDropDown != null) UI.lanesGfDropDown.selectedLabel = PlayState.SONG.gfVersion;
		for (i in 3...UI.characterDropdowns.length)
		{
			var dropDown:PsychUIDropDownMenu = UI.characterDropdowns[i];
			if(dropDown == null) continue;

			var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
			dropDown.selectedLabel = (extraChars != null && extraChars.length > i - 3) ? extraChars[i - 3] : '';
		}
		UI.stageDropDown.selectedLabel = PlayState.SONG.stage;
		StageData.loadDirectory(PlayState.SONG);

		// DATA TAB
		UI.gameOverCharDropDown.selectedLabel = PlayState.SONG.gameOverChar;
		UI.gameOverSndInputText.text = PlayState.SONG.gameOverSound;
		UI.gameOverLoopInputText.text = PlayState.SONG.gameOverLoop;
		UI.gameOverRetryInputText.text = PlayState.SONG.gameOverEnd;

		UI.noRGBCheckBox.checked = (PlayState.SONG.disableNoteRGB == true);
		UI.pixel4kTextureCheckBox.checked = (PlayState.SONG.pixel4kTexture == true);

		UI.noteTextureInputText.text = PlayState.SONG.arrowSkin;
		UI.noteSplashesInputText.text = PlayState.SONG.splashSkin;
	}
	
	override function beatHit(){
		for(i => char in UI.characters){
			if (char != null && curBeat % char.danceEveryNumBeats == 0 && !char.getAnimationName().startsWith('sing') && !char.stunned){
				char.dance();
			}
		}
		super.beatHit();
	}

	override function stepHit(){
		super.stepHit();
		retriggerSustainAnimations();
	}

	function retriggerSustainAnimations():Void
	{
		if(FlxG.sound.music == null || !FlxG.sound.music.playing) return;

		for(note in curRenderedNotes)
		{
			if(note == null || note.isEvent || note.sustainLength <= 0) continue;

			var holdStart:Float = note.strumTime;
			var holdEnd:Float = note.strumTime + note.sustainLength;
			if(Conductor.songPosition <= holdStart || Conductor.songPosition > holdEnd) continue;

			var num:Int = note.songData[1];
			var fieldInt:Int = Std.int(num / GRID_COLUMNS_PER_PLAYER);
			var char:Character = UI.characters[fieldInt];
			if(note.gfNote)
				char = UI.characters[2] != null ? UI.characters[2] : null;

			if(char != null && note.noteType != "No Animation"){
				char.holdTimer = 0;
				char.playAnim("sing" + ExtraKeysHandler.instance.data.animations[ExtraKeysHandler.instance.data.keys[PlayState.SONG.mania].notes[note.noteData]].sing
				+ (note.noteType == "Alt Animation" ? "-alt" : ""), true);
			}
		}
	}

	var noteSelectionSine:Float = 0;
	var selectedNotes:Array<MetaNote> = [];
	var ignoreClickForThisFrame:Bool = false;
	var songFinished:Bool = false;

	var fileDialog:FileDialogHandler = new FileDialogHandler();
	var lastFocus:PsychUIInputText;

	var autoSaveTime:Float = 0;
	var autoSaveCap:Int = 2; //in minutes
	var backupLimit:Int = 10;

	var lastBeatHit:Int = 0;
	var isCrosshair:Bool = false;
	var intendedCamZoom:Float = 1;
	var intendedCamX:Float = 0;
	override function update(elapsed:Float){
		if(UI.pendingLaneAdd){
			UI.pendingLaneAdd = false;
			var oldLanes:Int = GRID_PLAYERS;
			var newLanes:Int = oldLanes + 1;
			if(newLanes <= 999) changeLanes(newLanes, oldLanes);
		}
		if(UI.pendingLaneRemoveIndex >= 0){
			var laneIndex:Int = UI.pendingLaneRemoveIndex;
			UI.pendingLaneRemoveIndex = -1;
			removeLane(laneIndex);
		}

		FlxG.camera.zoom = CoolUtil.fpsLerp(FlxG.camera.zoom, intendedCamZoom, 0.1);
		FlxG.camera.scroll.x = CoolUtil.fpsLerp(FlxG.camera.scroll.x, intendedCamX, 0.1);
		var topY:Float = (FlxG.camera.height / 2) * (1 - (1 / FlxG.camera.zoom));
		for(playerBox in UI.playerBoxes)
			playerBox.y = topY;
		for(icon in icons)
			icon.y = topY + 5;
		UI.lanesBox.y = topY;
		eventIcon.y = topY + 50;
		mustHitIndicator.y = topY + 30;

		if(!FlxG.keys.pressed.CONTROL){
			if(FlxG.keys.justPressed.I) intendedCamX += 40;
			if(FlxG.keys.justPressed.O) intendedCamX -= 40;
		}
			
		if(FlxG.mouse.justPressed || FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle) FlxG.sound.play(Paths.sound('chartingSounds/ClickDown'));
		if(FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight || FlxG.mouse.justReleasedMiddle) FlxG.sound.play(Paths.sound('chartingSounds/ClickUp'));
		if(FlxG.keys.justPressed.ANY) FlxG.sound.play(Paths.sound('chartingSounds/keyboard${FlxG.random.int(1,3)}'));
		if(FlxG.sound.music.playing) UI.songPosSlider.value = (FlxG.sound.music != null && FlxG.sound.music.length > 0) ? (Conductor.songPosition / FlxG.sound.music.length) * FlxG.height : 0;

		if(UI.infoBox.selectedName == "Information"){
			UI.infoBox.resize(CoolUtil.fpsLerp(UI.infoBox.bg.width, 220, 0.2), CoolUtil.fpsLerp(UI.infoBox.bg.height, 220, 0.2));
		}
		if(!fileDialog.completed)
		{
			lastFocus = PsychUIInputText.focusOn;
			return;
		}

		for (num => key in keysArray)
			_keysPressedBuffer[num] = FlxG.keys.checkStatus(key, JUST_PRESSED);

		if(autoSaveCap > 0)
		{
			autoSaveTime += elapsed / 60.0;
			if(autoSaveTime >= autoSaveCap #if debug || FlxG.keys.justPressed.NUMPADMULTIPLY #end)
			{
			var box:NPUICountdown = new NPUICountdown(100, 100, 200, 80, "AutoSaving in...", 5, function() {saveChart();}, function() {UI.showOutput("Autosave cancelled!", true);});
			box.cameras = [camUI];
			add(box);
			autoSaveTime = 0;
			}
		}

		ClientPrefs.toggleVolumeKeys((PsychUIInputText.focusOn == null && !FlxG.keys.pressed.CONTROL));

		var lastTime:Float = Conductor.songPosition;
		var holdingAlt:Bool = FlxG.keys.pressed.ALT;
		if(FlxG.sound.music != null)
		{
			if(PsychUIInputText.focusOn == null) //If not typing anything
			{
				if(FlxG.keys.justPressed.F12)
				{
					super.update(elapsed);
					editorPlayStatePrompt();
					lastFocus = PsychUIInputText.focusOn;
					return;
				}
				else if(FlxG.keys.justPressed.F1)
				{
					var vis:Bool = !fullTipText.visible;
					tipBg.visible = tipBg.active = fullTipText.visible = fullTipText.active = vis;
				}

				var goingBack:Bool = false;
				if(FlxG.keys.pressed.RBRACKET || (FlxG.keys.pressed.LBRACKET && (goingBack = true)))
				{
					if(holdingAlt)
					{
						if(playbackRate != 1)
						{
							playbackRate = 1;
							setPitch();
						}
					}
					else
					{
						playbackRate = FlxMath.bound(playbackRate + elapsed * (!goingBack ? 1 : -1), UI.playbackSlider.min, UI.playbackSlider.max);
						setPitch();
					}
					UI.playbackSlider.value = playbackRate;
				}

				if(vortexEnabled && _keysPressedBuffer.contains(true))
				{
					var typeSelected:String = noteTypes[UI.noteTypeDropDown.selectedIndex];
					if(typeSelected != null)
					{
						typeSelected = typeSelected.trim();
						if(typeSelected.length < 1) typeSelected = null;
					}

					var sectionStart:Float = cachedSectionTimes[curSec];
					var strumTime:Float = Conductor.songPosition - sectionStart;
					strumTime -= strumTime % (Conductor.stepCrochet * 16 / curQuant);
					strumTime += sectionStart;

					var deletedNotes:Array<MetaNote> = [];
					var addedNotes:Array<MetaNote> = [];
					for (num => press in _keysPressedBuffer)
					{
						if(!press) continue;

						var didDelete:Bool = false;
						for (note in curRenderedNotes)
						{
							if(note == null || note.isEvent) continue;

							if(note.songData[1] == num && Math.abs(strumTime - note.strumTime) < 1)
							{
								deletedNotes.push(note);
								FlxG.sound.play(Paths.sound('chartingSounds/noteErase'));
								didDelete = true;
								break;
							}
						}

						if(didDelete) continue;

						var didAdd:Bool = false;
						var noteSetupData:Array<Dynamic> = [strumTime, num, 0];
						if(typeSelected != null) noteSetupData.push(typeSelected);
	
						var noteAdded:MetaNote = createNote(noteSetupData);
						for (num in sectionFirstNoteID...notes.length)
						{
							var note = notes[num];
							if(note.strumTime >= strumTime)
							{
								notes.insert(num, noteAdded);
								didAdd = true;
								break;
							}
						}
						if(!didAdd) notes.push(noteAdded);
						addedNotes.push(noteAdded);
						FlxG.sound.play(Paths.sound('chartingSounds/noteLay'));
					}

					if(deletedNotes.length > 0)
					{
						var wasSelected:Bool = false;
						for (note in deletedNotes)
						{
							if(selectedNotes.contains(note))
							{
								selectedNotes.remove(note);
								wasSelected = true;
							}
							notes.remove(note);
						}
						if(wasSelected) onSelectNote();
						addUndoAction(DELETE_NOTE, {notes: deletedNotes});
					}
					if(addedNotes.length > 0)
						addUndoAction(ADD_NOTE, {notes: addedNotes});

					softReloadNotes(true);
				}
				else if(!FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.A != FlxG.keys.justPressed.D && !holdingAlt)
				{
					if(FlxG.sound.music.playing)
						setSongPlaying(false);

					var shiftAdd:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;

					if(FlxG.keys.justPressed.A)
					{
						if(curSec - shiftAdd < 0) shiftAdd = curSec;

						if(shiftAdd > 0)
						{
							loadSection(curSec - shiftAdd);
							Conductor.songPosition = FlxG.sound.music.time = cachedSectionTimes[curSec] - Conductor.offset + 0.000001;
						}
					}
					else if(FlxG.keys.justPressed.D)
					{
						if(curSec + shiftAdd >= PlayState.SONG.notes.length) shiftAdd = PlayState.SONG.notes.length - curSec - 1;
						
						if(shiftAdd > 0)
						{
							loadSection(curSec + shiftAdd);
							Conductor.songPosition = FlxG.sound.music.time = cachedSectionTimes[curSec] - Conductor.offset + 0.000001;
						}
					}
				}
				else if(FlxG.keys.justPressed.HOME)
				{
					setSongPlaying(false);
					Conductor.songPosition = FlxG.sound.music.time = 0;
					loadSection(0);
				}
				else if(FlxG.keys.justPressed.END)
				{
					setSongPlaying(false);
					Conductor.songPosition = FlxG.sound.music.time = FlxG.sound.music.length - 1;
					loadSection(PlayState.SONG.notes.length - 1);
				}
				else if(FlxG.keys.justPressed.R)
				{
					var timeToGoBack:Float = 0;
					if(!FlxG.keys.pressed.SHIFT) timeToGoBack = cachedSectionTimes[curSec] + (curSec > 0 ? 0.000001 : 0);
					else loadSection(0);
					Conductor.songPosition = FlxG.sound.music.time = vocals.time = opponentVocals.time = timeToGoBack;
				}
				else if(FlxG.keys.pressed.W != FlxG.keys.pressed.S || FlxG.mouse.wheel != 0)
				{
					if(FlxG.sound.music.playing)
						setSongPlaying(false);

					if(UI.mouseSnapCheckBox.checked && FlxG.mouse.wheel != 0)
					{
						var snap:Float = Conductor.stepCrochet / (curQuant/16) / curZoom;
						var timeAdd:Float = (FlxG.keys.pressed.SHIFT ? 4 : 1) / (holdingAlt ? 4 : 1) * -FlxG.mouse.wheel * snap;
						var time:Float = Math.round((FlxG.sound.music.time + timeAdd) / snap) * snap;
						if(time > 0) time += 0.000001; //goes at the start of a section more properly
						FlxG.sound.music.time = time;
					}
					else
					{
						var speedMult:Float = (FlxG.keys.pressed.SHIFT ? 4 : 1) * (FlxG.mouse.wheel != 0 ? 4 : 1) / (holdingAlt ? 4 : 1);
						if(FlxG.keys.pressed.W || FlxG.mouse.wheel > 0)
							FlxG.sound.music.time -= Conductor.crochet * speedMult * 1.5 * elapsed / curZoom;
						else if((FlxG.keys.pressed.S && !FlxG.keys.pressed.CONTROL)|| FlxG.mouse.wheel < 0)
							FlxG.sound.music.time += Conductor.crochet * speedMult * 1.5 * elapsed / curZoom;
					}

					FlxG.sound.music.time = FlxMath.bound(FlxG.sound.music.time, 0, FlxG.sound.music.length - 1);
					if(FlxG.sound.music.playing) setSongPlaying(!FlxG.sound.music.playing);
				}
				else if(FlxG.keys.justPressed.SPACE)
				{
					setSongPlaying(!FlxG.sound.music.playing);
				}
			}

			if(!songFinished) Conductor.songPosition = FlxMath.bound(FlxG.sound.music.time + Conductor.offset, 0, FlxG.sound.music.length - 1);
			updateScrollY();
			UI.songPosSlider.value = (FlxG.sound.music != null && FlxG.sound.music.length > 0) ? (Conductor.songPosition / FlxG.sound.music.length) * FlxG.height : 0;
		}

		super.update(elapsed);
		
		if(songFinished)
		{
			onSongComplete();
			lastTime = FlxG.sound.music.time;
			songFinished = false;
		}
		else if(FlxG.sound.music != null)
		{
			if(FlxG.sound.music.time >= vocals.length)
				vocals.pause();
			if(FlxG.sound.music.time >= opponentVocals.length)
				opponentVocals.pause();

			while(curSec > 0 && Conductor.songPosition < cachedSectionTimes[curSec])
				loadSection(curSec - 1);
			while(curSec < cachedSectionTimes.length - 1 && Conductor.songPosition >= cachedSectionTimes[curSec + 1])
				loadSection(curSec + 1);
		}

		if(PsychUIInputText.focusOn == null && lastFocus == null)
		{
			var doCut:Bool = false;
			var canContinue:Bool = true;
			if(FlxG.keys.justPressed.ENTER)
			{
				goToPlayState();
				return;
			}
			else if(FlxG.keys.pressed.CONTROL && !isMovingNotes && (FlxG.keys.justPressed.Z || FlxG.keys.justPressed.Y || FlxG.keys.justPressed.X ||
				FlxG.keys.justPressed.C || FlxG.keys.justPressed.V || FlxG.keys.justPressed.A || FlxG.keys.justPressed.S || FlxG.keys.justPressed.PLUS || FlxG.keys.justPressed.MINUS))
			{
				canContinue = false;
				if(FlxG.keys.justPressed.PLUS && intendedCamZoom < 1.09)
					intendedCamZoom += 0.1;
				if(FlxG.keys.justPressed.MINUS && intendedCamZoom > 0.41)
					intendedCamZoom -= 0.1;
				if(FlxG.keys.justPressed.S)
					saveChart();
				else if(FlxG.keys.justPressed.Z)
					undo();
				else if(FlxG.keys.justPressed.Y)
					redo();
				else if((doCut = FlxG.keys.justPressed.X) || FlxG.keys.justPressed.C) // Cut (Ctrl + X) and Copy (Ctrl + C)
				{
					if(selectedNotes.length > 0)
					{
						copiedNotes = [];
						copiedEvents = [];
						var pushedNotes:Array<Array<Dynamic>> = [];

						for (note in selectedNotes)
						{
							if(note == null) continue;

							var copied:Array<Dynamic> = makeNoteDataCopy(note.songData, note.isEvent);
							pushedNotes.push(copied);
							if(note.isEvent) copiedEvents.push(copied);
							else copiedNotes.push(copied);
						}
						pushedNotes.sort((a:Array<Dynamic>, b:Array<Dynamic>) -> FlxSort.byValues(FlxSort.ASCENDING, a[0], b[0]));
						
						var minTime:Float = pushedNotes[0][0];
						for (note in pushedNotes)
							note[0] -= minTime;
					}
				}
				else if(FlxG.keys.justPressed.V) // Paste (Ctrl + V)
				{
					if(copiedNotes.length > 0 || copiedEvents.length > 0)
					{
						selectionBox.visible = false;
						stopMovingNotes();
						resetSelectedNotes();
						selectedNotes = pasteCopiedNotesToSection();
						selectedNotes.sort(CoolUtil.sortByTime);

						var didFind:Bool = false;
						var minNoteData:Float = Math.POSITIVE_INFINITY;
						for (note in selectedNotes)
						{
							if(note == null || note.isEvent) continue;

							if(minNoteData > note.songData[1]) minNoteData = note.songData[1];
							didFind = true;
						}
						if(!didFind) minNoteData = 0;
						
						var pushedNotes:Array<MetaNote> = [];
						var pushedEvents:Array<EventMetaNote> = [];
						for (note in selectedNotes)
						{
							if(note == null) continue;

							if(!note.isEvent)
							{
								note.changeNoteData(Std.int(note.songData[1] - minNoteData));
								pushedNotes.push(note);
							}
							else pushedEvents.push(cast (note, EventMetaNote));
						}
						addUndoAction(ADD_NOTE, {notes: pushedNotes, events: pushedEvents});
						moveSelectedNotes(Std.int(minNoteData), selectedNotes[0].y);
					}
				}
				else if(FlxG.keys.justPressed.A) // Select All (Ctrl + A)
				{
					var sel = selectedNotes;
					selectedNotes = curRenderedNotes.members.copy();
					addUndoAction(SELECT_NOTE, {old: sel, current: selectedNotes.copy()});
					onSelectNote();
				}
			}
			
			if(doCut || FlxG.keys.justPressed.DELETE || FlxG.keys.justPressed.BACKSPACE || (isMovingNotes && (FlxG.mouse.justPressedRight || FlxG.keys.justPressed.ESCAPE))) // Delete button
			{
				if(selectedNotes.length > 0)
				{
					var removedNotes:Array<MetaNote> = [];
					var removedEvents:Array<EventMetaNote> = [];
					while(selectedNotes.length > 0)
					{
						var note:MetaNote = selectedNotes[0];
						selectedNotes.shift();
						if(note == null) continue;
		
						var kind:String = !note.isEvent ? 'note' : 'event';
						if(!note.isEvent)
						{
							notes.remove(note);
							removedNotes.push(note);
						}
						else
						{
							var ev:EventMetaNote = cast (note, EventMetaNote);
							events.remove(ev);
							removedEvents.push(ev);
						}
					}
					movingNotes.clear();
					isMovingNotes = false;
					selectedNotes = [];
					onSelectNote();
					softReloadNotes();
					addUndoAction(DELETE_NOTE, {notes: removedNotes, events: removedEvents});
				}
			}
			else if(canContinue)
			{
				if(FlxG.keys.justPressed.LEFT != FlxG.keys.justPressed.RIGHT) //Lower/Higher quant
				{
					if(FlxG.keys.justPressed.LEFT)
						curQuant = quantizations[Std.int(Math.max(quantizations.indexOf(curQuant) - 1, 0))];
					else
						curQuant = quantizations[Std.int(Math.min(quantizations.indexOf(curQuant) + 1, quantizations.length - 1))];
					forceDataUpdate = true;
				}
				else if(FlxG.keys.justPressed.Z != FlxG.keys.justPressed.X) //Decrease/Increase Zoom
				{
					if(FlxG.keys.justPressed.Z)
						curZoom = zoomList[Std.int(Math.max(zoomList.indexOf(curZoom) - 1, 0))];
					else
						curZoom = zoomList[Std.int(Math.min(zoomList.indexOf(curZoom) + 1, zoomList.length - 1))];
	
					notes.sort(CoolUtil.sortByTime);
					var noteSec:Int = 0;
					var nextSectionTime:Float = cachedSectionTimes[noteSec + 1];
					var curSectionTime:Float = cachedSectionTimes[noteSec];
					for (num => note in notes)
					{
						if(note == null) continue;
			
						while(cachedSectionTimes[noteSec + 1] <= note.strumTime)
						{
							noteSec++;
							nextSectionTime = cachedSectionTimes[noteSec + 1];
							curSectionTime = cachedSectionTimes[noteSec];
						}
						positionNoteYOnTime(note, noteSec);
						note.updateSustainToZoom(cachedSectionCrochets[noteSec] / 4, curZoom);
					}
	
					for (event in events)
					{
						var secNum:Int = 0;
						for (time in cachedSectionTimes)
						{
							if(time > event.strumTime) break;
							secNum++;
						}
						positionNoteYOnTime(event, secNum);
					}
					loadSection();
					UI.showOutput('Zoom: ${Math.round(curZoom * 100)}%');
					updateScrollY();
				}
			}
		}

		if(selectionBox.visible)
		{
			if(FlxG.mouse.releasedRight)
			{
				var sel = selectedNotes.copy();
				updateSelectionBox();
				if(!FlxG.keys.pressed.SHIFT && !holdingAlt)
					resetSelectedNotes();

				var selectionBounds = selectionBox.getScreenBounds(null, camUI);
				for(note in curRenderedNotes){
					if(note == null) continue;

					if(!selectedNotes.contains(note) || holdingAlt){
						var noteBounds = note.getScreenBounds(null, camUI);
						noteBounds.top -= scrollY;
						noteBounds.bottom -= scrollY;
						noteBounds.left -= FlxG.camera.scroll.x;
						noteBounds.right -= FlxG.camera.scroll.x;

						if(selectionBounds.overlaps(noteBounds)){
							if(holdingAlt && selectedNotes.contains(note)){
								selectedNotes.remove(note);
								note.colorTransform.redMultiplier = note.colorTransform.greenMultiplier = note.colorTransform.blueMultiplier = 1;
								if(note.animation.curAnim != null) note.animation.curAnim.curFrame = 0;
							} else selectedNotes.push(note);
							onSelectNote();
						}
					}
				}
				selectionBox.visible = false;
				addUndoAction(SELECT_NOTE, {old: sel, current: selectedNotes.copy()});
			}
			else if(FlxG.mouse.justMoved)
				updateSelectionBox();
		}
		else if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
		{
			selectionBox.setPosition(FlxG.mouse.viewX, FlxG.mouse.viewY);
			selectionStart.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
			selectionBox.visible = true;
			updateSelectionBox();
		}

		var overlapsUI:Bool = UI.isOverlapping();

		if(FlxG.mouse.justPressed && overlapsUI)
			ignoreClickForThisFrame = true;

		var minX:Float = gridBg.x;
		if(SHOW_EVENT_COLUMN && lockedEvents) minX += GRID_SIZE;

		if(isMovingNotes && FlxG.mouse.justReleased)
			stopMovingNotes();

		if(FlxG.mouse.x >= minX && FlxG.mouse.x < gridBg.x + gridBg.width && !overlapsUI){
			Mouse.cursor = MouseCursor.CROSSHAIR;
			isCrosshair = true;
			var diffX:Float = FlxG.mouse.x - gridBg.x;
			var diffY:Float = FlxG.mouse.y - gridBg.y;
			if(!FlxG.keys.pressed.SHIFT)
				diffY -= diffY % (GRID_SIZE / (curQuant/16));

			if(nextGridBg.visible) diffY = Math.min(diffY, gridBg.height + nextGridBg.height);
			else diffY = Math.min(diffY, gridBg.height);

			if(prevGridBg.visible) diffY = Math.max(diffY, -prevGridBg.height);
			else diffY = Math.max(diffY, 0);

			var noteData:Int = Math.floor(diffX / GRID_SIZE);
			dummyArrow.visible = !selectionBox.visible;
			dummyArrow.x = gridBg.x + noteData * GRID_SIZE;
			if(SHOW_EVENT_COLUMN)
				noteData--;

			if(FlxG.keys.pressed.SHIFT || FlxG.mouse.y >= gridBg.y || !prevGridBg.visible)
				dummyArrow.y = gridBg.y + diffY;
			else
			{
				var t:Float = (diffY - (GRID_SIZE / (curQuant/16)));
				if(FlxG.mouse.y >= gridBg.y) t *= curZoom;
				dummyArrow.y = gridBg.y + t;
			}
			if(isMovingNotes)
			{
				var nData:Int = Std.int(Math.max(0, noteData));
				if(movingNotesLastData != nData)
				{
					FlxG.sound.play(Paths.sound("chartingSounds/stretchSNAP_UI"));
					var isFirst:Bool = true;
					var movingNotesMinData:Int = 0;
					var movingNotesMaxData:Int = 0;
					for (note in selectedNotes)
					{
						if(note == null || note.isEvent) continue;

						var data:Int = note.songData[1];
						if(isFirst || data < movingNotesMinData) movingNotesMinData = data;
						if(data > movingNotesMaxData) movingNotesMaxData = data;
						isFirst = false;
					}

					var diff:Int = nData - movingNotesLastData;
					var maxn:Int = (GRID_PLAYERS * GRID_COLUMNS_PER_PLAYER) - 1;
					movingNotesMinData += diff;
					movingNotesMaxData += diff;
					if(movingNotesMinData < 0)
						diff -= movingNotesMinData;
					else if(movingNotesMaxData > maxn)
						diff -= movingNotesMaxData - maxn;

					for (note in movingNotes)
					{
						if(note == null || note.isEvent) continue;

						var lane:Int = note.songData[1];

						note.changeNoteData(lane+diff);
						note.setSustainLength(note.sustainLength, Conductor.stepCrochet, curZoom); // Refresh the sustain

						positionNoteXByData(note);
					}
				}
				movingNotesLastData = nData;

				if(dummyArrow.y != movingNotesLastY)
				{
					FlxG.sound.play(Paths.sound("chartingSounds/stretchSNAP_UI"));
					var diff:Float = dummyArrow.y - movingNotesLastY;
					for (note in movingNotes)
					{
						if(note == null) continue;

						note.chartY += diff;
						var row:Float = (note.chartY / GRID_SIZE) / curZoom;
						var noteSecRow:Int = 0;
						while(noteSecRow + 1 < cachedSectionRow.length && cachedSectionRow[noteSecRow + 1] <= row)
						{
							noteSecRow++;
						}

						note.setStrumTime(Math.max(-5000, note.strumTime + (diff * cachedSectionCrochets[noteSecRow] / 4) / GRID_SIZE / curZoom));
						positionNoteYOnTime(note, noteSecRow);
						
						if(!note.isEvent && note.hasSustain)
							note.updateSustainToZoom(cachedSectionCrochets[noteSecRow] / 4, curZoom);
						
						if(note.isEvent) cast (note, EventMetaNote).updateEventText();
					}
					movingNotesLastY = dummyArrow.y;
				}
			}
			else if(FlxG.mouse.justPressed && !ignoreClickForThisFrame)
			{
				if(FlxG.keys.pressed.CONTROL && FlxG.mouse.justPressed)
				{
					if(selectedNotes.length > 0)
						moveSelectedNotes(noteData, dummyArrow.y);
					else
						UI.showOutput('You must select notes to move them!', true);
				}
				else if(FlxG.mouse.x >= gridBg.x && FlxG.mouse.x < gridBg.x + gridBg.width)
				{
					var closeNotes:Array<MetaNote> = curRenderedNotes.members.filter(function(note:MetaNote)
					{
						var chartY:Float = FlxG.mouse.y - note.chartY;
						return ((note.isEvent && noteData < 0) || (!note.isEvent && note.songData[1] == noteData)) && chartY >= 0 && chartY < GRID_SIZE;
					});
					closeNotes.sort(function(a:MetaNote, b:MetaNote) return Math.abs(a.strumTime - FlxG.mouse.y) < Math.abs(b.strumTime - FlxG.mouse.y) ? 1 : -1);

					var closest = closeNotes[0];
					if(closest != null && (!closest.isEvent || !lockedEvents))
					{
						if(FlxG.keys.pressed.SHIFT || holdingAlt) // Select Note/Event
						{
							var sel = selectedNotes.copy();
							if(!selectedNotes.contains(closest))
							{
								selectedNotes.push(closest);
								addUndoAction(SELECT_NOTE, {old: sel, current: selectedNotes.copy()});
							}
							else if(!holdingAlt)
							{
								resetSelectedNotes();
								selectedNotes.remove(closest);
								addUndoAction(SELECT_NOTE, {old: sel, current: selectedNotes.copy()});
							}
						}
						else if(!FlxG.keys.pressed.CONTROL)
						{
							var kind:String = !closest.isEvent ? 'note' : 'event';
							if(!closest.isEvent)
								notes.remove(closest);
							else
								events.remove(cast (closest, EventMetaNote));

							selectedNotes.remove(closest);
							curRenderedNotes.remove(closest, true);
							addUndoAction(DELETE_NOTE, !closest.isEvent ? {notes: [closest]} : {events: [closest]});
							FlxG.sound.play(Paths.sound('chartingSounds/noteErase'));
						}
						if(selectedNotes.length == 1) onSelectNote();
						forceDataUpdate = true;
					}
					else if(!holdingAlt && FlxG.mouse.y >= gridBg.y && FlxG.mouse.y < gridBg.y + gridBg.height) // Add note
					{
						var strumTime:Float = (diffY / GRID_SIZE * Conductor.stepCrochet / curZoom) + cachedSectionTimes[curSec];
						if(noteData >= 0)
						{
							var didAdd:Bool = false;

							var noteSetupData:Array<Dynamic> = [strumTime, noteData, 0];
							var typeSelected:String = noteTypes[UI.noteTypeDropDown.selectedIndex].trim();
							if(typeSelected != null && typeSelected.length > 0)
								noteSetupData.push(typeSelected);

							var noteAdded:MetaNote = createNote(noteSetupData);
							for (num in sectionFirstNoteID...notes.length)
							{
								var note = notes[num];
								if(note.strumTime >= strumTime)
								{
									notes.insert(num, noteAdded);
									didAdd = true;
									break;
								}
							}
							if(!didAdd) notes.push(noteAdded);
							FlxG.sound.play(Paths.sound('chartingSounds/noteLay'));

							if(!holdingAlt)
								resetSelectedNotes();

							selectedNotes.push(noteAdded);
							addUndoAction(ADD_NOTE, {notes: [noteAdded]});
						}
						else if(!lockedEvents)
						{
							var didAdd:Bool = false;
							var eventAdded:EventMetaNote;
							FlxG.sound.play(Paths.sound('chartingSounds/noteLay'));
							if (UI.eventsBox != null && UI.eventsBox.selectedName == "Modchart")
							{
								var action:String = (UI.actionsDropdown != null && UI.actionsDropdown.selectedLabel != null) ? UI.actionsDropdown.selectedLabel : "";
								var modifier:String = (UI.modifierInput != null) ? UI.modifierInput.text : "";
								var timeStr:String = (UI.timeStepper != null) ? Std.string(UI.timeStepper.value) : "";
								var valueStr:String = (UI.valueStepper != null) ? Std.string(UI.valueStepper.value) : "";
								var easeStr:String = (UI.easeInput != null) ? UI.easeInput.text : "";
								var playerStr:String = (UI.playerStepper != null) ? Std.string(UI.playerStepper.value) : "";
								var combined:String = action + "," + modifier + "," + timeStr + "," + valueStr + "," + easeStr + "," + playerStr + ",-1";

								var evData:Array<Dynamic> = [strumTime, [["Modchart Event", combined, ""]]];
								eventAdded = createEvent(evData);
							}
							else
							{
								var evName:String = eventsList[Std.int(Math.max(UI.eventDropDown.selectedIndex, 0))][0];
								var evData:Array<Dynamic> = [strumTime, [[evName, UI.value1InputText.text, UI.value2InputText.text]]];
								eventAdded = createEvent(evData);
							}
							for (num in sectionFirstEventID...events.length)
							{
								var event = events[num];
								if(event.strumTime >= strumTime)
								{
									events.insert(num, eventAdded);
									didAdd = true;
									break;
								}
							}
							if(!didAdd) events.push(eventAdded);

							if(!holdingAlt)
								resetSelectedNotes();

							selectedNotes.push(eventAdded);
							addUndoAction(ADD_NOTE, {events: [eventAdded]});
						}
						onSelectNote();
						softReloadNotes();
					}
				}
			}
		}
		else {
			if(!ignoreClickForThisFrame){
				if(FlxG.mouse.justPressed)
					resetSelectedNotes();

				dummyArrow.visible = false;
			}
			if(isCrosshair){
				isCrosshair = false;
				Mouse.cursor = MouseCursor.DEFAULT;
			}
		}
		ignoreClickForThisFrame = false;

		if(Conductor.songPosition != lastTime || forceDataUpdate)
		{
			var curTime:String = FlxStringUtil.formatTime(Conductor.songPosition / 1000, true);
			var songLength:String = (FlxG.sound.music != null) ? FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, true) : '???';
			var str:String =  '$curTime / $songLength' +
							  '\n\nSection: $curSec' +
							  '\nBeat: $curBeat' +
							  '\nStep: $curStep' +
							  '\n\nBeat Snap: ${curQuant} / 16' +
							  '\nSelected: ${selectedNotes.length}';

			if(str != UI.infoText.text)
			{
				UI.infoText.text = str;
				if(UI.infoText.autoSize) UI.infoText.autoSize = false;
			}

			var vortexPlaying:Bool = (vortexEnabled && FlxG.sound.music != null && FlxG.sound.music.playing);
			var canPlayHitSound:Bool = (FlxG.sound.music != null && FlxG.sound.music.playing && lastTime < Conductor.songPosition);
			var hitSoundPlayed:Array<Bool> = [for (i in 0...UI.hitsoundSliders.length) true];
			for (note in curRenderedNotes)
			{
				if(note == null || note.isEvent) continue;

				note.alpha = (note.strumTime >= Conductor.songPosition) ? 1 : 0.6;
				if(Conductor.songPosition > note.strumTime && lastTime <= note.strumTime)
				{
					if(canPlayHitSound)
					{
						var fID:Int = note.fieldID;
						if(fID >= 0 && fID < UI.hitsoundSliders.length && hitSoundPlayed[fID])
						{
							var hitVol:Float = UI.hitsoundSliders[fID].value;
							if(hitVol > 0)
								FlxG.sound.play(Paths.sound(note.mustPress ? 'chartingSounds/hitNotePlayer' : 'chartingSounds/hitNoteOpponent'), hitVol);
							hitSoundPlayed[fID] = false;
						}
					}

					var num:Int = note.songData[1];
					var fieldInt:Int = Std.int(num / GRID_COLUMNS_PER_PLAYER);
					var char:Character = UI.characters[fieldInt];
					if(note.gfNote){
						if(UI.characters[2] != null){
							char = UI.characters[2];
						} else {
							char = null;
						}
					}
					if (char != null && note.noteType != "No Animation"){
						char.holdTimer = 0;
						char.playAnim("sing" + ExtraKeysHandler.instance.data.animations[ExtraKeysHandler.instance.data.keys[PlayState.SONG.mania].notes[note.noteData]].sing
						+ (note.noteType == "Alt Animation" ? "-alt" : ""), true);
					}
					if(vortexPlaying)
					{
						var strumNote:StrumNote = strumLineNotes.members[num];
						if(strumNote != null)
						{
							strumNote.playAnim('confirm', true);
							strumNote.resetAnim = Math.max(Conductor.stepCrochet * 1.25, note.sustainLength) / 1000 / playbackRate;
						}
					}
				}
			}
			forceDataUpdate = false;
			
			// moved from beatHit()
			if(UI.metronomeStepper.value > 0 && lastBeatHit != curBeat)
				FlxG.sound.play(Paths.sound('Metronome_Tick'), UI.metronomeStepper.value);

			lastBeatHit = curBeat;
		}

		if(selectedNotes.length > 0)
		{
			noteSelectionSine += elapsed;
			var sineValue:Float = 0.75 + Math.cos(Math.PI * noteSelectionSine * (isMovingNotes ? 8 : 2)) / 4;

			var qPress = FlxG.keys.justPressed.Q;
			var ePress = FlxG.keys.justPressed.E;
			var addSus = (FlxG.keys.pressed.SHIFT ? 4 : 1) * (Conductor.stepCrochet / 2);
			if(qPress) addSus *= -1;

			if(qPress != ePress && selectedNotes.length != 1)
				UI.susLengthStepper.value += addSus;

			var noteSec:Int = 0;
			for (note in selectedNotes)
			{
				if(note == null || !note.exists) continue;

				if(!note.isEvent)
				{
					if(qPress != ePress)
					{
						while(cachedSectionTimes.length > noteSec + 1 && cachedSectionTimes[noteSec + 1] <= note.strumTime)
							noteSec++;

						note.setSustainLength(note.sustainLength + addSus, cachedSectionCrochets[noteSec] / 4, curZoom);
						if(selectedNotes.length == 1)
							UI.susLengthStepper.value = note.sustainLength;
					}
					note.animation.update(elapsed); //let selected notes be animated for better visibility
				}
				note.colorTransform.redMultiplier = note.colorTransform.greenMultiplier = note.colorTransform.blueMultiplier = sineValue;
			}
		}
		else noteSelectionSine = 0;

		easedScrollY = CoolUtil.smoothLerpPrecision(easedScrollY, scrollY, elapsed, SCROLL_EASE_DURATION);
		easedScrollY = CoolUtil.snap(easedScrollY, scrollY, 1 / 1000);
		FlxG.camera.scroll.y = easedScrollY;
		lastFocus = PsychUIInputText.focusOn;

		for(i => char in UI.characters){
			if(char == null) continue;
			var idleAnim:String = char.danceIdle ? ('danceLeft' + char.idleSuffix) : ('idle' + char.idleSuffix);
			var idleOffset:Array<Dynamic> = char.animOffsets.exists(idleAnim) ? char.animOffsets.get(idleAnim) : [0, 0];

			var offX:Float = -idleOffset[0] * char.scale.x;
			var offY:Float = idleOffset[1] * char.scale.y;

			var offsets:Array<Float> = [];
			if (char.animOffsets != null && char.anim != null && char.anim.curAnim != null && char.animOffsets.exists(char.anim.curAnim.name)){
				var daOffset = char.animOffsets.get(char.anim.curAnim.name);
				offsets = [daOffset[0] * char.scale.x, daOffset[1] * char.scale.y];
			}

			char.updateHitbox();
			char.x = UI.characterBoxes[i].x + (UI.characterBoxes[i].bg.width / 2) - ((char.frameWidth * char.scale.x) / 2) + offX - offsets[0];
			char.y = UI.characterBoxes[i].y + (UI.characterBoxes[i].bg.height / 2) - ((char.frameHeight * char.scale.y) / 2) + offY - offsets[1];
		}
	}

	function moveSelectedNotes(noteData:Int = 0, lastY:Float)
	{
		var originalNotes:Array<MetaNote> = [];
		var originalEvents:Array<EventMetaNote> = [];
		var movedNotes:Array<MetaNote> = [];
		var movedEvents:Array<EventMetaNote> = [];
		for (note in selectedNotes)
		{
			if(note == null) continue;

			if(!note.isEvent)
			{
				notes.remove(note);
				var secNum:Int = 0;
				for (time in cachedSectionTimes)
				{
					if(time > note.strumTime) break;
					secNum++;
				}
				originalNotes.push(note);
				var mov:MetaNote = createNote(note.songData, secNum);
				mov.rgbShader.enabled = note.rgbShader.enabled;
				movingNotes.add(mov);
				movedNotes.push(mov);
			}
			else
			{
				events.remove(cast (note, EventMetaNote));
				originalEvents.push(cast (note, EventMetaNote));
				var mov:EventMetaNote = createEvent(note.songData);
				movingNotes.add(mov);
				movedEvents.push(mov);
			}
		}
		selectedNotes = movingNotes.members.copy();
		isMovingNotes = true;
		movingNotesLastY = lastY;
		movingNotesLastData = noteData;
		movingNotes.sort(cast CoolUtil.sortByTime);
		addUndoAction(MOVE_NOTE, {originalNotes: originalNotes, originalEvents: originalEvents, movedNotes: movedNotes, movedEvents: movedEvents});
		softReloadNotes();
	}

	function stopMovingNotes() //This turns moving notes into saved notes
	{
		var pushedNotes:Array<MetaNote> = [];
		var pushedEvents:Array<EventMetaNote> = [];
		movingNotes.forEachAlive(function(note:MetaNote)
		{
			if(!note.isEvent)
			{
				notes.push(note);
				pushedNotes.push(note);
			}
			else
			{
				events.push(cast (note, EventMetaNote));
				pushedEvents.push(cast (note, EventMetaNote));
			}
		});
		notes.sort(CoolUtil.sortByTime);
		events.sort(CoolUtil.sortByTime);
		movingNotes.clear();
		isMovingNotes = false;
		softReloadNotes();
	}

	function makeNoteDataCopy(originalData:Array<Dynamic>, isEvent:Bool)
	{
		var dataCopy:Array<Dynamic> = originalData.copy();
		if(isEvent)
		{
			var eventGrp:Array<Array<Dynamic>> = cast dataCopy[1].copy();
			for (num => subEvent in eventGrp)
				eventGrp[num] = subEvent.copy();

			dataCopy[1] = eventGrp;
		}
		return dataCopy;
	}

	function updateScrollY()
	{
		var secStartTime:Null<Float> = cast cachedSectionTimes[curSec];
		var secCrochet:Null<Float> = cast cachedSectionCrochets[curSec];
		var secRows:Null<Float> = cast cachedSectionRow[curSec];
		if(secStartTime == null || secCrochet == null || secRows == null) return;

		scrollY = (((Conductor.songPosition - secStartTime) / secCrochet * GRID_SIZE * 4) + (secRows * GRID_SIZE)) * curZoom - FlxG.height/2;
	}

	function updateSelectionBox()
	{
		var diffX:Float = FlxG.mouse.viewX - selectionStart.x;
		var diffY:Float = FlxG.mouse.viewY - selectionStart.y;
		selectionBox.setPosition(selectionStart.x, selectionStart.y);

		if(diffX < 0) //Fixes negative X scale
		{
			diffX = Math.abs(diffX);
			selectionBox.x -= diffX;
		}
		if(diffY < 0) //Fixes negative Y scale
		{
			diffY = Math.abs(diffY);
			selectionBox.y -= diffY;
		}
		selectionBox.scale.set(diffX, diffY);
		selectionBox.updateHitbox();
	}

	function resetSelectedNotes()
	{
		for (note in selectedNotes)
		{
			if(note == null || !note.exists) continue;

			note.colorTransform.redMultiplier = note.colorTransform.greenMultiplier = note.colorTransform.blueMultiplier = 1;
			if(note.animation.curAnim != null) note.animation.curAnim.curFrame = 0;
		}
		selectedNotes = [];
		onSelectNote();
		forceDataUpdate = true;
	}

	function onSelectNote()
	{
		if(selectedNotes.length == 1) //Only one note selected
		{
			var note:MetaNote = selectedNotes[0];
			UI.strumTimeStepper.value = note.strumTime;
			if(!note.isEvent) //Normal note
			{
				if(!note.isEvent)
				{
					susLengthLastVal = UI.susLengthStepper.value = note.sustainLength;
					UI.noteTypeDropDown.selectedIndex = Std.int(Math.max(0, noteTypes.indexOf(note.noteType)));
				}
				else
				{
					susLengthLastVal = UI.susLengthStepper.value = 0;
					UI.noteTypeDropDown.selectedLabel = '';
				}
			}
			else //Event note
			{
				var eventNote:EventMetaNote = cast (selectedNotes[0], EventMetaNote);
				updateSelectedEventText();
			}
		}
		else if(selectedNotes.length > 1)
		{
			UI.susLengthStepper.min = -UI.susLengthStepper.max;
			susLengthLastVal = UI.susLengthStepper.value = 0;
			UI.strumTimeStepper.value = selectedNotes[0].strumTime;
			UI.noteTypeDropDown.selectedLabel = '';
			UI.eventDropDown.selectedLabel = '';
			UI.value1InputText.text = '';
			UI.value2InputText.text = '';
		}
		forceDataUpdate = true;
	}

	function updateSelectedEventText()
	{
		if(selectedNotes.length == 1 && selectedNotes[0].isEvent)
		{
			var eventNote:EventMetaNote = cast (selectedNotes[0], EventMetaNote);
			curEventSelected = Std.int(FlxMath.bound(curEventSelected, 0, eventNote.events.length - 1));
			UI.selectedEventText.text = 'Selected Event: ${curEventSelected + 1} / ${eventNote.events.length}';
			UI.selectedEventText.visible = true;
			
			var myEvent:Array<String> = eventNote.events[curEventSelected];
			if(myEvent != null)
			{
				var eventName:String = (myEvent[0] != null) ? myEvent[0] : '';
				for (num => event in eventsList)
				{
					if(event[0] == eventName)
					{
						UI.eventDropDown.selectedIndex = num;
						break;
					}
				}
				UI.value1InputText.text = (myEvent[1] != null) ? myEvent[1] : '';
				UI.value2InputText.text = (myEvent[2] != null) ? myEvent[2] : '';
				if (eventName == "Modchart Event") {
					UI.eventsBox.selectedName = "Modchart";
					var combined:String = (myEvent[1] != null) ? myEvent[1] : "";
					if (combined != "") {
						var parts:Array<String> = combined.split(",");
						while (parts.length < 7) parts.push("");
						if (UI.actionsDropdown != null) {
							UI.actionsDropdown.selectedLabel = parts[0];
						}
						if (UI.modifierInput != null) UI.modifierInput.text = parts[1];
						if (UI.timeStepper != null) {
							var tVal:Float = 0;
							try {tVal = Std.parseFloat(parts[2]);} catch(e:Dynamic) {tVal = UI.timeStepper.value;}
							UI.timeStepper.value = tVal;
						}
						if (UI.valueStepper != null) {
							var vVal:Float = 0;
							try {vVal = Std.parseFloat(parts[3]);} catch(e:Dynamic) {vVal = UI.valueStepper.value;}
							UI.valueStepper.value = vVal;
						}
						if (UI.easeInput != null) UI.easeInput.text = parts[4];
						if (UI.playerStepper != null) {
							var pVal:Int = 0;
							try pVal = {Std.parseInt(parts[5]);} catch(e:Dynamic) {pVal = Std.int(UI.playerStepper.value);}
							UI.playerStepper.value = pVal;
						}
					} else {
						if (UI.actionsDropdown != null) UI.actionsDropdown.selectedIndex = 0;
						if (UI.modifierInput != null) UI.modifierInput.text = "";
						if (UI.timeStepper != null) UI.timeStepper.value = 0;
						if (UI.valueStepper != null) UI.valueStepper.value = 0;
						if (UI.easeInput != null) UI.easeInput.text = "";
						if (UI.playerStepper != null) UI.playerStepper.value = -1;
					}
				} else UI.eventsBox.selectedName = "Events";
			}
		}
		else UI.selectedEventText.visible = false;
	}

	function changeLanes(newLanes:Int, oldLanes:Int){
		if(newLanes < oldLanes){
			var removedNotes:Array<MetaNote> = [for (note in notes) if(Std.int(note.songData[1] / GRID_COLUMNS_PER_PLAYER) >= newLanes) note];
			if(removedNotes.length > 0){
				resetSelectedNotes();
				addUndoAction(DELETE_NOTE, {notes: removedNotes});
				for(note in removedNotes){
					var idx:Int = notes.indexOf(note);
					if(idx >= 0) notes.splice(idx, 1);
				}
			}

			var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
			if(extraChars != null){
				var keepExtra:Int = newLanes - 3;
				if(keepExtra < 0) keepExtra = 0;
				if(extraChars.length > keepExtra){
					extraChars.splice(keepExtra, extraChars.length - keepExtra);
					Reflect.setField(PlayState.SONG, 'extraPlayers', extraChars);
				}
			}
		}

		GRID_PLAYERS = PlayState.SONG.lanes = newLanes;
		createGrids();
		for(note in notes)
			positionNoteXByData(note);
		for(note in events){
			positionNoteXByData(note, null, true);
			note.eventText.x = note.x - note.eventText.width - 10;
		}
		loadSection();
		updateJsonData();
		updateHeads(true);
	}

	function getLaneCharacter(i:Int):String{
		return switch(i){
			case 0: PlayState.SONG.player2;
			case 1: PlayState.SONG.player1;
			case 2: PlayState.SONG.gfVersion;
			default:
				var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
				(extraChars != null && extraChars.length > i - 3) ? extraChars[i - 3] : '';
		}
	}

	function setLaneCharacter(i:Int, name:String):Void{
		switch(i){
			case 0: PlayState.SONG.player2 = name;
			case 1: PlayState.SONG.player1 = name;
			case 2: PlayState.SONG.gfVersion = name;
			default:
				var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
				if(extraChars == null) extraChars = [];
				while(extraChars.length <= i - 3)
					extraChars.push('');
				extraChars[i - 3] = name;
				Reflect.setField(PlayState.SONG, 'extraPlayers', extraChars);
		}
	}

	function removeLane(laneIndex:Int){
		var oldLanes:Int = GRID_PLAYERS;
		var newLanes:Int = oldLanes - 1;
		if(newLanes < 2 || laneIndex < 2 || laneIndex >= oldLanes) return;

		var removedNotes:Array<MetaNote> = [for (note in notes) if(Std.int(note.songData[1] / GRID_COLUMNS_PER_PLAYER) == laneIndex) note];
		if(removedNotes.length > 0){
			resetSelectedNotes();
			addUndoAction(DELETE_NOTE, {notes: removedNotes});
			for(note in removedNotes){
				var idx:Int = notes.indexOf(note);
				if(idx >= 0) notes.splice(idx, 1);
			}
		}

		for(note in notes){
			var noteLane:Int = Std.int(note.songData[1] / GRID_COLUMNS_PER_PLAYER);
			if(noteLane > laneIndex)
				note.songData[1] -= GRID_COLUMNS_PER_PLAYER;
		}

		for(i in laneIndex...(oldLanes - 1))
			setLaneCharacter(i, getLaneCharacter(i + 1));
		setLaneCharacter(oldLanes - 1, '');

		var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
		if(extraChars != null){
			var keepExtra:Int = newLanes - 3;
			if(keepExtra < 0) keepExtra = 0;
			if(extraChars.length > keepExtra){
				extraChars.splice(keepExtra, extraChars.length - keepExtra);
				Reflect.setField(PlayState.SONG, 'extraPlayers', extraChars);
			}
		}

		GRID_PLAYERS = PlayState.SONG.lanes = newLanes;
		lastplayerBoxesColumns = -1;
		createGrids();
		for(note in notes)
			positionNoteXByData(note);
		for(note in events){
			positionNoteXByData(note, null, true);
			note.eventText.x = note.x - note.eventText.width - 10;
		}
		loadSection();
		updateJsonData();
		updateHeads(true);
	}

	public var lastplayerBoxesColumns:Int = -1;

	function createGrids(){
		var destroyed:Bool = false;
		var stripes:Array<Int> = null;
		if(prevGridBg != null){
			stripes = prevGridBg.stripes;
			remove(prevGridBg);
			remove(gridBg);
			remove(nextGridBg);
			prevGridBg = FlxDestroyUtil.destroy(prevGridBg);
			gridBg = FlxDestroyUtil.destroy(gridBg);
			nextGridBg = FlxDestroyUtil.destroy(nextGridBg);
			remove(waveformSprite);
			remove(dummyArrow);
			remove(vortexIndicator);
			remove(eventLockOverlay);
			remove(timeLine);
			destroyed = true;
		}

		if(destroyed){
            for (icon in icons) icon = FlxDestroyUtil.destroy(icon);
            icons = [];
            if(eventIcon != null) eventIcon = FlxDestroyUtil.destroy(eventIcon);
        }

		var columnCount:Int = (GRID_COLUMNS_PER_PLAYER * GRID_PLAYERS) + (SHOW_EVENT_COLUMN ? 1 : 0);
		gridBg = new ChartingGridSprite(columnCount, gridColors[0], gridColors[1]);
		gridBg.screenCenter(X);
		gridBg.x -= 20;

		prevGridBg = new ChartingGridSprite(columnCount, gridColorsOther[0], gridColorsOther[1]);
		nextGridBg = new ChartingGridSprite(columnCount, gridColorsOther[0], gridColorsOther[1]);

		@:privateAccess
		prevGridBg.scrollFactor.x = nextGridBg.scrollFactor.x = gridBg.scrollFactor.x = 
		prevGridBg.stripe.scrollFactor.x = nextGridBg.stripe.scrollFactor.x = gridBg.stripe.scrollFactor.x = 
		prevGridBg.vortexLine.scrollFactor.x = nextGridBg.vortexLine.scrollFactor.x = gridBg.vortexLine.scrollFactor.x = 1;

		prevGridBg.x = nextGridBg.x = gridBg.x;
		prevGridBg.stripes = nextGridBg.stripes = gridBg.stripes = stripes;
		
		if(destroyed){
			insert(getFirstNull(), prevGridBg);
			insert(getFirstNull(), nextGridBg);
			insert(getFirstNull(), gridBg);
			loadSection();
		} else {
			add(prevGridBg);
			add(nextGridBg);
			add(gridBg);
		}
		waveformSprite = new FlxSprite(gridBg.x + (SHOW_EVENT_COLUMN ? GRID_SIZE : 0), 0).makeGraphic(1, 1, 0x00FFFFFF);
		waveformSprite.scrollFactor.x = 1;
		waveformSprite.visible = false;
		if(chartEditorSave.data.waveformColor != null)
			waveformSprite.color = CoolUtil.colorFromString(chartEditorSave.data.waveformColor);
		add(waveformSprite);

		dummyArrow = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		dummyArrow.setGraphicSize(GRID_SIZE, GRID_SIZE);
		dummyArrow.updateHitbox();
		dummyArrow.scrollFactor.x = 1;
		add(dummyArrow);

		vortexIndicator = new FlxSprite(gridBg.x - GRID_SIZE, FlxG.height/2).loadGraphic(Paths.image('editors/vortex_indicator'));
		vortexIndicator.setGraphicSize(GRID_SIZE);
		vortexIndicator.updateHitbox();
		vortexIndicator.scrollFactor.set(1, 0);
		vortexIndicator.active = false;
		updateVortexColor();
		add(vortexIndicator);
		add(strumLineNotes);

		add(behindRenderedNotes);
		add(curRenderedNotes);
		add(movingNotes);

		eventLockOverlay = new FlxSprite(gridBg.x, 0).makeGraphic(1, 1, FlxColor.BLACK);
		eventLockOverlay.alpha = 0.6;
		eventLockOverlay.visible = false;
		eventLockOverlay.scrollFactor.x = 1;
		eventLockOverlay.scale.x = GRID_SIZE;
		eventLockOverlay.updateHitbox();
		add(eventLockOverlay);

		timeLine = new FlxSprite(gridBg.x, 0).makeGraphic(1, 1, FlxColor.WHITE);
		timeLine.setGraphicSize(Std.int(gridBg.width), 4);
		timeLine.updateHitbox();
		timeLine.screenCenter(Y);
		timeLine.scrollFactor.set(1, 0);
		add(timeLine);
		
		var startX:Float = gridBg.x;
		var startY:Float = FlxG.height/2;
		vortexIndicator.visible = strumLineNotes.visible = strumLineNotes.active = vortexEnabled;
		if(SHOW_EVENT_COLUMN) startX += GRID_SIZE;

		UI.createCharacterBoxes();
		UI.createPlayerBoxes();

		remove(UI);
		add(UI);

		remove(selectionBox);
		add(selectionBox);
		for (box in UI.playerBoxes){
			box.cameras = [FlxG.camera];
			box.scrollFactor.set(1, 0);
		}
		UI.lanesBox.cameras = [FlxG.camera];
		UI.lanesBox.scrollFactor.set(1, 0);

		strumLineNotes.clear();
		for (i in 0...Std.int(GRID_PLAYERS * GRID_COLUMNS_PER_PLAYER))
		{
			var note:StrumNote = new StrumNote(startX + (GRID_SIZE * i), startY, i % GRID_COLUMNS_PER_PLAYER, 0);
			note.modPos.x = note.x;
			note.modPos.y = note.y;
			note.scrollFactor.set(1, 0);
			note.playAnim('static');
			note.alpha = 0.4;
			note.updateHitbox();
			if(note.width > note.height)
				note.setGraphicSize(GRID_SIZE);
			else
				note.setGraphicSize(0, GRID_SIZE);
	
			note.updateHitbox();
			note.x += GRID_SIZE/2 - note.width/2;
			note.y += GRID_SIZE/2 - note.height/2;
			strumLineNotes.add(note);
		}

		var columns:Int = 0;
        var iconX:Float = gridBg.x;
        var iconY:Float = 50;
        var gridStripes:Array<Int> = [];
		if(SHOW_EVENT_COLUMN) 
        {
            if(eventIcon == null)
            {
				eventIcon = new FlxSprite(0, iconY).loadGraphic(Paths.image('editors/eventArrow'));
				eventIcon.antialiasing = ClientPrefs.data.antialiasing;
				eventIcon.alpha = 0.6;
				eventIcon.setGraphicSize(30, 30);
				eventIcon.updateHitbox();
				eventIcon.scrollFactor.set(1, 0);
				add(eventIcon);
            }
            eventIcon.x = iconX + (GRID_SIZE * 0.5) - eventIcon.width/2;
            
            columns++;
            iconX += GRID_SIZE;
        }

		if(mustHitIndicator == null){
			mustHitIndicator = FlxSpriteUtil.drawTriangle(new FlxSprite(0, iconY - 20).makeGraphic(16, 16, FlxColor.TRANSPARENT), 0, 0, 16);
			mustHitIndicator.scrollFactor.set(1, 0);
			mustHitIndicator.flipY = true;
			mustHitIndicator.cameras = [FlxG.camera];
			mustHitIndicator.offset.x += mustHitIndicator.width/2;
		}
		remove(mustHitIndicator);
		add(mustHitIndicator);

		for (i in 0...GRID_PLAYERS){
            if(columns > 0) gridStripes.push(columns);
            
            if(icons.length <= i){
				var icon:HealthIcon = new HealthIcon();
				icon.y = 5;
				icon.alpha = 0.6;
				icon.scrollFactor.set(1, 0);
				icon.scale.set(0.3, 0.3);
				icon.updateHitbox();
				icon.ID = i+1;
				if(i == 0) icon.ID = 2;
				if(i == 1) icon.ID = 1;
				add(icon);
				icons.push(icon);
            }

            icons[i].x = iconX + GRID_SIZE * ((GRID_COLUMNS_PER_PLAYER/2)-1) - icons[i].width/1.5;
            icons[i].y = 5;

            columns += GRID_COLUMNS_PER_PLAYER;
            iconX += GRID_SIZE * GRID_COLUMNS_PER_PLAYER;
        }

        prevGridBg.stripes = nextGridBg.stripes = gridBg.stripes = gridStripes;
	}

	var cachedSectionRow:Array<Int>;
	var cachedSectionTimes:Array<Float>;
	var cachedSectionCrochets:Array<Float>;
	var cachedSectionBPMs:Array<Float>;
	function loadChart(song:SwagSong)
	{
		PlayState.SONG = song;
		StageData.loadDirectory(PlayState.SONG);
		Conductor.bpm = PlayState.SONG.bpm;
	}

	function loadMusic(?killAudio:Bool = false)
	{
		setSongPlaying(false);
		var time:Float = Conductor.songPosition;

		if(killAudio)
		{
			var sndsToKill:Array<String> = [];
			for (key => snd in Paths.currentTrackedSounds)
			{
				if(key.contains('/songs/${Paths.formatToSongPath(PlayState.SONG.song)}/') && snd != null)
				{
					sndsToKill.push(key);
					snd.close();
				}
			}

			for (key in sndsToKill)
			{
				Assets.cache.clear(key);
				Paths.currentTrackedSounds.remove(key);
				Paths.localTrackedAssets.remove(key);
			}
		}

		try
		{
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0);
			FlxG.sound.music.pause();
			FlxG.sound.music.time = time;
			FlxG.sound.music.onComplete = (function() songFinished = true);
		}
		catch(e:Exception)
		{
			FlxG.log.error('Error loading song: $e');
			return;
		}

		@:privateAccess vocals.cleanup(true);
		@:privateAccess opponentVocals.cleanup(true);
		if (PlayState.SONG.needsVoices)
		{
			try
			{
				var playerVocals:Sound = Paths.voices(PlayState.SONG.song, (characterData.vocalsP1 == null || characterData.vocalsP1.length < 1) ? 'Player' : characterData.vocalsP1);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(PlayState.SONG.song));
				vocals.volume = 0;
				vocals.play();
				vocals.pause();
				vocals.time = time;
				
				var oppVocals:Sound = Paths.voices(PlayState.SONG.song, (characterData.vocalsP2 == null || characterData.vocalsP2.length < 1) ? 'Opponent' : characterData.vocalsP2);
				if(oppVocals != null && oppVocals.length > 0)
				{
					opponentVocals.loadEmbedded(oppVocals);
					opponentVocals.volume = 0;
					opponentVocals.play();
					opponentVocals.pause();
					opponentVocals.time = time;
				}
			}
			catch (e:Dynamic) {}
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Chart Editor', 'Song: ' + PlayState.SONG.song);
		#end

		updateAudioVolume();
		setPitch();
		_cacheSections();
	}

	function onSongComplete()
	{
		setSongPlaying(false);
		Conductor.songPosition = FlxG.sound.music.time = vocals.time = opponentVocals.time = FlxG.sound.music.length - 1;
		curSec = PlayState.SONG.notes.length - 1;
		forceDataUpdate = true;
	}

	function updateAudioVolume()
	{
		FlxG.sound.music.volume = UI.instVolumeStepper.value;
		vocals.volume = UI.playerVolumeStepper.value;
		opponentVocals.volume = UI.opponentVolumeStepper.value;
		if(UI.instMuteCheckBox.checked) FlxG.sound.music.volume = 0;
		if(UI.playerMuteCheckBox.checked) vocals.volume = 0;
		if(UI.opponentMuteCheckBox.checked) opponentVocals.volume = 0;
	}

	var playbackRate:Float = 1;
	function setPitch(?value:Null<Float>)
	{
		#if FLX_PITCH
		if(value == null) value = playbackRate;
		FlxG.sound.music.pitch = value;
		vocals.pitch = value;
		opponentVocals.pitch = value;
		#end
	}

	function setSongPlaying(doPlay:Bool)
	{
		if(FlxG.sound.music == null) return;

		vocals.time = FlxG.sound.music.time;
		opponentVocals.time = FlxG.sound.music.time;

		if(doPlay)
		{
			FlxG.sound.music.play();
			if(FlxG.sound.music.time < vocals.length) vocals.play(true, FlxG.sound.music.time);
			if(FlxG.sound.music.time < opponentVocals.length) opponentVocals.play(true, FlxG.sound.music.time);
			updateAudioVolume();
		}
		else
		{
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		for (note in strumLineNotes)
		{
			note.alpha = doPlay ? 1 : 0.4;
			if(!doPlay)
			{
				note.playAnim('static');
				note.resetAnim = 0;
			}
		}
	}

	function reloadNotes()
	{
		selectedNotes = [];
		for (note in notes) if(note != null) note.destroy();
		for (event in events) if(event != null) event.destroy();
		notes = [];
		events = [];
		undoActions = [];

		for (secNum => section in PlayState.SONG.notes)
			for (note in section.sectionNotes)
				if(note != null)
					notes.push(createNote(note, secNum));

		for (eventNum => event in PlayState.SONG.events)
			if(event != null && (cachedSectionTimes.length < 1 || event[0] < cachedSectionTimes[cachedSectionTimes.length-1])) //dont spawn events over the time limit
				events.push(createEvent(event));

		notes.sort(CoolUtil.sortByTime);
		events.sort(CoolUtil.sortByTime);

		loadSection();
	}

	function createNote(note:Dynamic, ?secNum:Null<Int> = null)
	{
		if(secNum == null) secNum = curSec;
		var section = PlayState.SONG.notes[secNum];

		var daStrumTime:Float = note[0];
		var daID:Int = ((note[4] == null) ? Std.int(note[1] / GRID_COLUMNS_PER_PLAYER) : Std.int(note[4]));
		note[1] = ((note[1] % GRID_COLUMNS_PER_PLAYER) + (daID * GRID_COLUMNS_PER_PLAYER));
		var daNoteData:Int = Std.int(note[1] % GRID_COLUMNS_PER_PLAYER);

		var swagNote:MetaNote = new MetaNote(daStrumTime, daNoteData, note);
		swagNote.mustPress = (swagNote.fieldID == 1 ? true : false);
		swagNote.setSustainLength(note[2], cachedSectionCrochets[secNum] / 4, curZoom);
		swagNote.gfNote = (section.gfSection && swagNote.mustPress == section.mustHitSection);
		swagNote.noteType = note[3];
		swagNote.scrollFactor.x = 1;
		var txt:FlxText = swagNote.findNoteTypeText(swagNote.noteType != null ? noteTypes.indexOf(swagNote.noteType) : 0);
		if(txt != null) txt.visible = showNoteTypeLabels;

		swagNote.updateHitbox();
		if(swagNote.width > swagNote.height)
			swagNote.setGraphicSize(GRID_SIZE);
		else
			swagNote.setGraphicSize(0, GRID_SIZE);

		swagNote.updateHitbox();
		swagNote.active = false;
		positionNoteXByData(swagNote);
		positionNoteYOnTime(swagNote, secNum);
		return swagNote;
	}

	function createEvent(event:Dynamic)
	{
		var daStrumTime:Float = event[0];
		var swagEvent:EventMetaNote = new EventMetaNote(daStrumTime, event);
		swagEvent.x = gridBg.x;
		swagEvent.eventText.x = swagEvent.x - swagEvent.eventText.width - 10;
		swagEvent.scrollFactor.x = 1;
		swagEvent.active = false;

		var secNum:Int = 0;
		for (i in 1...cachedSectionTimes.length)
		{
			if(cachedSectionTimes[i] > daStrumTime) break;
			secNum++;
		}
		positionNoteYOnTime(swagEvent, secNum);
		return swagEvent;
	}

	function _cacheSections()
	{
		var time:Float = 0;
		var row:Int = 0;
		cachedSectionRow = [];
		cachedSectionTimes = [];
		cachedSectionCrochets = [];
		cachedSectionBPMs = [];

		if(PlayState.SONG == null)
		{
			cachedSectionRow.push(0);
			cachedSectionTimes.push(0);
			cachedSectionCrochets.push(0);
			cachedSectionBPMs.push(0);
			return;
		}

		var bpm:Float = PlayState.SONG.bpm;
		var reachedLimit:Bool = false;
		for (secNum => section in PlayState.SONG.notes)
		{
			var secs:Null<Float> = cast section.sectionBeats;
			if(secs == null || Math.isNaN(secs) || secs <= 0) section.sectionBeats = 4;
	
			if(section.changeBPM) bpm = section.bpm;
			var beat:Float = Conductor.calculateCrochet(bpm);
			
			cachedSectionRow.push(row);
			cachedSectionTimes.push(time);
			cachedSectionCrochets.push(beat);
			cachedSectionBPMs.push(bpm);

			var lastTime:Float = time;
			var rowRound:Int = Math.round(4 * section.sectionBeats);
			row += rowRound;
			time += beat * (rowRound / 4);

			for (note in section.sectionNotes)
			{
				if(secNum > 0 && note[0] < lastTime) note[0] = lastTime;
				else if(secNum < PlayState.SONG.notes.length && note[0] >= time - 0.000001) note[0] = time - 0.000001;
			}

			if(FlxG.sound.music != null && time >= FlxG.sound.music.length)
			{
				var lastSectionNum:Int = PlayState.SONG.notes.length - 1;
				if(secNum < lastSectionNum) //Delete extra sections
				{
					while(PlayState.SONG.notes.length - 1 > secNum)
					{
						PlayState.SONG.notes.pop();
					}
					reachedLimit = true;
					break;
				}
				else if(secNum == lastSectionNum)
				{
					reachedLimit = true;
				}
			}
		}

		if(FlxG.sound.music != null && !reachedLimit) //Created sections to fill blank space
		{
			var lastSection = PlayState.SONG.notes[PlayState.SONG.notes.length-1];
			var beat:Float = Conductor.calculateCrochet(bpm);
			var sectionBeats:Float = lastSection != null ? lastSection.sectionBeats : 4;
			var rowRound:Int = Math.round(4 * sectionBeats);
			var timeAdd:Float = beat * (rowRound / 4);
			var mustHitSec:Bool = lastSection != null ? lastSection.mustHitSection : true;
			var changeBpmSec:Bool = lastSection != null ? lastSection.changeBPM : false;
			var altAnimSec:Bool = lastSection != null ? lastSection.altAnim : false;
			var gfSec:Bool = lastSection != null ? lastSection.gfSection : false;

			while(!reachedLimit)
			{
				PlayState.SONG.notes.push({
					sectionNotes: [],
					sectionBeats: sectionBeats,
					mustHitSection: mustHitSec,
					bpm: bpm,
					changeBPM: changeBpmSec,
					altAnim: altAnimSec,
					gfSection: gfSec,
					focusGF: false
				});

				cachedSectionRow.push(row);
				cachedSectionTimes.push(time);
				cachedSectionCrochets.push(beat);
				cachedSectionBPMs.push(bpm);

				row += rowRound;
				time += timeAdd;

				if(time >= FlxG.sound.music.length)
				{
					reachedLimit = true;
				}
			}
		}
		cachedSectionRow.push(row);
		cachedSectionTimes.push(time);
	}

	var showPreviousSection:Bool = true;
	var showNextSection:Bool = true;
	var showNoteTypeLabels:Bool = true;
	var forceDataUpdate:Bool = true;
	function loadSection(?sec:Null<Int> = null)
	{
		if(sec != null) curSec = sec;
		curSec = Std.int(FlxMath.bound(curSec, 0, PlayState.SONG.notes.length-1));
		Conductor.bpm = cachedSectionBPMs[curSec];

		var hei:Float = 0;
		if(curSec > 0)
		{
			prevGridBg.y = cachedSectionRow[curSec-1] * GRID_SIZE * curZoom;
			prevGridBg.rows = 4 * PlayState.SONG.notes[curSec-1].sectionBeats * curZoom;
			prevGridBg.visible = showPreviousSection;
			hei += prevGridBg.height;
			eventLockOverlay.y = prevGridBg.y;
		}
		else prevGridBg.visible = false;

		if(curSec < PlayState.SONG.notes.length - 1)
		{
			nextGridBg.y = cachedSectionRow[curSec+1] * GRID_SIZE * curZoom;
			nextGridBg.rows = 4 * PlayState.SONG.notes[curSec+1].sectionBeats * curZoom;
			nextGridBg.visible = showNextSection;
			hei += nextGridBg.height;
		}
		else nextGridBg.visible = false;

		gridBg.y = cachedSectionRow[curSec] * GRID_SIZE * curZoom;
		gridBg.rows = 4 * PlayState.SONG.notes[curSec].sectionBeats * curZoom;
		hei += gridBg.height;

		if(!prevGridBg.visible) eventLockOverlay.y = gridBg.y;
		eventLockOverlay.scale.y = hei;
		eventLockOverlay.updateHitbox();

		softReloadNotes();
		updateHeads();

		var sec = getCurChartSection();
		if(sec != null)
		{
			UI.mustHitCheckBox.checked = sec.mustHitSection;
			UI.focusGFCheckBox.checked = sec.focusGF;
			UI.gfSectionCheckBox.checked = sec.gfSection;
			UI.altAnimSectionCheckBox.checked = sec.altAnim;
			UI.changeBpmCheckBox.checked = sec.changeBPM;
			UI.changeBpmStepper.value = Conductor.bpm;
			UI.beatsPerSecStepper.value = sec.sectionBeats;

			UI.strumTimeStepper.step = Conductor.stepCrochet;
			UI.susLengthStepper.step = cachedSectionCrochets[curSec] / 4 / 2;
			UI.susLengthStepper.max = UI.susLengthStepper.step * 128;
			if(selectedNotes.length > 1) UI.susLengthStepper.min = -UI.susLengthStepper.max;
			else UI.susLengthStepper.min = 0;
		}
		prevGridBg.vortexLineEnabled = gridBg.vortexLineEnabled = nextGridBg.vortexLineEnabled = vortexEnabled;
		prevGridBg.vortexLineSpace = gridBg.vortexLineSpace = nextGridBg.vortexLineSpace = GRID_SIZE * 4 * curZoom;
		updateWaveform();
	}

	function softReloadNotes(onlyCurrent:Bool = false)
	{
		if(!onlyCurrent) behindRenderedNotes.clear();
		curRenderedNotes.clear();

		var minTime:Float = getMinNoteTime(curSec);
		var maxTime:Float = getMaxNoteTime(curSec);
		function curSecFilter(note:MetaNote)
		{
			return (note.strumTime >= minTime && note.strumTime < maxTime);
		}

		var firstNote:Bool = false;
		var firstEvent:Bool = false;
		sectionFirstNoteID = 0;
		sectionFirstEventID = 0;
		for (num => note in notes)
		{
			if(note != null && curSecFilter(note))
			{
				if(!firstNote) { sectionFirstNoteID = num; firstNote = true; }
				curRenderedNotes.add(note);
				note.alpha = (note.strumTime >= Conductor.songPosition) ? 1 : 0.6;
				if(note.hasSustain) note.updateSustainToZoom(cachedSectionCrochets[curSec] / 4, curZoom);
			}
		}

		if(SHOW_EVENT_COLUMN)
		{
			for (num => event in events)
			{
				if(event != null && curSecFilter(event))
				{
					if(!firstEvent) { sectionFirstEventID = num; firstEvent = true; }
					curRenderedNotes.add(event);
					event.alpha = (event.strumTime >= Conductor.songPosition) ? 1 : 0.6;
					event.eventText.visible = true;
				}
			}
		}

		if(!onlyCurrent)
		{
			if(showPreviousSection || showNextSection)
			{
				var prevMinTime:Float = getMinNoteTime(curSec-1);
				var prevMaxTime:Float = getMaxNoteTime(curSec-1);
				var nextMinTime:Float = getMinNoteTime(curSec+1);
				var nextMaxTime:Float = getMaxNoteTime(curSec+1);
				function otherSecFilter(note:MetaNote)
				{
					return (prevGridBg.visible && (note.strumTime >= prevMinTime && note.strumTime < prevMaxTime)) ||
						(nextGridBg.visible && (note.strumTime >= nextMinTime && note.strumTime < nextMaxTime));
				}
	
				for(note in notes.filter(otherSecFilter))
				{
					behindRenderedNotes.add(note);
					note.alpha = 0.4;
					if(note.hasSustain)
					{
						var noteSec:Int = curSec;
						if(prevGridBg.visible && note.strumTime >= prevMinTime && note.strumTime < prevMaxTime)
							noteSec = curSec - 1;
						else if(nextGridBg.visible && note.strumTime >= nextMinTime && note.strumTime < nextMaxTime)
							noteSec = curSec + 1;
						noteSec = Std.int(FlxMath.bound(noteSec, 0, cachedSectionCrochets.length - 1));
						note.updateSustainToZoom(cachedSectionCrochets[noteSec] / 4, curZoom);
					}
				}

				if(SHOW_EVENT_COLUMN)
				{
					for(event in events.filter(otherSecFilter))
					{
						behindRenderedNotes.add(event);
						event.alpha = 0.4;
						event.eventText.visible = false;
					}
				}
			}
		}
	}

	function getMinNoteTime(sec:Int)
	{
		var minTime:Float = 0;
		if(sec > 0)
			minTime = cachedSectionTimes[sec];
		return minTime;
	}

	function getMaxNoteTime(sec:Int)
	{
		var maxTime:Float = Math.POSITIVE_INFINITY;
		if(sec < cachedSectionTimes.length)
			maxTime = cachedSectionTimes[sec + 1];
		return maxTime;
	}
	
	function positionNoteXByData(note:MetaNote, ?data:Null<Int> = null, ?isEvent:Bool = false)
	{
		if(isEvent){
			note.x = gridBg.x + (GRID_SIZE - note.width) / 2;
		} else {
			if(data == null) data = note.songData[1];

			var noteX:Float = gridBg.x + (GRID_SIZE - note.width) / 2;
			if(SHOW_EVENT_COLUMN) noteX += GRID_SIZE;

			noteX += GRID_SIZE * data;
			note.x = noteX;
		}
	}

	function positionNoteYOnTime(note:MetaNote, section:Int)
	{
		var time:Float = note.strumTime - cachedSectionTimes[section];
		var noteY:Float = (time / cachedSectionCrochets[section]) * GRID_SIZE * 4 * curZoom;
		noteY += cachedSectionRow[section] * GRID_SIZE * curZoom;
		noteY = Math.max(noteY, -150);
		note.y = noteY + (GRID_SIZE/2 - note.height/2);
		note.chartY = noteY;
	}

	var characterData:Dynamic = {};
	function updateJsonData():Void
	{
		for (i in 1...GRID_PLAYERS+1)
		{
			var charName:String = null;
			switch(i){
				case 1: charName = PlayState.SONG.player1;
				case 2: charName = PlayState.SONG.player2;
				case 3: charName = PlayState.SONG.gfVersion;
				default:
					var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
					if(extraChars != null && extraChars.length > i - 4)
						charName = extraChars[i - 4];
			}
			var data:CharacterFile = loadCharacterFile(charName);
			Reflect.setField(characterData, 'iconP$i', !characterFailed ? data.healthicon : 'face');
			Reflect.setField(characterData, 'vocalsP$i', data.vocals_file != null ? data.vocals_file : '');
		}
	}
	
	var _lastSec:Int = -1;
	var _lastGfSection:Null<Bool> = null;
	function updateHeads(ignoreCheck:Bool = false):Void
	{
		var curSecData:SwagSection = PlayState.SONG.notes[curSec];
		var isGfSection:Bool = (curSecData != null && curSecData.gfSection == true);
		if(_lastGfSection == isGfSection && _lastSec == curSec && !ignoreCheck) return; //optimization

		var iconNum:Int = GRID_PLAYERS;
		for (i in 0...iconNum)
		{
			var icon:HealthIcon = icons[i];
			var iconName:String = Reflect.field(characterData, 'iconP${icon.ID}');
			icon.changeIcon(iconName);
		}

		if(icons.length > 1)
		{
			var iconP1:HealthIcon = icons[1];
			var iconP2:HealthIcon = icons[0];
			var iconP3:HealthIcon = icons[2];
			var mustHitSection:Bool = (curSecData != null && curSecData.mustHitSection == true);
			var focusGF:Bool = (curSecData != null && curSecData.focusGF == true);
			if (isGfSection)
			{
				if (mustHitSection)
					iconP1.changeIcon('gf');
				else
					iconP2.changeIcon('gf');
			}

			if(focusGF)
				if(GRID_PLAYERS >= 3) mustHitIndicator.x = iconP3.x + iconP3.width/1.5 + GRID_SIZE;
				else mustHitIndicator.x = ((iconP1.x + iconP1.width/1.5) + (iconP2.x + iconP2.width/1.5)) / 2 + GRID_SIZE
			else if(!mustHitSection)
				mustHitIndicator.x = iconP2.x + iconP2.width/1.5 + GRID_SIZE;
			else
				mustHitIndicator.x = iconP1.x + iconP1.width/1.5 + GRID_SIZE;
		}
		_lastGfSection = isGfSection;
		_lastSec = curSec;
	}

	function updateModEvV1():Void {
		if (selectedNotes.length != 1 || !selectedNotes[0].isEvent) return;

		var eventNote:EventMetaNote = cast(selectedNotes[0], EventMetaNote);

		if (eventNote.events == null || eventNote.events.length == 0) return;
		curEventSelected = Std.int(FlxMath.bound(curEventSelected, 0, eventNote.events.length - 1));

		var myEvent:Array<String> = eventNote.events[curEventSelected];
		if (myEvent == null) return;

		var eventName:String = (myEvent[0] != null) ? myEvent[0] : '';
		if (eventName != "Modchart Event") return;

		var action:String = (UI.actionsDropdown != null) ? UI.actionsDropdown.selectedLabel : '';
		var modifier:String = (UI.modifierInput != null) ? UI.modifierInput.text : '';
		var timeStr:String = (UI.timeStepper != null) ? Std.string(UI.timeStepper.value) : '';
		var valueStr:String = (UI.valueStepper != null) ? Std.string(UI.valueStepper.value) : '';
		var easeStr:String = (UI.easeInput != null) ? UI.easeInput.text : '';
		var playerStr:String = (UI.playerStepper != null) ? Std.string(UI.playerStepper.value) : '';

		var combined:String = action + "," + modifier + "," + timeStr + "," + valueStr + "," + easeStr + "," + playerStr + ",-1";

		eventNote.events[curEventSelected][1] = combined;

		eventNote.updateEventText();
		eventNote.loadIcon();
	}

	var eventsList:Array<Array<String>>;
	var curEventSelected:Int = 0;

	var susLengthLastVal:Float = 0; //used for multiple notes selected

	function pasteCopiedNotesToSection(?canCopyNotes:Bool = true, ?canCopyEvents:Bool = true, ?showMessage:Bool = true) //Used on "Paste Section" and "Copy Last Section" buttons
	{
		var curSectionTime:Null<Float> = cachedSectionTimes[curSec];
		if(curSectionTime == null)
		{
			UI.showOutput('ERROR: Unknown section??', true);
			return [];
		}

		var pushedNotes:Array<MetaNote> = [];
		var nts:Array<MetaNote> = [];
		var evs:Array<EventMetaNote> = [];
		if(canCopyNotes && copiedNotes.length > 0)
		{
			for (note in copiedNotes)
			{
				if(note == null) continue;
				var dataCopy:Array<Dynamic> = makeNoteDataCopy(note, false);
				dataCopy[0] += curSectionTime;

				var createdNote = createNote(dataCopy, curSec);
				notes.push(createdNote);
				pushedNotes.push(createdNote);
				nts.push(createdNote);
			}
			notes.sort(CoolUtil.sortByTime);
		}

		if(canCopyEvents && copiedEvents.length > 0)
		{
			for (event in copiedEvents)
			{
				if(event == null) continue;
				var dataCopy:Array<Dynamic> = makeNoteDataCopy(event, true);
				dataCopy[0] += curSectionTime;

				var createdEvent = createEvent(dataCopy);
				events.push(createdEvent);
				pushedNotes.push(createdEvent);
				evs.push(createdEvent);
			}
			events.sort(CoolUtil.sortByTime);
		}
		loadSection();
		
		if(showMessage)
		{
			if(nts.length == 0 && evs.length == 0)
			{
				UI.showOutput('Nothing to paste!', true);
				return [];
			}

			var str:String = '';
			if(nts.length > 0) str += 'Notes Added: ${nts.length}';
			if(evs.length > 0)
			{
				if(str.length > 0) str += '\n';
				str += 'Events Added: ${evs.length}';
			}

			if(str.length > 0) UI.showOutput(str);
		}
		addUndoAction(ADD_NOTE, {notes: nts, events: evs});
		return pushedNotes;
	}

	function updateChartData()
	{
		for (secNum => section in PlayState.SONG.notes)
			PlayState.SONG.notes[secNum].sectionNotes = [];

		notes.sort(CoolUtil.sortByTime);
		var noteSec:Int = 0;
		var nextSectionTime:Float = cachedSectionTimes[noteSec + 1];
		var curSectionTime:Float = cachedSectionTimes[noteSec];

		for (num => note in notes)
		{
			if(note == null) continue;

			while(cachedSectionTimes[noteSec + 1] <= note.strumTime)
			{
				noteSec++;
				nextSectionTime = cachedSectionTimes[noteSec + 1];
				curSectionTime = cachedSectionTimes[noteSec];
			}

			var arr:Array<Dynamic> = PlayState.SONG.notes[noteSec].sectionNotes;
			note.songData[4] = Std.int(note.songData[1] / GRID_COLUMNS_PER_PLAYER);
			arr.push(note.songData);
		}

		events.sort(CoolUtil.sortByTime);
		PlayState.SONG.events = [];
		for (event in events)
			PlayState.SONG.events.push(event.songData);
	}

	public static function ensureDirectory(path:String) {
	    var parent = haxe.io.Path.directory(path);
	    if (parent != "" && !sys.FileSystem.exists(parent)) ensureDirectory(parent);
	    if (!sys.FileSystem.exists(path)) sys.FileSystem.createDirectory(path);
	}

	public static function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public function saveChart(auto:Bool = true, dif:String = null)
	{
		updateChartData();

		PlayState.SONG.format = "notepulse";

		if (PlayState.SONG.events != null && PlayState.SONG.events.length > 1)
			PlayState.SONG.events.sort(sortByTime);

		var json = {
			"song": PlayState.SONG
		};

		var data:String = haxe.Json.stringify(json, "\t");

		if (data == null || data.length <= 0)
			return;

		if (auto)
		{
			var chartPath:String = Song.chartPath;

			if (chartPath == null || chartPath == "")
			{
				UI.showOutput('Failed to save chart: Song.chartPath is null or empty', true);
				return;
			}

			var chartDir = haxe.io.Path.directory(chartPath);
			if (!sys.FileSystem.exists(chartDir))
			{
				var ensureDirectory = function(path:String)
				{
					var parent = haxe.io.Path.directory(path);
					if (parent != "" && !sys.FileSystem.exists(parent))
						ensureDirectory(parent);
					if (!sys.FileSystem.exists(path))
						sys.FileSystem.createDirectory(path);
				}
				ensureDirectory(chartDir);
			}

			try
			{
				sys.io.File.saveContent(chartPath, data.trim());
				UI.showOutput('Saved to: $chartPath', false, true);
			}
			catch (e:Dynamic)
			{
				UI.showOutput('Failed to save chart: $e', true);
			}
		}
		else
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Song.chartPath);
			chartPath = Song.chartPath;
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}

	inline function getCurChartSection()
	{
		return PlayState.SONG.notes != null ? PlayState.SONG.notes[curSec] : null;
	}

	function updateNotesRGB()
	{
		PlayState.SONG.disableNoteRGB = UI.noRGBCheckBox.checked;

		for (note in notes)
		{
			if(note == null) continue;

			note.rgbShader.enabled = !UI.noRGBCheckBox.checked;
			if(note.rgbShader.enabled)
			{
				var data = funkin.backend.NoteTypesConfig.loadNoteTypeData(note.noteType);
				if(data == null || data.length < 1) continue;

				for (line in data)
				{
					var prop:String = line.property.join('.');
					if(prop == 'rgbShader.enabled')
						note.rgbShader.enabled = line.value;
				}
			}
		}

		for (note in strumLineNotes)
			note.rgbShader.enabled = !UI.noRGBCheckBox.checked;
	}

	function updatePixelTexture(){
		PlayState.SONG.pixel4kTexture = UI.pixel4kTextureCheckBox.checked;
		for (note in notes)
		{
			if(note == null) continue;
			note.reloadNote();
		}
		for (note in strumLineNotes){
			if(note == null) continue;
			note.reloadNote();
			if(note.width > note.height)
				note.setGraphicSize(GRID_SIZE);
			else
				note.setGraphicSize(0, GRID_SIZE);
	
			note.updateHitbox();
			note.x += GRID_SIZE/2 - note.width/2;
			note.y += GRID_SIZE/2 - note.height/2;
		}
	}

	function updateGridVisibility()
	{
		UI.showLastGridButton.text.text = showPreviousSection	? '  Hide Last Section' :  '  Show Last Section';
		UI.showNextGridButton.text.text = showNextSection		? '  Hide Next Section' :  '  Show Next Section';

		prevGridBg.visible = (curSec > 0 && showPreviousSection);
		nextGridBg.visible = (curSec < PlayState.SONG.notes.length - 1 && showNextSection);
		
		UI.noteTypeLabelsButton.text.text = showNoteTypeLabels ? '  Hide Note Labels' : '  Show Note Labels';
		for (num => text in MetaNote.noteTypeTexts)
			text.visible = showNoteTypeLabels;
		softReloadNotes();
	}

	function adaptNotesToNewTimes(oldTimes:Array<Float>)
	{
		undoActions = [];
		setSongPlaying(false);
		var gridLerp:Float = FlxMath.bound((scrollY + FlxG.height/2 - gridBg.y) / gridBg.height, 0.000001, 0.999999);
		notes.sort(CoolUtil.sortByTime);
		_cacheSections();

		var noteSec:Int = 0;
		var oldNextSectionTime:Float = oldTimes[noteSec + 1];
		var oldCurSectionTime:Float = oldTimes[noteSec];
		var nextSectionTime:Float = cachedSectionTimes[noteSec + 1];
		var curSectionTime:Float = cachedSectionTimes[noteSec];

		for (num => note in notes)
		{
			if(note == null || note.strumTime <= 0) continue;

			while(noteSec + 2 < oldTimes.length && oldTimes[noteSec + 1] <= note.strumTime)
			{
				noteSec++;
				oldNextSectionTime = oldTimes[noteSec + 1];
				oldCurSectionTime = oldTimes[noteSec];
				nextSectionTime = cachedSectionTimes[noteSec + 1];
				curSectionTime = cachedSectionTimes[noteSec];

				if(noteSec + 1 >= cachedSectionTimes.length)
				{
					var changedSelected:Bool = false;
					for(i in num...notes.length)
					{
						var n = notes[num];
						if(n != null)
						{
							if(selectedNotes.contains(n))
							{
								selectedNotes.remove(n);
								changedSelected = true;
							}
							notes.remove(n);
							note.destroy();
						}
					}
					if(changedSelected) onSelectNote();
					loadSection();
					return;
				}
			}

			var shouldBound:Bool = (note.strumTime >= oldCurSectionTime && note.strumTime < oldNextSectionTime);
			var strumTime:Float = note.strumTime;

			var ratio:Float = (nextSectionTime - curSectionTime) / (oldNextSectionTime - oldCurSectionTime);
			var adaptedStrumTime:Float = ((note.strumTime - oldCurSectionTime) * ratio) + curSectionTime;
			note.setStrumTime(adaptedStrumTime);
			if(shouldBound)
				note.setStrumTime(FlxMath.bound(note.strumTime, curSectionTime, nextSectionTime));

			positionNoteYOnTime(note, noteSec);
			note.updateSustainToStepCrochet(cachedSectionCrochets[noteSec] / 4);
		}
		
		for (event in events)
		{
			var secNum:Int = 0;
			for (time in cachedSectionTimes)
			{
				if(time > event.strumTime) break;
				secNum++;
			}
			positionNoteYOnTime(event, secNum);
		}
		
		var time:Float = FlxMath.remapToRange(gridLerp, 0, 1, cachedSectionTimes[curSec], cachedSectionTimes[curSec + 1]);
		if(Math.isNaN(time))
		{
			time = 0;
			curSec = 0;
		}
		
		if(FlxG.sound.music != null && time >= FlxG.sound.music.length)
		{
			time = FlxG.sound.music.length - 1;
			curSec = PlayState.SONG.notes.length - 1;
		}
		FlxG.sound.music.time = time;
		Conductor.songPosition = time;
		forceDataUpdate = true;
		loadSection();
	}

	public static var doModchartOnEditor:Bool = true;
	var modchartCheckBox:PsychUICheckBox;
	function editorPlayStatePrompt(){
		FlxG.sound.play(Paths.sound('chartingSounds/openWindow'));
		openSubState(new BasePrompt(420, 200, 'Preview\nChoose the strums to play.', function(state:BasePrompt){
			var btnY = 390;
			var buttons:Array<PsychUIButton> = [];

			modchartCheckBox = new PsychUICheckBox(0, btnY - 37, 'Preview Modchart?', 100, function() doModchartOnEditor = modchartCheckBox.checked);
			modchartCheckBox.checked = doModchartOnEditor;
			modchartCheckBox.cameras = state.cameras;

			buttons.push(new PsychUIButton(0, btnY, 'Opponent', function(){
				openEditorPlayState(0);
			}));

			buttons.push(new PsychUIButton(0, btnY, 'Player', function(){
				openEditorPlayState(1);
			}));

			if (PlayState.SONG.lanes >= 3){
				state.bg.scale.x *= 1.3;
				buttons.push(new PsychUIButton(0, btnY, 'Girlfriend', function(){
					openEditorPlayState(2);
				}));
			}

			var cancelBtn = new PsychUIButton(0, btnY, 'Cancel', state.close);
			cancelBtn.normalStyle.bgColor = FlxColor.RED;
			cancelBtn.normalStyle.textColor = FlxColor.WHITE;
			buttons.push(cancelBtn);

			var spacing = 125;
			var totalWidth = spacing * (buttons.length - 1);
			for (i => btn in buttons){
				btn.screenCenter(X);
				btn.x += i * spacing - totalWidth / 2;
				btn.cameras = state.cameras;
				state.add(btn);
			}
			modchartCheckBox.screenCenter(X);
			modchartCheckBox.x -= spacing - totalWidth / 2;
			state.add(modchartCheckBox);
		}));
	}

	function openEditorPlayState(player:Int) {
		if(FlxG.sound.music == null)
		{
			UI.showOutput('Load a valid song to preview!', true);
			return;
		}
		setSongPlaying(false);
		chartEditorSave.flush();
		updateChartData();

		openSubState(new EditorPlayState(playbackRate, player));
		UI.upperBox.isMinimized = true;
		UI.upperBox.visible = UI.mainBox.visible = UI.infoBox.visible = false;
	}

	function goToPlayState()
	{
		persistentUpdate = false;
		FlxG.mouse.visible = false;
		chartEditorSave.flush();

		setSongPlaying(false);
		updateChartData();
		StageData.loadDirectory(PlayState.SONG);
		LoadingState.loadAndSwitchState(new PlayState());
		ClientPrefs.toggleVolumeKeys(true);
	}
	
	override function openSubState(SubState:FlxSubState)
	{
		if(!persistentUpdate) setSongPlaying(false);
		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		ClientPrefs.toggleVolumeKeys(true);
		super.closeSubState();
		setSongPlaying(false);
		UI.upperBox.isMinimized = true;
		UI.upperBox.visible = UI.mainBox.visible = UI.infoBox.visible = true;
		UI.upperBox.bg.visible = false;
		updateAudioVolume();
	}

	override function destroy(){
		FlxTween.cancelTweensOf(Main.fpsVar, ["alpha"]);
		FlxTween.tween(Main.fpsVar, {alpha: 1}, 1, {ease: FlxEase.circOut});

		WindowUtil.preventClose = false;
		WindowUtil.onEditorClosing = null;
		Note.globalRgbShaders = [];
		funkin.backend.NoteTypesConfig.clearNoteTypesData();

		for (num => text in MetaNote.noteTypeTexts)
			text.destroy();

		MetaNote.noteTypeTexts = [];
		fileDialog.destroy();
		super.destroy();
		Mouse.cursor = MouseCursor.DEFAULT;
	}

	function loadFileList(mainFolder:String, ?optionalList:String = null, ?fileTypes:Array<String> = null)
	{
		if(fileTypes == null) fileTypes = ['.json', '.xml'];

		var fileList:Array<String> = [];
		if(optionalList != null)
		{
			for (file in Mods.mergeAllTextsNamed(optionalList))
			{
				file = file.trim();
				if(file.length > 0 && !fileList.contains(file))
					fileList.push(file);
			}
		}

		for (directory in Mods.directoriesWithFile(Paths.getSharedPath(), mainFolder))
		{
			for (file in FileSystem.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file.trim()]);
				if (!FileSystem.isDirectory(path) && !file.startsWith('readme.'))
				{
					for (fileType in fileTypes)
					{
						var fileToCheck:String = file.substr(0, file.length - fileType.length);
						if(fileToCheck.length > 0 && path.endsWith(fileType) && !fileList.contains(fileToCheck))
						{
							fileList.push(fileToCheck);
							break;
						}
					}
				}
			}
		}
		return fileList;
	}

	var characterFailed:Bool = false;
	function loadCharacterFile(char:String):CharacterFile {
		characterFailed = false;
		var usingXML:Bool = false;
		var path:String = '';

		var jsonRelPath:String = 'characters/' + char + '.json';
		var xmlRelPath:String = 'characters/' + char + '.xml';

		#if MODS_ALLOWED
		if(FileSystem.exists(Paths.modFolders(jsonRelPath))){
			path = Paths.modFolders(jsonRelPath);
		} else if(FileSystem.exists(Paths.modFolders(xmlRelPath))){
			path = Paths.modFolders(xmlRelPath);
			usingXML = true;
		} else if(FileSystem.exists(Paths.getSharedPath(jsonRelPath))){
			path = Paths.getSharedPath(jsonRelPath);
		} else if(FileSystem.exists(Paths.getSharedPath(xmlRelPath))){
			path = Paths.getSharedPath(xmlRelPath);
			usingXML = true;
		}
		#else
		if(OpenFlAssets.exists(Paths.getSharedPath(jsonRelPath))){
			path = Paths.getSharedPath(jsonRelPath);
		} else if(OpenFlAssets.exists(Paths.getSharedPath(xmlRelPath))){
			path = Paths.getSharedPath(xmlRelPath);
			usingXML = true;
		}
		#end

		if (path == '') {
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER + '.json');
			usingXML = false;
			characterFailed = true;
		}

		#if MODS_ALLOWED
		var rawFile:String = File.getContent(path);
		#else
		var rawFile:String = OpenFlAssets.getText(path);
		#end

		return cast Json.parse(!usingXML ? rawFile : CodenameParser.characterParse(rawFile));
	}
	
	var overwriteSavedSomething:Bool = false;
	function overwriteCheck(savePath:String, overwriteName:String, saveData:String, continueFunc:Void->Void = null, ?continueOnCancel:Bool = false)
	{
		if(FileSystem.exists(savePath))
		{
			FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
			openSubState(new Prompt('Overwrite: "$overwriteName"?', function()
			{
				overwriteSavedSomething = true;
				File.saveContent(savePath, saveData);
				if(continueFunc != null) continueFunc();
			},
			continueOnCancel ? (function() if(continueFunc != null) continueFunc()) : null));
		}
		else
		{
			overwriteSavedSomething = true;
			File.saveContent(savePath, saveData);
			if(continueFunc != null) continueFunc();
		}
	}

	// Undo/Redo stuff
	var undoActions:Array<UndoStruct> = [];
	var currentUndo:Int = 0;
	function addUndoAction(action:UndoAction, data:Dynamic)
	{
		function destroyFromArr(arr:Array<MetaNote>)
		{
			if(arr == null || arr.length < 1) return;

			for (note in arr)
				if(note != null)
					note.destroy();
		}

		if(currentUndo > 0) undoActions = undoActions.slice(currentUndo);
		currentUndo = 0;
		undoActions.insert(0, {action: action, data: data});
		while(undoActions.length > 15)
		{
			var lastAction:UndoStruct = undoActions.pop();
			if(lastAction != null)
			{
				switch(lastAction.action)
				{
					case DELETE_NOTE:
						destroyFromArr(lastAction.data.notes);
						destroyFromArr(lastAction.data.events);
					case MOVE_NOTE:
						destroyFromArr(lastAction.data.originalNotes);
						destroyFromArr(lastAction.data.originalEvents);
					default:
				}
			}
		}
	}

	function undo()
	{
		if(isMovingNotes || currentUndo >= undoActions.length)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
			return;
		}

		var action:UndoStruct = undoActions[currentUndo];
		switch(action.action)
		{
			case ADD_NOTE:
				actionRemoveNotes(action.data.notes, action.data.events);

			case DELETE_NOTE:
				actionPushNotes(action.data.notes, action.data.events);

			case MOVE_NOTE:
				actionRemoveNotes(action.data.movedNotes, action.data.movedEvents);
				actionPushNotes(action.data.originalNotes, action.data.originalEvents);
				onSelectNote();

			case SELECT_NOTE:
				resetSelectedNotes();
				selectedNotes = action.data.old;
				if(lockedEvents) selectedNotes = selectedNotes.filter((note:MetaNote) -> !note.isEvent);
				onSelectNote();
		}
		UI.showOutput('Undo #${currentUndo+1}: ${action.action}');
		FlxG.sound.play(Paths.sound('chartingSounds/undo'));
		currentUndo++;
	}
	function redo()
	{
		if(isMovingNotes || currentUndo < 1)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
			return;
		}

		currentUndo--;
		var action:UndoStruct = undoActions[currentUndo];
		switch(action.action)
		{
			case ADD_NOTE:
				actionPushNotes(action.data.notes, action.data.events);

			case DELETE_NOTE:
				actionRemoveNotes(action.data.notes, action.data.events);

			case MOVE_NOTE:
				actionRemoveNotes(action.data.originalNotes, action.data.originalEvents);
				actionPushNotes(action.data.movedNotes, action.data.movedEvents);
				onSelectNote();

			case SELECT_NOTE:
				resetSelectedNotes();
				selectedNotes = action.data.current;
				if(lockedEvents) selectedNotes = selectedNotes.filter((note:MetaNote) -> !note.isEvent);
				onSelectNote();
		}
		UI.showOutput('Redo #${currentUndo+1}: ${action.action}');
		FlxG.sound.play(Paths.sound('chartingSounds/metronome2'), 0.4);
	}

	function actionPushNotes(dataNotes:Array<MetaNote>, dataEvents:Array<EventMetaNote>)
	{
		resetSelectedNotes();
		if(dataNotes != null && dataNotes.length > 0)
		{
			for (note in dataNotes)
			{
				if(note != null)
				{
					notes.push(note);
					selectedNotes.push(note);
					note.songData[0] = note.strumTime;
					note.songData[1] = note.chartNoteData;
				}
			}
			notes.sort(CoolUtil.sortByTime);
		}
		if(dataEvents != null && dataEvents.length > 0)
		{
			for (event in dataEvents)
			{
				if(event != null)
				{
					events.push(event);
					selectedNotes.push(event);
					event.songData[0] = event.strumTime;
				}
			}
			events.sort(CoolUtil.sortByTime);
		}
		softReloadNotes();
	}

	function actionRemoveNotes(dataNotes:Array<MetaNote>, dataEvents:Array<EventMetaNote>)
	{
		if(dataNotes != null && dataNotes.length > 0)
		{
			for (note in dataNotes)
			{
			    if(note == null) continue;
			
			    var idx:Int = notes.indexOf(note);
			    if(idx >= 0) notes.splice(idx, 1);
			
			    var selIdx:Int = selectedNotes.indexOf(note);
			    if(selIdx >= 0) selectedNotes.splice(selIdx, 1);
			
			    if(note.exists)
			    {
			        note.colorTransform.redMultiplier = note.colorTransform.greenMultiplier = note.colorTransform.blueMultiplier = 1;
			        if(note.animation.curAnim != null) note.animation.curAnim.curFrame = 0;
			    }
			}
		}
		if(dataEvents != null && dataEvents.length > 0)
		{
			for (event in dataEvents)
			{
				if(event != null)
				{
					var evIdx:Int = events.indexOf(event);
					if(evIdx >= 0) events.splice(evIdx, 1);

					selectedNotes.remove(event);

					if(event.exists)
					{
						event.colorTransform.redMultiplier = event.colorTransform.greenMultiplier = event.colorTransform.blueMultiplier = 1;
						if(event.animation.curAnim != null) event.animation.curAnim.curFrame = 0;
					}
				}
			}
		}
		softReloadNotes();
	}

	function actionReplaceNotes(oldNote:MetaNote, newNote:MetaNote)
	{
		for (act in undoActions)
		{
			for (field in Reflect.fields(act.data))
			{
				var fld:Array<MetaNote> = cast Reflect.field(act.data, field);
				if(fld != null && fld.length > 0)
					for (num => actNote in fld)
						if(actNote == oldNote)
							fld[num] = newNote;
			}
		}
	}

	// Ported from the old chart editor
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];
	function updateWaveform() {
		#if (lime_cffi && !macro)
		if(curSec < 0 || curSec >= cachedSectionTimes.length || !waveformEnabled)
		{
			waveformSprite.visible = false;
			return;
		}

		waveformSprite.visible = true;
		waveformSprite.y = gridBg.y;
		var width:Int = Std.int(GRID_SIZE * GRID_COLUMNS_PER_PLAYER * GRID_PLAYERS);
		var height:Int = Std.int(gridBg.height);
		if(Std.int(waveformSprite.height) != height && waveformSprite.pixels != null)
		{
			waveformSprite.pixels.dispose();
			waveformSprite.pixels.disposeImage();
			waveformSprite.makeGraphic(width, height, 0x00FFFFFF);
		}
		waveformSprite.pixels.fillRect(new Rectangle(0, 0, width, height), 0x00FFFFFF);

		wavData[0][0].resize(0);
		wavData[0][1].resize(0);
		wavData[1][0].resize(0);
		wavData[1][1].resize(0);

		var sound:FlxSound = switch(UI.waveformTarget)
		{
			case INST:
				FlxG.sound.music;
			case PLAYER:
				vocals;
			case OPPONENT:
				opponentVocals;
			default:
				null;
		}
		
		@:privateAccess
		if (sound != null && sound._sound != null && sound._sound.__buffer != null)
		{
			var bytes:Bytes = sound._sound.__buffer.data.toBytes();
			wavData = waveformData(sound._sound.__buffer, bytes, cachedSectionTimes[curSec] - Conductor.offset, cachedSectionTimes[curSec+1] - Conductor.offset, 1, wavData, height);
		}

		// Draws
		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);
		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);
		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);

		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		for (index in 0...length)
		{
			var lmin:Float = FlxMath.bound(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var lmax:Float = FlxMath.bound(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			var rmin:Float = FlxMath.bound(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			var rmax:Float = FlxMath.bound(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), index * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.WHITE);
		}
		#else
		waveformSprite.visible = false;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1)) {
			if (index >= 0) {
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0)
					if (sample > lmax) lmax = sample;
				else if (sample < 0)
					if (sample < lmin) lmin = sample;

				if (channels >= 2) {
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;
			while (simpleSample ? v1 : rows >= samplesPerRow) {
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length) array[0][0].push(lRMin);
					else array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length) array[0][1].push(lRMax);
					else array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length) array[1][0].push(rRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(rRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length) array[1][0].push(lRMin);
						else array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length) array[1][1].push(lRMax);
						else array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;
			if(gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}
}