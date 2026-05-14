package funkin.game.shaders;

import flixel.addons.display.FlxRuntimeShader;
import flixel.FlxCamera;
import openfl.filters.ShaderFilter;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import hscript.IHScriptCustomBehaviour;
import sys.FileSystem;
import sys.io.File;
import lime.graphics.opengl.GLProgram;

class FunkinRuntimeShader extends FlxRuntimeShader implements IHScriptCustomBehaviour {
	override function __createGLProgram(vert:String, frag:String):GLProgram {
		try {
            return super.__createGLProgram(vert, frag);
		} catch(error){
			Log.error('Shader Crash!');
			@:privateAccess return super.__createGLProgram(vert, FunkinShader._templateFrag);
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

class FunkinShader extends flixel.graphics.tile.FlxGraphicsShader {
	override function __createGLProgram(vertexSource:String, fragmentSource:String):GLProgram {
		try {
            return super.__createGLProgram(vertexSource, fragmentSource);
		} catch(error){
			Log.error('Shader Crash!');
			return super.__createGLProgram(vertexSource, _templateFrag);
		}
	}
	
	static final _templateFrag:String = "
		void main() 
        {
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
		}
    ";
}