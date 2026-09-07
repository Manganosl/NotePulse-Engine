package funkin.objects.notes.splashes;

import funkin.objects.notes.splashes.NoteSplash.PixelSplashShaderRef;
import funkin.game.shaders.RGBPalette;
import funkin.objects.FunkinSprite;

class SustainSplash extends FunkinSprite {
	public var noteData:Int;

	public var rgbShader:PixelSplashShaderRef;
	public var strum(default, set):StrumNote;
	private function set_strum(value:StrumNote){
		noteData = value.noteData;
		return strum = value;
	}
	public var updatedThisFrame:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAlpha:Float = 0;
	public var offsetAngle:Float = 0;
	public var offsetScaleX:Float = 0;
	public var offsetScaleY:Float = 0;

	override public function new(strum:StrumNote) {
		super();
		this.strum = strum;

		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		frames = Paths.getSparrowAtlas('noteSplashes/holdSplashes/sustain_cover');
		animation.addByPrefix('splash', 'sustain cover end0', 24, false);
		animation.addByPrefix('loop', 'sustain cover0', 24, true);
		animation.play("loop");

		updateHitbox();
		visible = true;
		antialiasing = ClientPrefs.data.antialiasing;

		scale.set(strum.scale.x / 0.7, strum.scale.y / 0.7);
		updateHitbox();
	}

	public inline function show(note:Note) {
		if(strum.animation.curAnim != null && strum.animation.curAnim.name == "static") return;
		updatedThisFrame = true;

		var tempShader:RGBPalette = null;

		if (note != null && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB)) {
			if (!note.noteSplashData.useGlobalShader) {
				if (note.noteSplashData.r != -1) note.rgbShader.r = note.noteSplashData.r;
				if (note.noteSplashData.g != -1) note.rgbShader.g = note.noteSplashData.g;
				if (note.noteSplashData.b != -1) note.rgbShader.b = note.noteSplashData.b;
				tempShader = note.rgbShader.parent;
			} else {
				tempShader = Note.globalRgbShaders[note.noteData % Note.globalRgbShaders.length];
			}
		} else {
			tempShader = Note.globalRgbShaders[0];
		}

		rgbShader.copyValues(tempShader);

		visible = true;

		angle = note.angle + offsetAngle;

		if (animation.curAnim == null || animation.curAnim.name != "loop") {
			animation.play("loop");
			centerSplash();
		}
	}

	public inline function hide(miss:Bool = false) {
		if (animation.curAnim != null && animation.curAnim.name == "splash") return;

		updatedThisFrame = true;

		if (miss) {
			visible = false;
			return;
		}

		if (animation.curAnim == null || animation.curAnim.name != "splash") {
			animation.play("splash");
			angle = offsetAngle;
			centerSplash();
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		updatedThisFrame = false;

		if (animation.curAnim != null && animation.curAnim.finished) {
			switch (animation.curAnim.name) {
				case "cover":
					animation.play("loop");
				case "splash":
					visible = false;
			}
		}

		centerSplash();
	}

	public function centerSplash() {
		centerOffsets();
		scale.x = strum.scale.x * (1 / (!PlayState.isPixelStage ? 0.7 : 6)) + offsetScaleX;
		scale.y = strum.scale.y * (1 / (!PlayState.isPixelStage ? 0.7 : 6)) + offsetScaleY;
		alpha = strum.alpha + offsetAlpha - (1 - strum.rgbShader.alphaMult);
		x = strum.modPos.x + (strum.width / 2) - (width / 2) + offsetX;
		y = strum.modPos.y + (strum.height / 2) - (height / 2) + offsetY;
	}
}