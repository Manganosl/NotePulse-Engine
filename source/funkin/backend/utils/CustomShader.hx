package funkin.backend.utils;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import hscript.IHScriptCustomBehaviour;
import sys.FileSystem;
import sys.io.File;

class CustomShader extends FlxRuntimeShader implements IHScriptCustomBehaviour {
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

    public function addToCameras(cameras:Array<FlxCamera>) {
        for (cam in cameras) addToCamera(cam);
    }

    public function addToCamera(cam:FlxCamera) {
        if (cam.filters == null) cam.filters = [];
        cam.filters.push(new ShaderFilter(this));
    }

    public function removeFromCameras(cameras:Array<FlxCamera>) {
        for (cam in cameras) removeFromCamera(cam);
    }

    public function removeFromCamera(cam:FlxCamera) {
        if (cam.filters != null) {
            cam.filters = [for (f in cam.filters) if (!(f is ShaderFilter && cast(f, ShaderFilter).shader == this)) f];
            if (cam.filters.length == 0) cam.filters = null;
        }
    }

    public function setUniform(name:String, value:Dynamic):Void {
        if (value is FlxGraphic) {
            setSampler2D(name, cast(value, FlxGraphic).bitmap);
            return;
        } else if (value is BitmapData) {
            setSampler2D(name, value);
            return;
        }
    
        switch (Type.typeof(value)) {
            case TFloat: setFloat(name, value);
            case TInt:
                try setInt(name, value) catch (_:Dynamic){}
                try setFloat(name, value) catch (_:Dynamic){}
            case TBool: setBool(name, value);
            case TClass(Array):
                var arr:Array<Dynamic> = cast value;
                if (arr == null || arr.length == 0) return;
                var t = Type.typeof(arr[0]);
                switch (t) {
                    case TFloat: setFloatArray(name, cast arr);
                    case TInt:
                        var fa:Array<Float> = [for (x in arr) (x:Float)];
                        var ia:Array<Int>   = [for (x in arr) (x:Int)];
                        try setIntArray(name, ia) catch (_:Dynamic){}
                        try setFloatArray(name, fa) catch (_:Dynamic){}
                    case TBool: setBoolArray(name, cast arr);
                    default:
                        var fa:Array<Float> = [for (x in arr) Std.parseFloat(Std.string(x))];
                        setFloatArray(name, fa);
                }
            default: setSampler2D(name, value);
        }
    }

    public function getUniform(name:String):Dynamic {
        var v:Dynamic;
        if ((v = getFloat(name)) != null) return v;
        if ((v = getInt(name)) != null) return v;
        if ((v = getBool(name)) != null) return v;
        if ((v = getFloatArray(name)) != null) return v;
        if ((v = getIntArray(name)) != null) return v;
        if ((v = getBoolArray(name)) != null) return v;
        if ((v = getSampler2D(name)) != null) return v;
        return 0;
    }

    public function hget(name:String):Dynamic {
        var fields = Type.getInstanceFields(Type.getClass(this));
        if (fields != null && (fields.indexOf(name) != -1 || fields.indexOf('get_${name}') != -1)) {
            return Reflect.getProperty(this, name);
        }
        return getUniform(name);
    }

    public function hset(name:String, val:Dynamic):Dynamic {
        var fields = Type.getInstanceFields(Type.getClass(this));
        if (fields != null && (fields.indexOf(name) != -1 || fields.indexOf('set_${name}') != -1)) {
            Reflect.setProperty(this, name, val);
            return val;
        }
        setUniform(name, val);
        return val;
    }
}