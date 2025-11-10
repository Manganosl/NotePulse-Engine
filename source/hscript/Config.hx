package hscript;

class Config {
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",
		"backend",
		"shaders",
		"psychlua",
		"options",
		"objects",
		"cutscenes"
	];
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"backend",
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack"
	];
	public static final DISALLOW_CUSTOM_CLASSES = [
		"flixel.FlxGame",
		"flixel.addons.ui.FlxUI9SliceSprite",
		"flixel.addons.ui.FlxUIList",
		"flixel.addons.ui.FlxUICursor",
		"flixel.addons.ui.FlxUINumericStepper",
		
		//Lime
		"hxp.Path"
	];
	public static final DISALLOW_ABSTRACT_AND_ENUM = [];
}