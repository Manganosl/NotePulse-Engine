package debug;
import backend.Conductor;
import states.PlayState;
import flixel.util.FlxStringUtil;
import backend.Song;

class ConductorInfo extends FramerateCategory {
	public function new() {
		super("Conductor Info");
	}

	public override inline function __enterFrame(t:Int) {
		if (alpha <= 0.05) return;
		if (Type.getClassName(Type.getClass(FlxG.state)) != 'states.PlayState') {
			this.text.text = 'Not in PlayState';
		} else if (Song.convertedChart) {
			_text = 'Running a PsychV1 Chart\nMight have issues!';
			_text += '\n\nCurrent Song Position: ${FlxStringUtil.formatTime(Conductor.songPosition / 1000, true)}';
			_text += '\n - ${PlayState.curBShit} beats';
			_text += '\n - ${PlayState.curSShit} steps';
			_text += '\nCurrent BPM: ${Conductor.bpm}';
			_text += '\nNotes Rendering: ${PlayState.notesLength-1}';
			_text += '\nNotes Left to Render: ${PlayState.unspawnNotesLength-1}';
			this.text.text = _text;
		} else {
			_text = 'Current Song Position: ${FlxStringUtil.formatTime(Conductor.songPosition / 1000, true)}';
			_text += '\n - ${PlayState.curBShit} beats';
			_text += '\n - ${PlayState.curSShit} steps';
			_text += '\nCurrent BPM: ${Conductor.bpm}';
			_text += '\nNotes Rendering: ${PlayState.notesLength}';
			_text += '\nNotes Left to Render: ${PlayState.unspawnNotesLength}';
			this.text.text = _text;
		}

		super.__enterFrame(t);
	}
}