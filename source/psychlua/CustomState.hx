package psychlua;

class CustomState extends MusicBeatState {
	public var stateName:String;
	
	#if LUA_ALLOWED
	/*public static function implement() {
		FunkinLua.registerFunction('openCustomState', (name:String) -> MusicBeatState.switchState(new CustomState(name)));
	}*/
	#end
	
	public function new(name:String) {
		super();
		stateName = name;
		//multiScript = false;
	}
	
	public override function create():Void {
		//rpcDetails = 'Custom State ($stateName)';
		
		preCreate();
		super.create();
	}
	function preCreate():Void {
		var loaded:Bool = false;
		
		if (!loaded) {
			//FlxTransitionableState.skipNextTransIn = true;
			var e:String = 'Custom state script was not found / had errors, for "$stateName"';
			MusicBeatState.switchState(new states.ErrorState('$e\n\nPress ACCEPT to attempt to reload the state.\nPress BACK to return to Main Menu.',
				() -> MusicBeatState.switchState(new CustomState(stateName)),
				() -> MusicBeatState.switchState(new states.MainMenuState())
			));
		}
	}
	
	/*public override function update(elapsed:Float):Void {
		preUpdate(elapsed);
		super.update(elapsed);
		postUpdate(elapsed);
	}*/
	
	public function customStateName():String {
		return stateName;
	}
}