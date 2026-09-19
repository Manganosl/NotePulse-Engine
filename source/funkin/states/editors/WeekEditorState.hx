package funkin.states.editors;

import funkin.data.WeekData;

import openfl.utils.Assets;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;
import haxe.Json;

import flixel.addons.transition.FlxTransitionableState;

import funkin.objects.HealthIcon;
import funkin.objects.MenuCharacter;
import funkin.objects.MenuItem;

import funkin.states.MainMenuState;
import funkin.states.editors.content.Prompt;

import funkin.states.editors.ui.WeekEditorUI;

class WeekEditorState extends MusicBeatState
{
	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	var lock:FlxSprite;
	var txtTracklist:FlxText;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var weekThing:MenuItem;
	var missingFileText:FlxText;

	var UI:WeekEditorUI;

	public static var unsavedProgress:Bool = false;

	var weekFile:WeekFile = null;
	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if(weekFile != null) this.weekFile = weekFile;
		else weekFileName = 'week1';
	}

	override function create() {
		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		
		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = ClientPrefs.data.antialiasing;

		weekThing = new MenuItem(0, bgSprite.y + 396, weekFileName);
		weekThing.y += weekThing.height + 20;
		weekThing.antialiasing = ClientPrefs.data.antialiasing;
		add(weekThing);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);
		
		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		
		lock = new FlxSprite();
		lock.frames = ui_tex;
		lock.animation.addByPrefix('lock', 'lock');
		lock.animation.play('lock');
		lock.antialiasing = ClientPrefs.data.antialiasing;
		add(lock);
		
		missingFileText = new FlxText(0, 0, FlxG.width, "");
		missingFileText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingFileText.borderSize = 2;
		missingFileText.visible = false;
		add(missingFileText); 
		
		var charArray:Array<String> = weekFile.weekCharacters;
		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 435).loadGraphic(Paths.image('Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.font("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(txtWeekTitle);

		UI = new WeekEditorUI(this);
		UI.createUI();
		add(UI);

		reloadAllShit();

		FlxG.mouse.visible = true;

		super.create();
	}

	public static var weekFileName:String = 'week1';

	//Used on onCreate and when you load a week
	function reloadAllShit() {
		var weekString:String = weekFile.songs[0][0];
		for (i in 1...weekFile.songs.length) {
			weekString += ', ' + weekFile.songs[i][0];
		}
		UI.songsInputText.text = weekString;
		UI.backgroundInputText.text = weekFile.weekBackground;
		UI.displayNameInputText.text = weekFile.storyName;
		UI.weekNameInputText.text = weekFile.weekName;
		UI.weekFileInputText.text = weekFileName;
		
		UI.opponentInputText.text = weekFile.weekCharacters[0];
		UI.boyfriendInputText.text = weekFile.weekCharacters[1];
		UI.girlfriendInputText.text = weekFile.weekCharacters[2];

		UI.hideCheckbox.checked = weekFile.hideStoryMode;

		UI.weekBeforeInputText.text = weekFile.weekBefore;

		UI.difficultiesInputText.text = '';
		if(weekFile.difficulties != null) UI.difficultiesInputText.text = weekFile.difficulties;

		UI.lockedCheckbox.checked = !weekFile.startUnlocked;
		lock.visible = UI.lockedCheckbox.checked;
		
		UI.hiddenUntilUnlockCheckbox.checked = weekFile.hiddenUntilUnlocked;
		UI.hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (UI.lockedCheckbox.checked ? 1 : 0);

		reloadBG();
		reloadWeekThing();
		updateText();
	}

	function updateText()
	{
		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekFile.weekCharacters[i]);
		}

		var stringThing:Array<String> = [];
		for (i in 0...weekFile.songs.length) {
			stringThing.push(weekFile.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;
		
		txtWeekTitle.text = weekFile.storyName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);
	}

	function reloadBG() {
		bgSprite.visible = true;
		var assetName:String = weekFile.weekBackground;

		var isMissing:Bool = true;
		if(assetName != null && assetName.length > 0) {
			if( #if MODS_ALLOWED FileSystem.exists(Paths.modsImages('menubackgrounds/menu_' + assetName)) || #end
			Assets.exists(Paths.getPath('images/menubackgrounds/menu_' + assetName + '.png', IMAGE), IMAGE)) {
				bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + assetName));
				isMissing = false;
			}
		}

		if(isMissing) {
			bgSprite.visible = false;
		}
	}

	function reloadWeekThing() {
		weekThing.visible = true;
		missingFileText.visible = false;
		var assetName:String = UI.weekFileInputText.text.trim();
		
		var isMissing:Bool = true;
		if(assetName != null && assetName.length > 0) {
			if( #if MODS_ALLOWED FileSystem.exists(Paths.modsImages('storymenu/' + assetName)) || #end
			Assets.exists(Paths.getPath('images/storymenu/' + assetName + '.png', IMAGE), IMAGE)) {
				weekThing.loadGraphic(Paths.image('storymenu/' + assetName));
				isMissing = false;
			}
		}

		if(isMissing) {
			weekThing.visible = false;
			missingFileText.visible = true;
			missingFileText.text = 'MISSING FILE: images/storymenu/' + assetName + '.png';
		}
		recalculateStuffPosition();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Week Editor", "Editting: " + weekFileName);
		#end
	}
	
	override function update(elapsed:Float)
	{
		if(loadedWeek != null) {
			weekFile = loadedWeek;
			loadedWeek = null;

			reloadAllShit();
		}

		if(UIInputText.focusOn == null)
		{
			ClientPrefs.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.ESCAPE)
			{
				if(!unsavedProgress)
				{
					MusicBeatState.switchState(new MainMenuState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				else openSubState(new ExitConfirmationPrompt(function() unsavedProgress = false));
			}
		}
		else ClientPrefs.toggleVolumeKeys(false);

		super.update(elapsed);

		lock.y = weekThing.y;
		missingFileText.y = weekThing.y + 36;
	}

	function recalculateStuffPosition() {
		weekThing.screenCenter(X);
		lock.x = weekThing.width + 10 + weekThing.x;
	}

	private static var _file:FileReference;
	public static function loadWeek() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([#if !mac jsonFilter #end]);
	}
	
	public static var loadedWeek:WeekFile = null;
	public static var loadError:Bool = false;
	private static function onLoadComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if(fullPath != null) {
			var rawJson:String = File.getContent(fullPath);
			if(rawJson != null) {
				loadedWeek = cast Json.parse(rawJson);
				if(loadedWeek.weekCharacters != null && loadedWeek.weekName != null) //Make sure it's really a week
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					trace("Successfully loaded file: " + cutName);
					loadError = false;

					weekFileName = cutName;
					_file = null;
					unsavedProgress = false;
					return;
				}
			}
		}
		loadError = true;
		loadedWeek = null;
		_file = null;
		#else
		trace("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
		private static function onLoadCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onLoadError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		trace("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile) {
		var data:String = haxe.Json.stringify(weekFile, "\t");
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, weekFileName + ".json");
		}
	}
	
	private static function onSaveComplete(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
		unsavedProgress = false;
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
		private static function onSaveCancel(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		trace("Cancelled file saving.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onSaveError(_):Void
	{
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}

class WeekEditorFreeplayState extends MusicBeatState
{
	var weekFile:WeekFile = null;
	public function new(weekFile:WeekFile = null)
	{
		super();
		this.weekFile = WeekData.createWeekFile();
		if(weekFile != null) this.weekFile = weekFile;
	}

	var bg:FlxSprite;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<HealthIcon> = [];

	var curSelected = 0;

	var UI:WeekEditorFreeplayUI;

	override function create() {
		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = FlxColor.WHITE;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...weekFile.songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, weekFile.songs[i][0], true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			var icon:HealthIcon = new HealthIcon(weekFile.songs[i][1]);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		UI = new WeekEditorFreeplayUI(this);
		UI.createUI();
		add(UI);

		changeSelection();
		super.create();
	}

	function updateBG() {
		weekFile.songs[curSelected][2][0] = Math.round(UI.bgColorStepperR.value);
		weekFile.songs[curSelected][2][1] = Math.round(UI.bgColorStepperG.value);
		weekFile.songs[curSelected][2][2] = Math.round(UI.bgColorStepperB.value);
		bg.color = FlxColor.fromRGB(weekFile.songs[curSelected][2][0], weekFile.songs[curSelected][2][1], weekFile.songs[curSelected][2][2]);
	}

	function changeSelection(change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, weekFile.songs.length - 1);
		for (num => item in grpSongs.members)
		{
			var icon:HealthIcon = iconArray[num];
			item.targetY = num - curSelected;
			item.alpha = 0.6;
			icon.alpha = 0.6;
			if (item.targetY == 0)
			{
				item.alpha = 1;
				icon.alpha = 1;
			}
		}
		//trace(weekFile.songs[curSelected]);
		UI.iconInputText.text = weekFile.songs[curSelected][1];

		var colors = weekFile.songs[curSelected][2];
		UI.bgColorStepperR.value = Math.round(colors[0]);
		UI.bgColorStepperG.value = Math.round(colors[1]);
		UI.bgColorStepperB.value = Math.round(colors[2]);
		updateBG();
	}

	override function update(elapsed:Float) {
		if(WeekEditorState.loadedWeek != null) {
			super.update(elapsed);
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new WeekEditorFreeplayState(WeekEditorState.loadedWeek));
			WeekEditorState.loadedWeek = null;
			return;
		}
		
		if(UIInputText.focusOn != null)
			ClientPrefs.toggleVolumeKeys(false);
		else
		{
			ClientPrefs.toggleVolumeKeys(true);
			if(FlxG.keys.justPressed.ESCAPE) {
				if(!WeekEditorState.unsavedProgress)
				{
					MusicBeatState.switchState(new MainMenuState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
				else openSubState(new ExitConfirmationPrompt());
			}

			if(controls.UI_UP_P) changeSelection(-1);
			if(controls.UI_DOWN_P) changeSelection(1);
		}
		super.update(elapsed);
	}
}