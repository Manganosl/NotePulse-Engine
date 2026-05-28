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

    public function copyValues(tempShader:RGBPalette)
    {
        if (tempShader != null)
        {
            for (i in 0...3)
            {
                shader.r.value[i] = tempShader.shader.r.value[i];
                shader.g.value[i] = tempShader.shader.g.value[i];
                shader.b.value[i] = tempShader.shader.b.value[i];
            }
            shader.mult.value[0]      = tempShader.shader.mult.value[0];
            shader.u_alpha.value[0]   = tempShader.shader.u_alpha.value[0];
            shader.u_flash.value[0]   = tempShader.shader.u_flash.value[0];
            shader.u_enabled.value[0] = tempShader.shader.u_enabled.value[0];

            shader.cosX.value[0]      = tempShader.shader.cosX.value[0];
            shader.cosY.value[0]      = tempShader.shader.cosY.value[0];
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
    
    private function set_enabled(value:Bool):Bool {
        enabled = value;
        shader.u_enabled.value = [value];
        return enabled;
    }

    private function set_angleX(v:Float):Float {
        angleX = v;
        shader.cosX.value = [Math.abs(Math.cos(v))];
        return v;
    }

    private function set_angleY(v:Float):Float {
        angleY = v;
        shader.cosY.value = [Math.abs(Math.cos(v))];
        return v;
    }
    
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
    
    private function set_r(value:FlxColor)      { if (allowNew && value != _original.r)         cloneOriginal(); return (r = parent.r = value); }
    private function set_g(value:FlxColor)      { if (allowNew && value != _original.g)         cloneOriginal(); return (g = parent.g = value); }
    private function set_b(value:FlxColor)      { if (allowNew && value != _original.b)         cloneOriginal(); return (b = parent.b = value); }
    private function set_mult(value:Float)      { if (allowNew && value != _original.mult)      cloneOriginal(); return (mult = parent.mult = value); }
    private function set_alphaMult(value:Float) { if (allowNew && value != _original.alphaMult) cloneOriginal(); return (alphaMult = parent.alphaMult = value); }
    private function set_flash(value:Float)     { if (allowNew && value != _original.flash)     cloneOriginal(); return (flash = parent.flash = value); }
    private function set_enabled(value:Bool)    { if (allowNew && value != _original.enabled)   cloneOriginal(); return (enabled = parent.enabled = value); }
    private function set_angleX(value:Float)    { if (allowNew && value != _original.angleX)    cloneOriginal(); return (angleX = parent.angleX = value); }
    private function set_angleY(value:Float)    { if (allowNew && value != _original.angleY)    cloneOriginal(); return (angleY = parent.angleY = value); }

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
        uniform float cosX;
        uniform float cosY;
        varying vec2 vTexCoord;
    ')
    @:glVertexBody('
        vec4 pos = openfl_Position;
        
        vec2 center = openfl_TextureSize * 0.5;
        
        vec2 centered = pos.xy - center;
        centered.y *= cosX;
        centered.x *= cosY;
        pos.xy = centered + center;

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

        this.r.value       = [1, 0, 0];
        this.g.value       = [0, 1, 0];
        this.b.value       = [0, 0, 1];
        this.mult.value    = [1];
        this.u_alpha.value = [1];
        this.u_flash.value = [0];
        this.u_enabled.value = [true];

        this.cosX.value  = [1.0];
        this.cosY.value  = [1.0];
    }
}
