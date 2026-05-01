package funkin.objects.notes.splashes;

import funkin.objects.notes.splashes.NoteSplash.PixelSplashShaderRef;
import funkin.game.shaders.RGBPalette;

class SustainSplash extends FlxSkewedSprite {
	// We can't use the normal visibility property as FunkinModchart messes with it.
	private var visibilityToggle:Bool = false;

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
		visibilityToggle = true;
		antialiasing = ClientPrefs.data.antialiasing;

		scale.set(strum.scale.x / 0.7, strum.scale.y / 0.7);
		updateHitbox();
	}

	public inline function show(note:Note) {
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

		visibilityToggle = true;

		if (animation.curAnim == null || animation.curAnim.name != "loop") {
			animation.play("loop");
			centerSplash();
		}
	}

	public inline function hide(miss:Bool = false) {
		if (animation.curAnim != null && animation.curAnim.name == "splash") return;

		updatedThisFrame = true;

		if (miss) {
			visibilityToggle = false;
			return;
		}

		if (animation.curAnim == null || animation.curAnim.name != "splash") {
			animation.play("splash");
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
					visibilityToggle = false;
			}
		}

		centerSplash();
	}

	public function centerSplash() {
		centerOffsets();
		visible = strum.visible;
		scale.x = strum.scale.x * (1 / (!PlayState.isPixelStage ? 0.7 : 6)) + offsetScaleX;
		scale.y = strum.scale.y * (1 / (!PlayState.isPixelStage ? 0.7 : 6)) + offsetScaleY;
		angle = strum.direction-90 + offsetAngle;
		alpha = (visibilityToggle ? (strum.alpha + offsetAlpha) : 0);
		x = strum.x + (strum.width / 2) - (width / 2) + offsetX;
		y = strum.y + (strum.height / 2) - (height / 2) + offsetY;
	}
}