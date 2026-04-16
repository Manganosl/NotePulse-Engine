package funkin.game.shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import hscript.IHScriptCustomBehaviour;
import sys.FileSystem;
import sys.io.File;

class CustomShader extends FunkinShader {
    public static var shaderCache:Map<String, Array<String>> = new Map();
    public var shader:FlxRuntimeShader;

    public function new(shaderName:String) {
        var frag:String = null;
        var vert:String = null;

        if (shaderCache.exists(shaderName)) {
            var data = shaderCache.get(shaderName);
            frag = data[0];
            vert = data[1];
        } 
        else {
            #if (!flash && sys)
            if (ClientPrefs.data.shaders) {
                for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/')) {
                    var fragPath:String = folder + shaderName + '.frag';
                    var vertPath:String = folder + shaderName + '.vert';

                    if (FileSystem.exists(fragPath)) frag = File.getContent(fragPath);
                    if (FileSystem.exists(vertPath)) vert = File.getContent(vertPath);

                    if (frag != null || vert != null) {
                        shaderCache.set(shaderName, [frag, vert]);
                        break;
                    }
                }
            }
            #end
        }

        super(frag, vert);
        this.shader = this;

        if (frag == null && vert == null) {
            #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
            MusicBeatState.getState().addTextToDebug('Missing shader $shaderName .frag AND .vert files!', FlxColor.RED, true, "error");
            #else
            Log.error('Missing shader $shaderName .frag AND .vert files!');
            #end
        }
    }
}