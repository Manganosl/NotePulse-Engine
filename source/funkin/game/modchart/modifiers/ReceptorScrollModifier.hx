package funkin.game.modchart.modifiers;

class ReceptorScrollModifier extends NoteModifier {
  var moveSpeed:Float = Conductor.crochet * 3; // gotta keep da sustain segments together so it doesnt look so shit
	override function getName()
		return 'receptorScroll';

  override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
  {
    if (getValue(player) == 0) return pos;

    var diff = timeDiff;
    var sPos = Conductor.songPosition;
    var vDiff = -(-diff - sPos) / moveSpeed;
    var reversed = Math.floor(vDiff)%2 == 0;

    var startY = pos.y;
    var revPerc = reversed ? 1-vDiff%1 : vDiff%1;
    // haha perc 30
    var upscrollOffset = 50;
    var downscrollOffset = FlxG.height - 150;

    var endY = upscrollOffset + ((downscrollOffset - Note.swagWidth * 0.5) * revPerc);

    pos.y = lerp(startY, endY, getValue(player));

    var songPos = sPos / moveSpeed;
    if (Math.floor(songPos) != Math.floor(vDiff))
      pos.alpha *= 0.5;

    return pos;
  }

	override function updateNote(beat:Float, daNote:Note, pos:Vector3, player:Int){
    if(getValue(player) == 0) return;
    if(daNote.isSustainNote && !daNote.isSustainEnd) return;
		var timeDiff = (daNote.strumTime - Conductor.songPosition);

		var diff = timeDiff;
		var sPos = Conductor.songPosition;

    var songPos = sPos / moveSpeed;
		var notePos = -(-diff - sPos) / moveSpeed;

		if(daNote.wasGoodHit) daNote.garbage=true;

  }
}
