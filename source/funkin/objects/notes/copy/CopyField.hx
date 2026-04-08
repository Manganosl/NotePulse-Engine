package funkin.objects.notes.copy;

import funkin.objects.notes.PlayField;
import funkin.objects.notes.Note;

class CopyField extends PlayField {
    public var sourceField:PlayField;
    
    public var noteMap:Map<Note, CopyNote> = new Map();

    override public function new(sourceField:PlayField) {
        this.sourceField = sourceField;

        super();

        for (strum in members.copy()) {
            strum.destroy();
            remove(strum, true);
        }
        members.splice(0, members.length);
        
        for (strum in sourceField.members) {
            var babyArrow:CopyStrum = new CopyStrum(strum, this);
            babyArrow.playAnim("static", true);
            babyArrow.parentField = this;
            add(babyArrow);
            babyArrow.postAddedToGroup();
        }
        adaptStrumline();
    }

    override function update(elapsed:Float) {
        syncNotes();

        super.update(elapsed);
    }

    public function syncNotes() {
        if (sourceField == null) return;

        for (note in sourceField.notes) {
            if (!noteMap.exists(note)) {
                var copy = new CopyNote(note, this);
                noteMap.set(note, copy);
                notes.push(copy); 
            }
        }
    }

    override public function forEachNote(func:Note->Void, onlySpawnedNotes = false){
        syncNotes();
		for (note in notes){
			if (note != null && note.exists && note.alive){
                var castedNote = cast(note, CopyNote);
				if(onlySpawnedNotes){
					if(castedNote.sourceNote.spawned){
						func(note);
					}
				} else func(note);
			}
		}
	}

    override public function destroy() {
        noteMap.clear();
        super.destroy();
    }
}