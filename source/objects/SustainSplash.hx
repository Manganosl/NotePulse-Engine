package objects;

import objects.NoteSplash.PixelSplashShaderRef;
import shaders.RGBPalette;

class SustainSplash extends FlxSkewedSprite {
	public var rgbShader:PixelSplashShaderRef;
	public var strum:StrumNote;
	public var shouldVisible:Bool = false;
	public var modchart:Bool = PlayState.fModchart;
	public var firstTime:Bool = true;
	public var updatedThisFrame:Bool = false;

	override public function new(strum:StrumNote) {
		super();
		this.strum = strum;

		rgbShader = new PixelSplashShaderRef();
		shader = rgbShader.shader;

		frames = Paths.getSparrowAtlas('noteSplashes/holdSplashes/sustain_cover');
		animation.addByPrefix('cover', 'sustain cover pre0', 24, false);
		animation.addByPrefix('splash', 'sustain cover end0', 24, false);
		animation.addByPrefix('loop', 'sustain cover0', 24, true);
		animation.play("loop");

		updateHitbox();
		visible = true;
		shouldVisible = false;
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

		if (!modchart) visible = true;
		shouldVisible = true;

		if (animation.curAnim == null || animation.curAnim.name != "loop") {
			animation.play("loop");
			center();
		}
	}

	public inline function hide(miss:Bool = false) {
		if (animation.curAnim != null && animation.curAnim.name == "splash") return;

		updatedThisFrame = true;

		if (miss) {
			if (!modchart) visible = false;
			shouldVisible = false;
		}

		if (animation.curAnim == null || animation.curAnim.name != "splash") {
			animation.play("splash");
			if (!firstTime) {
				strum.playAnim("pressed", true);
			} else {
				firstTime = false;
			}
			center();
		}
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		updatedThisFrame = false;
		modchart = PlayState.fModchart;	

		if (animation.curAnim != null && animation.curAnim.finished) {
			switch (animation.curAnim.name) {
				case "cover":
					animation.play("loop");
				case "splash":
					if (!modchart) visible = false;
					shouldVisible = false;
			}
		}

		center();
	}

	public function center() {
		centerOffsets();
		scale.x = strum.scale.x * (1 / (!PlayState.isPixelStage ? 0.7 : 6));
		scale.y = strum.scale.y * (1 / (!PlayState.isPixelStage ? 0.7 : 6));
		angle = strum.direction-90;
		alpha = strum.alpha;
		x = strum.x + (strum.width / 2) - (width / 2);
		y = strum.y + (strum.height / 2) - (height / 2);
	}
}