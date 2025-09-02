package backend.extraUtils;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxCamera;
import openfl.filters.ShaderFilter;

class CustomShader {
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

    // ---- NEW DYNAMIC ACCESS ----
    @:keep
    public function resolve(name:String):Dynamic {
        return getUniform(name);
    }

    @:keep
    public function setField(name:String, value:Dynamic):Dynamic {
        setUniform(name, value);
        return value;
    }

    private function setUniform(name:String, value:Dynamic):Void {
        switch (Type.typeof(value)) {
            case TFloat:
                shader.setFloat(name, value);
            case TInt:
                shader.setInt(name, value);
            case TBool:
                shader.setBool(name, value);
            case TClass(Array):
                if (value.length > 0) {
                    switch (Type.typeof(value[0])) {
                        case TFloat: shader.setFloatArray(name, cast value);
                        case TInt:   shader.setIntArray(name, cast value);
                        case TBool:  shader.setBoolArray(name, cast value);
                        default:
                    }
                }
            default:
                // Assume sampler2D/texture
                shader.setSampler2D(name, value);
        }
    }

    private function getUniform(name:String):Dynamic {
        try return shader.getFloat(name) catch (_) {}
        try return shader.getInt(name) catch (_) {}
        try return shader.getBool(name) catch (_) {}
        try return shader.getFloatArray(name) catch (_) {}
        try return shader.getIntArray(name) catch (_) {}
        try return shader.getBoolArray(name) catch (_) {}
        try return shader.getSampler2D(name) catch (_) {}
        return null;
    }

    // For legacy (or if you are masochistic)

    public function setFloat(name:String, value:Float) {
        shader.setFloat(name, value);
    }

    public function setInt(name:String, value:Int) {
        shader.setInt(name, value);
    }

    public function setBool(name:String, value:Bool) {
        shader.setBool(name, value);
    }

    public function setFloatArray(name:String, values:Array<Float>) {
        shader.setFloatArray(name, values);
    }

    public function setIntArray(name:String, values:Array<Int>) {
        shader.setIntArray(name, values);
    }

    public function setBoolArray(name:String, values:Array<Bool>) {
        shader.setBoolArray(name, values);
    }

    public function setSampler2D(name:String, texture:Dynamic) {
        shader.setSampler2D(name, texture);
    }

    public function getFloat(name:String) {
        return shader.getFloat(name);
    }

    public function getInt(name:String) {
        return shader.getInt(name);
    }

    public function getBool(name:String) {
        return shader.getBool(name);
    }

    public function getFloatArray(name:String) {
        return shader.getFloatArray(name);
    }

    public function getIntArray(name:String) {
        return shader.getIntArray(name);
    }

    public function getBoolArray(name:String) {
        return shader.getBoolArray(name);
    }

    public function getSampler2D(name:String) {
        return shader.getSampler2D(name);
    }
}