package funkin.game.shaders;

import openfl.display.GraphicsShader;

class OutlineShader extends GraphicsShader {
	@:glFragmentSource('
		#pragma header
		
		uniform float alphaMult;
		uniform float outlineMult;
		
		void main() {
			vec4 tex = texture2D(bitmap, openfl_TextureCoordv);
			
			vec4 outline = vec4(0.);
			vec2 step = (1. / openfl_TextureSize);
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(step.x, 0.)).a;
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(-step.x, 0.)).a;
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(0., step.y)).a;
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(0., -step.y)).a;
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(step.x, step.y)).a;
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(-step.x, step.y)).a;
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(step.x, -step.y)).a;
			outline.a += texture2D(bitmap, openfl_TextureCoordv + vec2(-step.x, -step.y)).a;
			outline.a = min(outline.a, 1.) * outlineMult;
			
			gl_FragColor = min(tex + outline, 1.) * alphaMult * openfl_Alphav;
		}
	')
	
	public function new(transparency:Float = 1, borderStrength:Float = .5) {
		super();
		
		data.alphaMult.value = [transparency];
		data.outlineMult.value = [borderStrength];
	}
}