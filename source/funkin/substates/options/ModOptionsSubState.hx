package funkin.substates.options;

import funkin.objects.notes.PlayField;
import funkin.substates.options.Option.ModOption;

class ModOptionsSubState extends BaseOptionsMenu
{
	var parsedJson:Dynamic;
	public function new(parsedJson:Dynamic){
		this.parsedJson = parsedJson;

		title = '${parsedJson.configName != null ? parsedJson.configName : "Mod Settings"}';
		rpcTitle = '${parsedJson.configName != null ? parsedJson.configName : "Mod Settings"} Menu'; //for Discord Rich Presence

		var jsonOptions:Array<Dynamic> = parsedJson.options;
		for(jsonOption in jsonOptions){
			if(jsonOption.type != "string"){
				var option:ModOption = new ModOption(jsonOption.name,
					jsonOption.desc,
					jsonOption.variable,
					jsonOption.type);
				addOption(option);
			} else {
				var option:ModOption = new ModOption(jsonOption.name,
					jsonOption.desc,
					jsonOption.variable,
					jsonOption.type,
					jsonOption.options);
				addOption(option);
			}
		}

		super();
	}
}