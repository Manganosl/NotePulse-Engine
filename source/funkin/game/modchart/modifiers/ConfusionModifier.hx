package funkin.game.modchart.modifiers;

class ConfusionModifier extends NoteModifier {
    override function getName() return 'confusion';
    override function shouldExecute(player:Int, val:Float) return true;

    var cMain:Array<Modifier>;
    var cMainCol:Array<Array<Modifier>>;
    var cOff:Array<Modifier>;
    var cOffCol:Array<Array<Modifier>>;

    var sRoll:Modifier;
    var sTwirl:Modifier;
    var sDizzy:Modifier;
    var sNoteAngleX:Modifier;
    var sNoteAngleY:Modifier;
    var sNoteAngle:Modifier;
    var sRecAngleX:Modifier;
    var sRecAngleY:Modifier;
    var sRecAngle:Modifier;
    var cNoteAngleX:Array<Modifier>;
    var cNoteAngleY:Array<Modifier>;
    var cNoteAngle:Array<Modifier>;
    var cRecAngleX:Array<Modifier>;
    var cRecAngleY:Array<Modifier>;
    var cRecAngle:Array<Modifier>;

    override function bind(){
        cMain = [submods.get('confusionX'), submods.get('confusionY'), null];
        cMainCol = [bindColumn('confusionX'), bindColumn('confusionY'), bindColumn('confusion')];
        cOff = [submods.get('confusionXOffset'), submods.get('confusionYOffset'), submods.get('confusionOffset')];
        cOffCol = [bindColumn('confusionXOffset'), bindColumn('confusionYOffset'), bindColumn('confusionOffset')];

        sRoll = submods.get('roll');
        sTwirl = submods.get('twirl');
        sDizzy = submods.get('dizzy');
        sNoteAngleX = submods.get('noteAngleX');
        sNoteAngleY = submods.get('noteAngleY');
        sNoteAngle = submods.get('noteAngle');
        sRecAngleX = submods.get('receptorAngleX');
        sRecAngleY = submods.get('receptorAngleY');
        sRecAngle = submods.get('receptorAngle');
        cNoteAngleX = bindColumn('note', 'AngleX');
        cNoteAngleY = bindColumn('note', 'AngleY');
        cNoteAngle = bindColumn('note', 'Angle');
        cRecAngleX = bindColumn('receptor', 'AngleX');
        cRecAngleY = bindColumn('receptor', 'AngleY');
        cRecAngle = bindColumn('receptor', 'Angle');
    }

    function getConfusion(axis:Int, beat:Float, column:Int, player:Int, onlyOffset:Bool = false){
        var mainAngle:Float = 0;
        if(!onlyOffset){
            var main = (axis == 2) ? getValue(player) : subVal(cMain[axis], player);
            main += colVal(cMainCol[axis], column, player);
            mainAngle = -((beat * main) % 360);
        }
        var constAngle:Float = subVal(cOff[axis], player) + colVal(cOffCol[axis], column, player);
        return mainAngle + constAngle;
    }

    override function getOrder() return Modifier.ModifierOrder.LAST + 200;

    override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:DrawInstruction, data:Int, player:Int, obj:FlxSprite){
        if(obj is Note){
            var note:Note = cast obj;
            if(note.isSustainNote) return pos;

            var angleX:Float = getConfusion(0, beat, data, player);
            var angleY:Float = getConfusion(1, beat, data, player);
            var angleZ:Float = getConfusion(2, beat, data, player);

            var yPos:Float = pos.y;

            angleX += subVal(sRoll, player) * yPos * 0.5;
            angleY += subVal(sTwirl, player) * yPos * 0.5;
            angleX += subVal(sNoteAngleX, player) + colVal(cNoteAngleX, data, player);
            angleY += subVal(sNoteAngleY, player) + colVal(cNoteAngleY, data, player);

            angleZ += (beat * subVal(sDizzy, player) % 360) * (180 / Math.PI);
            angleZ += subVal(sNoteAngle, player) + colVal(cNoteAngle, data, player);

            pos.addAngle(angleX, angleY, angleZ + note.offsetAngle);
        } else {
            var angleX:Float = getConfusion(0, beat, data, player);
            var angleY:Float = getConfusion(1, beat, data, player);
            var angleZ:Float = getConfusion(2, beat, data, player);

            angleX += subVal(sRecAngleX, player) + colVal(cRecAngleX, data, player);
            angleY += subVal(sRecAngleY, player) + colVal(cRecAngleY, data, player);
            angleZ += subVal(sRecAngle, player) + colVal(cRecAngle, data, player);

            pos.addAngle(angleX, angleY, angleZ);
        }
        return pos;
    }

    override function getSubmods(){
        var subMods:Array<String> = [
            "confusionOffset",
            "confusionX",
            "confusionY",
            "confusionXOffset",
            "confusionYOffset",
            "noteAngleX",
            "receptorAngleX",
            "noteAngleY",
            "receptorAngleY",
            "noteAngle", 
            "receptorAngle",
            "roll",
            "twirl",
            "dizzy"
        ];

        for(i in 0...PlayState.SONG.mania+1){
            subMods.push('note${i}AngleX');
            subMods.push('receptor${i}AngleX');
            subMods.push('note${i}AngleY');
            subMods.push('receptor${i}AngleY');
            subMods.push('note${i}Angle');
            subMods.push('receptor${i}Angle');
            subMods.push('confusion${i}');
            subMods.push('confusionOffset${i}');
            subMods.push('confusionX${i}');
            subMods.push('confusionXOffset${i}');
            subMods.push('confusionY${i}');
            subMods.push('confusionYOffset${i}');
        }

        return subMods;
    }
}