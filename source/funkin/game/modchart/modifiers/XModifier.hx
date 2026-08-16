package funkin.game.modchart.modifiers;

class XModifier extends NoteModifier {
    override function getName()
        return 'xmod';

    override function shouldExecute(player:Int, val:Float)
        return true;

    override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:flixel.FlxSprite)
    {
        var xmod = getValue(player) * getSubmodValue('xmod' + data, player);
        var note:Note = (obj is Note) ? cast obj : null;
        var multSpeed:Float = (note != null) ? note.multSpeed : 1;

		var reverse:Dynamic = modMgr.register.get("reverse");
		var reversePercent = reverse.getReverseValue(data, player);
		var mult = MathUtil.scale(reversePercent, 0, 1, 1, -1);

        var speed = xmod * multSpeed;

        pos.y += visualDiff * (speed - 1) * mult;

        return pos;
    }

    override function updateNote(beat:Float, daNote:Note, pos:Vector3, player:Int)
    {
        var xmod = getValue(player) * getSubmodValue('xmod' + daNote.noteData, player);
        daNote.modSpeed = xmod;
    }

    override function getSubmods()
    {
        var subMods:Array<String> = [];
        for (i in 0...PlayState.SONG.mania+1)
            subMods.push('xmod$i');

        return subMods;
    }
}