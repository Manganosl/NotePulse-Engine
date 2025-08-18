package states;

import flixel.text.FlxText;
import flixel.FlxState;

using StringTools;
class CrashHandlerState extends MusicBeatState
{	
	public var ermLeft:Bool = false;

	var error:String;
	var errorName:String;

	var bgError:flixel.FlxSprite;
	var errorTxt:FlxText;

	public function new(prevState:FlxState, error:String, errorName:String):Void {
        this.error = error;
        this.errorName = errorName;
        super();
	}

	override function create() {
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		flixel.FlxG.sound.playMusic(null, 0);
		ermLeft = true;
		
		var format:FlxTextFormat = new FlxTextFormat(FlxColor.RED);
		var marker = new FlxTextFormatMarkerPair(format, "<red>");

		var errorTextHAHA = "<red>* WHOOPS! NOTEPULSE ENGINE HAS CRASHED *<red>\n* " + errorName;
		bgError = new flixel.FlxSprite().makeGraphic(flixel.FlxG.width, flixel.FlxG.height, 0xFF000000);
		add(bgError);

		errorTxt = new FlxText(0, 0, flixel.FlxG.width - 40, errorTextHAHA, 30);
		if(Paths.font('vcr.ttf') != null) errorTxt.font = Paths.font('vcr.ttf');
		errorTxt.alignment = CENTER;
		errorTxt.screenCenter();
		errorTxt.applyMarkup(errorTxt.text,[marker]);
		add(errorTxt);

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		
		if (ermLeft && (flixel.FlxG.keys.justPressed.ENTER || flixel.FlxG.keys.justPressed.SPACE))
		{
			ermLeft = false;
			errorTxt.visible = false;

			flixel.FlxG.switchState(new MainMenuState());
		}
	}

	override function destroy() {
		flixel.FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		Conductor.set_bpm(100);

		super.destroy();
	}
}