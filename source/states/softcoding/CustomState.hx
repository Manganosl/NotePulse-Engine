package states.softcoding;

using StringTools;

class CustomState extends MusicBeatState
{
	public static var instance:CustomState;
	public var data:Dynamic = null;

	public function new(stateName:String, ?_data:Dynamic) {
		if(_data != null) this.data = _data;

		super();
		instance = this;
		this.useCustomStateName = true;
		this.className = stateName;
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
