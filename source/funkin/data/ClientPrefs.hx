package funkin.data;

import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import funkin.backend.utils.CoolUtil.*;

import funkin.objects.debug.FunkinDebugDisplay;
import funkin.states.menus.TitleState;

// Add a variable here and it will get automatically saved
@:structInit class SaveVariables {
	public var downScroll:Bool = false;
	public var middleScroll:Bool = false;
	public var opponentStrums:Bool = true;
	public var keybindShowcase:Bool = true;
	public var showFPS:Bool = true;
	public var flashing:Bool = true;
	public var autoPause:Bool = true;
	public var antialiasing:Bool = true;
	public var noteSkin:String = 'Default';
	public var splashSkin:String = 'Psych';
	public var splashAlpha:Float = 0.6;
	public var lowQuality:Bool = false;
	public var colorblindMode:Int = 0;
	public var shaders:Bool = true;
	public var cacheOnGPU:Bool = #if !switch false #else true #end; //From Stilic
	public var framerate:Int = 60;
	public var camZooms:Bool = true;
	public var ratingCam:String = "HUD";
	public var hideHud:Bool = false;
	public var language:Int = 0; //for english at begin
	public var noteOffset:Int = 0;
	public var devMode:Bool = false;

	public var arrowRGB:Array<Array<FlxColor>> = [
		[0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038],
		[0xFF999999, 0xFFFFFFFF, 0xFF201E31],
		[0xFFFFFF00, 0xFFFFFFFF, 0xFF993300],
		[0xFF8B4AFF, 0xFFFFFFFF, 0xFF3B177D],
		[0xFFFF0000, 0xFFFFFFFF, 0xFF660000],
		[0xFF0033FF, 0xFFFFFFFF, 0xFF000066],
		[0xFF221F21, 0xFFFFFFFF, 0xFF3C1F56],
		[0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
		[0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
		[0xFFF9393F, 0xFFFFFFFF, 0xFF651038],
		[0xFF999999, 0xFFFFFFFF, 0xFF201E31],
		[0xFFFFFF00, 0xFFFFFFFF, 0xFF993300],
		[0xFF8B4AFF, 0xFFFFFFFF, 0xFF3B177D],
		[0xFFFF0000, 0xFFFFFFFF, 0xFF660000],
		[0xFF0033FF, 0xFFFFFFFF, 0xFF000066]];
	public var arrowRGBPixel:Array<Array<FlxColor>> = [
		[0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
		[0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
		[0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000],
		[0xFFB6B6B6, 0xFFFFFFFF, 0xFF444444],
		[0xFFFFD94A, 0xFFF4FFFF, 0xFF663500],
	    [0xFFB055BC, 0xFFF6FFE6, 0xFF4D0060],
	    [0xFFDF3E23, 0xFFFFFAF5, 0xFF440000],
	    [0xFF2F69E5, 0xFFFFF9FF, 0xFF000F5D],
	    [0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
	    [0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
	    [0xFF71E300, 0xFFF6FFE6, 0xFF003100],
		[0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000],
	    [0xFFB6B6B6, 0xFFFFFFFF, 0xFF444444],
	    [0xFFFFD94A, 0xFFF4FFFF, 0xFF663500],
	    [0xFFB055BC, 0xFFF6FFE6, 0xFF4D0060],
	    [0xFFDF3E23, 0xFFFFFAF5, 0xFF440000],
	    [0xFF2F69E5, 0xFFFFF9FF, 0xFF000F5D]];

	public var ghostTapping:Bool = true;
	public var timeBarType:String = 'Time Left';
	public var scoreZoom:Bool = true;
	public var noReset:Bool = false;
	public var healthBarAlpha:Float = 1;
	public var hitsoundVolume:Float = 0;
	public var alphaFPS:Float = 0.5;
	public var pauseMusic:String = 'Tea Time';
	public var checkForUpdates:Bool = true;
	public var comboStacking:Bool = true;
	public var gameplaySettings:Map<String, Dynamic> = [
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		// -kade
		'songspeed' => 1.0,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public var comboOffset:Array<Int> = [0, 0, 0, 0];
	public var ratingOffset:Int = 0;
	public var epicWindow:Int = 23;
	public var sickWindow:Int = 45;
	public var goodWindow:Int = 90;
	public var badWindow:Int = 135;
	public var safeFrames:Float = 10;
	public var guitarHeroSustains:Bool = true;
	public var discordRPC:Bool = true;
	public var quantNotes:Bool = false;
}

class ClientPrefs {
	public static var data:SaveVariables = {};
	public static var defaultData:SaveVariables = {};

	public static var keyBinds:Map<String, Array<FlxKey>> = [
		'note_up'        => [W, UP],
		'note_left'      => [A, LEFT],
		'note_down'      => [S, DOWN],
		'note_right'     => [D, RIGHT],
		'ui_up'          => [W, UP],
		'ui_left'        => [A, LEFT],
		'ui_down'        => [S, DOWN],
		'ui_right'       => [D, RIGHT],
		'accept'         => [SPACE, ENTER],
		'back'           => [BACKSPACE, ESCAPE],
		'pause'          => [ENTER, ESCAPE],
		'reset'          => [R],
		'volume_mute'    => [ZERO],
		'volume_up'      => [NUMPADPLUS, PLUS],
		'volume_down'    => [NUMPADMINUS, MINUS],
		'debug_1'        => [SEVEN],
		'debug_2'        => [EIGHT],
		'debug_3'        => [NINE],

		'0_key_0'  => [SPACE],
		'1_key_0'  => [D, LEFT], '1_key_1' => [K, RIGHT],
		'2_key_0'  => [D, LEFT], '2_key_1' => [SPACE], '2_key_2' => [K, RIGHT],
		'3_key_0'  => [A, LEFT], '3_key_1' => [S, DOWN], '3_key_2' => [W, UP], '3_key_3' => [D, RIGHT],
		'4_key_0'  => [A, LEFT], '4_key_1' => [S, DOWN], '4_key_2' => [SPACE], '4_key_3' => [W, UP], '4_key_4' => [D, RIGHT],
		'5_key_0'  => [S], '5_key_1' => [D], '5_key_2' => [F], '5_key_3' => [J], '5_key_4' => [K], '5_key_5' => [L],
		'6_key_0'  => [S], '6_key_1' => [D], '6_key_2' => [F], '6_key_3' => [SPACE], '6_key_4' => [J], '6_key_5' => [K], '6_key_6' => [L],
		'7_key_0'  => [A], '7_key_1' => [S], '7_key_2' => [D], '7_key_3' => [F], '7_key_4' => [H], '7_key_5' => [J], '7_key_6' => [K], '7_key_7' => [L],
		'8_key_0'  => [A], '8_key_1' => [S], '8_key_2' => [D], '8_key_3' => [F], '8_key_4' => [SPACE], '8_key_5' => [H], '8_key_6' => [J], '8_key_7' => [K], '8_key_8' => [L],
		'9_key_0'  => [A], '9_key_1' => [S], '9_key_2' => [D], '9_key_3' => [F], '9_key_4' => [G], '9_key_5' => [SPACE], '9_key_6' => [H], '9_key_7' => [J], '9_key_8' => [K], '9_key_9' => [L],
		'10_key_0' => [A], '10_key_1' => [S], '10_key_2' => [D], '10_key_3' => [F], '10_key_4' => [G], '10_key_5' => [SPACE], '10_key_6' => [H], '10_key_7' => [J], '10_key_8' => [K], '10_key_9' => [L], '10_key_10' => [SEMICOLON],
		'11_key_0' => [CAPSLOCK], '11_key_1' => [A], '11_key_2' => [S], '11_key_3' => [D], '11_key_4' => [F], '11_key_5' => [G], '11_key_6' => [SPACE], '11_key_7' => [H], '11_key_8' => [J], '11_key_9' => [K], '11_key_10' => [L], '11_key_11' => [SEMICOLON],
		'12_key_0' => [CAPSLOCK], '12_key_1' => [A], '12_key_2' => [S], '12_key_3' => [D], '12_key_4' => [F], '12_key_5' => [G], '12_key_6' => [SPACE], '12_key_7' => [H], '12_key_8' => [J], '12_key_9' => [K], '12_key_10' => [L], '12_key_11' => [SEMICOLON], '12_key_12' => [QUOTE],
		'13_key_0' => [CAPSLOCK], '13_key_1' => [A], '13_key_2' => [S], '13_key_3' => [D], '13_key_4' => [F], '13_key_5' => [G], '13_key_6' => [SPACE], '13_key_7' => [H], '13_key_8' => [J], '13_key_9' => [K], '13_key_10' => [L], '13_key_11' => [SEMICOLON], '13_key_12' => [QUOTE], '13_key_13' => [RBRACKET],
		'14_key_0' => [TAB], '14_key_1' => [CAPSLOCK], '14_key_2' => [A], '14_key_3' => [S], '14_key_4' => [D], '14_key_5' => [F], '14_key_6' => [G], '14_key_7' => [SPACE], '14_key_8' => [H], '14_key_9' => [J], '14_key_10' => [K], '14_key_11' => [L], '14_key_12' => [SEMICOLON], '14_key_13' => [QUOTE], '14_key_14' => [RBRACKET],
		'15_key_0' => [TAB], '15_key_1' => [CAPSLOCK], '15_key_2' => [A], '15_key_3' => [S], '15_key_4' => [D], '15_key_5' => [F], '15_key_6' => [G], '15_key_7' => [SPACE], '15_key_8' => [H], '15_key_9' => [J], '15_key_10' => [K], '15_key_11' => [L], '15_key_12' => [SEMICOLON], '15_key_13' => [QUOTE], '15_key_14' => [RBRACKET], '15_key_15' => [BACKSLASH],
		'16_key_0' => [ONE], '16_key_1' => [TAB], '16_key_2' => [CAPSLOCK], '16_key_3' => [A], '16_key_4' => [S], '16_key_5' => [D], '16_key_6' => [F], '16_key_7' => [G], '16_key_8' => [SPACE], '16_key_9' => [H], '16_key_10' => [J], '16_key_11' => [K], '16_key_12' => [L], '16_key_13' => [SEMICOLON], '16_key_14' => [QUOTE], '16_key_15' => [RBRACKET], '16_key_16' => [BACKSLASH],
		'17_key_0' => [Q], '17_key_1' => [W], '17_key_2' => [E], '17_key_3' => [R], '17_key_4' => [T], '17_key_5' => [Y], '17_key_6' => [U], '17_key_7' => [I], '17_key_8' => [O], '17_key_9' => [A], '17_key_10' => [S], '17_key_11' => [D], '17_key_12' => [F], '17_key_13' => [SPACE], '17_key_14' => [H], '17_key_15' => [J], '17_key_16' => [K], '17_key_17' => [L]
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
		'note_up'		=> [DPAD_UP, Y],
		'note_left'		=> [DPAD_LEFT, X],
		'note_down'		=> [DPAD_DOWN, A],
		'note_right'	=> [DPAD_RIGHT, B],
		
		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
		
		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [BACK]
	];
	public static var defaultKeys:Map<String, Array<FlxKey>> = null;
	public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

	public static function resetKeys(controller:Null<Bool> = null) //Null = both, False = Keyboard, True = Controller
	{
		if(controller != true)
			for (key in keyBinds.keys())
				if(defaultKeys.exists(key))
					keyBinds.set(key, defaultKeys.get(key).copy());

		if(controller != false)
			for (button in gamepadBinds.keys())
				if(defaultButtons.exists(button))
					gamepadBinds.set(button, defaultButtons.get(button).copy());
	}

	public static function clearInvalidKeys(key:String)
	{
		var keyBind:Array<FlxKey> = keyBinds.get(key);
		var gamepadBind:Array<FlxGamepadInputID> = gamepadBinds.get(key);
		while(keyBind != null && keyBind.contains(NONE)) keyBind.remove(NONE);
		while(gamepadBind != null && gamepadBind.contains(NONE)) gamepadBind.remove(NONE);
	}

	public static function loadDefaultKeys() {
		defaultKeys = keyBinds.copy();
		defaultButtons = gamepadBinds.copy();
	}

	public static function saveSettings() {
		for (key in Reflect.fields(data)) {
			Reflect.setField(FlxG.save.data, key, Reflect.field(data, key));
		}

		FlxG.save.data.keyBinds = keyBinds;
		FlxG.save.data.gamepadBinds = gamepadBinds;

		FlxG.save.flush();
		FlxG.log.add("Settings saved!");
	}

	public static function loadPrefs() {
		for (key in Reflect.fields(data)) {
			if (key != 'gameplaySettings' && Reflect.hasField(FlxG.save.data, key)) {
				Reflect.setField(data, key, Reflect.field(FlxG.save.data, key));
			}
		}

		if (FlxG.save.data.keyBinds != null) {
			var loadedKeys:Map<String, Array<FlxKey>> = FlxG.save.data.keyBinds;
			for (control => keys in loadedKeys) {
				if (keyBinds.exists(control)) keyBinds.set(control, keys);
			}
		}

		if (FlxG.save.data.gamepadBinds != null) {
			var loadedButtons:Map<String, Array<FlxGamepadInputID>> = FlxG.save.data.gamepadBinds;
			for (control => buttons in loadedButtons) {
				if (gamepadBinds.exists(control)) gamepadBinds.set(control, buttons);
			}
		}

		if(ClientPrefs.data.framerate > FlxG.drawFramerate) // FPS did not apply.
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}

		if(Main.fpsVar != null) 
			Main.fpsVar.backgroundOpacity = ClientPrefs.data.alphaFPS;

		reloadVolumeKeys();
	}

	inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
	{
		if(!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
		return /*PlayState.isStoryMode ? defaultValue : */ (data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue);
	}

	public static function reloadVolumeKeys()
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
		toggleVolumeKeys(true);
	}
	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		FlxG.sound.muteKeys = turnOn ? TitleState.muteKeys : [];
		FlxG.sound.volumeDownKeys = turnOn ? TitleState.volumeDownKeys : [];
		FlxG.sound.volumeUpKeys = turnOn ? TitleState.volumeUpKeys : [];
	}
}
