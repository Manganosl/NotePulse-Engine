package funkin.states.editors;

import funkin.data.Section;
import funkin.game.Rating;
import funkin.data.Song;
import funkin.data.StageData;

import funkin.objects.notes.Note;
import funkin.objects.notes.PlayField;
import funkin.objects.notes.StrumNote;

import flixel.util.FlxSort;
import openfl.geom.Rectangle;
import openfl.events.KeyboardEvent;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;

import haxe.Json;
import funkin.objects.Character;

import funkin.states.editors.ChartingState;

import funkin.states.editors.content.MetaNote.EventMetaNote;
import funkin.states.editors.content.*;

import funkin.scripting.LuaUtils;

import funkin.game.modchart.*;
class ModchartEditor extends MusicBeatState
{
	var modManager:ModManager;
	var initialCrochet:Float = 0;
	// Borrowed from original PlayState
	public var bgCam:FlxCamera;
	public var camHUD:FlxCamera;
	public var camUI:FlxCamera;

	var prevGridBg:ChartingGridSprite;
	var gridBg:ChartingGridSprite;
	var nextGridBg:ChartingGridSprite;

	var songPosSlider:PsychUIBar;

	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var vocals:FlxSound;
	var opponentVocals:FlxSound;
	var inst:FlxSound;
	
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var allNotes:Array<Note> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();
	
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:PlayField;
	public var gfStrums:PlayField;
	public var playerStrums:PlayField;
	public var extraStrums:Array<PlayField> = [];
	
	var combo:Int = 0;
	var lastRating:FlxSprite;
	var lastCombo:FlxSprite;
	var lastScore:Array<FlxSprite> = [];
	var keysArray:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];
	
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	public var songSpeed:Float = 1;
	
	var totalPlayed:Int = 0;
	var totalNotesHit:Float = 0.0;
	var ratingPercent:Float;
	var ratingFC:String;
	
	var showCombo:Bool = false;
	var showComboNum:Bool = true;
	var showRating:Bool = true;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var guitarHeroSustains:Bool = false;

	public static var instance:ModchartEditor;

	private var player:Int;

	var paused:Bool = false;
	static inline var SEEK_STEP:Float = 1000;

	var dummyArrow:FlxSprite;

	var _file:FileReference;

	public function new()
	{
		super();

		keysArray = [];
		for (i in 0...PlayState.SONG.mania + 1){
			keysArray.push(PlayState.SONG.mania + '_key_$i');
		}

		instance = this;

		this.player = 0;
		
		Conductor.songPosition = 0;
		/* setting up some important data */
		this.playbackRate = 1;
		this.startPos = Conductor.songPosition;
	}

	var modchartBox:PsychUIBox;
	override public function create(){
		initPsychCamera();

		bgCam = new FlxCamera();
		bgCam.bgColor = 0xFF000000;
		FlxG.cameras.add(bgCam, false);

		camHUD = new FlxCamera();
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, true);

		camUI = new FlxCamera();
		camUI.bgColor = 0x00000000;
		FlxG.cameras.add(camUI, false);

		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		
		/* borrowed from PlayState */
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.cameras = [bgCam];
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);

        var box:FlxSprite = new FlxSprite();
        box.makeGraphic(camHUD.width, camHUD.height, FlxColor.TRANSPARENT);
        box.pixels.fillRect(new Rectangle(0, 0, camHUD.width, 5), FlxColor.RED);
        box.pixels.fillRect(new Rectangle(0, camHUD.height - 5, camHUD.width, 5), FlxColor.RED);
        box.pixels.fillRect(new Rectangle(0, 0, 5, camHUD.height), FlxColor.RED);
        box.pixels.fillRect(new Rectangle(camHUD.width - 5, 0, 5, camHUD.height), FlxColor.RED);
        box.dirty = true;

        add(box);
		camHUD.y -= 125;
		camHUD.zoom = 0.4;
		
		/**** NOTES ****/
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		strumLineNotes.cameras = [camHUD];
		add(strumLineNotes);

		opponentStrums = new PlayField();
		opponentStrums.cameras = [camHUD];
		playerStrums = new PlayField();
		playerStrums.cameras = [camHUD];
		if(PlayState.SONG.lanes >= 3){
			gfStrums = new PlayField();
			gfStrums.cameras = [camHUD];
			for(lane in 0...(PlayState.SONG.lanes-3)){
				extraStrums[lane] = new PlayField();
				extraStrums[lane].cameras = [camHUD];
			}
		}
		
		for(i in 0...PlayState.SONG.lanes)
			generateStaticArrows(i);

		if(PlayState.SONG.lanes >= 3){
			for(i in 0...gfStrums.length)
				gfStrums.members[i].x = (opponentStrums.members[i].x + playerStrums.members[i].x) / 2;
			for(strums in extraStrums)
				for(i in 0...strums.length)
					strums.members[i].x = gfStrums.members[i].x;
		}

		/***************/
		
		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		FlxG.mouse.visible = true;
		
		generateSong(PlayState.SONG.song);

		reloadManager();
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Modcharting a Song', PlayState.SONG.song, null, true, songLength);
		#end

		gridBg = new ChartingGridSprite(1, 0xFF3F3F3F, 0xFF2F2F2F);
		gridBg.screenCenter(X);
		prevGridBg = new ChartingGridSprite(1, 0xFF1F1F1F, 0xFF111111);
		nextGridBg = new ChartingGridSprite(1, 0xFF1F1F1F, 0xFF111111);
		prevGridBg.x = nextGridBg.x = gridBg.x = camUI.width-gridBg.width-25;
		prevGridBg.stripes = nextGridBg.stripes = gridBg.stripes = [1];
		gridBg.cameras = prevGridBg.cameras = nextGridBg.cameras = [camUI];
		add(prevGridBg);
		add(nextGridBg);
		add(gridBg);

		var whiteRect1:FlxSprite = new FlxSprite(gridBg.x-2, 0).makeGraphic(2, FlxG.height, FlxColor.WHITE);
		whiteRect1.scrollFactor.set();
		whiteRect1.cameras = [camUI];
		add(whiteRect1);

		var whiteRect2:FlxSprite = new FlxSprite(gridBg.x + gridBg.width, 0).makeGraphic(2, FlxG.height, FlxColor.WHITE);
		whiteRect2.scrollFactor.set();
		whiteRect2.cameras = [camUI];
		add(whiteRect2);

		dummyArrow = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		dummyArrow.setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
		dummyArrow.updateHitbox();
		dummyArrow.cameras = [camUI];
		dummyArrow.scrollFactor.x = 0;
		add(dummyArrow);

		add(behindRenderedNotes);
		add(curRenderedNotes);

		vortexIndicator = new FlxSprite(gridBg.x, FlxG.height/2).makeGraphic(ChartingState.GRID_SIZE, 2, FlxColor.RED);
		vortexIndicator.scrollFactor.set();
		vortexIndicator.cameras = [camUI];
		add(vortexIndicator);

		var thatBG:FlxSprite = new FlxSprite(0, FlxG.height-125).makeGraphic(FlxG.width, 125, FlxColor.BLACK);
		thatBG.alpha = 0.6;
		thatBG.cameras = [camUI];
		thatBG.scrollFactor.set();
		add(thatBG);

		var songLen:Float = (FlxG.sound.music != null ? FlxG.sound.music.length : 0.0001);
		songPosSlider = new PsychUIBar(0, thatBG.y, function(v:Float)
		{
			paused = true;
			if(FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if(vocals != null) vocals.pause();
				if(opponentVocals != null) opponentVocals.pause();
				FlxG.sound.music.time = v;
				Conductor.songPosition = v;
				seek(0);
			}
		}, Conductor.songPosition, 0, songLen, FlxG.width, 0xFF4D4D4D, FlxColor.WHITE);
		songPosSlider.y = thatBG.y;
		songPosSlider.valueText.visible = false;
		songPosSlider.minText.visible = false;
		songPosSlider.maxText.visible = false;
		songPosSlider.scrollFactor.set(0, 0);
		songPosSlider.cameras = [camUI];
		add(songPosSlider);

		modchartBox = new PsychUIBox(0, 0, 300, 280, ['Modchart', 'Song']);
		modchartBox.selectedName = 'Modchart';
		modchartBox.scrollFactor.set();
		modchartBox.cameras = [camUI];
		add(modchartBox);

		addModchartTab();
		addSongTab();

		_cacheSections();

		super.create();

		loadSection(0);
		reloadNotes();
	}

	var selectedEvent:EventMetaNote;

	var subdivisionsStepper:PsychUINumericStepper;
	var modifierInput:PsychUIInputText;
	var actionsDropdown:PsychUIDropDownMenu;
	var timeStepper:PsychUINumericStepper;
	var valueStepper:PsychUINumericStepper;
	var easeInput:PsychUIInputText;
	var playerStepper:PsychUINumericStepper;
	function updateModEvV1():Void {
		if (selectedEvent == null) return;

		var eventNote:EventMetaNote = selectedEvent;

		if (eventNote.events == null || eventNote.events.length == 0) return;

		var myEvent:Array<String> = eventNote.events[0];
		if (myEvent == null) return;

		var eventName:String = (myEvent[0] != null) ? myEvent[0] : '';
		if (eventName != "Modchart Event") return;

		var action:String = (actionsDropdown != null) ? actionsDropdown.selectedLabel : '';
		var modifier:String = (modifierInput != null) ? modifierInput.text : '';
		var timeStr:String = (timeStepper != null) ? Std.string(timeStepper.value) : '';
		var valueStr:String = (valueStepper != null) ? Std.string(valueStepper.value) : '';
		var easeStr:String = (easeInput != null) ? easeInput.text : '';
		var playerStr:String = (playerStepper != null) ? Std.string(playerStepper.value) : '';

		var combined:String = action + "," + modifier + "," + timeStr + "," + valueStr + "," + easeStr + "," + playerStr + ",-1";

		eventNote.events[0][1] = combined;

		eventNote.updateEventText();

		reloadManager();
	}

	function addModchartTab():Void {
		var tabGroupModchart = modchartBox.getTab('Modchart').menu;
		var posX = 10;
		var posY = 25;

		subdivisionsStepper = new PsychUINumericStepper(posX, posY-7.5, 1, 0, 1, 16, 1);
		subdivisionsStepper.value = PlayState.SONG.holdSubdivisions;	
		subdivisionsStepper.onValueChange = () -> {
			PlayState.SONG.holdSubdivisions = Std.int(subdivisionsStepper.value);
		};

		posY += 40;

		modifierInput = new PsychUIInputText(posX+150, posY, 120, '', 8);
    	modifierInput.onChange = function(old:String, cur:String){
			updateModEvV1();
		}

		var modifierLabelText = new FlxText(modifierInput.x, modifierInput.y - 15, 80, 'Modifier:');

		actionsDropdown = new PsychUIDropDownMenu(posX, posY, ["Add Modifier", "Set", "Ease", "EaseAdd", "SetAdd"], function(index:Int, name:String){
			updateModEvV1();
		});

		var actionsLabelText = new FlxText(actionsDropdown.x, actionsDropdown.y - 15, 80, 'Action:');

		posY += 40;

		timeStepper = new PsychUINumericStepper(posX, posY, 0.01, 0, 0, 9999, 2);
		timeStepper.onValueChange = function() {
			updateModEvV1();
		};

		valueStepper = new PsychUINumericStepper(posX + 150, posY, 0.01, 0, -999999, 999999, 2);
		valueStepper.onValueChange = function() {
			updateModEvV1();
		};

		posY += 40;

		easeInput = new PsychUIInputText(posX, posY, 120, '', 8);
		easeInput.onChange = function(old:String, cur:String){
			updateModEvV1();
		}

		posY += 40;

		playerStepper = new PsychUINumericStepper(posX, posY, 1, -1, -1, (PlayState.SONG.lanes - 1), 0);
		playerStepper.onValueChange = function() {
			updateModEvV1();
		};



		var timeLabelText = new FlxText(timeStepper.x, timeStepper.y - 15, 80, 'Time (beats):');
		var valueLabelText = new FlxText(valueStepper.x, valueStepper.y - 15, 80, 'Value:');
		var easeLabelText = new FlxText(easeInput.x, easeInput.y - 15, 80, 'Ease (if ease):');
		var playerLabelText = new FlxText(playerStepper.x, playerStepper.y - 15, 80, 'Player:');
		var subdivisionsLabelText = new FlxText(subdivisionsStepper.x, subdivisionsStepper.y - 15, 80, 'Subdivisions:');

		tabGroupModchart.add(subdivisionsStepper);
		tabGroupModchart.add(subdivisionsLabelText);
		tabGroupModchart.add(modifierInput);
		tabGroupModchart.add(modifierLabelText);
		tabGroupModchart.add(actionsLabelText);
		tabGroupModchart.add(timeStepper);
		tabGroupModchart.add(valueStepper);
		tabGroupModchart.add(easeInput);
		tabGroupModchart.add(playerStepper);
		tabGroupModchart.add(timeLabelText);
		tabGroupModchart.add(valueLabelText);
		tabGroupModchart.add(easeLabelText);
		tabGroupModchart.add(playerLabelText);
		tabGroupModchart.add(actionsDropdown);
	}

	function addSongTab():Void {
		var tabGroup = modchartBox.getTab('Song').menu;
		var posX = 10;
		var posY = 25;

		var saveButton:PsychUIButton = new PsychUIButton(posX, posY, 'Save Modchart', function()
		{
			saveChart();
		}, 100);
		saveButton.normalStyle.bgColor = FlxColor.GREEN;
		saveButton.normalStyle.textColor = FlxColor.WHITE;
		tabGroup.add(saveButton);
	}

	var vortexIndicator:FlxSprite;
	function createEvent(event:Dynamic)
	{
		if(event[1][0][0] != "Modchart Event") return null;
		var daStrumTime:Float = event[0];
		var swagEvent:EventMetaNote = new EventMetaNote(daStrumTime, event);
		swagEvent.x = gridBg.x;
		swagEvent.cameras = [camUI];
		swagEvent.eventText.cameras = [camUI];
		swagEvent.eventText.x = swagEvent.x - swagEvent.eventText.width - 10;
		swagEvent.scrollFactor.x = 0;
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

	function adaptNotesToNewTimes(oldTimes:Array<Float>){
		var gridLerp:Float = FlxMath.bound((scrollY + FlxG.height/2 - gridBg.y) / gridBg.height, 0.000001, 0.999999);
		_cacheSections();
		
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

	function updateScrollY()
	{
		var secStartTime:Null<Float> = cast cachedSectionTimes[curSec];
		var secCrochet:Null<Float> = cast cachedSectionCrochets[curSec];
		var secRows:Null<Float> = cast cachedSectionRow[curSec];
		if(secStartTime == null || secCrochet == null || secRows == null) return;

		scrollY = (((Conductor.songPosition - secStartTime) / secCrochet * ChartingState.GRID_SIZE * 4) + (secRows * ChartingState.GRID_SIZE)) * curZoom - FlxG.height/2;
	}

	var sectionFirstNoteID:Int = 0;
	var sectionFirstEventID:Int = 0;
	var curSec:Int = 0;
	var cachedSectionRow:Array<Int>;
	var cachedSectionTimes:Array<Float>;
	var cachedSectionCrochets:Array<Float>;
	var cachedSectionBPMs:Array<Float>;
	var showPreviousSection:Bool = true;
	var showNextSection:Bool = true;
	var showNoteTypeLabels:Bool = true;
	var forceDataUpdate:Bool = true;
	var scrollY:Float = 0;
	
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
	function loadSection(?sec:Null<Int> = null)
	{
		if(sec != null) curSec = sec;
		curSec = Std.int(FlxMath.bound(curSec, 0, PlayState.SONG.notes.length-1));
		Conductor.bpm = cachedSectionBPMs[curSec];

		var hei:Float = 0;
		if(curSec > 0)
		{
			prevGridBg.y = cachedSectionRow[curSec-1] * ChartingState.GRID_SIZE * curZoom;
			prevGridBg.rows = 4 * PlayState.SONG.notes[curSec-1].sectionBeats * curZoom;
			prevGridBg.visible = showPreviousSection;
			hei += prevGridBg.height;
		}
		else prevGridBg.visible = false;

		if(curSec < PlayState.SONG.notes.length - 1)
		{
			nextGridBg.y = cachedSectionRow[curSec+1] * ChartingState.GRID_SIZE * curZoom;
			nextGridBg.rows = 4 * PlayState.SONG.notes[curSec+1].sectionBeats * curZoom;
			nextGridBg.visible = showNextSection;
			hei += nextGridBg.height;
		}
		else nextGridBg.visible = false;

		gridBg.y = cachedSectionRow[curSec] * ChartingState.GRID_SIZE * curZoom;
		gridBg.rows = 4 * PlayState.SONG.notes[curSec].sectionBeats * curZoom;
		hei += gridBg.height;

		softReloadNotes();

		prevGridBg.vortexLineEnabled = gridBg.vortexLineEnabled = nextGridBg.vortexLineEnabled = true;
		prevGridBg.vortexLineSpace = gridBg.vortexLineSpace = nextGridBg.vortexLineSpace = ChartingState.GRID_SIZE * 4 * curZoom;
	}

	inline function getCurChartSection()
	{
		return PlayState.SONG.notes != null ? PlayState.SONG.notes[curSec] : null;
	}

	var behindRenderedNotes:FlxTypedGroup<MetaNote> = new FlxTypedGroup<MetaNote>();
	var curRenderedNotes:FlxTypedGroup<MetaNote> = new FlxTypedGroup<MetaNote>();
	var events:Array<EventMetaNote> = [];
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

		for (num => event in events)
		{
			if(event != null && curSecFilter(event))
			{
				if(!firstEvent) sectionFirstEventID = num;
				curRenderedNotes.add(event);
				event.alpha = (event.strumTime >= Conductor.songPosition) ? 1 : 0.6;
				event.eventText.visible = true;
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

				for(event in events.filter(otherSecFilter)){
					behindRenderedNotes.add(event);
					event.alpha = 0.4;
					event.eventText.visible = false;
				}
			}
		}
	}

	function reloadNotes()
	{
		for (event in events) if(event != null) event.destroy();
		events = [];

		for (eventNum => event in PlayState.SONG.events){
			if(event != null && (cachedSectionTimes.length < 1 || event[0] < cachedSectionTimes[cachedSectionTimes.length-1])){ //dont spawn events over the time limit
				var daEvent = createEvent(event);
				if(daEvent == null) continue;
				events.push(daEvent);
			}
		}
		events.sort(CoolUtil.sortByTime);

		loadSection();
	}

	function getMinNoteTime(sec:Int)
	{
		var minTime:Float = Math.NEGATIVE_INFINITY;
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
	
	function positionNoteXByData(note:MetaNote, ?data:Null<Int> = null)
	{
		if (data == null)
			data = note.songData[1];

		var noteX:Float = gridBg.x + (ChartingState.GRID_SIZE - note.width) / 2;
		noteX += ChartingState.GRID_SIZE;

		var lane:Int = Std.int(data % ChartingState.GRID_COLUMNS_PER_PLAYER);
		var groupIndex:Int = 0;

		if (note.gfStrum)
		{
			groupIndex = 2;
		}
		else
		{
			var sec:Int = 0;
			for (i in 0...cachedSectionTimes.length)
			{
				if (i == cachedSectionTimes.length - 1 ||
					(note.strumTime >= cachedSectionTimes[i] && note.strumTime < cachedSectionTimes[i + 1]))
				{
					sec = i;
					break;
				}
			}

			if (sec < 0) sec = 0;
			if (sec >= PlayState.SONG.notes.length) sec = PlayState.SONG.notes.length - 1;

			var section = PlayState.SONG.notes[sec];
			if (section != null && section.mustHitSection)
			{
				groupIndex = note.mustPress ? 0 : 1;
			}
			else
			{
				groupIndex = note.mustPress ? 1 : 0;
			}
		}

		if (groupIndex == 2)
			note.gfStrum = true;

		if (groupIndex >= ChartingState.GRID_PLAYERS) groupIndex = ChartingState.GRID_PLAYERS - 1;
		if (groupIndex < 0) groupIndex = 0;
		if (note.gfStrum)
			groupIndex = 2;

		noteX += ChartingState.GRID_SIZE * (groupIndex * ChartingState.GRID_COLUMNS_PER_PLAYER + lane);

		note.x = noteX;
	}

	function positionNoteYOnTime(note:MetaNote, section:Int)
	{
		var time:Float = note.strumTime - cachedSectionTimes[section];
		var noteY:Float = (time / cachedSectionCrochets[section]) * ChartingState.GRID_SIZE * 4 * curZoom;
		noteY += cachedSectionRow[section] * ChartingState.GRID_SIZE * curZoom;
		noteY = Math.max(noteY, -150);
		note.y = noteY + (ChartingState.GRID_SIZE/2 - note.height/2);
		note.chartY = noteY;
	}

	var curQuant(default, set):Int = 16;
	function set_curQuant(v:Int)
	{
		curQuant = v;
		return curQuant;
	}

	function goToPlayState()
	{
		StageData.loadDirectory(PlayState.SONG);
		LoadingState.loadAndSwitchState(new PlayState());
		ClientPrefs.toggleVolumeKeys(true);
	}

	private var isCrosshair:Bool = false;
	override function update(elapsed:Float)
	{
		if(FlxG.sound.music.playing) songPosSlider.value = Conductor.songPosition;

		ClientPrefs.toggleVolumeKeys(PsychUIInputText.focusOn == null);
		updateScrollY();
		camUI.scroll.y = scrollY;

		if(FlxG.sound.music != null)
		{
			while(curSec > 0 && Conductor.songPosition < cachedSectionTimes[curSec])
				loadSection(curSec - 1);
			while(curSec < cachedSectionTimes.length - 1 && Conductor.songPosition >= cachedSectionTimes[curSec + 1])
				loadSection(curSec + 1);
		}

		if (FlxG.keys.justPressed.SPACE && PsychUIInputText.focusOn == null)
			togglePause();

		if (FlxG.keys.justPressed.RIGHT && PsychUIInputText.focusOn == null)
			seek(Conductor.stepCrochet);

		if (FlxG.keys.justPressed.LEFT && PsychUIInputText.focusOn == null)
			seek(-Conductor.stepCrochet);

		if (FlxG.keys.justPressed.D && PsychUIInputText.focusOn == null)
			seek(Conductor.stepCrochet*4*4);

		if (FlxG.keys.justPressed.A && PsychUIInputText.focusOn == null)
			seek(-Conductor.stepCrochet*4*4);

		if((controls.BACK || FlxG.keys.justPressed.ESCAPE) && PsychUIInputText.focusOn == null)
		{
			goToPlayState();
			super.update(elapsed);
			return;
		}
		
		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) startSong();
		}
		else if(!paused) Conductor.songPosition += elapsed * 1000 * playbackRate;

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				dunceNote.cameras = [camHUD];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if(modManager != null){
			modManager.updateTimeline(curDecStep);
			modManager.update(elapsed);
		}
		notesFollow();

		var minX:Float = gridBg.x;
		if(FlxG.mouse.x >= minX && FlxG.mouse.x < gridBg.x + gridBg.width)
		{
			//if((!FlxG.mouse.overlaps(mainBox.bg) || !FlxG.mouse.overlaps(infoBox.bg))){
				Mouse.cursor = MouseCursor.CROSSHAIR;
				isCrosshair = true;
			//}
			var diffX:Float = FlxG.mouse.x - gridBg.x;
			var diffY:Float = (FlxG.mouse.y+camUI.scroll.y) - gridBg.y;
			if(!FlxG.keys.pressed.SHIFT)
				diffY -= diffY % (ChartingState.GRID_SIZE / (curQuant/16));

			if(nextGridBg.visible) diffY = Math.min(diffY, gridBg.height + nextGridBg.height);
			else diffY = Math.min(diffY, gridBg.height);

			if(prevGridBg.visible) diffY = Math.max(diffY, -prevGridBg.height);
			else diffY = Math.max(diffY, 0);

			var noteData:Int = Math.floor(diffX / ChartingState.GRID_SIZE);
			dummyArrow.x = gridBg.x + noteData * ChartingState.GRID_SIZE;
			dummyArrow.visible = true;
			noteData--;

			if(FlxG.keys.justPressed.Z != FlxG.keys.justPressed.X) //Decrease/Increase Zoom
				{
					if(FlxG.keys.justPressed.Z)
						curZoom = zoomList[Std.int(Math.max(zoomList.indexOf(curZoom) - 1, 0))];
					else
						curZoom = zoomList[Std.int(Math.min(zoomList.indexOf(curZoom) + 1, zoomList.length - 1))];
	
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
					showOutput('Zoom: ${Math.round(curZoom * 100)}%');
					updateScrollY();
				}

			if(FlxG.keys.pressed.SHIFT || (FlxG.mouse.y+camUI.scroll.y) >= gridBg.y || !prevGridBg.visible)
				dummyArrow.y = gridBg.y + diffY;
			else
			{
				var t:Float = (diffY - (ChartingState.GRID_SIZE / (curQuant/16)));
				if((FlxG.mouse.y+camUI.scroll.y) >= gridBg.y) t *= curZoom;
				dummyArrow.y = gridBg.y + t;
			}
			if(FlxG.mouse.justPressed)
			{
				if(FlxG.mouse.x >= gridBg.x && FlxG.mouse.x < gridBg.x + gridBg.width)
				{
					var closeNotes:Array<MetaNote> = curRenderedNotes.members.filter(function(note:MetaNote)
					{
						var chartY:Float = (FlxG.mouse.y+camUI.scroll.y) - note.chartY;
						return (note.isEvent && noteData < 0) && chartY >= 0 && chartY < ChartingState.GRID_SIZE;
					});
					closeNotes.sort(function(a:MetaNote, b:MetaNote) return Math.abs(a.strumTime - (FlxG.mouse.y+camUI.scroll.y)) < Math.abs(b.strumTime - (FlxG.mouse.y+camUI.scroll.y)) ? 1 : -1);

					var closest = closeNotes[0];
					if(closest != null)
					{
						if(!FlxG.keys.pressed.CONTROL)
						{
							for (i in 0...PlayState.SONG.events.length)
							{
								if (PlayState.SONG.events[i][0] == closest.strumTime)
								{
									PlayState.SONG.events.splice(i, 1);
									break;
								}
							}

							var evNote:EventMetaNote = cast(closest, EventMetaNote);
							events.remove(evNote);
							if(selectedEvent == evNote) selectedEvent = null;
							curRenderedNotes.remove(closest, true);
							closest.destroy();

							FlxG.sound.play(Paths.sound('chartingSounds/noteErase'));
							reloadManager();
						} else {
							selectedEvent = cast (closest, EventMetaNote);
							reloadEventText();
						}
					} else if((FlxG.mouse.y+camUI.scroll.y) >= gridBg.y && (FlxG.mouse.y+camUI.scroll.y) < gridBg.y + gridBg.height){ // Add note
						var strumTime:Float = (diffY / ChartingState.GRID_SIZE * Conductor.stepCrochet / curZoom) + cachedSectionTimes[curSec];

						var didAdd:Bool = false;
						var eventAdded:EventMetaNote;
						FlxG.sound.play(Paths.sound('chartingSounds/noteLay'));

						var action:String = (actionsDropdown != null && actionsDropdown.selectedLabel != null) ? actionsDropdown.selectedLabel : "";
						var modifier:String = (modifierInput != null) ? modifierInput.text : "";
						var timeStr:String = (timeStepper != null) ? Std.string(timeStepper.value) : "";
						var valueStr:String = (valueStepper != null) ? Std.string(valueStepper.value) : "";
						var easeStr:String = (easeInput != null) ? easeInput.text : "";
						var playerStr:String = (playerStepper != null) ? Std.string(playerStepper.value) : "";
						var combined:String = action + "," + modifier + "," + timeStr + "," + valueStr + "," + easeStr + "," + playerStr + ",-1";

						var evData:Array<Dynamic> = [strumTime, [["Modchart Event", combined, ""]]];
						eventAdded = createEvent(evData);
						for (num in sectionFirstEventID...events.length){
							var event = events[num];       
							if(event.strumTime >= strumTime){
								events.insert(num, eventAdded);
								selectedEvent = eventAdded;
								reloadEventText();
								PlayState.SONG.events.insert(num, evData);
								reloadManager();
								didAdd = true;
								break;
							}
						}
						if(!didAdd){
							events.push(eventAdded);
							PlayState.SONG.events.push(evData);
							reloadManager();
							selectedEvent = eventAdded;
							reloadEventText();
						}
						softReloadNotes();
					}
				} else selectedEvent = null;
			}
		} else dummyArrow.visible = false;

		if(modManager != null){
			for(field in PlayField.fields){
				field.forEachAlive(function(strum:StrumNote)
				{
					var pos = modManager.getPos(0, 0, 0, curDecBeat, strum.noteData, field.player, strum, [], strum.vec3Cache);
					modManager.updateObject(curDecBeat, strum, pos, field.player);
					strum.modPos.x = pos.x;
					strum.modPos.y = pos.y;
					strum.z = pos.z;
				});
			}
		}
		strumLineNotes.sort(PlayState.sortByOrderStrumNote);
		
		super.update(elapsed);
	}

	function reloadEventText(){
		if(selectedEvent != null){
			var myEvent:Array<String> = selectedEvent.events[0];
			if(myEvent != null){
				var eventName:String = (myEvent[0] != null) ? myEvent[0] : '';
				if (eventName == "Modchart Event") {
					var combined:String = (myEvent[1] != null) ? myEvent[1] : "";
					if (combined != "") {
						var parts:Array<String> = combined.split(",");
						while (parts.length < 7) parts.push("");
						if (actionsDropdown != null) {
							actionsDropdown.selectedLabel = parts[0];
						}
						if (modifierInput != null) modifierInput.text = parts[1];
						if (timeStepper != null) {
							var tVal:Float = 0;
							try {tVal = Std.parseFloat(parts[2]);} catch(e:Dynamic) {tVal = timeStepper.value;}
							timeStepper.value = tVal;
						}
						if (valueStepper != null) {
							var vVal:Float = 0;
							try {vVal = Std.parseFloat(parts[3]);} catch(e:Dynamic) {vVal = valueStepper.value;}
							valueStepper.value = vVal;
						}
						if (easeInput != null) easeInput.text = parts[4];
						if (playerStepper != null) {
							var pVal:Int = 0;
							try pVal = {Std.parseInt(parts[5]);} catch(e:Dynamic) {pVal = Std.int(playerStepper.value);}
							playerStepper.value = pVal;
						}

					} else {
						if (actionsDropdown != null) actionsDropdown.selectedIndex = 0;
						if (modifierInput != null) modifierInput.text = "";
						if (timeStepper != null) timeStepper.value = 0;
						if (valueStepper != null) valueStepper.value = 0;
						if (easeInput != null) easeInput.text = "";
						if (playerStepper != null) playerStepper.value = -1;
					}
				}
			}
		}
	}

	function notesFollow(){
		if(notes.length > 0)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				noteFollowStrum(daNote);

				if(daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					opponentNoteHit(daNote);

				if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
				{
					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}
	}

	public function noteFollowStrum(daNote:Note){
		if(modManager == null) return;
		var pN:Int = daNote.playField.player;
		var pos = modManager.getPos(daNote.strumTime, modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed),
			daNote.strumTime - Conductor.songPosition, curDecBeat, daNote.noteData, pN, daNote, [], daNote.vec3Cache);

    	daNote.distance = modManager.getVisPos(Conductor.songPosition, daNote.strumTime, songSpeed);

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
	
	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if (PlayState.SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
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
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}
	
	override function sectionHit()
	{
		if (PlayState.SONG.notes[curSection] != null)
		{
			if (PlayState.SONG.notes[curSection].changeBPM){
				Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
			}
		}
		super.sectionHit();
	}

	override function destroy()
	{
		FlxG.cameras.remove(camHUD);
		camHUD.destroy();
		FlxG.sound.list.remove(inst);
		if(vocals != null){
			vocals.stop();
			FlxG.sound.list.remove(vocals);
		}
		if(opponentVocals != null){
			opponentVocals.stop();
			FlxG.sound.list.remove(opponentVocals);
		}
		flixel.util.FlxDestroyUtil.destroy(inst);
		camHUD = null;
		super.destroy();
	}
	
	function startSong():Void
	{
		startingSong = false;
		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.time = startPos;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong;
		//vocals.volume = 1;
		vocals.time = startPos;
		vocals.play();
		//opponentVocals.volume = 1;
		opponentVocals.time = startPos;
		opponentVocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
	}

	// Borrowed from PlayState
	function generateSong(dataPath:String)
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);

		var songData = PlayState.SONG;
		Conductor.bpm = songData.bpm;

		var boyfriendVocals:String = loadCharacterFile(PlayState.SONG.player1).vocals_file;
		var dadVocals:String = loadCharacterFile(PlayState.SONG.player2).vocals_file;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();

		try
		{
			if (songData.needsVoices || Paths.voices(songData.song) != null)
			{
				var playerVocals = Paths.voices(songData.song, boyfriendVocals);
				if (playerVocals == null)
					playerVocals = Paths.voices(songData.song);
				if (playerVocals != null)
				{
					vocals.loadEmbedded(playerVocals);
					FlxG.sound.list.add(vocals);
					vocals.persist = true;
					vocals.looped = true;
					vocals.volume = 0;
					vocals.play();
					vocals.pause();
				}

				var oppVocals = Paths.voices(songData.song, dadVocals);
				if (oppVocals == null)
					oppVocals = Paths.voices(songData.song);
				if (oppVocals != null)
				{
					opponentVocals.loadEmbedded(oppVocals);
					FlxG.sound.list.add(opponentVocals);
					opponentVocals.persist = true;
					opponentVocals.looped = true;
					opponentVocals.volume = 0;
					opponentVocals.play();
					opponentVocals.pause();
				}
			}
		}
		catch (e:Dynamic) {}

		vocals.volume = 1;
		opponentVocals.volume = 1;

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		FlxG.sound.list.add(inst);
		FlxG.sound.music.volume = 0;

		notes = new FlxTypedGroup<Note>();
		notes.cameras = [camHUD];
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		initialCrochet = Conductor.crochet;
		var holdCrochet:Float = Math.max(Conductor.stepCrochet / PlayState.SONG.holdSubdivisions, 10);

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if(daStrumTime < startPos) continue;

				var daNoteData:Int = Std.int(songNotes[1] % (PlayState.SONG.mania + 1));
				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, true, this);
				swagNote.row = Conductor.secsToRow(daStrumTime);
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<(PlayState.SONG.mania + 1)));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				final fieldID:Int = songNotes[4];
				swagNote.mustPress = (fieldID == 0 ? false : (fieldID == 1 ? true : false));
				swagNote.playField = PlayField.fields[fieldID];
				swagNote.gfStrum = (songNotes[4] == 2 ? true : false);
				if(swagNote.gfStrum) swagNote.mustPress = false;

				swagNote.scrollFactor.set();
				swagNote.cameras = [camHUD];
				allNotes.push(swagNote);
				unspawnNotes.push(swagNote);

				final susLength = (swagNote.sustainLength / holdCrochet);
				final floorSus:Int = Math.floor(susLength);

				if(floorSus > 0) {
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (holdCrochet * susNote), daNoteData, oldNote, true, true, this);
						sustainNote.sustainLength = holdCrochet;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.gfStrum = swagNote.gfStrum;
						sustainNote.parent = swagNote;
						sustainNote.playField = swagNote.playField;
						sustainNote.scrollFactor.set();
						sustainNote.cameras = [camHUD];
						allNotes.push(sustainNote);
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

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
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
			}
		}

		unspawnNotes.sort(CoolUtil.sortByTime);
	}
	
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;

		var playField:PlayField = null;
		switch (player)
		{
			case 1: playField = playerStrums;
			case 2: playField = gfStrums;
			default: playField = opponentStrums;
		}

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
			babyArrow.cameras = [camHUD];
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player != 1 && player != 2)
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1)
					{
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();

			i++;
		}
	}

	public function finishSong():Void
	{
		if(ClientPrefs.data.noteOffset <= 0) {
			endSong();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endSong();
			});
		}
	}

	public function endSong()
	{
		vocals.pause();
		vocals.destroy();
		opponentVocals.pause();
		opponentVocals.destroy();
		if(finishTimer != null)
		{
			finishTimer.cancel();
			finishTimer.destroy();
		}
		//close();
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
	}
	
	function opponentNoteHit(note:Note):Void
	{
		var strum:StrumNote = note.strum;
		if(strum != null) {
			strum.playAnim('confirm', true);
			strum.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
		}
		note.hitByOpponent = true;

		if (!note.isSustainNote)
			invalidateNote(note);
	}
	
	function resyncVocals():Void
	{
		if(paused) return;
		if(finishTimer != null) return;

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
		vocals.play();
		opponentVocals.play();
	}
	
	function loadCharacterFile(char:String):CharacterFile {
		var characterPath:String = 'characters/' + char + '.json';
		var isJSON:Bool = true;
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			isJSON = true;
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end
		return cast Json.parse(rawJson);
	}

	function togglePause()
	{
		paused = !paused;

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		else
		{
			FlxG.sound.music.play();
			vocals.play();
			opponentVocals.play();
		}
	}

	function seek(delta:Float){
		var newTime = Math.max(0, FlxG.sound.music.time + delta);

		// Audio
		FlxG.sound.music.time = newTime;
		vocals.time = newTime;
		opponentVocals.time = newTime;
		Conductor.songPosition = newTime;

		for (note in notes)
		{
			note.kill();
		}
		notes.clear();

		unspawnNotes = [];

		for (note in allNotes)
		{
			note.revive();
			note.spawned = false;
			note.wasGoodHit = false;
			note.hitByOpponent = false;
			note.tooLate = false;
			note.visible = true;
			note.active = true;

			if(note.isSustainNote)
				if(note.clipRect != null)
					note.clipRect = null;

			if (note.strumTime >= newTime)
			{
				unspawnNotes.push(note);
			}
			else if (note.isSustainNote)
			{
				if (note.parent != null && note.parent.strumTime + note.parent.sustainLength >= newTime)
				{
					notes.add(note);
					note.spawned = true;
				}
				else
				{
					note.kill();
				}
			}
			else
			{
				note.kill();
			}
		}

		unspawnNotes.sort(CoolUtil.sortByTime);
		if(delta > 0) return;
		reloadManager();
	}

	function reloadManager(){
		modManager = new ModManager(this);
		modManager.receptors = [for(i in PlayField.fields) i.members];
		modManager.registerDefaultModifiers();
		modManager.registerScriptedModifiers();
		
		for (songEvent in PlayState.SONG.events){
			for (i in 0...songEvent[1].length){
				var evName:String = songEvent[1][i][0];
				if(evName == "Modchart Event"){
					var value1:String = songEvent[1][i][1];
					if(value1 == null) continue;
					var info = value1.split(',');
					final daBeat:Float = Conductor.getBeat(songEvent[0] + ClientPrefs.data.noteOffset);
					var ease = FlxEase.linear;
					if(info[4] != null) ease = LuaUtils.getTweenEaseByString(info[4]);

					switch(info[0]){
						case "Ease": modManager.ease(info[1], daBeat, Std.parseFloat(info[2]), Std.parseFloat(info[3]), ease, Std.parseInt(info[5]), Std.parseInt(info[6]));
						case "Set": modManager.set(info[1], daBeat, Std.parseFloat(info[3]), Std.parseInt(info[5]), Std.parseInt(info[6]));
					}
				}
			}
		}
	}

	private var outputGroup:Array<FlxText> = [];
	function showOutput(message:String, isError:Bool = false, isSave:Bool = false)
	{
		var outputTxt = new FlxText(25, FlxG.height - 50, FlxG.width - 50, '', 20);
		outputTxt.borderSize = 2;
		outputTxt.borderStyle = OUTLINE_FAST;
		outputTxt.scrollFactor.set();
		outputTxt.cameras = [camUI];
		outputTxt.alpha = 1;
		outputTxt.text = message;
		outputTxt.y = FlxG.height - outputTxt.height - 30;
		add(outputTxt);
		outputGroup.push(outputTxt);
		for(txt in outputGroup)
		{
			if(txt == null) continue;
			if(txt == outputTxt) continue;
			FlxTween.cancelTweensOf(txt, ["y"]);
			FlxTween.tween(txt, {y: txt.y - 35}, 0.2, {ease: FlxEase.cubeOut});
		}
		if(isError)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			outputTxt.color = FlxColor.RED;
		}
		else if(isSave)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
			outputTxt.color = FlxColor.GREEN;
		}
		else
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			outputTxt.color = FlxColor.WHITE;
		}
		FlxTween.tween(outputTxt, {alpha: 0}, 5, {ease: FlxEase.cubeIn, onComplete: function(twn:FlxTween)
		{
			outputGroup.remove(outputTxt);
			outputTxt.destroy();
		}});
	}

	public function saveChart(auto:Bool = true, dif:String = null)
	{
		PlayState.SONG.format = "notepulse";

		if (PlayState.SONG.events != null && PlayState.SONG.events.length > 1)
			PlayState.SONG.events.sort(CoolUtil.sortByTime);

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
				showOutput('Failed to save chart: Song.chartPath is null or empty', true);
				return;
			}

			var chartDir = haxe.io.Path.directory(chartPath);
			if (!sys.FileSystem.exists(chartDir))
			{
				var ensureDirectory = function(path:String)
				{
					var parent = haxe.io.Path.directory(path);
					if (parent != "" && !sys.FileSystem.exists(parent))
						ChartingState.ensureDirectory(parent);
					if (!sys.FileSystem.exists(path))
						sys.FileSystem.createDirectory(path);
				}
				ChartingState.ensureDirectory(chartDir);
			}

			try
			{
				sys.io.File.saveContent(chartPath, data.trim());
				showOutput('Saved to: $chartPath', false, true);
			}
			catch (e:Dynamic)
			{
				showOutput('Failed to save chart: $e', true);
			}
		}
		else
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Song.chartPath);
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
}