package objects;

class SustainSplash extends FlxSkewedSprite {
	public var strum:StrumNote;
	public var shouldVisible:Bool = false;
	public var modchart:Bool = PlayState.fModchart;
	public var firstTime:Bool = true;
	override public function new(strum:StrumNote) {
		super();
		this.strum = strum;

		frames = Paths.getSparrowAtlas('noteSplashes/holdSplashes/sustain_cover');
		animation.addByPrefix('cover', 'sustain cover pre0', 24, false);
		animation.addByPrefix('splash', 'sustain cover end0', 24, false);
		animation.addByPrefix('loop', 'sustain cover0', 24);
		animation.play("loop");
		updateHitbox();
		visible = true;
		shouldVisible = false;
		antialiasing = ClientPrefs.data.antialiasing;

		scale.set(strum.scale.x / 0.7, strum.scale.y / 0.7);
		updateHitbox();
	}

	public var updatedThisFrame:Bool = false;

	public inline function show() {
		updatedThisFrame = true;
		if(!modchart) visible = true;
		shouldVisible = true;
		if (animation.curAnim.name != "loop") {
			animation.play("cover");
			center();
		}
	}
	public inline function hide(miss:Bool = false) {
		if (animation.curAnim.name == "splash") return;
		updatedThisFrame = true;
		if (miss) {if(!modchart) visible = false; shouldVisible = false;}
		if (animation.curAnim.name != "splash") {
			animation.play("splash");
			if (!firstTime) strum.playAnim("pressed", true); else firstTime = false;
			center();
		}
	}

	override public function update(elapsed:Float) {
		shader = strum.shader;
		super.update(elapsed);
		updatedThisFrame = false;
		modchart = PlayState.fModchart;	


		if (animation.curAnim.finished) {
			if (animation.curAnim.name == "cover") animation.play("loop");
			if (animation.curAnim.name == "splash") {if(!modchart) visible = false; shouldVisible = false;}
		}
		center();
	}

	public function center() {
		centerOffsets();
		scale.x = strum.scale.x*1/(!PlayState.isPixelStage ? 0.7 : 6);
		scale.y = strum.scale.y*1/(!PlayState.isPixelStage ? 0.7 : 6);
		alpha = strum.alpha;
		x = strum.x + (strum.width/2) - (width/2);
		y = strum.y + (strum.height/2) - (height/2);
	}
}