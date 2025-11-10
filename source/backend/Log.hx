package backend;

import haxe.Constraints.Function;
import haxe.PosInfos;
import lime.app.Application;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

using StringTools;

#if PRETTY_TRACE
class Log
{
    // Taken from Cobalt's Horizon Engine; THANK YOU COBALT!!
	// https://gist.github.com/martinwells/5980517
	// https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
	public static var format(default, set):String = '';

	private static var ogTrace:Function;
	private static var logFileOutput:FileOutput;
	private static var preformatted:String = '\033[30;90m[\033[30;33mTIME \033[30;90m| \033[30;32mFILE\033[30;90m] LEVEL \033[0;0mMSG';

	private static var log:Array<String> = [];

	public static function init():Void
	{
		ogTrace = haxe.Log.trace;
		#if PRETTY_TRACE haxe.Log.trace = hxTrace; #end
		format = '[TIME | FILE] LEVEL MSG';
	}

	@:keep public static function ansi(color:Int):String
		return '\033[30;${color}m';

	static function hxTrace(value:Dynamic, ?pos:PosInfos):Void
		print(value, 'TRACE', 105, pos);

	public static function error(value:Dynamic, ?pos:PosInfos):Void
		print(value, 'ERROR', 101, pos);

	public static function warn(value:Dynamic, ?pos:PosInfos):Void
		print(value, 'WARN', 103, pos);
	
	public static function info(value:Dynamic, ?pos:PosInfos):Void
		print(value, 'INFO', 106, pos);

	static public function print(value:Dynamic, ?level:String = 'TRACE', ?color:Int = 201, ?pos:PosInfos):Void
	{
		var msg = preformatted.replace('TIME', DateTools.format(Date.now(), '%H:%M:%S')).replace('FILE', '${pos.fileName}:${pos.lineNumber}');
		msg = msg.replace('LEVEL', '\033[90;48;5;${color}m $level \033[0;0m')
			.replace('MSG', value);
		Sys.println(msg);

		log.push('${format.replace('TIME', DateTools.format(Date.now(), '%H:%M:%S')).replace('FILE', '${pos.fileName}:${pos.lineNumber}').replace('LEVEL', level).replace('MSG', value)}');
	}

	@:keep static public function set_format(val:String):String
	{
		preformatted = val.replace('[', '${ansi(90)}[')
			.replace(']', '${ansi(90)}]')
			.replace('TIME', '${ansi(33)}TIME')
            .replace('|', '${ansi(90)}|')
			.replace('FILE', '${ansi(32)}FILE')
			.replace('MSG', '\033[0;0mMSG');
		return format = val;
	}

	static public function consoleColorToInt(color:LogColor, isBackground:Bool = false):Int {
		return switch(color) {
			case BLACK:
				(isBackground ? 40 : 30);
			case RED:
				(isBackground ? 41 : 31);
			case GREEN:
				(isBackground ? 42 : 32);
			case YELLOW:
				(isBackground ? 43 : 33);
			case BLUE:
				(isBackground ? 44 : 34);
			case MAGENTA:
				(isBackground ? 45 : 35);
			case CYAN:
				(isBackground ? 46 : 36);
			case WHITE:
				(isBackground ? 47 : 37);
			case DEFAULT:
				(isBackground ? 49 : 39);
			case CUSTOM(color):
				color;
			default: //also accounts for RESET
				0;
		}
	}
}

enum LogColor {
	BLACK;
	RED;
	GREEN;
	YELLOW;
	BLUE;
	MAGENTA;
	CYAN;
	WHITE;
	DEFAULT;
	RESET;
	CUSTOM(color:Int);
}
#else
typedef Log = haxe.Log; //TODO: Add support for no Pretty Traces
#end