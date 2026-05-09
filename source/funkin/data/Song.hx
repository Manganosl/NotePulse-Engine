package funkin.data;

import tjson.TJSON as Json;
import lime.utils.Assets;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import funkin.data.Section;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	@:optional var lanes:Int;

	@:optional var holdSubdivisions:Int;
	@:optional var playfields:Int;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	
	@:optional var disableNoteRGB:Bool;

	@:optional var pixel4kTexture:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
	@:optional var mania:Int;
	@:optional var gfStrums:Bool;
	@:optional var format:String;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public static var convertedChart:Bool;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	private static function onLoadJson(songJson:Dynamic){
        convertedChart = false;
        if(songJson.format == null)
            throw new haxe.Exception('No chart format found!');

        Log.info('Loaded ${songJson.format} Song!');

        if(songJson.gfVersion == null)
        {
            songJson.gfVersion = songJson.player3;
            songJson.player3 = null;
        }

        if(StringTools.startsWith(songJson.format, 'psych_v1')) {
            convertedChart = true;
            songJson.format = 'psych_v1';

            var characters:Array<String> = [songJson.player1, songJson.player2, songJson.gfVersion];
            for (i in 0...characters.length)
            {
                switch(characters[i])
                {
                    case 'pico-playable':
                        characters[i] = 'pico-player';

                    case 'tankman-playable':
                        characters[i] = 'tankman-player';
                }
            }

            songJson.player1 = characters[0];
            songJson.player2 = characters[1];
            songJson.gfVersion = characters[2];
        }

        if(songJson.events == null && songJson.format == 'psych_legacy')
        {
            songJson.events = [];
            for (secNum in 0...songJson.notes.length)
            {
                var sec:SwagSection = songJson.notes[secNum];

                var i:Int = 0;
                var notes:Array<Dynamic> = sec.sectionNotes;
                var len:Int = notes.length;
                while(i < len) {
                    var note:Array<Dynamic> = notes[i];
                    if(note[1] < 0) {
                        songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
                        notes.remove(note);
                        len = notes.length;
                        continue;
                    }
                    i++;
                }
            }
        }

        if (songJson.mania == null){
            songJson.mania = 3;
        }

        var keyCount:Int = songJson.mania + 1;

        if (songJson.lanes == null){
            if(songJson.gfStrums != null && songJson.gfStrums == true)
                songJson.lanes = 3;
            else
                songJson.lanes = 2;
        }

        if (songJson.playfields == null){
            songJson.playfields = 1;
        }
    
        if (songJson.pixel4kTexture == null){
            if(songJson.mania == 3) songJson.pixel4kTexture = false;
            else songJson.pixel4kTexture = true;
        }

        if (songJson.holdSubdivisions == null){
            songJson.holdSubdivisions = 4;
        }

        if (convertedChart && Std.is(songJson.notes, Array)) {
            var sections:Array<Dynamic> = cast songJson.notes;

            for (section in sections) {
                if (
                    section == null ||
                    !Reflect.hasField(section, "sectionNotes") ||
                    !Reflect.hasField(section, "mustHitSection")
                ) continue;
                
                if (!section.mustHitSection) {
                    var notes:Array<Dynamic> = cast section.sectionNotes;
                
                    for (note in notes) {
                        if (note == null || note.length <= 1) continue;
                    
                        var col:Int = Std.parseInt('' + note[1]);
                        if (Math.isNaN(col)) continue;
                    
                        if (col >= 0 && col < keyCount) {
                            note[1] = col + keyCount;
                        } else if (col >= keyCount && col < keyCount * 2) {
                            note[1] = col - keyCount;
                        }
                    }
                }
            }
        }

        if (songJson.notes != null) {
            var sections:Array<Dynamic> = cast songJson.notes;
            for (section in sections) {
                if (section == null || section.sectionNotes == null) continue;

                var notes:Array<Dynamic> = cast section.sectionNotes;
                var mustHit:Bool = section.mustHitSection;

                for (note in notes) {
                    if (note == null || note.length < 2) continue;
                    if (!Std.isOfType(note[4], Int)) {
                        if (note[4] == true) {
                            note[4] = 2;
                        } else {
                            var col:Int = Std.parseInt('' + note[1]);
                            var isPlayerNote:Bool = (col < keyCount) ? mustHit : !mustHit;

                            note[4] = isPlayerNote ? 1 : 0;
                        }
                    }
                }
            }
        }
    }

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadRawSong(jsonInput:String, ?folder:String):String {
		var rawJson = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if MODS_ALLOWED
		var moddyFile:String = Paths.modsJson(formattedFolder + '/' + formattedSong);
		if (FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if (rawJson == null) {
			#if sys
			if (FileSystem.exists(Paths.json(formattedFolder + '/' + formattedSong)))
				rawJson = File.getContent(Paths.json(formattedFolder + '/' + formattedSong));
			#else
			rawJson = Assets.getText(Paths.json(formattedFolder + '/' + formattedSong));
			#end

			if (rawJson == null) {
				throw new haxe.Exception("Missing file: " + Paths.json(formattedFolder + '/' + formattedSong));
			}

			rawJson = rawJson.trim();
		}

		while (!rawJson.endsWith("}")) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		return rawJson;
	}

	public static var loadedSongName:String;
	public static var chartPath:String;
	public static function loadFromJson(jsonInput:String, ?folder:String, ?isSong:Bool = true):SwagSong
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		if(isSong) chartPath = Paths.json('$formattedFolder/$formattedSong');
		loadedSongName = folder;
		return parseRawJSON(jsonInput, loadRawSong(jsonInput, folder));
	}

	public static function parseRawJSON(jsonInput:String, rawSONG:String) {
		var songJson:Dynamic = parseJSONshit(rawSONG);
		if(!jsonInput.startsWith('events')) StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var parsed:Dynamic = Json.parse(rawJson);
		
		if (parsed.song != null) {
			if (Std.isOfType(parsed.song, String)) {
				parsed.format ??= 'psych_v1';
				return parsed;
			}
			
			parsed.song.format = 'psych_legacy';
			return parsed.song;
		}
		
		if (parsed.events != null) {
			return {
				events: cast parsed.events,
				song: "",
				notes: [],
				bpm: 0,
				needsVoices: true,
				speed: 1,
				player1: "",
				player2: "",
				gfVersion: "",
				stage: "",
				format: 'psych_v1'
			};
		}

		throw new haxe.Exception("No song data found, or is invalid.");
	}
}
