package funkin.game.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.FlxSprite;

class RGBPalette
{
    public var shader(default, null):RGBPaletteShader = new RGBPaletteShader();
    public var r(default, set):FlxColor;
    public var g(default, set):FlxColor;
    public var b(default, set):FlxColor;
    
    public var alphaMult(default, set):Float;
    public var flash(default, set):Float;
    public var enabled(default, set):Bool;
    public var mult(default, set):Float;

    public var angleX(default, set):Float;
    public var angleY(default, set):Float;

	public var centerOffsetX(default, set):Float;
	public var centerOffsetY(default, set):Float;
	public var centerOffsetZ(default, set):Float;

    public function copyValues(tempShader:RGBPalette)
    {
        if (tempShader != null)
        {
            for (i in 0...3)
            {
                shader.r.value[i] = tempShader.shader.r.value[i];
                shader.g.value[i] = tempShader.shader.g.value[i];
                shader.b.value[i] = tempShader.shader.b.value[i];
                shader.centerOffset.value[i] = tempShader.shader.centerOffset.value[i];
            }
            shader.mult.value[0] = tempShader.shader.mult.value[0];
            shader.u_alpha.value[0] = tempShader.shader.u_alpha.value[0];
            shader.u_flash.value[0] = tempShader.shader.u_flash.value[0];
            shader.u_enabled.value[0] = tempShader.shader.u_enabled.value[0];
            shader.angleX.value[0] = tempShader.shader.angleX.value[0];
            shader.angleY.value[0] = tempShader.shader.angleY.value[0];
            shader.centerOffset.value[0] = tempShader.shader.centerOffset.value[0];
            shader.centerOffset.value[1] = tempShader.shader.centerOffset.value[1];
            shader.centerOffset.value[2] = tempShader.shader.centerOffset.value[2];
        }
        else shader.mult.value[0] = 0.0;
    }
    
    private function set_r(color:FlxColor) {
        r = color;
        shader.r.value = [color.redFloat, color.greenFloat, color.blueFloat];
        return color;
    }
    
    private function set_g(color:FlxColor) {
        g = color;
        shader.g.value = [color.redFloat, color.greenFloat, color.blueFloat];
        return color;
    }
    
    private function set_b(color:FlxColor) {
        b = color;
        shader.b.value = [color.redFloat, color.greenFloat, color.blueFloat];
        return color;
    }
    
    private function set_mult(value:Float) {
        mult = FlxMath.bound(value, 0, 1);
        shader.mult.value = [mult];
        return mult;
    }
    
    private function set_flash(value:Float):Float {
        flash = value;
        shader.u_flash.value = [value];
        return flash;
    }
    
    private function set_alphaMult(value:Float):Float {
        alphaMult = value;
        shader.u_alpha.value = [value];
        return alphaMult;
    }

    private function set_centerOffsetX(value:Float):Float {
        centerOffsetX = value;
        shader.centerOffset.value[0] = value;
        return centerOffsetX;
    }

    private function set_centerOffsetY(value:Float):Float {
        centerOffsetY = value;
        shader.centerOffset.value[1] = value;
        return centerOffsetY;
    }

    private function set_centerOffsetZ(value:Float):Float {
        centerOffsetZ = value;
        shader.centerOffset.value[2] = value;
        return centerOffsetZ;
    }
    
    function set_enabled(value:Bool):Bool {
        enabled = value;
        shader.u_enabled.value = [value];
        return enabled;
    }

    private function set_angleX(v:Float) { angleX = v; shader.angleX.value = [v]; return v; }
    private function set_angleY(v:Float) { angleY = v; shader.angleY.value = [v]; return v; }
    
    public function setColors(colors:Array<FlxColor>) {
        while (colors.length < 3) colors.push(FlxColor.WHITE);
        r = colors[0]; g = colors[1]; b = colors[2];
    }
    
    public function new() {
        r = 0xFFFF0000; g = 0xFF00FF00; b = 0xFF0000FF;
        mult = 1.0; flash = 0.0; alphaMult = 1.0; enabled = true;
        angleX = 0; angleY = 0;
    }
}

class RGBShaderReference
{
    public var r(default, set):FlxColor;
    public var g(default, set):FlxColor;
    public var b(default, set):FlxColor;
    public var colorArray:Array<FlxColor> = [];
    
    public var mult(default, set):Float;
    public var alphaMult(default, set):Float;
    public var flash(default, set):Float;
    public var enabled(default, set):Bool = true;

    public var angleX(default, set):Float;
    public var angleY(default, set):Float;

	public var centerOffsetX(default, set):Float;
	public var centerOffsetY(default, set):Float;
	public var centerOffsetZ(default, set):Float;
    
    public var shader:FlxShader;
    public var parent:RGBPalette;
    
    private var _owner:FlxSprite;
    private var _original:RGBPalette;
    public var allowNew = true;

    public function new(owner:FlxSprite, ref:RGBPalette) {
        parent = ref;
        _owner = owner;
        _original = ref;
        shader = ref.shader;
        owner.shader = ref.shader;
        
        @:bypassAccessor {
            r = parent.r; g = parent.g; b = parent.b;
            mult = parent.mult; alphaMult = parent.alphaMult;
            flash = parent.flash; enabled = parent.enabled;
            angleX = parent.angleX; angleY = parent.angleY;
        }
    }
    
    private function set_r(value:FlxColor) { if (allowNew && value != _original.r) cloneOriginal(); return (r = parent.r = value); }
    private function set_g(value:FlxColor) { if (allowNew && value != _original.g) cloneOriginal(); return (g = parent.g = value); }
    private function set_b(value:FlxColor) { if (allowNew && value != _original.b) cloneOriginal(); return (b = parent.b = value); }
    private function set_mult(value:Float) { if (allowNew && value != _original.mult) cloneOriginal(); return (mult = parent.mult = value); }
    private function set_alphaMult(value:Float) { if (allowNew && value != _original.alphaMult) cloneOriginal(); return (alphaMult = parent.alphaMult = value); }
    private function set_flash(value:Float) { if (allowNew && value != _original.flash) cloneOriginal(); return (flash = parent.flash = value); }
    private function set_enabled(value:Bool) { if (allowNew && value != _original.enabled) cloneOriginal(); return (enabled = parent.enabled = value); }
    private function set_angleX(value:Float) { if (allowNew && value != _original.angleX) cloneOriginal(); return (angleX = parent.angleX = value); }
    private function set_angleY(value:Float) { if (allowNew && value != _original.angleY) cloneOriginal(); return (angleY = parent.angleY = value); }
    private function set_centerOffsetX(value:Float) { if (allowNew && value != _original.centerOffsetX) cloneOriginal(); return (centerOffsetX = parent.centerOffsetX = value); }
    private function set_centerOffsetY(value:Float) { if (allowNew && value != _original.centerOffsetY) cloneOriginal(); return (centerOffsetY = parent.centerOffsetY = value); }
    private function set_centerOffsetZ(value:Float) { if (allowNew && value != _original.centerOffsetZ) cloneOriginal(); return (centerOffsetZ = parent.centerOffsetZ = value); }

    public function setColors(colors:Array<FlxColor>) {
        r = colors[0]; g = colors[1]; b = colors[2];
        colorArray = colors;
    }
    
    private function cloneOriginal() {
        if (allowNew) {
            allowNew = false;
            if (_original != parent) return;
            parent = new RGBPalette();
            parent.copyValues(_original);
            _owner.shader = parent.shader;
        }
    }
}

class RGBPaletteShader extends FlxShader
{
    @:glVertexHeader('
        #pragma header

        uniform float angleX;
        uniform float angleY;
        uniform vec3 centerOffset;

        varying vec2 vTexCoord;
    ')
    @:glVertexBody('
        vec4 pos = openfl_Position;

        float cosX = cos(angleX);
        float cosY = cos(angleY);

        mat2 rotX = mat2(
            1.0, 0.0,
            0.0, cosX
        );

        mat2 rotY = mat2(
            cosY, 0.0,
            0.0, 1.0
        );

        vec2 centered = pos.xy - centerOffset.xy;
        centered = rotY * rotX * centered;
        pos.xy = centered + centerOffset.xy;

        gl_Position = openfl_Matrix * pos;
        vTexCoord = openfl_TextureCoordv;
    ')
    @:glFragmentHeader('
        #pragma header
        
        varying vec2 vTexCoord;

        uniform vec3 r;
        uniform vec3 g;
        uniform vec3 b;
        uniform float mult;
        uniform float u_alpha;
        uniform float u_flash;
        uniform bool u_enabled;

        vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) 
        {
            vec4 color = flixel_texture2D(bitmap, coord);
            if (!u_enabled || color.a == 0.0 || mult == 0.0) return color;

            vec4 newColor = color;
            newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
            newColor.a = color.a;
            
            color = mix(color, newColor, mult);
            
            if(color.a > 0.0) return vec4(color.rgb, color.a);
            return vec4(0.0, 0.0, 0.0, 0.0);
        }
    ')
    @:glFragmentSource('
        #pragma header

        void main() 
        {
            vec4 texOutput = flixel_texture2DCustom(bitmap, vTexCoord);

            if (u_flash != 0.0)
                texOutput = mix(texOutput, vec4(1.0, 1.0, 1.0, 1.0), u_flash) * texOutput.a;

            texOutput *= u_alpha;
            gl_FragColor = texOutput;
        }
    ')
	
    public function new()
    {
        super();

        this.r.value = [1, 0, 0];
        this.g.value = [0, 1, 0];
        this.b.value = [0, 0, 1];
        this.mult.value = [1];
        this.u_alpha.value = [1];
        this.u_flash.value = [0];
        this.u_enabled.value = [true];

        this.angleX.value = [0];
        this.angleY.value = [0];
        this.centerOffset.value = [0, 0, 0];
    }
}