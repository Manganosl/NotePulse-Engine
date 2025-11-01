package backend.utils;

import backend.ExtraKeysHandler.EKNoteColor;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import states.menus.FreeplayState.SongMetadata;

class CoolUtil
{
	public static inline function addZeros(str:String, num:Int) {
		while(str.length < num) str = '0${str}';
		return str;
	}

	inline static public function getBuildTarget() {
		#if windows
		return 'windows';
		#elseif linux
		return 'linux';
		#elseif mac
		return 'mac';
		#elseif html5
		return 'browser';
		#elseif android
		return 'android';
		#elseif ios
		return 'ios';
		#else
		return 'unknown';
		#end
	}

	public static function getSizeString(size:Float):String {
		var labels = ["B", "KB", "MB", "GB", "TB"];
		var rSize:Float = size;
		var label:Int = 0;
		while(rSize > 1024 && label < labels.length-1) {
			label++;
			rSize /= 1024;
		}
		return '${Std.int(rSize) + "." + addZeros(Std.string(Std.int((rSize % 1) * 100)), 2)}${labels[label]}';
	}

	public static inline function getFPSRatio(ratio:Float):Float {
		return FlxMath.bound(ratio * 60 * FlxG.elapsed, 0, 1);
	}

	public static inline function lerpColor(color1:FlxColor, color2:FlxColor, ratio:Float, fpsSensitive:Bool = false) {
		if (!fpsSensitive)
			ratio = getFPSRatio(ratio);
		return FlxColor.interpolate(color1, color2, ratio);
	}
	
	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float):Float {
		return FlxMath.lerp(v1, v2, getFPSRatio(ratio));
	}

	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}

public static function getSongsForCurrentMod():Array<SongMetadata> {
    var result:Array<SongMetadata> = [];

    var selectedDir:String = Mods.currentModDirectory;
    var restoreDir:String = Mods.currentModDirectory;

    if (selectedDir == null) return result;

    for (i in 0...WeekData.weeksList.length) {
        var weekName:String = WeekData.weeksList[i];
        var leWeek:WeekData = WeekData.weeksLoaded.get(weekName);

        WeekData.setDirectoryFromWeek(leWeek);

        if (Mods.currentModDirectory == selectedDir) {
            for (j in 0...leWeek.songs.length) {
                // <-- IMPORTANT: force dynamic so Haxe/C++ doesn't infer wrong compile-time types
                var songEntry:Dynamic = leWeek.songs[j];

                // cast the expected string positions explicitly
                var songName:String = cast songEntry[0];
                var songCharacter:String = cast songEntry[1];

                // default fallback color
                var color:Int = -7179779;

                // pull the 3rd element dynamically (if present)
                var c:Dynamic = null;
                if (songEntry != null && Reflect.hasField(songEntry, "length") && songEntry.length > 2) {
                    c = songEntry[2];
                }

                if (c != null) {
                    // if it's an array (RGB)
                    if (Std.is(c, Array)) {
                        var arr:Array<Dynamic> = cast c;
                        if (arr != null && arr.length >= 3) {
                            // ensure elements are Ints before using them
                            var r:Int = cast arr[0];
                            var g:Int = cast arr[1];
                            var b:Int = cast arr[2];
                            color = FlxColor.fromRGB(r, g, b);
                        }
                    }
                    // if it's already an Int color
                    else if (Std.is(c, Int)) {
                        color = cast c;
                    }
                    // if it's a String (e.g. "0xFF33AA" or "1234567"), try parse
                    else if (Std.is(c, String)) {
                        var s:String = cast c;
                        // try parse decimal first
                        var parsed:Null<Int> = Std.parseInt(s);
                        if (parsed != null) {
                            color = parsed;
                        } else {
                            // try hex like "0xFF33AA" or "#FF33AA"
                            var hex = s.replace("#", "");
                            if (hex.indexOf("0x") == 0) hex = hex.substr(2);
                            // attempt parse base 16
                            try {
                                color = Std.parseInt("0x" + hex);
                            } catch (e:Dynamic) {
                                // leave default
                            }
                        }
                    }
                }

                var meta:SongMetadata = new SongMetadata(songName, i, songCharacter, color);
                result.push(meta);
            }
        }
    }

    // restore global state
    Mods.currentModDirectory = restoreDir;
    return result;
}


	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		var daList:String = null;
		#if (sys && MODS_ALLOWED)
		var formatted:Array<String> = path.split(':'); //prevent "shared:", "preload:" and other library names on file path
		path = formatted[formatted.length-1];
		if(FileSystem.exists(path)) daList = File.getContent(path);
		#else
		if(Assets.exists(path)) daList = Assets.getText(path);
		#end
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth) {
			for(row in 0...sprite.frameHeight) {
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel != 0) {
					if(countByColor.exists(colorOfThisPixel))
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687))
						countByColor[colorOfThisPixel] = 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key in countByColor.keys()) {
			if(countByColor[key] >= maxCount) {
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function getArrowRGB(path:String = 'arrowRGB.json', defaultArrowRGB:Array<EKNoteColor>):ArrowRGBSavedData {
		var result:ArrowRGBSavedData;
		var content:String = '';
		#if sys
		if(FileSystem.exists(path)) content = File.getContent(path);
		else {
			// create a default ArrowRGBSavedData
			var colorsToUse = [];
			for (color in defaultArrowRGB) {
				colorsToUse.push(color);
			}

			var defaultSaveARGB:ArrowRGBSavedData = new ArrowRGBSavedData(colorsToUse);

			// write it
			var writer = new json2object.JsonWriter<ArrowRGBSavedData>();
			content = writer.write(defaultSaveARGB, '    ');
			File.saveContent(path, content);

			trace(path + ' (Color save) didn\'t exist. Written.');
		}
		#else
		if(Assets.exists(path)) content = Assets.getText(path);
		#end

		var parser = new json2object.JsonParser<ArrowRGBSavedData>();
		parser.fromJson(content);
		result = parser.value;

		// automatically (?) sets colors of notes that have no colors
		for (i in 0...ExtraKeysHandler.instance.data.maxKeys+1) {
			// colors dont exist
			
			// cannot take the previous approach since 
			// this is indexed and not per mania
			if (result.colors[i] == null) {
				result.colors[i] = defaultArrowRGB[i];
			}
		}

		return result;
	}

	public static function getKeybinds(path:String = 'ekkeybinds.json', defaultKeybinds:Array<Array<Array<Int>>>):EKKeybindSavedData {
		var result:EKKeybindSavedData;
		var content:String = '';
		#if sys
		if(FileSystem.exists(path)) {
			content = File.getContent(path);
			//trace('Keybind file $path $content');
		} 
		else {
			var defaultKeybindSave:EKKeybindSavedData = new EKKeybindSavedData(defaultKeybinds);
			// write it
			var writer = new json2object.JsonWriter<EKKeybindSavedData>();
			content = writer.write(defaultKeybindSave, '  ');
			File.saveContent(path, content);
			trace(path + ' (Keybind save) didn\'t exist. Written.');
		}
		#else
		if(Assets.exists(path)) content = Assets.getText(path);
		#end

		var parser = new json2object.JsonParser<EKKeybindSavedData>();
		parser.fromJson(content);
		result = parser.value;

		// automatically (?) sets keybinds of #keys that have no keybinds
		for (i in 0...ExtraKeysHandler.instance.data.maxKeys+1) {
			// keybinds dont exist, keybinds are not enough
			if (result.keybinds[i] == null || result.keybinds[i].length != (i + 1)) {
				result.keybinds[i] = defaultKeybinds[i];
			}
		}

		return result;
	}
}

class ArrowRGBSavedData {
	public var colors:Array<EKNoteColor>;

	public function new(colors){
		this.colors = colors;
	}
}

class EKKeybindSavedData {
	public var keybinds:Array<Array<Array<Int>>>;

	public function new(keybinds){
		this.keybinds = keybinds;
	}
}