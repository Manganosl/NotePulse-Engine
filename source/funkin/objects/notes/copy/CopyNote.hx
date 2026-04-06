package funkin.objects.notes.copy;

import funkin.objects.notes.Note;
import funkin.objects.notes.PlayField;

class CopyNote extends Note {
    public var sourceNote:Note;

    public function new(sourceNote:Note, sourceField:PlayField) {
        this.sourceNote = sourceNote;
        
        super(sourceNote.strumTime, sourceNote.noteData, sourceNote.prevNote, sourceNote.isSustainNote, false, null, true);
        
        this.playField = sourceField;
        
        this.isSustainEnd = sourceNote.isSustainEnd;
        this.frames = sourceNote.frames;
        this.animation = sourceNote.animation;
        
        if (sourceNote.parent != null) this.parent = sourceNote.parent;

        sourceNote.copyingNotes.push(this);

        syncValues();
    }

    override function destroy() {
        super.destroy();
        cast(playField, CopyField).noteMap.remove(sourceNote);
        sourceNote.copyingNotes.remove(this);
    }

    override function update(elapsed:Float) {
        syncValues();

        super.update(elapsed);

        if (sourceNote != null && !sourceNote.exists) {
            this.kill();
        }
    }

    public function syncValues() {
        if (sourceNote == null || !sourceNote.exists) return;

        this.strumTime = sourceNote.strumTime;
        this.sustainLength = sourceNote.sustainLength;
        this.canBeHit = sourceNote.canBeHit;
        this.tooLate = sourceNote.tooLate;
        this.wasGoodHit = sourceNote.wasGoodHit;
        this.missed = sourceNote.missed;
        this.hitByOpponent = sourceNote.hitByOpponent;
        this.noteWasHit = sourceNote.noteWasHit;
        
        this.row = sourceNote.row;
        this.characters = sourceNote.characters;
        this.noteData = sourceNote.noteData;
        this.noteType = sourceNote.noteType;
        this.ignoreNote = sourceNote.ignoreNote;
        this.lowPriority = sourceNote.lowPriority;
        
        this.hitHealth = sourceNote.hitHealth;
        this.missHealth = sourceNote.missHealth;
        this.copyX = sourceNote.copyX;
        this.copyY = sourceNote.copyY;
        this.copyAngle = sourceNote.copyAngle;

        if(this.spawned != sourceNote.spawned) {
            this.spawned = sourceNote.spawned;
            if(spawned){
                if(sourceNote.createdFrom != null){
                    sourceNote.createdFrom.add(this);
                    trace("Added a copy note to the original note's createdFrom list.");
                }
            } else {
                if(sourceNote.createdFrom != null){
                    sourceNote.createdFrom.remove(this);
                    trace("Removed a copy note from the original note's createdFrom list.");
                }
            }
        }
        
        if (sourceNote.animation != null && sourceNote.animation.curAnim != null) {
            var animName:String = sourceNote.animation.curAnim.name;
            
            if (this.animation != null) {
                if (this.animation.curAnim == null || this.animation.curAnim.name != animName) {
                    this.animation.play(animName, true);
                }
            }
        }

        if (isSustainNote && !isSustainEnd) {
            this.scale.y = sourceNote.scale.y;
        }
    }

    override function set_noteType(value:String):String {
        if(noteType != value) {
            noteType = value;
            reloadNote(null);
        }
        return value;
    }

    override function set_texture(value:String):String {
        if(texture != value) {
            texture = value;
            reloadNote(value);
        }
        return value;
    }
}