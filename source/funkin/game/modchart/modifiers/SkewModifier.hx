package funkin.game.modchart.modifiers;

class SkewModifier extends NoteModifier {
    override function getName() return 'skewX';
    override function getOrder() return PRE_REVERSE;

    var sSkewY:Modifier;
    var sNoteSkewX:Modifier;
    var sNoteSkewY:Modifier;
    var sReceptorSkewX:Modifier;
    var sReceptorSkewY:Modifier;
    var cSkewX:Array<Modifier>;
    var cSkewY:Array<Modifier>;
    var cNoteSkewX:Array<Modifier>;
    var cNoteSkewY:Array<Modifier>;
    var cReceptorSkewX:Array<Modifier>;
    var cReceptorSkewY:Array<Modifier>;

    override function bind() {
        sSkewY = submods.get("skewY");
        sNoteSkewX = submods.get("noteSkewX");
        sNoteSkewY = submods.get("noteSkewY");
        sReceptorSkewX = submods.get("receptorSkewX");
        sReceptorSkewY = submods.get("receptorSkewY");
        cSkewX = bindColumn('skewX');
        cSkewY = bindColumn('skewY');
        cNoteSkewX = bindColumn('noteSkewX');
        cNoteSkewY = bindColumn('noteSkewY');
        cReceptorSkewX = bindColumn('receptorSkewX');
        cReceptorSkewY = bindColumn('repectorSkewY');
    }

    var _kx:Float = 0;
    var _ky:Float = 0;
    function computeSkew(isNote:Bool, data:Int, player:Int):Void {
        _kx = getValue(player) + colVal(cSkewX, data, player);
        _ky = subVal(sSkewY, player) + colVal(cSkewY, data, player);
        if(isNote){
            _kx += subVal(sNoteSkewX, player) + colVal(cNoteSkewX, data, player);
            _ky += subVal(sNoteSkewY, player) + colVal(cNoteSkewY, data, player);
        } else {
            _kx += subVal(sReceptorSkewX, player) + colVal(cReceptorSkewX, data, player);
            _ky += subVal(sReceptorSkewY, player) + colVal(cReceptorSkewY, data, player);
        }
    }
    
    override function shouldExecute(player:Int, val:Float) return true;
    override function ignorePos() return false;
    override function ignoreUpdateReceptor() return false;
    override function ignoreUpdateNote() return false;

    override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:DrawInstruction, data:Int, player:Int, obj:FlxSprite) {
        var note:Note = (obj is Note) ? cast obj : null;
        if(note != null && note.isSustainNote) return pos;
        computeSkew(note != null, data, player);
        pos.addSkew(_kx, _ky);
        return pos;
    }

    override function getSubmods() {
        var subMods:Array<String> = ["skewY", "noteSkewX", "noteSkewY", "receptorSkewX", "receptorSkewY"];
        for (i in 0...PlayState.SONG.mania) {
            subMods.push('skewX$i');
            subMods.push('skewY$i');
            subMods.push('noteSkewX$i');
            subMods.push('noteSkewY$i');
            subMods.push('receptorSkewX$i');
            subMods.push('receptorSkewY$i');
        }
        return subMods;
    }
}