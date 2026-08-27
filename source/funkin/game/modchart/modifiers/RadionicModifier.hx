package funkin.game.modchart.modifiers;

class RadionicModifier extends NoteModifier {
  var arrowSize:Float = Note.swagWidth;
  var zPulseAmount:Float = 80;

  override function getName()
    return 'radionic';

  override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite):Vector3
  {
    var perc = getValue(player);
    if (perc == 0) return pos;

    var angle = ((1 / Conductor.crochet) * ((Conductor.songPosition + timeDiff) * Math.PI * 0.25)) + (Math.PI * player);

    var offsetX = pos.x - PlayField.fields[player].members[data].x;
    var offsetY = 0.0;

    var circf = arrowSize + data * arrowSize;

    var sinAng = Math.sin(angle);
    var cosAng = Math.cos(angle);

    var targetX = FlxG.width * 0.5 + ((sinAng * offsetY + cosAng * (circf + offsetX)) * 0.7) * 1.125;
    var targetY = FlxG.height * 0.5 + ((cosAng * offsetY + sinAng * (circf + offsetX)) * 0.7) * 0.875;

    pos.x = lerp(pos.x, targetX, perc);
    pos.y = lerp(pos.y, targetY, perc);

    var amount = 0.6;
    var beatFrac = beat - Math.floor(beat);
    var ease = FlxEase.cubeOut(beatFrac);
    var pulseFactor = 1 + amount - ease * amount;
    var zOffset = (pulseFactor - 1) * zPulseAmount;

    pos.z = lerp(pos.z, pos.z + zOffset, perc) / 1280;

    return pos;
  }
}