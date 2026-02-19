package funkin.shaders;

import flixel.system.FlxAssets.FlxShader;

class ChromaticWarp {
    public var shader(default, null):ChromaWarpShader = new ChromaWarpShader();
    public var distortion(default, set):Float;

    private function set_distortion(value:Float) {
        distortion = value;
        shader.distortion.value = [distortion];
        return distortion;
    }

    public function new()
    {
        distortion = 0;
    }
}

class ChromaWarpShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        //   CHROMATIC ABBERATION https://www.shadertoy.com/view/wsdBWM
        //   by Tech_ (ported by lunar) 
        //   Fixed transparency by Manganos

        uniform float distortion;

        vec2 PincushionDistortion(in vec2 uv, float strength) 
        {
            vec2 st = uv - 0.5;
            float uvA = atan(st.x, st.y);
            float uvD = dot(st, st);
            return 0.5 + vec2(sin(uvA), cos(uvA)) * sqrt(uvD) * (1.0 - strength * uvD);
        }

        vec4 ChromaticAbberation(sampler2D tex, in vec2 uv) 
        {
            vec4 rSample = flixel_texture2D(tex, PincushionDistortion(uv, ((0.3 * distortion) * 0.9) + (distortion * 0.1)));
            vec4 gSample = flixel_texture2D(tex, PincushionDistortion(uv, ((0.15 * distortion) * 0.9) + (distortion * 0.1)));
            vec4 bSample = flixel_texture2D(tex, PincushionDistortion(uv, ((0.075 * distortion) * 0.9) + (distortion * 0.1)));

            vec3 color = vec3(rSample.r, gSample.g, bSample.b);

            float finalAlpha = max(rSample.a, max(gSample.a, bSample.a));

            return vec4(color, finalAlpha);
        }

        void main()
        {
            gl_FragColor = ChromaticAbberation(bitmap, openfl_TextureCoordv);
        }
	')
  
    public function new()
    {
      super();
    }
}