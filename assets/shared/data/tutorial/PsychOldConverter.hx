import backend.Difficulty;
import tjson.TJSON;

function onCreate() {
    // Remove the "//" on the convertToOld lines to use it

    // Converting json, path starts in mods
    //convertToOld('tenkaichi-battleworld');

    // Converting current song and difficulty
     convertToOld('data/'+game.songName+'/'+game.songName+Difficulty.getFilePath());

    // Converting events.json on current song
    // Must be named events.json to be able to convert it as event
    // Alternatively, you can set the second argument to true,
    // which will force it to convert as event regardless of the name
    //convertToOld('data/'+game.songName+'/events');
    return;
}

function convertToOld(path:String, ?convertAsEvent, ?printMessage:Bool) {
    if (!StringTools.endsWith(path, '.json')) path += '.json';
    if (StringTools.endsWith(path, 'events.json')) convertAsEvent = true;
    else if (convertAsEvent == null) convertAsEvent = false;
    printMessage ??= true;
    try {
        var _song:Dynamic = TJSON.parse(File.getContent(Paths.modFolders(path)));

        if (!convertAsEvent) {
            for (section in _song.notes) {
                if (section.sectionNotes != null && section.sectionNotes.length != 0) {
                    for (notes in section.sectionNotes) {
                        if (!section.mustHitSection) {
                            if (notes[1] > 3) {
                                notes[1] = notes[1] % 4;
                            }
                            else {
                                notes[1] += 4;
                            }
                        }
                    }
                }
            }
        }

        if (_song.format == null || _song.format != 'psych_legacy_convert') _song.format = 'psych_legacy_convert';
        _song = {song: _song};

        var saveToFolder = 'converted_charts/';
        var savePath = saveToFolder+path.substring(path.lastIndexOf('/')+1);
        if (!FileSystem.exists(saveToFolder) || !FileSystem.isDirectory(saveToFolder)) FileSystem.createDirectory(saveToFolder);
        _song = TJSON.encode(_song, 'fancy');
        File.saveContent(savePath, _song);
        if (printMessage) debugPrint('File '+(FileSystem.exists(savePath) ? 'overwritten' : 'saved')+' at '+savePath, FlxColor.LIME);
    }
    catch(e:Dynamic) {
        var msg = e.toString();
        if (StringTools.startsWith(e.toString(), '[file_contents')) msg = 'Missing file: '+e.toString().substring(15, e.toString().length-1);
        debugPrint('Error converting chart: '+msg, FlxColor.RED);
    }
}
