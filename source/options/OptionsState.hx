package options;

import states.MainMenuState;
import backend.StageData;
import backend.CoolUtil;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var descText:FlxText;
	private var cosanegra:FlxSprite;
	private var controlesActivos:Bool = true;
	private var titleText:FlxText;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;
	var intendedSelY:Float = 0;
	var intendedSelLeftX:Float = 0;
	var intendedSelRightX:Float = 0;

	function openSelectedSubstate(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new options.NoteOffsetState());
		}
	}

	function descriptionchange(label:String) {
		switch(label) {
			case 'Note Colors':
				descText.text = "I mean, why explain it";
			case 'Controls':
				descText.text = 'Change your controls (Use "Q" and "E" to change between EK controls)';
			case 'Graphics':
				descText.text = "Just a bunch of graphics related options";
			case 'Visuals and UI':
				descText.text = "This won't affect your gameplay";
			case 'Gameplay':
				descText.text = "This WILL affect your gameplay";
			case 'Adjust Delay and Combo':
				descText.text = "Adjust the delay of your notes and the combo text (Only if its camera is set to HUD in Visuals and UI)";
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

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();
			
			var cosanegra:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 300, 0xff000000);
			cosanegra.antialiasing = ClientPrefs.data.antialiasing;
			cosanegra.screenCenter();
			cosanegra.alpha = 0.5;
			cosanegra.y = -210;
			add(cosanegra);

			titleText = new FlxText(0, 10, 1145, "Options > ", 32); //Alphabet(75, 45, title, true);
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
		controlesActivos = true;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		selectorLeft.x = CoolUtil.fpsLerp(selectorLeft.x, intendedSelLeftX, 0.25);
		selectorRight.x = CoolUtil.fpsLerp(selectorRight.x, intendedSelRightX, 0.25);
		selectorLeft.y = CoolUtil.fpsLerp(selectorLeft.y, intendedSelY, 0.25);
		selectorRight.y = CoolUtil.fpsLerp(selectorRight.y, intendedSelY, 0.25);

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
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if(onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else MusicBeatState.switchState(new MainMenuState());
			}
		}
		else if (controls.ACCEPT && controlesActivos) {
			controlesActivos = false;
			for (item in grpOptions.members) {
				FlxTween.tween(item, {alpha: 0}, 0.1, {ease: FlxEase.quadOut});
				FlxTween.tween(selectorLeft, {alpha: 0}, 0.1, {ease: FlxEase.quadOut});
				FlxTween.tween(selectorRight, {alpha: 0}, 0.1, {ease: FlxEase.quadOut});
				cosanegra.alpha = 0;
				titleText.alpha = 0;
				descText.alpha = 0;
				openSelectedSubstate(options[curSelected]); 
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
			
			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				intendedSelLeftX = item.x - 63;
				intendedSelRightX = item.x + item.width + 15;
				intendedSelY = item.y;
				selectorLeft.alpha = 1;
				selectorRight.alpha = 1;
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