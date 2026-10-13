package funkin.objects.notes;

import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;
import funkin.objects.notes.StrumNote;
import funkin.objects.notes.StrumNote.StrumBoundaries;
import funkin.objects.audio.MeshRender;
import funkin.game.modchart.ModManager;
import funkin.game.modchart.math.DrawInstruction;
import funkin.states.PlayState;

class PlayField extends FlxTypedSpriteContainer<StrumNote> {
	public static var fields:Array<PlayField> = [];
	private var stateGeneration:(Int, Bool)->Void = null;

	public var sustainSegments:Int = 4;

	public var keysArray:Array<String>;

	public var keyCount(default, set):Int;

    public var player:Int = 0;
	public var notes:Array<Note> = [];

	public var showNotePaths:Bool = false;
	public var notePathGroup:FlxTypedGroup<MeshRender>;
	public var notePathSamples:Int = 40;
	public var notePathThickness:Float = 3.5;
	public var notePathCamMargin:Float = 48;
	public var notePathMaxLength:Float = 1450;
	var notePathMeshes:Map<Int, MeshRender> = [];
	var notePathVecCache:DrawInstruction = new DrawInstruction();
	var pathX:Array<Float> = [];
	var pathY:Array<Float> = [];
	static var noExclusions:Array<String> = [];

	public var inControl(null, set):Bool;
	public var downScroll(null, set):Bool;
	public var direction(null, set):Float;
	public var cpuControlled(null, set):Bool;
	public var noteHitCallback(null, set):Note->Void;
	public var noteMissCallback(null, set):Note->Void;
	public var noteSpeed(null, set):Float;
	public var texture(null, set):String;

	public var scrollFactorX(null, set):Float;
	public var scrollFactorY(null, set):Float;

	function set_scrollFactorX(value:Float){
		for(note in notes)
			note.scrollFactor.x = value;
		for(strum in members)
			strum.scrollFactor.x = value;
		return value;
	}

	function set_scrollFactorY(value:Float){
		for(note in notes)
			note.scrollFactor.y = value;
		for(strum in members)
			strum.scrollFactor.y = value;
		return value;
	}

	function set_inControl(value:Bool){
		for(strum in members) strum.inControl = value;
		return value;
	}
	function set_downScroll(value:Bool){
		for(strum in members) strum.downScroll = value;
		return value;
	}
	function set_direction(value:Float){
		for(strum in members) strum.direction = value;
		return value;
	}
	function set_cpuControlled(value:Bool){
		for(strum in members) strum.cpuControlled = value;
		return value;
	}
	function set_noteHitCallback(value:Note->Void){
		for(strum in members) strum.noteHitCallback = value;
		return value;
	}
	function set_noteMissCallback(value:Note->Void){
		for(strum in members) strum.noteMissCallback = value;
		return value;
	}
	function set_noteSpeed(value:Float){
		for(strum in members) strum.noteSpeed = value;
		return value;
	}
	function set_texture(value:String){
		for(strum in members) strum.texture = value;
		return value;
	}

	function set_keyCount(value:Int) {
		if(value == keyCount) return value;

		for(strum in members) {
			strum.kill();
			strum.exists = false;
			strum.destroy();
			remove(strum);
		}

		clear();

		keyCount = value;
		
		this.keysArray = [];
		for (i in 0...keyCount) {
			this.keysArray.push((keyCount - 1) + '_key_$i');
		}

		for (i in 0...keyCount) {
			var babyArrow:StrumNote = new StrumNote(0, 0, i, this.player, this);
			babyArrow.playAnim("static", true);
			babyArrow.parentField = this;
			add(babyArrow);
			babyArrow.postAddedToGroup();
		}

		if(notes != null){
			var i:Int = notes.length - 1;
			while (i >= 0){
				var note = notes[i];
				if(note == null || !note.exists){
					notes.splice(i, 1);
					i--;
					continue;
				}
				if(note.spawned){
					note.defaultRGB();
					note.reloadNote(note.texture);
					note.spawnedKeyCount = keyCount;
				}
				i--;
			}
		}
		adaptStrumline();
		if(stateGeneration != null) stateGeneration(this.player, false);
		return value;
	}

    public function new() {
        super();
        this.player = fields.length;
		this.keyCount = (PlayState.SONG != null && PlayState.SONG.mania != null) ? PlayState.SONG.mania + 1 : 4;

		fields.push(this);

		notePathGroup = new FlxTypedGroup<MeshRender>();
    }

	override public function destroy() {
		fields.remove(this);
		if (notePathGroup != null) {
			notePathGroup.destroy();
			notePathGroup = null;
		}
		notePathMeshes.clear();
		pathX.resize(0);
		pathY.resize(0);
		super.destroy();
	}

	public function adaptStrumline() {
		var strumLineWidth:Float = 0;
		var strumLineIsBig:Bool = false;

		for (note in this.members) strumLineWidth += note.width;
		strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;

		while (strumLineIsBig) {
			strumLineWidth = 0;
			for (note in this.members) {
				note.retryBound();
				strumLineWidth += note.width;
			}
			strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;
		}
	}

	public static function forEachField(func:PlayField->Void){
		for (field in fields)
			if (field != null && field.exists && field.alive)
				func(field);
	}

	public function forEachNote(func:Note->Void, onlySpawnedNotes = false){
		for (note in notes){
			if (note != null && note.exists && note.alive){
				if(onlySpawnedNotes){
					if(note.spawned){
						func(note);
					}
				} else func(note);
			}
		}
	}

	override function set_camera(value:FlxCamera){
		forEachNote(note -> {
			note.camera = value;
		});
		for(strum in members)
			strum.camera = value;
		if(notePathGroup != null)
			notePathGroup.camera = value;
		return camera = value;
	}

	override function set_cameras(value:Array<FlxCamera>){
		forEachNote(note -> {
			note.cameras = value;
		});
		for(strum in members)
			strum.cameras = value;
		if(notePathGroup != null)
			notePathGroup.cameras = value;
		return cameras = value;
	}

	function getNotePathMesh(lane:Int):MeshRender {
		var mesh = notePathMeshes.get(lane);
		if (mesh == null) {
			mesh = new MeshRender(0, 0, FlxColor.WHITE);
			mesh.cameras = notePathGroup.cameras;
			mesh.alpha = 0;
			notePathGroup.add(mesh);
			notePathMeshes.set(lane, mesh);
		}
		return mesh;
	}

	public function updateNotePaths(curDecBeat:Float, songPosition:Float, playbackRate:Float, songSpeed:Float, spawnTime:Float, camBaseL:Float, camBaseT:Float, camBaseR:Float, camBaseB:Float):Void {
		if (notePathGroup == null) return;

		var modManager = ModManager.instance;
		if(modManager == null){
			notePathGroup.visible = false;
			return;
		}

		final camL:Float = camBaseL - notePathCamMargin;
		final camT:Float = camBaseT - notePathCamMargin;
		final camR:Float = camBaseR + notePathCamMargin;
		final camB:Float = camBaseB + notePathCamMargin;

		for(strum in members)
			if (strum != null && strum.exists && strum.alive)
				updateNotePathMesh(strum, modManager, curDecBeat, songPosition, playbackRate, songSpeed, spawnTime, camL, camT, camR, camB);

		notePathGroup.visible = true;
	}

	function updateNotePathMesh(strum:StrumNote, modManager:ModManager, curDecBeat:Float, songPosition:Float, playbackRate:Float, songSpeed:Float, spawnTime:Float, camL:Float, camT:Float, camR:Float, camB:Float):Void {
		var mesh = getNotePathMesh(strum.noteData);

		mesh.alpha = showNotePaths ? 0.75 : 1 - mesh.alphaMult;
		if(mesh.alpha == 0) return;

		var maxTDiff:Float = spawnTime * playbackRate;
		if (songSpeed < 1) maxTDiff /= songSpeed;

		final spawnDiff:Float = modManager.getVisPos(songPosition, songPosition + maxTDiff, songSpeed);
		final spawnPos = modManager.getPos(songPosition + maxTDiff, spawnDiff, maxTDiff, curDecBeat, strum.noteData, player, strum, noExclusions, notePathVecCache);
		final spawnX:Float = spawnPos.x;
		final spawnY:Float = spawnPos.y + strum.y - 50;
		final recvX:Float = strum.modPos.x;
		final recvY:Float = strum.modPos.y;

		final boxLeft:Float = Math.min(spawnX, recvX);
		final boxRight:Float = Math.max(spawnX, recvX);
		final boxTop:Float = Math.min(spawnY, recvY);
		final boxBottom:Float = Math.max(spawnY, recvY);

		final onScreen:Bool = boxRight >= camL && boxLeft <= camR && boxBottom >= camT && boxTop <= camB;
		mesh.visible = onScreen;
		if (!onScreen) return;

		final cx:Float = strum.width * 0.5;
		final cy:Float = strum.height * 0.5;
		final maxLen:Float = notePathMaxLength;
		final samples:Int = notePathSamples;

		pathX.resize(0);
		pathY.resize(0);

		var total:Float = 0;
		for (k in 0...samples + 1) {
			final i:Int = samples - k;
			var px:Float;
			var py:Float;

			if (i == 0) {
				px = spawnX + cx;
				py = spawnY + cy;
			} else {
				var tDiff:Float = maxTDiff * (1 - i / samples);
				var diff:Float = modManager.getVisPos(songPosition, songPosition + tDiff, songSpeed);
				var time:Float = songPosition + tDiff;

				if (i == samples) { time = 0; diff = 0; tDiff = 0; }

				final pos = modManager.getPos(time, diff, tDiff, curDecBeat, strum.noteData, player, strum, noExclusions, notePathVecCache);
				px = pos.x + cx;
				py = pos.y + strum.y - 50 + cy;
			}

			if (k > 0) {
				final dx:Float = px - pathX[k - 1];
				final dy:Float = py - pathY[k - 1];
				final seg:Float = Math.sqrt(dx * dx + dy * dy);

				if (maxLen > 0 && total + seg > maxLen) {
					final t:Float = seg > 0.001 ? (maxLen - total) / seg : 0;
					pathX.push(pathX[k - 1] + dx * t);
					pathY.push(pathY[k - 1] + dy * t);
					break;
				}
				total += seg;
			}

			pathX.push(px);
			pathY.push(py);
		}

		mesh.clear();
		buildLineStrip(mesh, pathX, pathY, notePathThickness);
	}

	static function clampPathLength(points:Array<FlxPoint>, maxLen:Float):Void {
		if (maxLen <= 0 || points.length < 2) return;

		var total:Float = 0;
		var i:Int = points.length - 1;
		while (i > 0){
			var a = points[i - 1];
			var b = points[i];
			var dx:Float = b.x - a.x;
			var dy:Float = b.y - a.y;
			var segLen:Float = Math.sqrt(dx * dx + dy * dy);

			if (total + segLen > maxLen)
			{
				var remaining:Float = maxLen - total;
				var t:Float = segLen > 0.001 ? remaining / segLen : 0;
				var cutX:Float = b.x + (a.x - b.x) * t;
				var cutY:Float = b.y + (a.y - b.y) * t;

				for (j in 0...i)
					points[j].put();
				points.splice(0, i);
				points.unshift(FlxPoint.get(cutX, cutY));
				return;
			}

			total += segLen;
			i--;
		}
	}

	static function buildLineStrip(mesh:MeshRender, xs:Array<Float>, ys:Array<Float>, thickness:Float):Void {
		if (xs.length < 2) return;

		final half:Float = thickness * 0.5;
		var j:Int = xs.length - 1;
		while (j > 0)
		{
			final x0:Float = xs[j];
			final y0:Float = ys[j];
			final x1:Float = xs[j - 1];
			final y1:Float = ys[j - 1];
			j--;

			final dx:Float = x1 - x0;
			final dy:Float = y1 - y0;
			final len:Float = Math.sqrt(dx * dx + dy * dy);
			if (len < 0.001) continue;

			final nx:Float = -dy / len * half;
			final ny:Float = dx / len * half;

			mesh.build_quad(
				x0 + nx, y0 + ny,
				x0 - nx, y0 - ny,
				x1 - nx, y1 - ny,
				x1 + nx, y1 + ny
			);
		}
	}
}