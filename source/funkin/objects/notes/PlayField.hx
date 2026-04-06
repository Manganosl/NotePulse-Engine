package funkin.objects.notes;

import funkin.objects.notes.StrumNote;
import funkin.objects.notes.StrumNote.StrumBoundaries;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import funkin.states.PlayState;

class PlayField extends FlxTypedGroup<StrumNote> {
	public static var fields:Array<PlayField> = [];

    public var player:Int = 0;
	public var notes:Array<Note> = [];

	public var alpha(null, set):Float;

	public var inControl(null, set):Bool;
	public var downScroll(null, set):Bool;
	public var direction(null, set):Float;
	public var cpuControlled(null, set):Bool;
	public var noteHitCallback(null, set):Note->Void;
	public var noteMissCallback(null, set):Note->Void;
	public var noteSpeed(null, set):Float;
	public var texture(null, set):String;

	function set_alpha(value:Float){
		for(strum in members) strum.alpha = value;
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

    public function new(player:Int) {
        super();
        this.player = player;

        for (i in 0...PlayState.SONG.mania + 1) {
            var babyArrow:StrumNote = new StrumNote(0, 0, i, player);
			babyArrow.playAnim("static", true);
			babyArrow.parentField = this;
            add(babyArrow);
			babyArrow.postAddedToGroup();
        }
        adaptStrumline();

		FlxG.signals.stateSwitched.addOnce(function(){
			fields = [];
		});

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
		return camera = value;
	}

	override function set_cameras(value:Array<FlxCamera>){
		forEachNote(note -> {
			note.cameras = value;
		});
		return cameras = value;
	}
}