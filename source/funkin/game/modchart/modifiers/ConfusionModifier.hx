package funkin.game.modchart.modifiers;

class ConfusionModifier extends NoteModifier {
    override function getName() return 'confusion';
    override function shouldExecute(player:Int, val:Float) return true;

    function getConfusion(suffix:String = '', beat:Float, column:Int, player:Int, onlyOffset:Bool = false) {
        var mainAngle:Float = 0;
        if (!onlyOffset) {
            var main = (suffix.length == 0) ? getValue(player) : getSubmodValue('confusion$suffix', player);
            main += getColumnSubmodValue('confusion$suffix', column, player);
            mainAngle = -((beat * main) % 360);
        }
        var constAngle:Float = getSubmodValue('confusion${suffix}Offset', player) + getColumnSubmodValue('confusion${suffix}Offset', column, player);
        return mainAngle + constAngle;
    }

    override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int) {
        if(note.isSustainNote) {
            note.angle = note.mAngle + note.offsetAngle;
            return;
        }
        var data:Int = note.noteData;
        
        var angleX:Float = getConfusion("X", beat, data, player);
        var angleY:Float = getConfusion("Y", beat, data, player);
        var angleZ:Float = getConfusion("", beat, data, player);

        var yPos:Float = pos.y;
        
        angleX += getSubmodValue("roll", player) * yPos * 0.5;
        angleY += getSubmodValue("twirl", player) * yPos * 0.5;
        angleX += getSubmodValue("noteAngleX", player) + getColumnSubmodValue('note', data, player, 'AngleX');
        angleY += getSubmodValue("noteAngleY", player) + getColumnSubmodValue('note', data, player, 'AngleY');

        angleZ += (beat * getSubmodValue("dizzy", player) % 360) * (180 / Math.PI);
        angleZ += getSubmodValue("noteAngle", player) + getColumnSubmodValue('note', data, player, 'Angle');

        //if (note.rgbShader != null) {
        //    note.rgbShader.angleX = angleX * (Math.PI / 180);
        //    note.rgbShader.angleY = angleY * (Math.PI / 180);
        //}
        
        note.angle = angleZ + note.offsetAngle;
    }

    override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int) {
        var data:Int = receptor.noteData;
        
        var angleX:Float = getConfusion("X", beat, data, player);
        var angleY:Float = getConfusion("Y", beat, data, player);
        var angleZ:Float = getConfusion("", beat, data, player);

        angleX += getSubmodValue("receptorAngleX", player) + getColumnSubmodValue('receptor', data, player, 'AngleX');
        angleY += getSubmodValue("receptorAngleY", player) + getColumnSubmodValue('receptor', data, player, 'AngleY');
        angleZ += getSubmodValue("receptorAngle", player) + getColumnSubmodValue('receptor', data, player, 'Angle');

        //if (receptor.rgbShader != null) {
        //    receptor.rgbShader.angleX = angleX * (Math.PI / 180);
        //    receptor.rgbShader.angleY = angleY * (Math.PI / 180);
        //}
        
        receptor.angle = angleZ;
    }

    override function getSubmods() {
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

        for(i in 0...PlayState.SONG.mania+1) {
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