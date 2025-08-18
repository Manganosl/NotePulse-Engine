package states.softcoding;

using StringTools;

class CustomSubstate extends MusicBeatSubstate
{
	public static var instance:CustomSubstate;
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
