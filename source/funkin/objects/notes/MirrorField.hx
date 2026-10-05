package funkin.objects.notes;

import funkin.game.modchart.ModManager;
import funkin.objects.notes.splashes.NoteSplash;
import funkin.objects.notes.splashes.SustainSplash;
import funkin.states.PlayState;

class MirrorField extends PlayField {
	public var source(default, null):PlayField;

	public var alphaMult:Float = 1;
	public var alphaOverride:Null<Float> = null;

	public var profile:Bool = false;
	var pAcc:Float = 0;
	var pNotes:Int = 0;
	var pDrawn:Int = 0;
	var pFrames:Int = 0;
	var pLast:Float = 0;

	public var mirrorNotes:Bool = true;
	public var mirrorNoteSplashes:Bool = true;
	public var mirrorSustainSplashes:Bool = true;

	public function new(source:PlayField, ?addToState:Bool = true) {
		super();
		this.source = source;
		this.sustainSegments = source.sustainSegments;
		configureStrums();
		syncFromSource();

		var mm = ModManager.instance;
		if (mm != null) copyModchart(mm);

		if (addToState) addToNoteGroup();
		adoptSourceCameras();
	}

	function addToNoteGroup():Void {
		var ps = PlayState.instance;
		if (ps == null || ps.noteGroup == null) return;
		if (ps.noteGroup.members.indexOf(this) < 0) ps.noteGroup.add(this);
	}

	function adoptSourceCameras():Void {
		@:privateAccess {
			if (_cameras == null && source != null && source._cameras != null) cameras = source.cameras;
		}
	}

	override function set_keyCount(value:Int) {
		var r = super.set_keyCount(value);
		keysArray = [];
		configureStrums();
		return r;
	}

	function configureStrums():Void {
		for (m in members) {
			if (m == null) continue;
			m.cpuControlled = true;
			m.inControl = false;
			m.noteHitCallback = null;
			m.noteMissCallback = null;
			m.resetAnim = 0;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		adoptSourceCameras();

		var mm = ModManager.instance;
		if (mm != null && mm.receptors[player] != members) copyModchart(mm);

		syncFromSource();
	}

	public function syncFromSource():Void {
		if (source == null || !source.exists) return;

		if (keyCount != source.keyCount) keyCount = source.keyCount;
		sustainSegments = source.sustainSegments;

		var n = Std.int(Math.min(members.length, source.members.length));
		for (i in 0...n) {
			var m = members[i];
			var s = source.members[i];
			if (m == null || s == null) continue;

			m.x = s.x;
			m.y = s.y;
			m.alpha = (alphaOverride != null ? alphaOverride : s.alpha) * alphaMult;
			m.visible = s.visible;
			m.downScroll = s.downScroll;
			m.direction = s.direction;
			m.noteSpeed = s.noteSpeed;
			m.sustainReduce = s.sustainReduce;

			if (m.texture != s.texture) m.texture = s.texture;

			if (m.defScale.x != s.defScale.x || m.defScale.y != s.defScale.y) {
				m.defScale.copyFrom(s.defScale);
				m.scale.copyFrom(s.defScale);
				m.updateHitbox();
			}

			var sa = s.animation.curAnim;
			if (sa != null) {
				var ma = m.animation.curAnim;
				if (ma == null || ma.name != sa.name) {
					m.playAnim(sa.name, true);
					ma = m.animation.curAnim;
				}
				if (ma != null && ma.curFrame != sa.curFrame) ma.curFrame = sa.curFrame;
			}
			m.resetAnim = 0;

			if (m.rgbShader != null && s.rgbShader != null) {
				if (m.rgbShader.r != s.rgbShader.r) m.rgbShader.r = s.rgbShader.r;
				if (m.rgbShader.g != s.rgbShader.g) m.rgbShader.g = s.rgbShader.g;
				if (m.rgbShader.b != s.rgbShader.b) m.rgbShader.b = s.rgbShader.b;
			}
		}
	}

	public function copyModchart(mm:ModManager, ?fromPlayer:Int):Void {
		var src:Int = fromPlayer ?? source.player;
		mm.receptors[player] = members;

		for (name in mm.register.keys())
			mm.setValue(name, mm.getValue(name, src), player);
	}

	override function draw() {
		super.draw();
		if (source == null || !source.exists) return;

		var ps = PlayState.instance;
		if (ps == null) return;

		var cams = this.cameras;

		if(mirrorNotes){
			var spawned = ps.notes != null ? ps.notes.members : null;
			if (spawned != null) {
				for (i in 0...spawned.length) {
					var note = spawned[i];
					if (note == null || note.playField != source || !note.exists || !note.alive || !note.visible) continue;
					pNotes++;
					drawMirroredNote(ps, note, cams);
				}
			}
		}

		if (mirrorNoteSplashes) drawMirroredNoteSplashes(ps, cams);
		if (mirrorSustainSplashes) drawMirroredSustainSplashes(cams);
	}

	function drawMirroredNote(ps:PlayState, note:Note, cams:Array<FlxCamera>):Void {
		if (members[note.noteData] == null) return;

		final oPF = note.playField;
		final oX = note.x, oY = note.y, oZ = note.z, oAngle = note.angle, oMAngle = note.mAngle, oDist = note.distance;
		final oSX = note.scale.x, oSY = note.scale.y;
		final oOrX = note.origin.x, oOrY = note.origin.y, oOfX = note.offset.x, oOfY = note.offset.y;
		final oA3X = note.angle3D.x, oA3Y = note.angle3D.y, oA3Z = note.angle3D.z;
		final oSkX = note.skewOffset.x, oSkY = note.skewOffset.y;
		final oModSpeed = note.modSpeed;
		final ct = note.colorTransform;
		final oRM = ct.redMultiplier, oGM = ct.greenMultiplier, oBM = ct.blueMultiplier, oAM = ct.alphaMultiplier;
		final oRO = ct.redOffset, oGO = ct.greenOffset, oBO = ct.blueOffset, oAO = ct.alphaOffset;
		final oClip = note.clipRect;
		final hadClip = oClip != null;
		var cX:Float = 0, cY:Float = 0, cW:Float = 0, cH:Float = 0;
		if (hadClip) { cX = oClip.x; cY = oClip.y; cW = oClip.width; cH = oClip.height; }
		var oCams:Array<FlxCamera> = null;
		@:privateAccess oCams = note._cameras;

		inline function restore():Void {
			note.playField = (oPF);
			@:privateAccess note._cameras = oCams;
			note.x = oX; note.y = oY; note.z = oZ; note.angle = oAngle; note.mAngle = oMAngle; note.distance = oDist;
			note.scale.set(oSX, oSY);
			note.origin.set(oOrX, oOrY);
			note.offset.set(oOfX, oOfY);
			note.angle3D.x = oA3X; note.angle3D.y = oA3Y; note.angle3D.z = oA3Z;
			note.skewOffset.set(oSkX, oSkY);
			note.modSpeed = oModSpeed;
			note.setColorTransform(oRM, oGM, oBM, oAM, oRO, oGO, oBO, oAO);
			if (hadClip) {
				oClip.x = cX; oClip.y = cY; oClip.width = cW; oClip.height = cH;
				note.clipRect = oClip;
			} else if (note.clipRect != null)
				note.clipRect = null;
		}

		try {
			note.playField = (this);
			ps.noteFollowStrum(note);
			if(note.spawned){
				@:privateAccess note._cameras = cams;
				note.draw();
				pDrawn++;
			}
		} catch (e:Dynamic) {
			restore();
			throw e;
		}
		restore();
	}

	function drawMirroredNoteSplashes(ps:PlayState, cams:Array<FlxCamera>):Void {
		var group = ps.grpNoteSplashes;
		if (group == null) return;

		for (sp in group.members) {
			if (sp == null || !sp.exists || !sp.alive || !sp.visible) continue;
			var babyArrow = sp.babyArrow;
			if (babyArrow == null || babyArrow.parentField != source) continue;

			var m = members[sp.noteData];
			if (m == null) continue;

			final oX = sp.x, oY = sp.y;
			var oCams:Array<FlxCamera> = null;
			@:privateAccess oCams = sp._cameras;

			sp.x = m.modPos.x - Note.swagWidth * 0.95;
			sp.y = m.modPos.y - Note.swagWidth;
			@:privateAccess sp._cameras = cams;
			sp.draw();
			@:privateAccess sp._cameras = oCams;
			sp.x = oX;
			sp.y = oY;
		}
	}

	function drawMirroredSustainSplashes(cams:Array<FlxCamera>):Void {
		var n = Std.int(Math.min(members.length, source.members.length));
		for (i in 0...n) {
			var m = members[i];
			var s = source.members[i];
			if (m == null || s == null) continue;

			var ss:SustainSplash = s.sustainSplash;
			if (ss == null || !ss.exists || !ss.alive || !ss.visible) continue;

			final oX = ss.x, oY = ss.y, oSX = ss.scale.x, oSY = ss.scale.y, oAlpha = ss.alpha;
			var oCams:Array<FlxCamera> = null;
			@:privateAccess oCams = ss._cameras;

			var k:Float = 1 / (!PlayState.isPixelStage ? 0.7 : 6);
			ss.scale.set(m.scale.x * k + ss.offsetScaleX, m.scale.y * k + ss.offsetScaleY);
			ss.alpha = m.alpha + ss.offsetAlpha;
			ss.x = m.modPos.x + (m.width / 2) - (ss.width / 2) + ss.offsetX;
			ss.y = m.modPos.y + (m.height / 2) - (ss.height / 2) + ss.offsetY;
			@:privateAccess ss._cameras = cams;
			ss.draw();
			@:privateAccess ss._cameras = oCams;

			ss.x = oX;
			ss.y = oY;
			ss.scale.set(oSX, oSY);
			ss.alpha = oAlpha;
		}
	}
}
