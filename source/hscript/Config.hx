package hscript;

class Config {
	public static final ALLOWED_CUSTOM_CLASSES = [
		"flixel",
		"funkin.backend",
		"funkin.scripting.objects",
		"funkin.objects",
		"funkin.shaders",
		"funkin.cutscenes",
	];
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
		"funkin.backend",
		"flixel",
		"openfl",
		"haxe.xml",
		"haxe.CallStack"
	];
	public static final DISALLOW_CUSTOM_CLASSES = [
		"flixel.FlxGame",
		"funkin.objects.debug",
		"flixel.addons.ui.FlxUI9SliceSprite",
		"flixel.addons.ui.FlxUIList",
		"flixel.addons.ui.FlxUICursor",
		"flixel.addons.ui.FlxUINumericStepper",
		
		//Lime
		"hxp.Path"
	];
	public static final DISALLOW_ABSTRACT_AND_ENUM = [];

	@:unreflective
	public static final IMPORT_BLACKLIST:Array<String> = [];
}