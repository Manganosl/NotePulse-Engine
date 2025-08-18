package states.editors;

import backend.WeekData;
import states.FreeplayState.SongMetadata;


class ModSelector extends MusicBeatState{
    private var modArray:Array<String> = [];
    private var goto:Class<MusicBeatState>;
    private var gotoArgs:Array<Dynamic> = [];
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

    private static var curSelected:Int = 0;
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

        grpAlph = new FlxTypedGroup<Alphabet>();
		add(grpAlph);

        for (i in 0...modArray.length){
			var modText:Alphabet = new Alphabet(90, 320, modArray[i], true);
			modText.targetY = i;
			grpAlph.add(modText);

			modText.scaleX = Math.min(1, 980 / modText.width);
			modText.snapToPosition();

			Mods.currentModDirectory = modArray[i];
			//var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			//icon.sprTracker = songText;

			modText.visible = modText.active = modText.isMenuItem = false;
			//icon.visible = icon.active = false;

			//iconArray.push(icon);
			//add(icon);

			modText.x += 40;
			modText.screenCenter(X);
		}

        changeSelection();
		updateTexts();
    }

    var velXtra:Float = 0;

    function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (change == -1) velXtra += 450;
		else if (change == 1) velXtra += -450;

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0){
			curSelected = modArray.length - 1;
			velXtra -= (450*modArray.length - 1)/4;
		}
		if (curSelected >= modArray.length){
			curSelected = 0;
			velXtra += (450*modArray.length - 1)/4;
		}

		var bullShit:Int = 0;

		/*for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;*/

		for (item in grpAlph.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
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
		    //iconArray[i].visible = iconArray[i].active = false;
	    }
	    _lastVisibles = [];

	    var min:Int = Math.round(Math.max(0, Math.min(modArray.length, lerpSelected - _drawDistance)));
	    var max:Int = Math.round(Math.max(0, Math.min(modArray.length, lerpSelected + _drawDistance)));
	
	    for (i in min...max)
	    {
	    	var item:Alphabet = grpAlph.members[i];
	    	item.visible = item.active = true;

	    	var y:Float = ((FlxG.height - 120) / 2) + ((i - lerpSelected) * 135); 

	    	item.x = (-50 + (Math.abs(Math.cos((y + (135 / 2) - (FlxG.camera.scroll.y + (FlxG.height / 2))) / (FlxG.height * 1.25) * Math.PI)) * 150));

	    	item.y = y;
	    	velXtra = CoolUtil.fpsLerp(velXtra, 0, 0.01);
		    backdrop.velocity.set(50, 30+velXtra);

    		//var icon:HealthIcon = iconArray[i];
		    //icon.visible = icon.active = true;
	    	//icon.x = item.x - 60;
    		//icon.y = y + 20;

		    _lastVisibles.push(i);
	    }
    }

    var holdTime:Float = 0;
	var updateOn:Bool = true;
	private var songs:Array<SongMetadata> = [];
    override public function update(elapsed:Float){
        var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT/* && controlsActive*/) shiftMult = 3;
        if(modArray.length > 1){
			if (controls.UI_UP_P/* && controlsActive*/)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P/* && controlsActive*/)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}
            if(controls.UI_DOWN || controls.UI_UP/* && controlsActive*/)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}
            if(FlxG.mouse.wheel != 0/* && controlsActive*/) 
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
            if (controls.ACCEPT /*&& controlsActive*/)
		    {
				Mods.currentModDirectory = modArray[curSelected];
				if(goto != states.editors.ChartingState && goto != states.editors.CharacterEditorState)
                	try MusicBeatState.switchState(Type.createInstance(goto, gotoArgs));
				else if(goto == states.editors.ChartingState){
					grpAlph.clear();
					songs = [];
					updateOn = false;
					for (i in 0...WeekData.weeksList.length) {
						var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
						var leSongs:Array<String> = [];
						var leChars:Array<String> = [];

						for (j in 0...leWeek.songs.length){
							leSongs.push(leWeek.songs[j][0]);
							leChars.push(leWeek.songs[j][1]);
						}

						// songs siempre es null, arreglar esto de aqui
						WeekData.setDirectoryFromWeek(leWeek);
						for (song in leWeek.songs){
							var colors:Array<Int> = song[2];
							if(colors == null || colors.length < 3){
								colors = [146, 113, 253];
							}
							addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
						}
					}
					if(songs != null){
						if (songs.length > 0) {
							for (i in 0...songs.length){
								if(songs[i] != null){
									if(Mods.currentModDirectory == songs[i].folder){
										var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
										songText.targetY = i;
										grpAlph.add(songText);

										songText.scaleX = Math.min(1, 980 / songText.width);
										songText.snapToPosition();

										//var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
										//icon.sprTracker = songText;

										songText.visible = songText.active = songText.isMenuItem = false;
										//icon.visible = icon.active = false;

										//iconArray.push(icon);
										//add(icon);

										songText.x += 40;
										songText.screenCenter(X);
									}
								}
							}
						}
					}
            	}
        	}
		}
        if(updateOn && (grpAlph != null)) updateTexts(elapsed);
		super.update(elapsed);
    }

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}
}