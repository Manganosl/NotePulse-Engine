package backend.extraUtils;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import tea.backend.SScriptCustomBehavior;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;

class CustomShader implements SScriptCustomBehavior {
    public var shader:FlxRuntimeShader;

    public function new(shaderName:String) {
        PlayState.instance.initLuaShader(shaderName);
        shader = PlayState.instance.createRuntimeShader(shaderName);
    }

    public function addToCameras(cameras:Array<FlxCamera>) {
        for (cam in cameras) addToCamera(cam);
    }

    public function addToCamera(cam:FlxCamera) {
        if (cam.filters == null) cam.filters = [];
        cam.filters.push(new ShaderFilter(shader));
    }

    public function removeFromCameras(cameras:Array<FlxCamera>) {
        for (cam in cameras) removeFromCamera(cam);
    }

    public function removeFromCamera(cam:FlxCamera) {
        if (cam.filters != null) {
            cam.filters = [for (f in cam.filters) if (!(f is ShaderFilter && cast(f, ShaderFilter).shader == shader)) f];
            if (cam.filters.length == 0) cam.filters = null;
        }
    }

    public function customSet(o:Dynamic, f:String, v:Dynamic):Dynamic return hset(f, v);
    public function customGet(o:Dynamic, f:String):Dynamic return hget(f);

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

    private inline function isNumber(x:Dynamic):Bool {
        return x is Float || x is Int;
    }

    private function setUniform(name:String, value:Dynamic):Void {
        if (value is FlxGraphic) {
            shader.setSampler2D(name, cast(value, FlxGraphic).bitmap);
            return;
        } else if (value is BitmapData) {
            shader.setSampler2D(name, value);
            return;
        }
    
        switch (Type.typeof(value)) {
            case TFloat:
                shader.setFloat(name, value);
        
            case TInt:
                try shader.setInt(name, value) catch (_:Dynamic) {}
                try shader.setFloat(name, value) catch (_:Dynamic) {}

            case TBool:
                shader.setBool(name, value);
        
            case TClass(Array):
                var arr:Array<Dynamic> = cast value;
                if (arr == null || arr.length == 0) return;
                var t = Type.typeof(arr[0]);
                switch (t) {
                    case TFloat:
                        shader.setFloatArray(name, cast arr);
                    case TInt:
                        var fa:Array<Float> = [for (x in arr) (x:Float)];
                        var ia:Array<Int>   = [for (x in arr) (x:Int)];
                        try shader.setIntArray(name, ia) catch (_:Dynamic) {}
                        try shader.setFloatArray(name, fa) catch (_:Dynamic) {}
                    case TBool:
                        shader.setBoolArray(name, cast arr);
                    default:
                        var fa:Array<Float> = [for (x in arr) Std.parseFloat(Std.string(x))];
                        shader.setFloatArray(name, fa);
                }

            default:
                shader.setSampler2D(name, value);
        }
    }

    private function getUniform(name:String):Dynamic {
        try return shader.getFloat(name) catch (_:Dynamic) {}
        try return shader.getInt(name) catch (_:Dynamic) {}
        try return shader.getBool(name) catch (_:Dynamic) {}
        try return shader.getFloatArray(name) catch (_:Dynamic) {}
        try return shader.getIntArray(name) catch (_:Dynamic) {}
        try return shader.getBoolArray(name) catch (_:Dynamic) {}
        try return shader.getSampler2D(name) catch (_:Dynamic) {}
        return 0;  // 0 to prevent errors
    }

    // In case something goes wrong!
    public function setFloat(name:String, value:Float) shader.setFloat(name, value);
    public function setInt(name:String, value:Int) shader.setInt(name, value);
    public function setBool(name:String, value:Bool) shader.setBool(name, value);
    public function setFloatArray(name:String, values:Array<Float>) shader.setFloatArray(name, values);
    public function setIntArray(name:String, values:Array<Int>) shader.setIntArray(name, values);
    public function setBoolArray(name:String, values:Array<Bool>) shader.setBoolArray(name, values);
    public function setSampler2D(name:String, texture:Dynamic) shader.setSampler2D(name, texture);

    public function getFloat(name:String) return shader.getFloat(name);
    public function getInt(name:String) return shader.getInt(name);
    public function getBool(name:String) return shader.getBool(name);
    public function getFloatArray(name:String) return shader.getFloatArray(name);
    public function getIntArray(name:String) return shader.getIntArray(name);
    public function getBoolArray(name:String) return shader.getBoolArray(name);
    public function getSampler2D(name:String) return shader.getSampler2D(name);
}
