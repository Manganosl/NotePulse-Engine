package modchart.backend.standalone;

class Adapter {
	public static var instance:IAdapter;

	public static function init() {
		if (instance != null)
			return;

		final adapter = Type.createInstance(Type.resolveClass('modchart.backend.standalone.NotePulse'), []);

		#if FM_VERBOSE
		trace('[FunkinModchart Verbose] Found Adapter!');
		#end

		instance = adapter;
	}
}
