import flixel.FlxState;
import backend.ExtraKeysHandler;
import states.init.ScaleSimulationState;
import backend.WeekData;
import backend.Highscore;
import states.menus.TitleState;
import states.init.OutdatedState;

class Init extends FlxState {
	var mustUpdate:Bool = false;
	public static var updateVersion:String = '';

    override public function create(){
		Paths.clearStoredMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];

		FlxG.save.bind('funkin', CoolUtil.getSavePath());

		ClientPrefs.loadPrefs();

		if (ExtraKeysHandler.instance.data.scales == null)
			MusicBeatState.switchState(new ScaleSimulationState());

		#if CHECK_FOR_UPDATES
		if(ClientPrefs.data.checkForUpdates) {
			Log.hxTrace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/Manganosl/NotePulse-Engine/refs/heads/main/CurrentVersion.md");

			http.onData = function (data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = Main.npeVersion.trim();
				Log.info('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion) {
					Log.warn('versions arent matching!');
					mustUpdate = true;
				}
			}

			http.onError = function (error) {
		        Log.error(error);
			}

			http.request();
		}
		#end

		Highscore.load();

	    if (mustUpdate) {
	    	FlxG.switchState(new OutdatedState());
	    } else {
	    	FlxG.switchState(new TitleState());
	    }

		FlxG.signals.postUpdate.add(handleDaKeys);
    }

	function handleDaKeys(){
		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F2)
			backend.utils.WindowUtil.showConsole();

		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F5){
			Mods.modPack = null;
			psychlua.GlobalHandler.stopGlobalHX();
			MusicBeatState.switchState(new TitleState());
		}
	}
}