package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import flixel.text.FlxText;
import flixel.util.FlxTimer;

@:access(funkin.states.editors.NoteSplashDebugState)
class NoteSplashDebugUI extends FlxSpriteContainer
{
	private var splashEditor:NoteSplashDebugState;

	public var imageInputText:UIInputText;
	public var nameInputText:UIInputText;
	public var stepperMinFps:UINumericStepper;
	public var stepperMaxFps:UINumericStepper;

	public var offsetsText:FlxText;
	public var curFrameText:FlxText;
	public var curAnimText:FlxText;
	public var savedText:FlxText;

	public var missingTextBG:FlxSprite;
	public var missingText:FlxText;

	public function new(splashEditor:NoteSplashDebugState)
	{
		super();
		this.splashEditor = splashEditor;
	}

	public function createUI()
	{
		var txtx = 60;
		var txty = 640;

		var imageName:FlxText = new FlxText(txtx, txty - 120, 'Image Name:', 16);
		add(imageName);

		imageInputText = new UIInputText(txtx, txty - 100, 360, NoteSplashDebugState.defaultTexture, 16);
		imageInputText.onChange = function(old:String, cur:String)
		{
			trace('changed image to $cur');
		}
		imageInputText.unfocus = function()
		{
			splashEditor.textureName = imageInputText.text;
			try {
				splashEditor.loadFrames();
			} catch(e:Dynamic) {
				trace('ERROR! $e');
				splashEditor.textureName = NoteSplashDebugState.defaultTexture;
				splashEditor.loadFrames();

				missingText.text = 'ERROR WHILE LOADING IMAGE:\n${imageInputText.text}';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				new FlxTimer().start(2.5, function(tmr:FlxTimer)
				{
					missingText.visible = false;
					missingTextBG.visible = false;
				});
			}
		};
		add(imageInputText);

		var animName:FlxText = new FlxText(txtx, txty, 'Animation Name:', 16);
		add(animName);

		nameInputText = new UIInputText(txtx, txty + 20, 360, '', 16);
		nameInputText.onChange = function(old:String, cur:String)
		{
			trace('changed anim name to $cur');
			splashEditor.config.anim = cur;
			splashEditor.curAnim = 1;
			splashEditor.reloadAnims();
		};
		add(nameInputText);

		add(new FlxText(txtx, txty - 50, 0, 'Min/Max Framerate:', 16));
		stepperMinFps = new UINumericStepper(txtx, txty - 30, 1, 22, 1, 60, 0);
		stepperMinFps.onValueChange = function(){
			if(stepperMinFps.value > stepperMaxFps.value)
				stepperMaxFps.value = stepperMinFps.value;
			splashEditor.config.minFps = Std.int(stepperMinFps.value);
			splashEditor.config.maxFps = Std.int(stepperMaxFps.value);
		}
		add(stepperMinFps);

		stepperMaxFps = new UINumericStepper(txtx + 60, txty - 30, 1, 26, 1, 60, 0);
		stepperMaxFps.onValueChange = function(){
			if(stepperMaxFps.value < stepperMinFps.value)
				stepperMinFps.value = stepperMaxFps.value;
			splashEditor.config.minFps = Std.int(stepperMinFps.value);
			splashEditor.config.maxFps = Std.int(stepperMaxFps.value);
		}
		add(stepperMaxFps);

		//
		offsetsText = new FlxText(300, 150, 680, '', 16);
		offsetsText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetsText.scrollFactor.set();
		add(offsetsText);

		curFrameText = new FlxText(300, 100, 680, '', 16);
		curFrameText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		curFrameText.scrollFactor.set();
		add(curFrameText);

		curAnimText = new FlxText(300, 50, 680, '', 16);
		curAnimText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		curAnimText.scrollFactor.set();
		add(curAnimText);

		var text:FlxText = new FlxText(0, 520, FlxG.width,
			"Press SPACE to Reset animation\n
			Press ENTER twice to save to the loaded Note Splash PNG's folder\n
			A/D change selected note - Arrow Keys to change offset (Hold shift for 10x)\n
			Ctrl + C/V - Copy & Paste", 16);
		text.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.scrollFactor.set();
		add(text);

		savedText = new FlxText(0, 340, FlxG.width, '', 24);
		savedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		savedText.scrollFactor.set();
		add(savedText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);
	}
}
