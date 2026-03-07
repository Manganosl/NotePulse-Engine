package funkin.objects;

import funkin.objects.StrumNote;
import funkin.objects.StrumNote.StrumBoundaries;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import funkin.states.PlayState;

class PlayField extends FlxTypedGroup<StrumNote> {
	public static var fields:Array<PlayField> = [];

    public var player:Int = 0;
	public var notes:Array<Note> = [];

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
}