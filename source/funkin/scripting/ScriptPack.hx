package funkin.scripting;

#if HSCRIPT_ALLOWED
using StringTools;

/**
 * A group of scripts that can be called, configured and reloaded together.
 */
class ScriptPack {
	public var name:String;

	public var scripts:Array<FunkinScript> = [];
	public var parent:Dynamic = null;
	public var additionalDefaultVariables:Map<String, Dynamic> = [];

	public var returnStopValue:Bool = false;

	public function new(?name:String = "ScriptPack", ?returnStopValue:Bool = false) {
		this.name = name;
		this.returnStopValue = returnStopValue;
	}

	/**
	 * Adds a script to the pack
	 * @return The script, or `null` if it was `null` or a dummy
	 */
	public function add(script:FunkinScript):Null<FunkinScript> {
		if(script == null || script.isDummy) return null;
		scripts.push(script);
		configureNewScript(script);
		return script;
	}

	/**
	 * Adds a script to the pack on a specific position
	 * @return The script, or `null` if it was `null` or a dummy
	 */
	public function insert(pos:Int, script:FunkinScript):Null<FunkinScript> {
		if(script == null || script.isDummy) return null;
		scripts.insert(pos, script);
		configureNewScript(script);
		return script;
	}

	/**
	 * Removes a script from the pack
	 * @return The script, or `null` if it was `null` or a dummy
	 */
	public function remove(script:FunkinScript):Bool
		return scripts.remove(script);

	function configureNewScript(script:FunkinScript):Void {
		if(parent != null) script.setParent(parent);
		for(k => v in additionalDefaultVariables) script.set(k, v);
	}

	public function contains(path:String):Bool
		return getByPath(path) != null;

	public function getByPath(path:String):Null<FunkinScript> {
		for(s in scripts)
			if(s != null && s.scriptName == path) return s;
		return null;
	}

	public function getByName(fileName:String):Null<FunkinScript> {
		for(s in scripts) {
			if(s == null || s.scriptName == null) continue;
			var name:String = s.scriptName.substring(s.scriptName.lastIndexOf("/") + 1);
			if(name == fileName) return s;
		}
		return null;
	}

	public function load():Void {
		for(s in scripts.copy())
			if(s != null) s.load();
	}

	/**
	 * Loads a script from a path and adds it to the pack
	 * @return The script, or `null` if the file doesn't exist
	 */
	public function importScript(path:String, ?absolute:Bool = false):Null<FunkinScript> {
		var scriptPath:String = path;
		if(!absolute) scriptPath = Paths.getScriptPath(path.endsWith(".hx") ? path : path + ".hx");

		var script = new FunkinScript(scriptPath, parent);
		return add(script);
	}

	/**
	 * Calls `func` on every active script
	 *
	 * @param ignoreStops If `true`, `Function_StopHScript` / `Function_StopAll` are ignored
	 * @param exclusions `scriptName`s of scripts that will not be called
	 * @param excludeValues Returned values that will be ignored
	 * @return The last value returned by a script (other than `Function_Continue`)
	 */
	public function call(func:String, ?args:Array<Dynamic>, ?ignoreStops:Bool = false, ?exclusions:Array<String>, ?excludeValues:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [];

		for(sc in scripts) {
			if(sc == null || sc.interp == null) continue;
			if(exclusions.contains(sc.scriptName)) continue;

			var myValue:Dynamic = sc.call(func, args);

			// Need to check if its a string because of the fucking compiler or some shit like that
			if(!ignoreStops && (myValue is String) && (myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll)) {
				if(returnStopValue && !excludeValues.contains(myValue)) returnVal = myValue;
				break;
			}

			if(myValue != null && myValue != LuaUtils.Function_Continue && !excludeValues.contains(myValue)) {
				returnVal = myValue;
			}
		}

		return returnVal;
	}

	/**
	 * Sets a variable for every script in this pack
	 */
	public function set(variable:String, value:Dynamic, ?exclusions:Array<String>):Void {
		if(exclusions == null) exclusions = [];
		for(sc in scripts)
			if(sc != null && !exclusions.contains(sc.scriptName)) sc.set(variable, value);
	}

	/**
	 * Get the first non-null value of variable found in the scripts
	 */
	public function get(variable:String):Dynamic {
		for(sc in scripts) {
			var v:Dynamic = sc != null ? sc.get(variable) : null;
			if(v != null) return v;
		}
		return null;
	}

	/**
	 * Sets the parent of every script
	 */
	public function setParent(newParent:Dynamic):Void {
		parent = newParent;
		for(sc in scripts)
			if(sc != null) sc.setParent(newParent);
	}

	/**
	 * Hot-reloads every script
	 * @return How many scripts were reloaded.
	 */
	public function reload():Int {
		var count:Int = 0;
		for(sc in scripts.copy())
			if(sc != null && sc.reload()) count++;
		return count;
	}

	public function destroy():Void {
		for(sc in scripts) {
			if(sc == null) continue;
			sc.call("onDestroy", []);
			sc.stop();
		}
		scripts.resize(0);
	}
}
#end
