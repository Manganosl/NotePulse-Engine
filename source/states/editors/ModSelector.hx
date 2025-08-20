package states.editors;

import backend.WeekData;
import states.FreeplayState.SongMetadata;
import objects.HealthIcon;

class ModSelector extends MusicBeatState{
    private var modArray:Array<String> = [];
    private var goto:Class<MusicBeatState>;
    private var gotoArgs:Array<Dynamic> = [];
	var curDifficulty:Int = -1;
	var currentSong:SongMetadata = null;
	var currentMod:String = null;
	var currentDifficulties:Array<String> = [];
	var inSongSelect:Bool = false;
	var inDifSelect:Bool = false;
	var iconArray:Array<HealthIcon> = [];
    public function new(state:Class<MusicBeatState>, args:Array<Dynamic>){
        goto = state;
        if(args != null) gotoArgs = args; else gotoArgs = [];
        for (folder in Mods.getModDirectories()){
			modArray.push(folder);
		}
        super();
    }

    var bg:FlxSprite;
    var backdrop:flixel.addons.display.FlxBackdrop;

    private var curSelected:Int = 0;
	var lerpSelected:Float = 0;
    private var grpAlph:FlxTypedGroup<Alphabet>;

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
    }

    var velXtra:Float = 0;

	function reloadMods(){
		if(grpAlph != null) remove(grpAlph);
        grpAlph = new FlxTypedGroup<Alphabet>();
		add(grpAlph);

		var listLength = inDifSelect ? currentDifficulties.length : (inSongSelect ? currentSongs.length : modArray.length);
        for (i in 0...listLength){
			var modText:Alphabet = new Alphabet(90, 320, modArray[i], true);
			modText.targetY = i;
			grpAlph.add(modText);

			modText.scaleX = Math.min(1, 980 / modText.width);
			modText.snapToPosition();

			if (!inSongSelect) {
    			Mods.currentModDirectory = modArray[curSelected];
    			WeekData.setDirectoryFromWeek();
			}

			modText.visible = modText.active = modText.isMenuItem = false;

			modText.x += 40;
			modText.screenCenter(X);
		}
	}

    function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (change == -1) velXtra += 450;
		else if (change == 1) velXtra += -450;

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		var listLength = inDifSelect ? currentDifficulties.length : (inSongSelect ? currentSongs.length : modArray.length);
		if (curSelected < 0){
    		curSelected = listLength - 1;
    		velXtra -= (450*listLength - 1)/4;
		}
		if (curSelected >= listLength){
		    curSelected = 0;
		    velXtra += (450*listLength - 1)/4;
		}

		var bullShit:Int = 0;

		if(inSongSelect){
			for (i in 0...iconArray.length){
				iconArray[i].alpha = 0.6;
			}
			iconArray[curSelected].alpha = 1;
		}

		var listLength = inDifSelect ? currentDifficulties.length : (inSongSelect ? currentSongs.length : modArray.length);

		for (i in 0...grpAlph.length){
    		var item = grpAlph.members[i];
    		item.alpha = 0.6;
    		if ((!inSongSelect && item.targetY == curSelected) || (inSongSelect && i == curSelected) || (inDifSelect && i == curSelected))
        		item.alpha = 1;
		}
		if (!inSongSelect)
    		Mods.currentModDirectory = modArray[curSelected];
	}

    var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
    public function updateTexts(elapsed:Float = 0.0)
    {
	    lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
	    for (i in _lastVisibles)
	    {
		    grpAlph.members[i].visible = grpAlph.members[i].active = false;
		    if(inSongSelect) iconArray[i].visible = iconArray[i].active = false;
	    }
	    _lastVisibles = [];
		var listLength = inDifSelect ? currentDifficulties.length : (inSongSelect ? currentSongs.length : modArray.length);

	    var min:Int = Math.round(Math.max(0, Math.min(listLength, lerpSelected - _drawDistance)));
	    var max:Int = Math.round(Math.max(0, Math.min(listLength, lerpSelected + _drawDistance)));
	
	    for (i in min...max)
	    {
	    	var item:Alphabet = grpAlph.members[i];
			if (item == null) return;
	    	item.visible = item.active = true;

	    	var y:Float = ((FlxG.height - 120) / 2) + ((i - lerpSelected) * 135); 

	    	item.x = (-50 + (Math.abs(Math.cos((y + (135 / 2) - (FlxG.camera.scroll.y + (FlxG.height / 2))) / (FlxG.height * 1.25) * Math.PI)) * 150));

	    	item.y = y;
	    	velXtra = CoolUtil.fpsLerp(velXtra, 0, 0.01);
		    backdrop.velocity.set(50, 30+velXtra);

			if(inSongSelect){
    			var icon:HealthIcon = iconArray[i];
		    	icon.visible = icon.active = true;
	    		icon.x = item.x - 60;
    			icon.y = y + 20;
			}

		    _lastVisibles.push(i);
	    }
    }

    var holdTime:Float = 0;
	var updateOn:Bool = true;
	private var songs:Array<SongMetadata> = [];
	private var currentSongs:Array<SongMetadata> = [];
    override public function update(elapsed:Float){
        var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;
        if(modArray.length > 1){
			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}
            if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}
            if(FlxG.mouse.wheel != 0) 
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
            if (controls.ACCEPT){
				if(goto != states.editors.ChartingState){
					currentMod = modArray[curSelected];
					Mods.currentModDirectory = currentMod;
                	try MusicBeatState.switchState(Type.createInstance(goto, gotoArgs));
				}
				else if(goto == states.editors.ChartingState){
					if(inDifSelect){
						curDifficulty = curSelected;
						Mods.currentModDirectory = currentMod;
						PlayState.storyDifficulty = curDifficulty;
						PlayState.storyWeek = currentSong.week;
						var weekName = WeekData.weeksList[currentSong.week];
						WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(weekName));
						var formated = backend.Highscore.formatSong(currentSong.songName.toLowerCase(), curDifficulty);
						PlayState.SONG = backend.Song.loadFromJson(formated, currentSong.songName.toLowerCase());
						try LoadingState.loadAndSwitchState(new ChartingState(currentSong), false);
					}
					else if(inSongSelect){
						currentSong = currentSongs[curSelected];
						PlayState.storyWeek = currentSong.week;						
						Difficulty.loadFromWeek();
    					currentDifficulties = Difficulty.list;
    					remove(grpAlph);
    					grpAlph = new FlxTypedGroup<Alphabet>();
    					add(grpAlph);
						for(i in iconArray) remove(i);
						iconArray = [];
    					for (i in 0...currentDifficulties.length) {
        					var diffText:Alphabet = new Alphabet(90, 320, currentDifficulties[i], true);
        					diffText.targetY = i;
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
					} else {
						PlayState.isStoryMode = false;
						currentMod = modArray[curSelected];
						Mods.currentModDirectory = currentMod;
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
					PlayState.isStoryMode = false;
					Mods.currentModDirectory = currentMod;
					reloadSongs();
					arrayModSongs();
					curSelected = 0;
					_lastVisibles = [];
        			changeSelection();
					updateTexts();
				} else if (inSongSelect){
					inDifSelect = false;
					inSongSelect = false;
					PlayState.isStoryMode = false;
					for(i in iconArray) remove(i);
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

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
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
		if(songs != null){
			if (songs.length > 0) {
				remove(grpAlph);
				grpAlph = new FlxTypedGroup<Alphabet>();
				add(grpAlph);
				currentSongs = [];
				inSongSelect = true;
				for (i in 0...songs.length){
					if(songs[i] != null){
						Mods.currentModDirectory = currentMod;
						if(Mods.currentModDirectory == songs[i].folder){
							currentSongs.push(songs[i]);
							var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
							songText.targetY = i;
							grpAlph.add(songText);

							songText.scaleX = Math.min(1, 980 / songText.width);
							songText.snapToPosition();

							var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
							icon.sprTracker = songText;

							songText.visible = songText.active = songText.isMenuItem = false;
							icon.visible = icon.active = false;

							iconArray.push(icon);
							add(icon);

							songText.x += 40;
							songText.screenCenter(X);
						}
					}
				}
			} // No songs
		} // No songs
	}
}