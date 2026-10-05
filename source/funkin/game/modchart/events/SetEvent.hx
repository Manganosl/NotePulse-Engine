// @author Nebula_Zorua

package funkin.game.modchart.events;

class SetEvent extends ModEvent {
	override function run(curStep:Float)
	{
		if (mod != null) manager.setModValue(mod, endVal, player);
		else manager.setValue(modName, endVal, player);
        finished = true;
	}
}
