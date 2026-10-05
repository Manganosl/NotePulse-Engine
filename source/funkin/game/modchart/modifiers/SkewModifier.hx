package funkin.game.modchart.modifiers;

class SkewModifier extends NoteModifier {
    override function getName() return 'skewX';
    override function getOrder() return PRE_REVERSE;

    var sSkewY:Modifier;
    var sNoteSkewX:Modifier;
    var sNoteSkewY:Modifier;
    var cSkewX:Array<Modifier>;
    var cSkewY:Array<Modifier>;
    var cNoteSkewX:Array<Modifier>;
    var cNoteSkewY:Array<Modifier>;

    override function bind() {
        sSkewY = submods.get("skewY");
        sNoteSkewX = submods.get("noteSkewX");
        sNoteSkewY = submods.get("noteSkewY");
        cSkewX = bindColumn('skewX');
        cSkewY = bindColumn('skewY');
        cNoteSkewX = bindColumn('noteSkewX');
        cNoteSkewY = bindColumn('noteSkewY');
    }

    var _kx:Float = 0;
    var _ky:Float = 0;
    function computeSkew(isNote:Bool, data:Int, player:Int):Void {
        if(isNote){
            _kx = subVal(sNoteSkewX, player) + colVal(cNoteSkewX, data, player);
            _ky = subVal(sNoteSkewY, player) + colVal(cNoteSkewY, data, player);
        } else {
            _kx = getValue(player) + colVal(cSkewX, data, player);
            _ky = subVal(sSkewY, player) + colVal(cSkewY, data, player);
        }
    }
    
    override function shouldExecute(player:Int, val:Float) return true;
    override function ignorePos() return false;
    override function ignoreUpdateReceptor() return false;
    override function ignoreUpdateNote() return false;

    override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int) {
        if(note.isSustainNote) return;
        computeSkew(true, note.noteData, player);
        note.skewOffset.set(_kx, _ky);
    }

    override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int) {
        computeSkew(false, receptor.noteData, player);
        receptor.skewOffset.set(_kx, _ky);
    }

    override function getSubmods() {
        var subMods:Array<String> = ["skewY", "noteSkewX", "noteSkewY"];
        for (i in 0...PlayState.SONG.mania) {
            subMods.push('skewX${i}');
            subMods.push('skewY${i}');
            subMods.push('noteSkewX${i}');
            subMods.push('noteSkewY${i}');
        }
        return subMods;
    }
}