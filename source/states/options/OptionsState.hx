package states.options;

import states.MainMenuState;
import backend.StageData;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [
		'Note Colors',
		'Controls',
		'Adjust Delay and Combo',
		'Graphics',
		'Visuals and UI',
		'Gameplay',
		'Misc'
	];

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var descText:FlxText;
	private var titleText:FlxText;
	private var topOverlay:FlxSprite;

	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;

	private var selectorLeft:Alphabet;
	private var selectorRight:Alphabet;

	private var intendedSelY:Float = 0;
	private var intendedSelLeftX:Float = 0;
	private var intendedSelRightX:Float = 0;

	private var doControls:Bool = true;

	function openSelectedSubstate(label:String)
	{
		switch(label)
		{
			case 'Note Colors':
				openSubState(new substates.options.NotesSubState());
			case 'Controls':
				openSubState(new substates.options.ControlsSubState());
			case 'Graphics':
				openSubState(new substates.options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new substates.options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new substates.options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new states.options.NoteOffsetState());
			case 'Misc':
				openSubState(new substates.options.MiscSettingsSubState());
		}
	}

	function descriptionChange(label:String)
	{
		switch(label)
		{
			case 'Note Colors':
				descText.text = "Change the colors of notes and splashes.";
			case 'Controls':
				descText.text = "Rebind your keys and controller inputs.";
			case 'Graphics':
				descText.text = "Performance and visual quality settings.";
			case 'Visuals and UI':
				descText.text = "Purely cosmetic UI and visual options.";
			case 'Gameplay':
				descText.text = "These options directly affect gameplay.";
			case 'Misc':
				descText.text = "Other miscellaneous settings.";
			case 'Adjust Delay and Combo':
				descText.text = "Calibrate note timing and combo offset.";
		}
	}

	override function create()
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		topOverlay = new FlxSprite().makeGraphic(FlxG.width, 300, 0xFF000000);
		topOverlay.antialiasing = ClientPrefs.data.antialiasing;
		topOverlay.alpha = 0.5;
		topOverlay.y = -210;

		titleText = new FlxText(0, 10, FlxG.width, "Options >", 32);
		titleText.setFormat(
			Paths.font("vcr.ttf"),
			32,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);
		titleText.scrollFactor.set();

		descText = new FlxText(0, 50, FlxG.width, "", 15);
		descText.setFormat(
			Paths.font("vcr.ttf"),
			15,
			FlxColor.WHITE,
			LEFT,
			FlxTextBorderStyle.OUTLINE,
			FlxColor.BLACK
		);
		descText.scrollFactor.set();

		selectorLeft = new Alphabet(0, 0, '>', true);
		selectorRight = new Alphabet(0, 0, '<', true);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		add(selectorLeft);
		add(selectorRight);
		add(topOverlay);
		add(titleText);
		add(descText);

		for (num => option in options)
		{
			var optionText:Alphabet = new Alphabet(0, 0, option, true);
			optionText.screenCenter();
			optionText.y += (100 * (num - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		descriptionChange(options[curSelected]);
		changeSelection(0, false);
		selectorLeft.x = intendedSelLeftX;
		selectorRight.x = intendedSelRightX;
		selectorLeft.y = intendedSelY;
		selectorRight.y = intendedSelY;

		ClientPrefs.saveSettings();
		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		changeSelection(0, false);

		topOverlay.alpha = 0.5;
		titleText.alpha = 1;
		descText.alpha = 1;
		selectorLeft.alpha = 1;
		selectorRight.alpha = 1;

		ClientPrefs.saveSettings();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		doControls = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		selectorLeft.x = CoolUtil.fpsLerp(selectorLeft.x, intendedSelLeftX, 0.25);
		selectorRight.x = CoolUtil.fpsLerp(selectorRight.x, intendedSelRightX, 0.25);
		selectorLeft.y = CoolUtil.fpsLerp(selectorLeft.y, intendedSelY, 0.25);
		selectorRight.y = CoolUtil.fpsLerp(selectorRight.y, intendedSelY, 0.25);

		if (!doControls) return;

		if (controls.UI_UP_P)
		{
			changeSelection(-1);
			descriptionChange(options[curSelected]);
		}

		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
			descriptionChange(options[curSelected]);
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if (onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else
				MusicBeatState.switchState(new MainMenuState());
		}
		else if (controls.ACCEPT)
		{
			doControls = false;

			for (item in grpOptions.members)
				FlxTween.tween(item, {alpha: 0}, 0.1, {ease: FlxEase.quadOut});

			FlxTween.tween(selectorLeft, {alpha: 0}, 0.1);
			FlxTween.tween(selectorRight, {alpha: 0}, 0.1);

			topOverlay.alpha = 0;
			titleText.alpha = 0;
			descText.alpha = 0;

			openSelectedSubstate(options[curSelected]);
		}
	}

	function changeSelection(change:Int = 0, ?playSound:Bool = true)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (num => item in grpOptions.members)
		{
			item.targetY = num - curSelected;
			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
				intendedSelLeftX = item.x - 63;
				intendedSelRightX = item.x + item.width + 15;
				intendedSelY = item.y;
			}
		}

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
