package funkin.scripting.lua.functions;

import funkin.scripting.objects.*;

import openfl.utils.Assets;

#if (LUA_ALLOWED)
class FlixelAnimateFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua:State = funk.lua;
		Lua_helper.add_callback(lua, "addAnimationBySymbol", function(tag:String, name:String, symbol:String, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0)
		{
			var obj:Dynamic = PlayState.instance.variables.get(tag);
			if(cast (obj, FlxAnimate) == null) return false;

			obj.anim.addBySymbol(name, symbol, framerate, loop, matX, matY);
			if(obj.anim.lastPlayedAnim == null)
			{
				if(obj.playAnim != null) obj.playAnim(name, true); //is ModchartAnimateSprite
				else obj.animation.play(name, true);
			}
			return true;
		});

		Lua_helper.add_callback(lua, "addAnimationBySymbolIndices", function(tag:String, name:String, symbol:String, ?indices:Any = null, ?framerate:Float = 24, ?loop:Bool = false, ?matX:Float = 0, ?matY:Float = 0)
		{
			var obj:Dynamic = PlayState.instance.variables.get(tag);
			if(cast (obj, FlxAnimate) == null) return false;

			if(indices == null)
				indices = [0];
			else if(Std.isOfType(indices, String))
			{
				var strIndices:Array<String> = cast (indices, String).trim().split(',');
				var myIndices:Array<Int> = [];
				for (i in 0...strIndices.length) {
					myIndices.push(Std.parseInt(strIndices[i]));
				}
				indices = myIndices;
			}

			obj.anim.addBySymbolIndices(name, symbol, indices, framerate, loop, matX, matY);
			if(obj.anim.lastPlayedAnim == null)
			{
				if(obj.playAnim != null) obj.playAnim(name, true); //is ModchartAnimateSprite
				else obj.animation.play(name, true);
			}
			return true;
		});
	}
}
#end