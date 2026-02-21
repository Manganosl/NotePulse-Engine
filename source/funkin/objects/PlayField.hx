package funkin.objects;

import funkin.objects.StrumNote;
import funkin.objects.StrumNote.StrumBoundaries;

class PlayField extends FlxTypedGroup<StrumNote> {
    public var player:Int = 0;

    public function new(player:Int) {
        super();
        this.player = player;

        for (i in 0...PlayState.SONG.mania + 1) {
            var babyArrow:StrumNote = new StrumNote(0, 0, i, player);
            add(babyArrow);
        }
        adaptStrumline();
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