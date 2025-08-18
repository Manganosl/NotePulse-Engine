package debug;

import debug.native.HiddenProcess;
import debug.RegistryUtil;
#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

using StringTools;

class SystemInfo extends FramerateCategory {
	public static var osInfo:String = "Unknown";
	public static var gpuName:String = "Unknown";
	public static var vRAM:String = "Unknown";
	public static var cpuName:String = "Unknown";
	public static var totalMem:String = "Unknown";
	public static var memType:String = "Unknown";
	public static var gpuMaxSize:String = "Unknown";

	static var __formattedSysText:String = "";

	public static inline function init() {
		#if linux
		var process = new HiddenProcess("cat", ["/etc/os-release"]);
		if (process.exitCode() != 0) trace('Unable to grab OS Label');
		else {
			var osName = "";
			var osVersion = "";
			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.startsWith("PRETTY_NAME=")) {
					var index = line.indexOf('"');
					if (index != -1)
						osName = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osName = arr.join("=");
					}
				}
				if (line.startsWith("VERSION=")) {
					var index = line.indexOf('"');
					if (index != -1)
						osVersion = line.substring(index + 1, line.lastIndexOf('"'));
					else {
						var arr = line.split("=");
						arr.shift();
						osVersion = arr.join("=");
					}
				}
			}
			if (osName != "")
				osInfo = '${osName} ${osVersion}'.trim();
		}
		#elseif windows
		var windowsCurrentVersionPath = "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion";
		var buildNumber = Std.parseInt(RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "CurrentBuildNumber"));
		var edition = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, "ProductName");

		var lcuKey = "WinREVersion"; // Last Cumulative Update Key On Older Windows Versions
		if (buildNumber >= 22000) { // Windows 11 Initial Release Build Number
			edition = edition.replace("Windows 10", "Windows 11");
			lcuKey = "LCUVer"; // Last Cumulative Update Key On Windows 11
		}

		var lcuVersion = RegistryUtil.get(HKEY_LOCAL_MACHINE, windowsCurrentVersionPath, lcuKey);

		osInfo = edition;

		if (lcuVersion != null && lcuVersion != "")
			osInfo += ' ${lcuVersion}';
		else if (lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo += ' ${lime.system.System.platformVersion}';
		#else
		if (lime.system.System.platformLabel != null && lime.system.System.platformLabel != "" && lime.system.System.platformVersion != null && lime.system.System.platformVersion != "")
			osInfo = '${lime.system.System.platformLabel.replace(lime.system.System.platformVersion, "").trim()} ${lime.system.System.platformVersion}';
		else
			trace('Unable to grab OS Label');
		#end

		try {
			#if windows
			cpuName = RegistryUtil.get(HKEY_LOCAL_MACHINE, "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", "ProcessorNameString");
			#elseif mac
			var process = new HiddenProcess("sysctl -a | grep brand_string"); // Somehow this isnt able to use the args but it still works
			if (process.exitCode() != 0) throw 'Could not fetch CPU information';

			cpuName = process.stdout.readAll().toString().trim().split(":")[1].trim();
			#elseif linux
			var process = new HiddenProcess("cat", ["/proc/cpuinfo"]);
			if (process.exitCode() != 0) throw 'Could not fetch CPU information';

			for (line in process.stdout.readAll().toString().split("\n")) {
				if (line.indexOf("model name") == 0) {
					cpuName = line.substring(line.indexOf(":") + 2);
					break;
				}
			}
			#end
		} catch (e) {
			trace('Unable to grab CPU Name: $e');
		}

		@:privateAccess {
			if (flixel.FlxG.stage.context3D != null && flixel.FlxG.stage.context3D.gl != null) {
				gpuName = Std.string(flixel.FlxG.stage.context3D.gl.getParameter(flixel.FlxG.stage.context3D.gl.RENDERER)).split("/")[0].trim();
				#if !flash
				var size = FlxG.bitmap.maxTextureSize;
				gpuMaxSize = size+"x"+size;
				#end

				if(openfl.display3D.Context3D.__glMemoryTotalAvailable != -1) {
					var vRAMBytes:UInt = cast(flixel.FlxG.stage.context3D.gl.getParameter(openfl.display3D.Context3D.__glMemoryTotalAvailable), UInt);
					if (vRAMBytes == 1000 || vRAMBytes == 1 || vRAMBytes <= 0)
						trace('Unable to grab GPU VRAM');
					else
						vRAM = CoolUtil.getSizeString(vRAMBytes * 1000);
				}
			} else
				trace('Unable to grab GPU Info');
		}

		#if cpp
		totalMem = Std.string(Math.round(getTotalMem() / 1073741824)) + " GB";
		#else
		trace('Unable to grab RAM Amount');
		#end

		try {
			memType = getMemType();
		} catch (e) {
			trace('Unable to grab RAM Type: $e');
		}
		formatSysInfo();
	}

	static function formatSysInfo() {
		__formattedSysText = "";
		if (osInfo != "Unknown") __formattedSysText += 'System: $osInfo';
		if (cpuName != "Unknown") __formattedSysText += '\nCPU: $cpuName ${openfl.system.Capabilities.cpuArchitecture} ${(openfl.system.Capabilities.supports64BitProcesses ? '64-Bit' : '32-Bit')}';
		if (gpuName != cpuName || vRAM != "Unknown") {
			var gpuNameKnown = gpuName != "Unknown" && gpuName != cpuName;
			var vramKnown = vRAM != "Unknown";

			if(gpuNameKnown || vramKnown) __formattedSysText += "\n";

			if(gpuNameKnown) __formattedSysText += 'GPU: $gpuName';
			if(gpuNameKnown && vramKnown) __formattedSysText += " | ";
			if(vramKnown) __formattedSysText += 'VRAM: $vRAM'; // 1000 bytes of vram (apus)
		}
		//if (gpuMaxSize != "Unknown") __formattedSysText += '\nMax Bitmap Size: $gpuMaxSize';
		if (totalMem != "Unknown" && memType != "Unknown") __formattedSysText += '\nTotal MEM: $totalMem $memType';
	}

	public function new() {
		super("System Info");
	}

	public override function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;

		_text = __formattedSysText;
		_text += '${__formattedSysText == "" ? "" : "\n"}Garbage Collector: ${disableCount > 0 ? "OFF" : "ON"} (${disableCount})';

		this.text.text = _text;
		super.__enterFrame(t);
	}

	public static function getTotalMem():Float {
        var process = new Process("wmic", ["ComputerSystem", "get", "TotalPhysicalMemory"]);
        var output = process.stdout.readAll().toString();
        process.close();

        var lines = output.split("\n").map(StringTools.trim).filter(function(line) return line != "" && !line.startsWith("TotalPhysicalMemory"));
        if (lines.length > 0) {
            var bytes = Std.parseFloat(lines[0]);
            return bytes;
        }
        return -1;
    }

	public static function getMemType():String {
		#if windows
		var memoryMap:Map<Int, String> = [
			0 => null,
			1 => "Other",
			2 => "DRAM",
			3 => "Synchronous DRAM",
			4 => "Cache DRAM",
			5 => "EDO",
			6 => "EDRAM",
			7 => "VRAM",
			8 => "SRAM",
			9 => "RAM",
			10 => "ROM",
			11 => "Flash",
			12 => "EEPROM",
			13 => "FEPROM",
			14 => "EPROM",
			15 => "CDRAM",
			16 => "3DRAM",
			17 => "SDRAM",
			18 => "SGRAM",
			19 => "RDRAM",
			20 => "DDR",
			21 => "DDR2",
			22 => "DDR2 FB-DIMM",
			24 => "DDR3",
			25 => "FBD2",
			26 => "DDR4",
			27 => "LPDDR",
			28 => "LPDDR2",
			29 => "LPDDR3",
			30 => "LPDDR4",
			31 => "Logical Non-volatile device",
			32 => "HBM",
			33 => "HBM2",
			34 => "DDR5",
			35 => "LPDDR5",
			36 => "HBM3",
		];
		var memoryOutput:Int = -1;

		var process = new HiddenProcess("powershell", ["-Command", "Get-CimInstance Win32_PhysicalMemory | Select-Object -ExpandProperty SMBIOSMemoryType" ]);
		if (process.exitCode() == 0) memoryOutput = Std.int(Std.parseFloat(process.stdout.readAll().toString().trim().split("\n")[1]));
		if (memoryOutput != -1) return memoryMap[memoryOutput] == null ? 'Unknown ($memoryOutput)' : memoryMap[memoryOutput];
		#elseif mac
		var process = new HiddenProcess("system_profiler", ["SPMemoryDataType"]);
		var reg = ~/Type: (.+)/;
		reg.match(process.stdout.readAll().toString());
		if (process.exitCode() == 0) return reg.matched(1);
		#elseif linux
		/*var process = new HiddenProcess("sudo", ["dmidecode", "--type", "17"]);
		if (process.exitCode() != 0) return "Unknown";
		var lines = process.stdout.readAll().toString().split("\n");
		for (line in lines) {
			if (line.indexOf("Type:") == 0) {
				return line.substring("Type:".length).trim();
			}
		}*/
		// TODO: sort of unsafe? also requires users to use `sudo`
		// when launching the engine through the CLI, REIMPLEMENT LATER. 
		#end
		return "Unknown";
	}

	public static var disableCount:Int = 0;

	public static function askDisable() {
		disableCount++;
		if (disableCount > 0)
			disable();
		else
			enable();
	}
	public static function askEnable() {
		disableCount--;
		if (disableCount > 0)
			disable();
		else
			enable();
	}
	public static function enable() {
		#if (cpp || hl)
		Gc.enable(true);
		#end
	}

	public static function disable() {
		#if (cpp || hl)
		Gc.enable(false);
		#end
	}
}