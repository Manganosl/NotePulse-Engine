package funkin.states.editors;

import funkin.states.editors.content.Prompt;
import funkin.data.WeekData;
import funkin.states.menus.FreeplayState.SongMetadata;
import funkin.objects.HealthIcon;
import funkin.objects.AttachedSprite;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.util.FlxSort;
import haxe.Json;
import funkin.states.scripted.ScriptedState;
import funkin.scripting.GlobalHandler;

class ModSelectorState extends MusicBeatState {
	static final EXCLUDED_DIRS:Array<String> = [
		"assets","data","fonts","images","music","sounds","videos",
		"ndlls","scripts","shaders","characters","songs","stages",
		"weeks","states","custom_events","custom_notetypes"
	];

	var goto:Class<Dynamic>;
	var gotoArgs:Array<Dynamic>;

	var modArray:Array<String> = [];
	var songs:Array<SongMetadata> = [];
	var currentSongs:Array<SongMetadata> = [];
	var currentDifficulties:Array<String> = [];

	var currentMod:String = null;
	var currentSong:SongMetadata = null;
	var curDifficulty:Int = -1;

	var inSongSelect:Bool = false;
	var inDifSelect:Bool = false;

	var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var holdTime:Float = 0;
	var velXtra:Float = 0;

	var grpAlph:FlxTypedGroup<Alphabet>;
	var iconGroup:FlxTypedGroup<Dynamic>;
	var iconArray:Array<Dynamic> = [];

	var bg:FlxSprite;
	var backdrop:flixel.addons.display.FlxBackdrop;
	var titleText:FlxText;
	var descText:FlxText;
	var _file:FileReference;

	static inline final DRAW_DIST:Int = 4;
	var _lastVisibles:Array<Int> = [];

	public function new(state:Class<Dynamic>, args:Array<Dynamic>) {
		goto = state;
		gotoArgs = args ?? [];
		for (folder in Mods.getModDirectories())
			if (!EXCLUDED_DIRS.contains(folder)) modArray.push(folder);
		super();
	}

	override public function create() {
		super.create();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		backdrop = new flixel.addons.display.FlxBackdrop(Paths.image('grid'));
		backdrop.velocity.set(50, 30);
		backdrop.alpha = 0.9;
		add(backdrop);

		iconGroup = new FlxTypedGroup();
		add(iconGroup);

		reloadMods();
		if (goto == ChartingState || goto == ModchartEditorState) reloadSongs();

		var bar = new FlxSprite().makeGraphic(FlxG.width, 300, 0xff000000);
		bar.antialiasing = ClientPrefs.data.antialiasing;
		bar.screenCenter();
		bar.alpha = 0.5;
		bar.y = -210;
		add(bar);

		titleText = new FlxText(0, 10, 1145, "Mod Selector > ", 32);
		titleText.setFormat(Paths.font("default.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		add(titleText);

		descText = new FlxText(0, 50, 1180, "Press ACCEPT to select a mod.", 15);
		descText.setFormat(Paths.font("default.ttf"), 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		add(descText);

		changeSelection();
		updateTexts();

		FlxTween.cancelTweensOf(Main.fpsVar);
		FlxTween.tween(Main.fpsVar, {y: 105}, 1, {ease: FlxEase.circOut});
	}

	override public function update(elapsed:Float) {
		if (grpAlph.length >= 1) {
			handleInput(elapsed);
		}
		updateTexts(elapsed);
		super.update(elapsed);
	}

	function handleInput(elapsed:Float) {
		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		if (controls.UI_UP_P)  { changeSelection(-shiftMult); holdTime = 0; }
		if (controls.UI_DOWN_P){ changeSelection(shiftMult);  holdTime = 0; }

		if (controls.UI_UP || controls.UI_DOWN) {
			var prevHold = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var newHold = Math.floor((holdTime - 0.5) * 10);
			if (holdTime > 0.5 && newHold - prevHold > 0)
				changeSelection((newHold - prevHold) * (controls.UI_UP ? -shiftMult : shiftMult));
		}

		if (FlxG.mouse.wheel != 0) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
			changeSelection(-shiftMult * FlxG.mouse.wheel, false);
		}

		if (controls.ACCEPT) onAccept();
		if (controls.BACK) onBack();
	}

	function onAccept() {
		if (goto == ScriptedState) {
			setMod(modArray[curSelected]);
			if (Mods.modPack?.hasGlobalScript == true) GlobalHandler.loadGlobalHX();
			FlxG.sound.music.stop();
			FlxTween.cancelTweensOf(Main.fpsVar);
			Main.fpsVar.y = 10;
			MusicBeatState.switchState(new funkin.states.menus.TitleState());
			return;
		}

		if (goto == BasePrompt) {
			setMod(modArray[curSelected]);
			openConfigPrompt();
			return;
		}

		if (goto == ChartingState || goto == ModchartEditorState) {
			onAcceptCharter();
			return;
		}

		currentMod = (curSelected == 0) ? null : modArray[curSelected];
		if (currentMod != null) Mods.currentModDirectory = currentMod;
		try MusicBeatState.switchState(Type.createInstance(goto, gotoArgs));
	}

	function onAcceptCharter() {
		if (inDifSelect) {
			if (curSelected == 0) {
				promptNewDifficulty(currentSong, null);
			} else {
				curDifficulty = curSelected - 1;
				Mods.currentModDirectory = currentMod;
				PlayState.storyDifficulty = curDifficulty;
				PlayState.storyWeek = currentSong.week;
				WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[currentSong.week]));
				var fmt = funkin.data.Highscore.formatSong(currentSong.songName.toLowerCase(), curDifficulty);
				PlayState.SONG = funkin.data.Song.loadFromJson(fmt, currentSong.songName.toLowerCase());
				var nextState = (goto == ModchartEditorState) ? new ModchartEditorState() : new ChartingState();
				try LoadingState.loadAndSwitchState(nextState, false);
			}
		} else if (inSongSelect) {
			if (curSelected == 0) {
				promptNewSong();
			} else {
				currentSong = currentSongs[curSelected - 1];
				PlayState.storyWeek = currentSong.week;
				Difficulty.loadFromWeek();
				currentDifficulties = Difficulty.list;
				enterDifSelect();
			}
		} else {
			setMod(modArray[curSelected]);
			PlayState.isStoryMode = false;
			titleText.text = "Mod Selector > " + currentMod;
			descText.text = "Press ACCEPT to select a song.";
			reloadSongs();
			enterSongSelect();
		}
	}

	function onBack() {
		if (!inDifSelect && !inSongSelect) {
			try MusicBeatState.switchState(new funkin.states.MainMenuState());
		} else if (inDifSelect) {
			inDifSelect = false;
			titleText.text = "Mod Selector > " + currentMod;
			descText.text = "Press ACCEPT to select a song.";
			reloadSongs();
			enterSongSelect(true);
		} else {
			inSongSelect = false;
			titleText.text = "Mod Selector > ";
			descText.text = "Press ACCEPT to select a mod.";
			clearIcons();
			reloadMods();
			resetSelection();
		}
	}

	function enterSongSelect(skipReload:Bool = false) {
		if (!skipReload) reloadSongs();
		clearIcons();
		remove(grpAlph);
		grpAlph = new FlxTypedGroup<Alphabet>();
		add(grpAlph);
		currentSongs = [];
		inSongSelect = true;
		inDifSelect = false;

		addExtraOption("New Song", "editors/new", 0, 255);
		for (song in songs) {
			if (song == null || currentMod != song.folder) continue;
			Mods.currentModDirectory = currentMod;
			currentSongs.push(song);

			var txt = new Alphabet(90, 320, song.songName, true);
			txt.targetY = currentSongs.length;
			setupAlphaItem(txt);
			grpAlph.add(txt);

			var icon = new HealthIcon(song.songCharacter);
			icon.sprTracker = txt;
			icon.visible = icon.active = false;
			iconArray.push(icon);
			iconGroup.add(icon);
		}
		resetSelection();
	}

	function enterDifSelect() {
		clearIcons();
		remove(grpAlph);
		grpAlph = new FlxTypedGroup<Alphabet>();
		add(grpAlph);
		inDifSelect = true;
		inSongSelect = false;

		titleText.text = "Mod Selector > " + currentMod + " > " + currentSong.songName;
		descText.text = "Press ACCEPT to select a difficulty.";

		addExtraOption("New Difficulty", "editors/new", 0, 255);
		for (i in 0...currentDifficulties.length) {
			var txt = new Alphabet(90, 320, currentDifficulties[i], true);
			txt.targetY = i + 1;
			setupAlphaItem(txt);
			grpAlph.add(txt);
		}
		resetSelection();
	}

	function reloadMods() {
		if (grpAlph != null) remove(grpAlph);
		grpAlph = new FlxTypedGroup<Alphabet>();
		add(grpAlph);
		iconArray = [];

		for (i in 0...modArray.length) {
			var txt = new Alphabet(90, 320, modArray[i], true);
			txt.targetY = i;
			setupAlphaItem(txt);
			grpAlph.add(txt);
		}
	}

	function reloadSongs() {
		WeekData.reloadWeekFiles(false);
		songs = [];
		for (i in 0...WeekData.weeksList.length) {
			var week = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			WeekData.setDirectoryFromWeek(week);
			for (song in week.songs) {
				var colors:Array<Int> = song[2];
				if (colors == null || colors.length < 3) colors = [146, 113, 253];
				songs.push(new SongMetadata(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2])));
			}
		}
	}

	function setupAlphaItem(txt:Alphabet) {
		txt.scaleX = Math.min(1, 980 / txt.width);
		txt.snapToPosition();
		txt.visible = txt.active = txt.isMenuItem = false;
		txt.x += 40;
		txt.screenCenter(X);
	}

	function addExtraOption(label:String, icon:String, r:Int = 0, g:Int = 0, b:Int = 0) {
		var txt = new Alphabet(90, 320, label, true);
		txt.color = FlxColor.fromRGB(r, g, b, 255);
		setupAlphaItem(txt);
		grpAlph.add(txt);

		if (icon != null) {
			var spr = new AttachedSprite(icon);
			spr.sprTracker = txt;
			spr.scale.set(1.6, 1.6);
			spr.offset.set(-15, -25);
			spr.visible = spr.active = false;
			iconArray.push(spr);
			iconGroup.add(spr);
		}
	}

	function changeSelection(change:Int = 0, playSound:Bool = true) {
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var len = grpAlph.length;
		if (len == 0) return;

		if (change == -1) velXtra += 450;
		else if (change == 1) velXtra -= 450;

		curSelected = (curSelected + change + len) % len;

		for (i in 0...grpAlph.length)
			grpAlph.members[i].alpha = (i == curSelected) ? 1 : 0.6;

		if (inSongSelect || inDifSelect)
			for (i in 0...iconArray.length)
				iconArray[i].alpha = (i == curSelected) ? 1 : 0.6;
	}

	function updateTexts(elapsed:Float = 0) {
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		for (i in _lastVisibles) {
			if (i < grpAlph.length) grpAlph.members[i].visible = grpAlph.members[i].active = false;
			if ((inSongSelect || inDifSelect) && i < iconArray.length)
				iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var len = grpAlph.length;
		var min = Std.int(Math.max(0, Math.min(len, lerpSelected - DRAW_DIST)));
		var max = Std.int(Math.max(0, Math.min(len, lerpSelected + DRAW_DIST)));

		velXtra = CoolUtil.fpsLerp(velXtra, 0, 0.01);
		backdrop.velocity.set(50, 30 + velXtra);

		for (i in min...max) {
			if (i >= grpAlph.length) continue;
			var item = grpAlph.members[i];
			item.visible = item.active = true;

			var y = ((FlxG.height - 120) / 2) + ((i - lerpSelected) * 135);
			item.x = -50 + Math.abs(Math.cos((y + 67.5 - (FlxG.camera.scroll.y + FlxG.height / 2)) / (FlxG.height * 1.25) * Math.PI)) * 150;
			item.y = y;

			if ((inSongSelect || inDifSelect) && i < iconArray.length) {
				var icon = iconArray[i];
				icon.visible = icon.active = true;
				icon.x = item.x - 60;
				icon.y = y + 20;
			}
			_lastVisibles.push(i);
		}
	}

	function promptNewSong() {
		openSubState(new BasePrompt(FlxG.width / 2, 300, "Enter new song name (No spaces)", function(state:BasePrompt) {
			var input = new PsychUIInputText(state.bg.x + 20, state.bg.y + 90, 250, "", 16);
			state.add(input);

			state.add(new PsychUIButton(state.bg.x + 20, input.y + 40, "Confirm", function() {
				var songName = input.text;
				state.close();
				openSubState(new BasePrompt(FlxG.width / 2, 300, "Enter new difficulty name (No spaces)", function(state2:BasePrompt) {
					var input2 = new PsychUIInputText(state2.bg.x + 20, state2.bg.y + 90, 250, "", 16);
					state2.add(input2);

					state2.add(new PsychUIButton(state2.bg.x + 20, input2.y + 40, "Confirm", function() {
						saveLevel(makeBlankSong(songName), true, input2.text);
						state2.close();
						openSubState(new GoodBye());
					}));
				}));
			}));
		}));
	}

	function promptNewDifficulty(song:SongMetadata, _) {
		openSubState(new BasePrompt(FlxG.width / 2, 300, "Enter new difficulty name (No spaces)", function(state:BasePrompt) {
			var input = new PsychUIInputText(state.bg.x + 20, state.bg.y + 90, 250, "", 16);
			state.add(input);

			state.add(new PsychUIButton(state.bg.x + 20, input.y + 40, "Confirm", function() {
				saveLevel(makeBlankSong(song.songName), true, input.text);
				state.close();
				openSubState(new GoodBye());
			}));
		}));
	}

	function makeBlankSong(name:String):Dynamic {
		return {
			song: name, notes: [], events: [],
			bpm: 150.0, mania: 3, needsVoices: true,
			gfStrums: false, player1: 'bf', player2: 'dad',
			gfVersion: 'gf', speed: 1, stage: 'stage'
		};
	}

	inline function setMod(mod:String) {
		currentMod = mod;
		Mods.currentLoadedMod = Mods.currentModDirectory = mod;
	}

	function clearIcons() {
		for (icon in iconArray) iconGroup.remove(icon);
		iconArray = [];
	}

	function resetSelection() {
		curSelected = 0;
		_lastVisibles = [];
		changeSelection();
		updateTexts();
	}

	public function saveLevel(songData:Dynamic, auto:Bool = false, dif:String = null) {
		if (songData.events != null && songData.events.length > 1)
			songData.events.sort((a, b) -> FlxSort.byValues(FlxSort.ASCENDING, a[0], b[0]));

		var data = haxe.Json.stringify({song: songData}, "\t");
		if (data == null || data.length == 0) return;

		if (auto) {
			var songName = Paths.formatToSongPath(songData.song);
			var suffix = (dif != null && dif != '' && dif != Difficulty.getDefault()) ? '-$dif' : '';
			#if MODS_ALLOWED
			var path = Paths.modJson('$songName/$songName$suffix');
			ensureDirectory(haxe.io.Path.directory(path));
			try sys.io.File.saveContent(path, data.trim());
			#else
			var dir = 'assets/shared/data/$songName/';
			if (!sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
			try sys.io.File.saveContent('$dir$songName$suffix.json', data.trim());
			#end
		}
	}

	function ensureDirectory(path:String) {
		var parent = haxe.io.Path.directory(path);
		if (parent != "" && !sys.FileSystem.exists(parent)) ensureDirectory(parent);
		if (!sys.FileSystem.exists(path)) sys.FileSystem.createDirectory(path);
	}

	function openConfigPrompt() {
		openSubState(new BasePrompt(FlxG.width / 2, 600, 'Edit $currentMod Config File', function(state:BasePrompt) {
			var cfg = readModPackConfig();
			var sx = state.bg.x + 20;
			var sy = state.bg.y + 90;
			var sp = 40;
			var iw = 250;
			var ts = 10;

			inline function label(x:Float, y:Float, t:String) { state.add(new FlxText(x, y - 14, 0, t, ts)); }
			inline function input(x:Float, y:Float, v:String) { var i = new PsychUIInputText(x, y, iw, v); state.add(i); return i; }

			label(sx, sy,      "Mod Name:");           var nameInput      = input(sx, sy,      cfg.name);
			label(sx, sy+sp,   "Description:");        var descInput      = input(sx, sy+sp,   cfg.description);
			label(sx, sy+sp*2, "Title State:");        var titleInput     = input(sx, sy+sp*2, cfg.titleState);
			label(sx, sy+sp*3, "Main Menu State:");    var mainMenuInput  = input(sx, sy+sp*3, cfg.mainMenuState);
			label(sx, sy+sp*4, "Story Menu State:");   var storyMenuInput = input(sx, sy+sp*4, cfg.storyMenuState);
			label(sx, sy+sp*5, "Freeplay State:");     var freeplayInput  = input(sx, sy+sp*5, cfg.freeplayState);
			label(sx, sy+sp*6, "Pause Substate:");     var pauseInput     = input(sx, sy+sp*6, cfg.pauseSubState);
			label(sx, sy+sp*7, "Discord RPC ID:");     var discordInput   = input(sx, sy+sp*7, cfg.discordRPC);
			label(sx, sy+sp*8, "Default Transition:"); var transInput     = input(sx, sy+sp*8, cfg.defaultTransition);

			var checkY = transInput.y + 35;
			var globalCheck = new PsychUICheckBox(sx, checkY, "Has Global Script?", 100);
			var globallyCheck = new PsychUICheckBox(sx + 180, checkY, "Runs Globally?", 100);
			var forceCheck = new PsychUICheckBox(sx + 180 * 2, checkY, "Forces its states?", 100);
			globalCheck.checked = cfg.hasGlobalScript;
			globallyCheck.checked = cfg.runsGlobally;
			forceCheck.checked = cfg.forceStates;
			state.add(globalCheck);
			state.add(globallyCheck);
			state.add(forceCheck);

			var saveBtn = new PsychUIButton(sx, globalCheck.y + 45, "Save", function() {
				var newData = {
					name: nameInput.text, description: descInput.text,
					titleState: titleInput.text, mainMenuState: mainMenuInput.text,
					storyMenuState: storyMenuInput.text, freeplayState: freeplayInput.text,
					pauseSubState: pauseInput.text, discordRPC: discordInput.text,
					defaultTransition: transInput.text,
					hasGlobalScript: globalCheck.checked,
					runsGlobally: globallyCheck.checked,
					forceStates: forceCheck.checked
				};
				sys.io.File.saveContent(Paths.mods('$currentMod/pack.json'), Json.stringify(newData, "\t"));
				Mods.currentLoadedMod = null;
				state.close();
			});
			state.add(saveBtn);
			state.add(new PsychUIButton(saveBtn.x + 110, saveBtn.y, "Cancel", function() {
				Mods.currentLoadedMod = null;
				state.close();
			}));
		}));
	}

	function readModPackConfig() {
		var d = { name:"", description:"", titleState:"", mainMenuState:"", storyMenuState:"",
			freeplayState:"", pauseSubState:"", discordRPC:"", defaultTransition:"",
			runsGlobally:false, hasGlobalScript:false, forceStates:false };
		if (Mods.modPack == null) return d;
		try {
			if (Mods.modPack.name            != null) d.name            = Mods.modPack.name;
			if (Mods.modPack.description     != null) d.description     = Mods.modPack.description;
			if (Mods.modPack.titleState      != null) d.titleState      = Mods.modPack.titleState;
			if (Mods.modPack.mainMenuState   != null) d.mainMenuState   = Mods.modPack.mainMenuState;
			if (Mods.modPack.storyMenuState  != null) d.storyMenuState  = Mods.modPack.storyMenuState;
			if (Mods.modPack.freeplayState   != null) d.freeplayState   = Mods.modPack.freeplayState;
			if (Mods.modPack.pauseSubState   != null) d.pauseSubState   = Mods.modPack.pauseSubState;
			if (Mods.modPack.discordRPC      != null) d.discordRPC      = Mods.modPack.discordRPC;
			if (Mods.modPack.defaultTransition != null) d.defaultTransition = Mods.modPack.defaultTransition;
			if (Mods.modPack.runsGlobally    != null) d.runsGlobally    = Mods.modPack.runsGlobally;
			if (Mods.modPack.hasGlobalScript != null) d.hasGlobalScript = Mods.modPack.hasGlobalScript;
			if (Mods.modPack.forceStates     != null) d.forceStates     = Mods.modPack.forceStates;
		} catch(_) {}
		return d;
	}
}

class GoodBye extends MusicBeatSubstate {
	override public function create() {
		var msg = new FlxText(0, 0, 1000,
			"Song File Created!\nNow you'll be redirected to the Week Editor so you can add this song.\nThen, you'll be able to access this song directly from here!", 32);
		msg.setFormat(Paths.font("default.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		msg.scrollFactor.set();
		msg.screenCenter();
		add(msg);
		new FlxTimer().start(5, function(_) {
			try MusicBeatState.switchState(new funkin.states.editors.WeekEditorState());
			close();
		});
	}
}