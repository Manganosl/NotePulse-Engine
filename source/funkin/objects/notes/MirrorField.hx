package funkin.objects.notes;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import funkin.game.modchart.ModManager;
import funkin.states.PlayState;
import openfl.geom.ColorTransform;

private class NoteSnapshot {
	public var savedPlayField:PlayField;
	public var savedCameras:Array<FlxCamera>;
	public var savedX:Float = 0;
	public var savedY:Float = 0;
	public var savedDepth:Float = 0;
	public var savedAngle:Float = 0;
	public var savedSustainAngle:Float = 0;
	public var savedScrollDistance:Float = 0;
	public var savedAngle3DX:Float = 0;
	public var savedAngle3DY:Float = 0;
	public var savedAngle3DZ:Float = 0;
	public var savedSpeedMultiplier:Float = 1;
	public var savedScale:FlxPoint = new FlxPoint();
	public var savedOrigin:FlxPoint = new FlxPoint();
	public var savedOffset:FlxPoint = new FlxPoint();
	public var savedSkew:FlxPoint = new FlxPoint();
	public var savedColor:ColorTransform = new ColorTransform();
	public var savedClipRect:FlxRect;
	public var savedClipValues:FlxRect = new FlxRect();
	public var hadClipRect:Bool = false;

	public function new() {}

	public function capture(note:Note):Void{
		savedPlayField = note.playField;
		@:privateAccess savedCameras = note._cameras;
		savedX = note.x;
		savedY = note.y;
		savedDepth = note.z;
		savedAngle = note.angle;
		savedSustainAngle = note.mAngle;
		savedScrollDistance = note.distance;
		savedAngle3DX = note.angle3D.x;
		savedAngle3DY = note.angle3D.y;
		savedAngle3DZ = note.angle3D.z;
		savedSpeedMultiplier = note.modSpeed;
		savedScale.copyFrom(note.scale);
		savedOrigin.copyFrom(note.origin);
		savedOffset.copyFrom(note.offset);
		savedSkew.copyFrom(note.skewOffset);

		var noteColor = note.colorTransform;
		savedColor.redMultiplier = noteColor.redMultiplier;
		savedColor.greenMultiplier = noteColor.greenMultiplier;
		savedColor.blueMultiplier = noteColor.blueMultiplier;
		savedColor.alphaMultiplier = noteColor.alphaMultiplier;
		savedColor.redOffset = noteColor.redOffset;
		savedColor.greenOffset = noteColor.greenOffset;
		savedColor.blueOffset = noteColor.blueOffset;
		savedColor.alphaOffset = noteColor.alphaOffset;

		savedClipRect = note.clipRect;
		hadClipRect = savedClipRect != null;
		if(hadClipRect) savedClipValues.copyFrom(savedClipRect);
	}

	public function restore(note:Note):Void{
		@:bypassAccessor note.playField = savedPlayField;
		@:privateAccess note._cameras = savedCameras;
		note.x = savedX;
		note.y = savedY;
		note.z = savedDepth;
		note.angle = savedAngle;
		note.mAngle = savedSustainAngle;
		note.distance = savedScrollDistance;
		note.angle3D.x = savedAngle3DX;
		note.angle3D.y = savedAngle3DY;
		note.angle3D.z = savedAngle3DZ;
		note.modSpeed = savedSpeedMultiplier;
		note.scale.copyFrom(savedScale);
		note.origin.copyFrom(savedOrigin);
		note.offset.copyFrom(savedOffset);
		note.skewOffset.copyFrom(savedSkew);
		note.setColorTransform(savedColor.redMultiplier, savedColor.greenMultiplier, savedColor.blueMultiplier, savedColor.alphaMultiplier,
			savedColor.redOffset, savedColor.greenOffset, savedColor.blueOffset, savedColor.alphaOffset);

		if(hadClipRect){
			if(note.clipRect != savedClipRect || savedClipRect.x != savedClipValues.x || savedClipRect.y != savedClipValues.y
				|| savedClipRect.width != savedClipValues.width || savedClipRect.height != savedClipValues.height){
				savedClipRect.copyFrom(savedClipValues);
				note.clipRect = savedClipRect;
			}
		} else if(note.clipRect != null) note.clipRect = null;
	}
}

class MirrorField extends PlayField {
	public var sourceField(default, null):PlayField;
	public var alphaMultiplier:Float = 1;
	public var alphaOverride:Null<Float> = null;
	public var sustainSegmentsOverride:Null<Int> = null;
	public var cullOffscreen:Bool = true;
	public var cullMargin:Float = 600;
	public var mirrorNotes:Bool = true;
	public var mirrorNoteSplashes:Bool = true;
	public var mirrorSustainSplashes:Bool = true;

	var lastModManager:ModManager;
	var noteSnapshot:NoteSnapshot = new NoteSnapshot();

	public function new(sourceField:PlayField, addToState:Bool = true) {
		super();
		this.sourceField = sourceField;
		sustainSegments = sourceField.sustainSegments;
		configureStrums();
		copyStrumLook();
		lastModManager = ModManager.instance;
		if(lastModManager != null) lastModManager.registerPlayer(player);
		if(addToState) addToNoteGroup();
		adoptSourceCameras();
		syncFromSource();
	}

	override function set_keyCount(value:Int):Int {
		var newKeyCount = super.set_keyCount(value);
		keysArray = [];
		configureStrums();
		if(sourceField != null) copyStrumLook();
		return newKeyCount;
	}

	function configureStrums():Void{
		for(strum in members){
			if(strum == null) continue;
			strum.cpuControlled = true;
			strum.inControl = false;
			strum.noteHitCallback = null;
			strum.noteMissCallback = null;
			strum.resetAnim = 0;
		}
	}

	inline function syncStrumLook(mirrorStrum:StrumNote, sourceStrum:StrumNote):Void{
		if(mirrorStrum.texture != sourceStrum.texture) mirrorStrum.texture = sourceStrum.texture;
		var mirrorColors = mirrorStrum.rgbShader;
		var sourceColors = sourceStrum.rgbShader;
		if(mirrorColors != null && sourceColors != null){
			if(mirrorColors.r != sourceColors.r) mirrorColors.r = sourceColors.r;
			if(mirrorColors.g != sourceColors.g) mirrorColors.g = sourceColors.g;
			if(mirrorColors.b != sourceColors.b) mirrorColors.b = sourceColors.b;
		}
	}

	function copyStrumLook():Void{
		var sourceStrums = sourceField.members;
		var strumCount = members.length < sourceStrums.length ? members.length : sourceStrums.length;
		for(strumIndex in 0...strumCount){
			var mirrorStrum = members[strumIndex];
			var sourceStrum = sourceStrums[strumIndex];
			if(mirrorStrum == null || sourceStrum == null) continue;
			syncStrumLook(mirrorStrum, sourceStrum);
			mirrorStrum.sustainReduce = sourceStrum.sustainReduce;
			mirrorStrum.downScroll = sourceStrum.downScroll;
		}
	}

	function addToNoteGroup():Void{
		var playState = PlayState.instance;
		if(playState == null || playState.noteGroup == null) return;
		if(playState.noteGroup.members.indexOf(this) < 0) playState.noteGroup.add(this);
	}

	function adoptSourceCameras():Void{
		@:privateAccess{
			if(_cameras == null && sourceField != null && sourceField._cameras != null) cameras = sourceField.cameras;
		}
	}

	override function update(elapsed:Float):Void{
		super.update(elapsed);
		adoptSourceCameras();

		var currentModManager = ModManager.instance;
		if(currentModManager != lastModManager){
			lastModManager = currentModManager;
			if(currentModManager != null && currentModManager.receptors[player] != members) currentModManager.registerPlayer(player);
		}

		if(sourceField != null && sourceField.exists) syncFromSource();
	}

	function syncFromSource():Void{
		if(keyCount != sourceField.keyCount) keyCount = sourceField.keyCount;

		var targetSegments:Int = sustainSegmentsOverride != null ? sustainSegmentsOverride : sourceField.sustainSegments;
		if(sustainSegments != targetSegments) sustainSegments = targetSegments;

		var sourceStrums = sourceField.members;
		var strumCount = members.length < sourceStrums.length ? members.length : sourceStrums.length;

		for(strumIndex in 0...strumCount){
			var mirrorStrum = members[strumIndex];
			var sourceStrum = sourceStrums[strumIndex];
			if(mirrorStrum == null || sourceStrum == null) continue;

			if(mirrorStrum.x != sourceStrum.x) mirrorStrum.x = sourceStrum.x;
			if(mirrorStrum.y != sourceStrum.y) mirrorStrum.y = sourceStrum.y;

			var targetAlpha = (alphaOverride != null ? alphaOverride : sourceStrum.alpha) * alphaMultiplier;
			if(mirrorStrum.alpha != targetAlpha) mirrorStrum.alpha = targetAlpha;
			if(mirrorStrum.visible != sourceStrum.visible) mirrorStrum.visible = sourceStrum.visible;

			var sourceAnimation = sourceStrum.animation.curAnim;
			if(sourceAnimation != null){
				var mirrorAnimation = mirrorStrum.animation.curAnim;
				if(mirrorAnimation == null || mirrorAnimation.name != sourceAnimation.name){
					syncStrumLook(mirrorStrum, sourceStrum);
					mirrorStrum.playAnim(sourceAnimation.name, true);
					mirrorAnimation = mirrorStrum.animation.curAnim;
				}
				if(mirrorAnimation != null && mirrorAnimation.curFrame != sourceAnimation.curFrame) mirrorAnimation.curFrame = sourceAnimation.curFrame;
			}

			if(mirrorStrum.resetAnim != 0) mirrorStrum.resetAnim = 0;
		}
	}

	override function draw():Void{
		super.draw();

		var playState = PlayState.instance;
		if(sourceField == null || !sourceField.exists || playState == null) return;

		var drawCameras = cameras;
		if(mirrorNotes) drawNotes(playState, drawCameras);
		if(mirrorNoteSplashes) drawNoteSplashes(playState, drawCameras);
		if(mirrorSustainSplashes) drawSustainSplashes(drawCameras);
	}

	function drawNotes(playState:PlayState, drawCameras:Array<FlxCamera>):Void{
		if(playState.notes == null) return;

		var spawnedNotes = playState.notes.members;
		for(noteIndex in 0...spawnedNotes.length){
			var currentNote = spawnedNotes[noteIndex];
			if(currentNote == null || currentNote.playField != sourceField || !currentNote.exists || !currentNote.alive || !currentNote.visible) continue;
			drawNote(playState, currentNote, drawCameras);
		}
	}

	function drawNote(playState:PlayState, currentNote:Note, drawCameras:Array<FlxCamera>):Void{
		if(members[currentNote.noteData] == null) return;

		noteSnapshot.capture(currentNote);
		try{
			@:bypassAccessor currentNote.playField = this;
			playState.noteFollowStrum(currentNote);
			if(!cullOffscreen || !isOffscreen(currentNote, drawCameras)){
				@:privateAccess currentNote._cameras = drawCameras;
				currentNote.draw();
			}
		}catch(error:Dynamic){
			noteSnapshot.restore(currentNote);
			throw error;
		}
		noteSnapshot.restore(currentNote);
	}

	function isOffscreen(currentNote:Note, drawCameras:Array<FlxCamera>):Bool{
		for(camera in drawCameras){
			if(camera == null || !camera.visible) continue;
			var screenX = currentNote.x - camera.scroll.x * currentNote.scrollFactor.x;
			var screenY = currentNote.y - camera.scroll.y * currentNote.scrollFactor.y;
			if(screenX >= -cullMargin && screenX <= camera.width + cullMargin && screenY >= -cullMargin && screenY <= camera.height + cullMargin) return false;
		}
		return true;
	}

	function drawNoteSplashes(playState:PlayState, drawCameras:Array<FlxCamera>):Void{
		var splashGroup = playState.grpNoteSplashes;
		if(splashGroup == null) return;

		var splashes = splashGroup.members;
		for(splashIndex in 0...splashes.length){
			var splash = splashes[splashIndex];
			if(splash == null || !splash.exists || !splash.alive || !splash.visible) continue;

			var targetStrum = splash.babyArrow;
			if(targetStrum == null || targetStrum.parentField != sourceField) continue;

			var mirrorStrum = members[splash.noteData];
			if(mirrorStrum == null) continue;

			var originalX = splash.x;
			var originalY = splash.y;
			var originalCameras:Array<FlxCamera> = null;
			@:privateAccess originalCameras = splash._cameras;

			splash.x = mirrorStrum.modPos.x - Note.swagWidth * 0.95;
			splash.y = mirrorStrum.modPos.y - Note.swagWidth;
			@:privateAccess splash._cameras = drawCameras;
			splash.draw();
			@:privateAccess splash._cameras = originalCameras;
			splash.x = originalX;
			splash.y = originalY;
		}
	}

	function drawSustainSplashes(drawCameras:Array<FlxCamera>):Void{
		var sourceStrums = sourceField.members;
		var strumCount = members.length < sourceStrums.length ? members.length : sourceStrums.length;
		var splashScaleFactor:Float = 1 / (!PlayState.isPixelStage ? 0.7 : 6);

		for(strumIndex in 0...strumCount){
			var mirrorStrum = members[strumIndex];
			var sourceStrum = sourceStrums[strumIndex];
			if(mirrorStrum == null || sourceStrum == null) continue;

			var sustainSplash = sourceStrum.sustainSplash;
			if(sustainSplash == null || !sustainSplash.exists || !sustainSplash.alive || !sustainSplash.visible) continue;

			var originalX = sustainSplash.x;
			var originalY = sustainSplash.y;
			var originalScaleX = sustainSplash.scale.x;
			var originalScaleY = sustainSplash.scale.y;
			var originalAlpha = sustainSplash.alpha;
			var originalCameras:Array<FlxCamera> = null;
			@:privateAccess originalCameras = sustainSplash._cameras;

			sustainSplash.scale.set(mirrorStrum.scale.x * splashScaleFactor + sustainSplash.offsetScaleX, mirrorStrum.scale.y * splashScaleFactor + sustainSplash.offsetScaleY);
			sustainSplash.alpha = mirrorStrum.alpha + sustainSplash.offsetAlpha;
			sustainSplash.x = mirrorStrum.modPos.x + (mirrorStrum.width / 2) - (sustainSplash.width / 2) + sustainSplash.offsetX;
			sustainSplash.y = mirrorStrum.modPos.y + (mirrorStrum.height / 2) - (sustainSplash.height / 2) + sustainSplash.offsetY;
			@:privateAccess sustainSplash._cameras = drawCameras;
			sustainSplash.draw();
			@:privateAccess sustainSplash._cameras = originalCameras;

			sustainSplash.x = originalX;
			sustainSplash.y = originalY;
			sustainSplash.scale.set(originalScaleX, originalScaleY);
			sustainSplash.alpha = originalAlpha;
		}
	}
}