package funkin.modchart;

// could be added automaticaly instead of manually (todo ???)

class ScriptedModifier extends Modifier
{
	var name:String;
	var prefix:String;
	var modName:String;
	var modUpdate:Bool = false;
	var modOrder:Int = DEFAULT;
	var modType:ModifierType = MISC_MOD;
}