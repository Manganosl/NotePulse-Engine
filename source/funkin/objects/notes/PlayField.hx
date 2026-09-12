package funkin.objects.notes;

import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;
import funkin.objects.notes.StrumNote;
import funkin.objects.notes.StrumNote.StrumBoundaries;
import funkin.objects.audio.MeshRender;
import funkin.game.modchart.ModManager;
import funkin.game.modchart.math.Vector3;
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
	public var notePathSamples:Int = 24;
	public var notePathThickness:Float = 3.5;
	public var notePathCamMargin:Float = 48;
	public var notePathMaxLength:Float = 1250;
	public var notePathBaseAlpha:Float = 0.75;
	var notePathMeshes:Map<Int, MeshRender> = [];
	var notePathVecCache:Vector3 = new Vector3();

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
		return camera = value;
	}

	override function set_cameras(value:Array<FlxCamera>){
		forEachNote(note -> {
			note.cameras = value;
		});
		for(strum in members)
			strum.cameras = value;
		return cameras = value;
	}

	function getNotePathMesh(lane:Int):MeshRender {
		var mesh = notePathMeshes.get(lane);
		if (mesh == null) {
			mesh = new MeshRender(0, 0, FlxColor.WHITE);
			mesh.cameras = notePathGroup.cameras;
			mesh.alpha = notePathBaseAlpha;
			notePathGroup.add(mesh);
			notePathMeshes.set(lane, mesh);
		}
		return mesh;
	}

	public function updateNotePaths(curDecBeat:Float, songPosition:Float, playbackRate:Float, songSpeed:Float, spawnTime:Float, camBaseL:Float, camBaseT:Float, camBaseR:Float, camBaseB:Float):Void {
		if (notePathGroup == null) return;

		var modManager = ModManager.instance;
		if (modManager == null || !showNotePaths) {
			notePathGroup.visible = false;
			return;
		}

		var camL:Float = camBaseL - notePathCamMargin;
		var camT:Float = camBaseT - notePathCamMargin;
		var camR:Float = camBaseR + notePathCamMargin;
		var camB:Float = camBaseB + notePathCamMargin;

		forEachAlive(function(strum:StrumNote) {
			updateNotePathMesh(strum, modManager, curDecBeat, songPosition, playbackRate, songSpeed, spawnTime, camL, camT, camR, camB);
		});

		notePathGroup.visible = true;
	}

	function updateNotePathMesh(strum:StrumNote, modManager:ModManager, curDecBeat:Float, songPosition:Float, playbackRate:Float, songSpeed:Float, spawnTime:Float, camL:Float, camT:Float, camR:Float, camB:Float):Void {
		var mesh = getNotePathMesh(strum.noteData);

		var maxTDiff:Float = spawnTime * playbackRate;
		if (songSpeed < 1) maxTDiff /= songSpeed;

		var spawnDiff:Float = modManager.getVisPos(songPosition, songPosition + maxTDiff, songSpeed);
		var spawnPos = modManager.getPos(songPosition + maxTDiff, spawnDiff, maxTDiff, curDecBeat, strum.noteData, player, strum, [], notePathVecCache);
		var spawnX:Float = spawnPos.x;
		var spawnY:Float = spawnPos.y + strum.y - 50;
		var recvX:Float = strum.modPos.x;
		var recvY:Float = strum.modPos.y;

		var boxLeft:Float = Math.min(spawnX, recvX);
		var boxRight:Float = Math.max(spawnX, recvX);
		var boxTop:Float = Math.min(spawnY, recvY);
		var boxBottom:Float = Math.max(spawnY, recvY);

		var onScreen:Bool = boxRight >= camL && boxLeft <= camR && boxBottom >= camT && boxTop <= camB;
		mesh.visible = onScreen;
		if (!onScreen) return;

		mesh.alpha = notePathBaseAlpha * strum.rgbShader.alphaMult;

		var points:Array<FlxPoint> = [];
		points.push(FlxPoint.get(spawnX, spawnY));

		for (i in 1...notePathSamples + 1)
		{
			var frac:Float = i / notePathSamples;
			var tDiff:Float = maxTDiff * (1 - frac);
			var diff:Float = modManager.getVisPos(songPosition, songPosition + tDiff, songSpeed);
			var time:Float = songPosition + tDiff;

			if (i == notePathSamples) { time = 0; diff = 0; tDiff = 0; }

			var pos = modManager.getPos(time, diff, tDiff, curDecBeat, strum.noteData, player, strum, [], notePathVecCache);
			points.push(FlxPoint.get(pos.x, pos.y + strum.y - 50));
		}

		var centerX:Float = strum.width * 0.5;
		var centerY:Float = strum.height * 0.5;
		if (centerX != 0 || centerY != 0)
			for (p in points)
			{
				p.x += centerX;
				p.y += centerY;
			}

		clampPathLength(points, notePathMaxLength);

		mesh.clear();
		buildLineStrip(mesh, points, notePathThickness);

		for (p in points)
			p.put();
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

	static function buildLineStrip(mesh:MeshRender, points:Array<FlxPoint>, thickness:Float):Void {
		if (points.length < 2) return;

		var half:Float = thickness * 0.5;
		for (i in 0...points.length - 1)
		{
			var p0 = points[i];
			var p1 = points[i + 1];

			var dx:Float = p1.x - p0.x;
			var dy:Float = p1.y - p0.y;
			var len:Float = Math.sqrt(dx * dx + dy * dy);
			if (len < 0.001) continue;

			var nx:Float = -dy / len * half;
			var ny:Float = dx / len * half;

			mesh.build_quad(
				p0.x + nx, p0.y + ny,
				p0.x - nx, p0.y - ny,
				p1.x - nx, p1.y - ny,
				p1.x + nx, p1.y + ny
			);
		}
	}
}