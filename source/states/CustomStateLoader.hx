package states;

import states.MainMenuState;
import backend.StageData;
import states.PlayState;
import backend.Song;
import backend.Mods;
import states.CustomState;
import backend.Paths;
import debug.CodenameBuildField;

class CustomStateLoader extends MusicBeatState
{
	var options:Array<String> = ['ParkPass', 'Raps of Mt. Ebbot', "Rewrite"];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var descText:FlxText;
	private var cosanegra:FlxSprite;
	private var controlesActivos:Bool = true;
	private var titleText:FlxText;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'ParkPass':
				Mods.currentModDirectory = "ParkPass";
				PlayState.SONG = Song.loadFromJson("menu-hard", "menu");
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = 0;
				CodenameBuildField.engineName = "ParkPass 1.1";
				LoadingState.loadAndSwitchState(new PlayState());
			case 'Raps of Mt. Ebbot':
				Mods.currentModDirectory = "Raps Of Mt. Ebott";
				PlayState.SONG = Song.loadFromJson("menu-hard", "menu");
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = 0;
				CodenameBuildField.engineName = "Raps of Mt. Ebbot DEMO";
				//PlayState.storyWeek = 203;
				LoadingState.loadAndSwitchState(new PlayState());
			//case 'Graphics >':
			//	openSubState(new options.GraphicsSettingsSubState());
			//case 'Visuals and UI >':
			//	openSubState(new options.VisualsUISubState());
			//case 'Gameplay >':
			//	openSubState(new options.GameplaySettingsSubState());
			//case 'Adjust Delay and Combo':
			//	MusicBeatState.switchState(new options.NoteOffsetState());
			case "Rewrite":
				Mods.currentModDirectory = "Sonic";
				CodenameBuildField.engineName = "Vs Rewrite 2.0";
				MusicBeatState.switchState(new CustomState('mods/Sonic/states/TitleState.hx'));
		}
	}

	function descriptionchange(label:String) {
		switch(label) {
			case 'ParkPass':
				descText.text = "";
			case 'Raps of Mt. Ebbot':
				descText.text = '';
			//case 'Graphics >':
			//	descText.text = "Just a bunch of graphics related options";
			//case 'Visuals and UI >':
			//	descText.text = "This won't affect your gameplay";
			//case 'Gameplay >':
			//	descText.text = "This WILL affect your gameplay";
			//case 'Adjust Delay and Combo':
			//	MusicBeatState.switchState(new options.NoteOffsetState());
		}
	}

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();

		cosanegra = new FlxSprite().makeGraphic(200, 500, 0xff000000);
		cosanegra.antialiasing = ClientPrefs.data.antialiasing;
		cosanegra.screenCenter();
		add(cosanegra);

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		changeSelection();
		ClientPrefs.saveSettings();

		for (item in grpOptions.members) {
			FlxTween.tween(item, {x: 100}, 0.1, {ease: FlxEase.quadOut});
			}
			
			var cosanegra:FlxSprite = new FlxSprite().makeGraphic(5000, 300, 0xff000000);
			cosanegra.antialiasing = ClientPrefs.data.antialiasing;
			cosanegra.screenCenter();
			cosanegra.alpha = 0.5;
			cosanegra.y = -210;
			add(cosanegra);

			titleText = new FlxText(0, 10, 1145, "State Loader", 32); //Alphabet(75, 45, title, true);
			titleText.alpha = 1;
			titleText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			titleText.scrollFactor.set();
			add(titleText);
	
			descText = new FlxText(0, 50, 1180, "", 15);
			descText.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			descText.scrollFactor.set();
			add(descText);

			descriptionchange(options[curSelected]);
		    changeSelection(0);

			for (item in grpOptions.members) {
				FlxTween.tween(item, {x: 100}, 0.1, {ease: FlxEase.quadOut});
				}

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		changeSelection(0);
		cosanegra.alpha = 1;
		titleText.alpha = 1;
		descText.alpha = 1;
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
		new FlxTimer().start(0.6, function(tmr:FlxTimer) {
			controlesActivos = true;
		});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P && controlesActivos) {
			changeSelection(-1);
			descriptionchange(options[curSelected]);
		}
		if (controls.UI_DOWN_P && controlesActivos) {
			changeSelection(1);
			descriptionchange(options[curSelected]);
		}

		if (controls.BACK && controlesActivos) {
			for (item in grpOptions.members) {
				FlxTween.tween(item, {x: item.x +1800}, 0.6, {ease: FlxEase.quadOut});
				}
				new FlxTimer().start(0.4, function(tmr:FlxTimer) {
					FlxG.sound.play(Paths.sound('cancelMenu'));
					if(onPlayState)
					{
						StageData.loadDirectory(PlayState.SONG);
						LoadingState.loadAndSwitchState(new PlayState());
						FlxG.sound.music.volume = 0;
					}
					else MusicBeatState.switchState(new MainMenuState());
				});
		}
		else if (controls.ACCEPT && controlesActivos) {
			controlesActivos = false;
			for (item in grpOptions.members) {
			FlxTween.tween(item, {x: item.x -1000}, 0.6, {ease: FlxEase.quadOut});
			new FlxTimer().start(0.6, function(tmr:FlxTimer) {
				cosanegra.alpha = 0;
			    titleText.alpha = 0;
			    descText.alpha = 0;
				openSelectedSubstate(options[curSelected]); 
			}); //descriptionchange(options[curSelected]);
		}
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			FlxTween.tween(item, {x: 100}, 0.1, {ease: FlxEase.quadOut});
			
			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				FlxTween.tween(item, {x: 200}, 0.1, {ease: FlxEase.quadOut});
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}