package funkin.objects;

import funkin.objects.StrumNote;
import funkin.objects.StrumNote.StrumBoundaries;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;
import funkin.states.PlayState;

class PlayField extends FlxTypedGroup<StrumNote> {
    public var player:Int = 0;
	private var keysArray:Array<String>;
	public var notes:Array<Note>;

    public function new(player:Int) {
        super();
        this.player = player;

        for (i in 0...PlayState.SONG.mania + 1) {
            var babyArrow:StrumNote = new StrumNote(0, 0, i, player);
			babyArrow.playAnim("static", true);
            add(babyArrow);
        }
        adaptStrumline();
		keysArray = [];
		for (i in 0...PlayState.SONG.mania + 1){
			keysArray.push(PlayState.SONG.mania + '_key_$i');
		}
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.signals.stateSwitched.addOnce(removeListeners);
    }

	override public function destroy() {
		super.destroy();
		removeListeners();
	}

	public function onKeyPress(event:KeyboardEvent) {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
		var note:StrumNote = members[key];
		if (note != null && !note.cpuControlled) {
			note.playAnim("pressed", true);
			note.resetAnim = 0;
		}
	}

	public function onKeyRelease(event:KeyboardEvent) {
		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
		var note:StrumNote = members[key];
		if (note != null && !note.cpuControlled) {
			note.playAnim("static", true);
			note.resetAnim = 0;
		}
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

	private var removedListeners:Bool = false;
	private function removeListeners() {
		if(removedListeners) return;
		removedListeners = true;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
	}
}