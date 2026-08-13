package funkin.objects.notes;

import funkin.objects.notes.StrumNote;
import funkin.objects.notes.StrumNote.StrumBoundaries;
import funkin.states.PlayState;

class PlayField extends FlxTypedSpriteGroup<StrumNote> {
	public static var fields:Array<PlayField> = [];
	private var stateGeneration:(Int, Bool)->Void = null;

	public var keysArray:Array<String>;

	public var keyCount(default, set):Int;

    public var player:Int = 0;
	public var notes:Array<Note> = [];

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
				note.defaultRGB();
				note.reloadNote(note.texture);
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
    }

	override public function destroy() {
		fields.remove(this);
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
}