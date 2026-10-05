package funkin.game.modchart.modifiers;

using StringTools;
// NOTE: THIS SHOULDNT HAVE ITS PERCENTAGE MODIFIED
// THIS IS JUST HERE TO ALLOW OTHER MODIFIERS TO HAVE PERSPECTIVE

// did my research
// i now know what a frustrum is lmao
// stuff ill forget after tonight

// its the next day and yea i forgot already LOL
// something somethng clipping idk

// either way
// perspective projection woo

class PerspectiveModifier extends NoteModifier {
  override function getName()return 'perspectiveDONTUSE';
	override function getOrder()
		return Modifier.ModifierOrder.LAST + 100;
  override function shouldExecute(player:Int, val:Float)return true;

  var fov = Math.PI/2;
  var near = 0.01;
  var far = 2;

  public var cullZ:Float = 0.1;  // I hate it when the notes are so big

  function FastTan(rad:Float) // thanks schmoovin
  {
    return FlxMath.fastSin(rad) / FlxMath.fastCos(rad);
  }

  var _ta:Float = 1;
  var _a:Float = 0;
  var _b:Float = 0;

  override function bind() {
    _ta = FastTan(fov/2);
    _a = (near+far)/(near-far);
    _b = 2*near*far/(near-far);
  }

  public function getVector(curZ:Float,pos:Vector3):Vector3 {
    var halfOffset = new Vector3((FlxG.width / 2) - (Note.swagWidth / 2), (FlxG.height / 2) - (Note.swagWidth / 2));
    var origAlpha = pos.alpha;
    var origGlow = pos.glow;
    pos = pos.subtract(halfOffset);
    var oX = pos.x;
    var oY = pos.y;

    var aspect = 1;

    var shit = curZ-1;
    if(shit>0)shit=0; // thanks schmovin!!

    var ta = FastTan(fov/2);
    var x = oX * aspect/ta;
    var y = oY/ta;
    var a = (near+far)/(near-far);
    var b = 2*near*far/(near-far);
    var z = (a*shit+b);
    var returnedVector = new Vector3(x/z,y/z,z, origAlpha, origGlow).add(halfOffset);

    return returnedVector;
  }

  override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite) {
    var hx = (FlxG.width / 2) - (Note.swagWidth / 2);
    var hy = (FlxG.height / 2) - (Note.swagWidth / 2);

    var oX = pos.x - hx;
    var oY = pos.y - hy;

    var shit = pos.z - 1;
    if (shit > 0) shit = 0; // thanks schmovin!!

    var aspect = 1;
    var x = oX * aspect / _ta;
    var y = oY / _ta;
    var z = (_a * shit + _b);

    var alpha = (z <= cullZ) ? 0.0 : pos.alpha;
    return new Vector3(x / z + hx, y / z + hy, z + 0.0, alpha, pos.glow);
  }

	override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int){
    receptor.scale.scale(1/pos.z);
  }
  
	override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int){
    note.scale.scale(1/pos.z);
  }
}