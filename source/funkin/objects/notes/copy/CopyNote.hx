package funkin.objects.notes.copy;

import funkin.objects.notes.Note;
import funkin.objects.notes.PlayField;

class CopyNote extends Note {
    public var sourceNote:Note;

    public function new(sourceNote:Note, sourceField:PlayField) {
        this.sourceNote = sourceNote;
        
        super(sourceNote.strumTime, sourceNote.noteData, sourceNote.prevNote, sourceNote.isSustainNote, false, null, true);
        
        this.playField = sourceField;
        
        this.graphic = sourceNote.graphic;
        this.isSustainNote = sourceNote.isSustainNote;
        this.isSustainEnd = sourceNote.isSustainEnd;
        this.frames = sourceNote.frames;
        
        if (sourceNote.parent != null) this.parent = sourceNote.parent;

        sourceNote.copyingNotes.push(this);

        rgbShader = sourceNote.rgbShader;
        shader = sourceNote.shader;

        this.hitHealth = 0;
        this.missHealth = 0;

        syncValues();

        if (isSustainNote && !isSustainEnd) {
            this.scale.y = sourceNote.scale.y;
        }
    }

    override function destroy() {
        super.destroy();
        var castedField = cast(playField, CopyField);
        castedField.noteMap.remove(sourceNote);
        castedField.notes.remove(this);
        sourceNote.copyingNotes.remove(this);
    }

    override function update(elapsed:Float) {
        syncValues();

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

        this.clipRect = sourceNote.clipRect;
        
        if (sourceNote.animation != null && sourceNote.animation.curAnim != null) {
            var animName:String = sourceNote.animation.curAnim.name;
            
            if (this.animation != null) {
                if (this.animation.curAnim == null || this.animation.curAnim.name != animName) {
                    this.animation.play(animName, true);
                }
                
                if (this.animation.curAnim != null) {
                    this.animation.curAnim.curFrame = sourceNote.animation.curAnim.curFrame;
                }
            }
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