package substates.options;

class MiscSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc Settings';
		rpcTitle = 'Misc Settings Menu';

		#if !mobile
		var option:Option = new Option('FPS Counter',
			'If unchecked, hides FPS Counter.',
			'showFPS',
			'bool');
		addOption(option);
		option.onChange = onChangeFPSCounter;

		var option:Option = new Option('FPS Counter Background Alpha',
			'Set the transparency of the FPS counter\'s background.',
			'alphaFPS',
			'percent');
		addOption(option);
		option.onChange = onChangeFPSalpha;
		#end

		var option:Option = new Option('Developer Mode',
			'If checked, editors will be enabled.',
			'devMode',
			'bool');
		addOption(option);

		var option:Option = new Option('Auto Pause',
			"If checked, the game automatically pauses if the screen isn't on focus.",
			'autoPause',
			'bool');
		addOption(option);
		option.onChange = onChangeAutoPause;

		#if DISCORD_ALLOWED
		var option:Option = new Option('Discord Rich Presence',
			"Uncheck this to prevent accidental leaks, it will hide the Application from your \"Playing\" box on Discord",
			'discordRPC',
			'bool');
		addOption(option);
		#end

		#if CHECK_FOR_UPDATES
		if(Main.GIT_COMMIT == null){
			var option:Option = new Option('Check for Updates',
				'On Release builds, turn this on to check for NotePulse updates when you start the game.',
				'checkForUpdates',
				'bool');
			addOption(option);
		}
		#end

		super();
	}

	#if !mobile
	function onChangeFPSCounter()
		if(Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;

	function onFPSalpha()
		if(Main.fpsVar != null)
			Main.fpsVar.backgroundOpacity = ClientPrefs.alphaFPS;
	#end

	function onChangeAutoPause()
		FlxG.autoPause = ClientPrefs.data.autoPause;
}