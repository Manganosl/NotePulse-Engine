package states.editors;

import backend.ui.*;
import backend.WeekData;
import states.FreeplayState.SongMetadata;
import objects.HealthIcon;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flixel.util.FlxSort;

class ModSelector extends MusicBeatState{
	var exclusions:Array<String> = ["assets", "data", "fonts", "images", "music", "sounds", "videos", "ndlls", "scripts", "shaders", "characters", "songs", "stages", "weeks", "states", "custom_events", "custom_notetypes"];

    private var modArray:Array<String> = [];
    private var goto:Class<MusicBeatState>;
    private var gotoArgs:Array<Dynamic> = [];
	var curDifficulty:Int = -1;
	var currentSong:SongMetadata = null;
	var currentMod:String = null;
	var currentDifficulties:Array<String> = [];
	var inSongSelect:Bool = false;
	var inDifSelect:Bool = false;
	var iconArray:Array<Dynamic> = [];
	private var descText:FlxText;
	private var cosanegra:FlxSprite;
	private var titleText:FlxText;
	var _file:FileReference;

    public function new(state:Class<MusicBeatState>, args:Array<Dynamic>){
        goto = state;
        gotoArgs = args != null ? args : [];
        for (folder in Mods.getModDirectories()){
			if(!exclusions.contains(folder)) modArray.push(folder);
		}
        super();
    }

    var bg:FlxSprite;
    var backdrop:flixel.addons.display.FlxBackdrop;

    private var curSelected:Int = 0;
	var lerpSelected:Float = 0;
    private var grpAlph:FlxTypedGroup<Alphabet>;

	var iconGroup:FlxTypedGroup<Dynamic>;
    var uiGroup:FlxTypedGroup<Dynamic>;

    override public function create(){
        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		backdrop = new flixel.addons.display.FlxBackdrop(Paths.image('grid'));
		backdrop.velocity.set(50, 30);
		backdrop.alpha = 0.9;
		add(backdrop);	

		reloadMods();
		
        changeSelection();
		updateTexts();
		if (goto == states.editors.ChartingState) reloadSongs();

		iconGroup = new FlxTypedGroup();
		add(iconGroup);

		uiGroup = new FlxTypedGroup();
		add(uiGroup);

		cosanegra = new FlxSprite().makeGraphic(FlxG.width, 300, 0xff000000);
		cosanegra.antialiasing = ClientPrefs.data.antialiasing;
		cosanegra.screenCenter();
		cosanegra.alpha = 0.5;
		cosanegra.y = -210;
		uiGroup.add(cosanegra);

		titleText = new FlxText(0, 10, 1145, "Mod Selector > ", 32); //Alphabet(75, 45, title, true);
		titleText.alpha = 1;
		titleText.setFormat(Paths.font("default.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		uiGroup.add(titleText);
	
		descText = new FlxText(0, 50, 1180, "Press ACCEPT to select a mod.", 15);
		descText.setFormat(Paths.font("default.ttf"), 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		uiGroup.add(descText);
    }

    var velXtra:Float = 0;

	function reloadMods(){
		if(grpAlph != null) remove(grpAlph);
        grpAlph = new FlxTypedGroup<Alphabet>();
		add(grpAlph);
		iconArray = [];

        for (i in 0...modArray.length){
			var modText:Alphabet = new Alphabet(90, 320, modArray[i], true);
			modText.targetY = i;
			grpAlph.add(modText);
			modText.scaleX = Math.min(1, 980 / modText.width);
			modText.snapToPosition();
			modText.visible = modText.active = modText.isMenuItem = false;
			modText.x += 40;
			modText.screenCenter(X);
		}
	}

    function changeSelection(change:Int = 0, playSound:Bool = true){
		if (change == -1) velXtra += 450;
		else if (change == 1) velXtra += -450;

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		var listLength = grpAlph.length;
		if (curSelected < 0){
    		curSelected = listLength - 1;
    		velXtra -= (450*listLength - 1)/4;
		}
		if (curSelected >= listLength){
		    curSelected = 0;
		    velXtra += (450*listLength - 1)/4;
		}

		if(inSongSelect || inDifSelect){
			for (i in 0...iconArray.length){
				iconArray[i].alpha = 0.6;
			}
			if (curSelected < iconArray.length) iconArray[curSelected].alpha = 1;
		}

		for (i in 0...grpAlph.length){
    		var item = grpAlph.members[i];
    		item.alpha = 0.6;
    		if (i == curSelected) item.alpha = 1;
		}
	}

    var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
    public function updateTexts(elapsed:Float = 0.0){
	    lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
	    for (i in _lastVisibles){
		    if (i < grpAlph.length) grpAlph.members[i].visible = grpAlph.members[i].active = false;
		    if((inSongSelect || inDifSelect) && i < iconArray.length) iconArray[i].visible = iconArray[i].active = false;
	    }
	    _lastVisibles = [];
		var listLength = grpAlph.length;

	    var min:Int = Math.round(Math.max(0, Math.min(listLength, lerpSelected - _drawDistance)));
	    var max:Int = Math.round(Math.max(0, Math.min(listLength, lerpSelected + _drawDistance)));
	
	    for (i in min...max){
	    	if (i >= grpAlph.length) continue;
	    	var item:Alphabet = grpAlph.members[i];
		    item.visible = item.active = true;

		    var y:Float = ((FlxG.height - 120) / 2) + ((i - lerpSelected) * 135); 
		    item.x = (-50 + (Math.abs(Math.cos((y + (135 / 2) - (FlxG.camera.scroll.y + (FlxG.height / 2))) / (FlxG.height * 1.25) * Math.PI)) * 150));
		    item.y = y;
		    velXtra = CoolUtil.fpsLerp(velXtra, 0, 0.01);
		    backdrop.velocity.set(50, 30+velXtra);

			if((inSongSelect || inDifSelect) && i < iconArray.length){
    			var icon:Dynamic = iconArray[i];
		    	icon.visible = icon.active = true;
    			icon.x = item.x - 60;
    			icon.y = y + 20;
			}

		    _lastVisibles.push(i);
	    }
    }

    var holdTime:Float = 0;
	private var songs:Array<SongMetadata> = [];
	private var currentSongs:Array<SongMetadata> = [];

    override public function update(elapsed:Float){
        var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;
        if(grpAlph.length >= 1){
			if (controls.UI_UP_P){
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P){
				changeSelection(shiftMult);
				holdTime = 0;
			}
            if(controls.UI_DOWN || controls.UI_UP){
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}
            if(FlxG.mouse.wheel != 0){
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}

            if (controls.ACCEPT){
				if(goto != states.editors.ChartingState){
					if(curSelected == 0){
						currentMod = null;
					} else {
						currentMod = modArray[curSelected];
						Mods.currentModDirectory = currentMod;
					}
					try MusicBeatState.switchState(Type.createInstance(goto, gotoArgs));
				}
				else if(goto == states.editors.ChartingState){
					if(inDifSelect){
						if(curSelected == 0){
							var newDiffName:String = null;
							openSubState(new NewJson("Enter new difficulty name (No spaces)", function(str2){
								newDiffName = str2;

						        var newSong:Dynamic = {
						            song: newSongName,
						            notes: [],
						            events: [],
						            bpm: 150.0,
						            mania: 3,
						            needsVoices: true,
						            gfStrums: false,
						            player1: 'bf',
						            player2: 'dad',
						            gfVersion: 'gf',
						            speed: 1,
						            stage: 'stage'
						        };

						        saveLevel(newSong, true, newDiffName);
								openSubState(new GoodBye());
							}));
						} else {
							curDifficulty = curSelected-1;
							Mods.currentModDirectory = currentMod;
							PlayState.storyDifficulty = curDifficulty;
							PlayState.storyWeek = currentSong.week;
							var weekName = WeekData.weeksList[currentSong.week];
							WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(weekName));
							var formated = backend.Highscore.formatSong(currentSong.songName.toLowerCase(), curDifficulty);
							trace(formated);
							PlayState.SONG = backend.Song.loadFromJson(formated, currentSong.songName.toLowerCase());
							try LoadingState.loadAndSwitchState(new ChartingState(), false);
						}
					} else if(inSongSelect){
						if (curSelected == 0) {
						    var newSongName:String = null;
						    var newDiffName:String = null;

						    openSubState(new NewJson("Enter new song name (No spaces)", function(str) {
						        newSongName = str;

						        openSubState(new NewJson("Enter new difficulty name (No spaces)", function(str2) {
						            newDiffName = str2;

						            var newSong:Dynamic = {
						                song: newSongName,
						                notes: [],
						                events: [],
						                bpm: 150.0,
						                mania: 3,
						                needsVoices: true,
						                gfStrums: false,
						                player1: 'bf',
						                player2: 'dad',
						                gfVersion: 'gf',
						                speed: 1,
						                stage: 'stage'
						            };

						            saveLevel(newSong, true, newDiffName);
									openSubState(new GoodBye());
						        }));
						    }));
						} else {
							currentSong = currentSongs[curSelected-1];
							PlayState.storyWeek = currentSong.week;						
							Difficulty.loadFromWeek();
    						currentDifficulties = Difficulty.list;
    						remove(grpAlph);
    						grpAlph = new FlxTypedGroup<Alphabet>();
    						add(grpAlph);
							for(i in iconArray) iconGroup.remove(i);
							iconArray = [];
							titleText.text = "Mod Selector > " + currentMod + " > " + currentSong.songName;
							descText.text = "Press ACCEPT to select a difficulty.";
							addExtraOption("New Difficulty", "editors/new", 0, 255);
    						for (i in 0...currentDifficulties.length) {
        						var diffText:Alphabet = new Alphabet(90, 320, currentDifficulties[i], true);
        						diffText.targetY = i+1;
        						grpAlph.add(diffText);
        						diffText.scaleX = Math.min(1, 980 / diffText.width);
        						diffText.snapToPosition();
        						diffText.visible = diffText.active = diffText.isMenuItem = false;
        						diffText.x += 40;
        						diffText.screenCenter(X);
    						}
    						curSelected = 0;
    						_lastVisibles = [];
    						inDifSelect = true;
    						inSongSelect = false;
    						changeSelection();
    						updateTexts();
    						return;
						}
					} else {
						PlayState.isStoryMode = false;
						currentMod = modArray[curSelected];
						Mods.currentModDirectory = currentMod;
						titleText.text = "Mod Selector > " + currentMod;
						descText.text = "Press ACCEPT to select a song.";
						reloadSongs();
						arrayModSongs();
						curSelected = 0;
						_lastVisibles = [];
        				changeSelection();
						updateTexts();
					}
				}
        	}
			if (controls.BACK){
				if(!inDifSelect && !inSongSelect){
    				try MusicBeatState.switchState(new states.MainMenuState());
				} else if (inDifSelect){
					inDifSelect = false;
					inSongSelect = true;
					for(i in iconArray) iconGroup.remove(i);
					titleText.text = "Mod Selector > " + currentMod;
					descText.text = "Press ACCEPT to select a song.";
					iconArray = [];
					reloadSongs();
					arrayModSongs();
					curSelected = 0;
					_lastVisibles = [];
        			changeSelection();
					updateTexts();
				} else if (inSongSelect){
					inDifSelect = false;
					inSongSelect = false;
					for(i in iconArray) iconGroup.remove(i);
					titleText.text = "Mod Selector > ";
					descText.text = "Press ACCEPT to select a mod.";
					iconArray = [];
					reloadMods();
					curSelected = 0;
					_lastVisibles = [];
					changeSelection();
					updateTexts();
				}
			}
		}
        if(grpAlph != null) updateTexts(elapsed);
		super.update(elapsed);
    }

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int){
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function reloadSongs(){
		WeekData.reloadWeekFiles(false);
		songs = [];
		for (i in 0...WeekData.weeksList.length) {
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length){
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs){
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3){
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
	}

	function arrayModSongs(){
		if(songs != null && songs.length > 0){
			remove(grpAlph);
			grpAlph = new FlxTypedGroup<Alphabet>();
			add(grpAlph);
			iconArray = [];
			currentSongs = [];
			inSongSelect = true;
			addExtraOption("New Song", "editors/new", 0, 255);
			for (i in 0...songs.length){
				if(songs[i] != null && currentMod == songs[i].folder){
					Mods.currentModDirectory = currentMod;
					currentSongs.push(songs[i]);
					var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
					songText.targetY = i+1;
					grpAlph.add(songText);
					songText.scaleX = Math.min(1, 980 / songText.width);
					songText.snapToPosition();

					var icon:Dynamic = new HealthIcon(songs[i].songCharacter);
					icon.sprTracker = songText;
					icon.visible = icon.active = false;

					iconArray.push(icon);
					iconGroup.add(icon);

					songText.visible = songText.active = songText.isMenuItem = false;
					songText.x += 40;
					songText.screenCenter(X);
				}
			}
		}
	}

	function addExtraOption(text:String, icona:String, redMult:Int = 0, greenMult:Int = 0, blueMult:Int = 0){
		var optionText:Alphabet = new Alphabet(90, 320, text, true);
		grpAlph.add(optionText);
		optionText.scaleX = Math.min(1, 980 / optionText.width);
		optionText.snapToPosition();

		optionText.color = FlxColor.fromRGB(redMult, greenMult, blueMult, 255);

		var icon:ImIcon = null;
		if(icona != null){
			icon = new ImIcon(0, 0, Paths.image(icona));
			icon.sprTracker = optionText;
			icon.scale.set(1.6, 1.6);
			icon.offset.set(-15, -25);
			icon.visible = icon.active = false;
			iconArray.push(icon);
			iconGroup.add(icon);
		}

		optionText.visible = optionText.active = optionText.isMenuItem = false;
		optionText.x += 40;
		optionText.screenCenter(X);		
	}

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

	public function saveLevel(songData:Dynamic, auto:Bool = false, dif:String = null):Void{
    	if (songData.events != null && songData.events.length > 1)
    	    songData.events.sort(sortByTime);

    	var json = { song: songData };
    	var data:String = haxe.Json.stringify(json, "\t");

    	if (data != null && data.length > 0)
    	{
    	    if (auto)
    	    {
    	        var songName = Paths.formatToSongPath(songData.song);
    	        var diff = dif;
    	        var diffSuffix = (diff != null && diff != '' && diff != Difficulty.getDefault()) ? '-' + diff : '';
    	        var fileName = songName + diffSuffix;

    	        #if MODS_ALLOWED
    	        var folder = songName;
    	        var chartFile = fileName;
    	        var chartPath = Mods.currentModDirectory != null ? Paths.modJson(folder + '/' + chartFile) : 'assets/shared/data/' + songName + '/';

    	        var chartDir = haxe.io.Path.directory(chartPath);
    	        if (!sys.FileSystem.exists(chartDir)) {
    	            var ensureDirectory = function(path:String) {
    	                var parent = haxe.io.Path.directory(path);
    	                if (parent != "" && !sys.FileSystem.exists(parent)) ensureDirectory(parent);
    	                if (!sys.FileSystem.exists(path)) sys.FileSystem.createDirectory(path);
    	            }
    	            ensureDirectory(chartDir);
    	        }

    	        try
    	            sys.io.File.saveContent(chartPath, data.trim());
    	        #else
    	        var chartDir = 'assets/shared/data/' + songName + '/';
    	        if (!sys.FileSystem.exists(chartDir)) sys.FileSystem.createDirectory(chartDir);
    	        var chartPath = chartDir + fileName + ".json";
    	        try {
    	            sys.io.File.saveContent(chartPath, data.trim());
    	        }
    	        #end
    	    }
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

	private function ensureDirectory(path:String) {
    	var parent = haxe.io.Path.directory(path);
    	if (parent != "" && !sys.FileSystem.exists(parent)) ensureDirectory(parent);
    	if (!sys.FileSystem.exists(path)) sys.FileSystem.createDirectory(path);
	}
}

class ImIcon extends FlxSprite {
	public var sprTracker:FlxSprite;
	override function update(elapsed:Float){
		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
		super.update(elapsed);
	}
}

class NewJson extends MusicBeatSubstate{
	var txt:String;
	var callback:String->Void;
	public function new(txt:String, callback:String->Void){
		this.txt = txt;
		this.callback = callback;
		super();
	}
	override public function create(){
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff000000);
		bg.scrollFactor.set(0, 0);
		bg.screenCenter();
		bg.alpha = 0.25;
		add(bg);

		var input:PsychUIInputText = new PsychUIInputText(0, 0, 300, "", 16);
		input.screenCenter();
		input.scrollFactor.set(0, 0);
		add(input);

		var textString:FlxText = new FlxText(0, input.y-input.height-100, 0, txt, 32);
		textString.setFormat(Paths.font("default.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		textString.scrollFactor.set(0, 0);
		textString.screenCenter();
		textString.y = input.y-input.height-10;
		add(textString);

		var confirmButton:PsychUIButton = new PsychUIButton(0, input.y+input.height+100, "Confirm", function(){
			callback(input.text);
			close();
		});
		confirmButton.screenCenter();
		confirmButton.scrollFactor.set(0, 0);
		confirmButton.y = input.y+input.height;
		add(confirmButton);
	}
}

class GoodBye extends MusicBeatSubstate{
	override public function create(){
		var warningText:FlxText = new FlxText(0, 0, 1000, "Song File Created!\nNow you'll be redirected to the Week Editor so you can add this song\nThen, you'll be able to access this song directly from here!");
		warningText.setFormat(Paths.font("default.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		warningText.scrollFactor.set(0, 0);
		warningText.screenCenter();
		add(warningText);
		new FlxTimer().start(5, function(tmr:FlxTimer){ try MusicBeatState.switchState(new states.editors.WeekEditorState()); close();});
	}
}