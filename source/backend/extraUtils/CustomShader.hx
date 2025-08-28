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

    public function addToCamera(camera:Array<FlxCamera>) {
        for(cam in camera){
            if(cam.filters == null) cam.filters = [];
            cam.filters.push(new ShaderFilter(shader));
        }
    }

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