package;

import flixel.FlxState;
import funkin.backend.ExtraKeysHandler;
import funkin.states.init.ScaleSimulationState;
import funkin.data.Highscore;
import funkin.states.menus.TitleState;
import funkin.states.init.OutdatedState;
import funkin.backend.utils.helpers.FunkinRatioScaleMode;
import flixel.addons.transition.FlxTransitionableState;

class Init extends FlxState {
	var mustUpdate:Bool = false;
	public static var updateVersion:String = '';

    override public function create(){
		Paths.clearStoredMemory();

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();

		#if VIDEOS_ALLOWED
		funkin.objects.FunkinVideoSprite.init();
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = 60;
		FlxG.keys.preventDefaultKeys = [TAB];
		FlxG.mouse.visible = false;
		FlxG.scaleMode = new FunkinRatioScaleMode();
		FlxG.signals.preStateSwitch.add((cast FlxG.scaleMode : FunkinRatioScaleMode).resetSize);
		FlxG.signals.postUpdate.add(handleDaKeys);

		if (ExtraKeysHandler.instance.data.scales == null) {
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new ScaleSimulationState());
		}

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
			FlxTransitionableState.skipNextTransOut = true;
	    	FlxG.switchState(new OutdatedState());
	    } else {
			FlxTransitionableState.skipNextTransOut = true;
	    	FlxG.switchState(new TitleState());
	    }
    }

	function handleDaKeys(){
		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F2)
			funkin.backend.utils.WindowUtil.showConsole();

		if(FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.F5){
			Mods.currentModDirectory = null;
			Mods.currentLoadedMod = null;
			Mods.modPack = null;
			funkin.scripting.GlobalHandler.stopGlobalHX();
			MusicBeatState.switchState(new TitleState());
		}
	}
}