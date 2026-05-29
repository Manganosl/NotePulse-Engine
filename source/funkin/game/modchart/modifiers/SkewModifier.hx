package funkin.game.modchart.modifiers;

class SkewModifier extends NoteModifier {
    override function getName() return 'skewX';
    override function getOrder() return PRE_REVERSE;

    function getSkew(isNote:Bool, data:Int, player:Int):Array<Float> {
        var skew:Array<Float> = [0, 0];

        skew[0] = getValue(player);
        skew[1] = getSubmodValue("skewY", player);

        skew[0] += getSubmodValue('skewX${data}', player);
        skew[1] += getSubmodValue('skewY${data}', player);

        if(isNote){
            skew[0] = getSubmodValue("noteSkewX", player);
            skew[1] = getSubmodValue("noteSkewY", player);

            skew[0] += getSubmodValue('noteSkewX${data}', player);
            skew[1] += getSubmodValue('noteSkewY${data}', player);
        }

        return skew;
    }
    
    override function shouldExecute(player:Int, val:Float) return true;
    override function ignorePos() return false;
    override function ignoreUpdateReceptor() return false;
    override function ignoreUpdateNote() return false;

    override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int) {
        if(note.isSustainNote) return;
        var skew:Array<Float> = getSkew(true, note.noteData, player);
        note.skewOffset.set(skew[0], skew[1]);
    }

    override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int) {
        var skew:Array<Float> = getSkew(false, receptor.noteData, player);
        receptor.skewOffset.set(skew[0], skew[1]);
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