package substates.options;

class MiscSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = 'Misc Settings';
		rpcTitle = 'Misc Settings Menu'; //for Discord Rich Presence

		//I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Developer Mode', //Name
			'If checked, editors will be enabled.', //Description
			'devMode', //Save data variable name
			'bool'); //Variable type
		addOption(option);

		super();
	}
}