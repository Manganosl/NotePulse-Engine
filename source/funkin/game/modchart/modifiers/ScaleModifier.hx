package funkin.game.modchart.modifiers;

class ScaleModifier extends NoteModifier {
    override function getName() return 'tiny';
    override function getOrder() return PRE_REVERSE;

    var sZoom:Modifier;
    var sMini:Modifier;
    var sScale:Modifier;
    var sTinyX:Modifier;
    var sTinyY:Modifier;
    var sScaleX:Modifier;
    var sScaleY:Modifier;
    var sStretch:Modifier;
    var sSquish:Modifier;
    var cTinyX:Array<Modifier>;
    var cTinyY:Array<Modifier>;
    var cScaleX:Array<Modifier>;
    var cScaleY:Array<Modifier>;
    var cStretch:Array<Modifier>;
    var cSquish:Array<Modifier>;

    override function bind() {
        sZoom = submods.get("zoom");
        sMini = submods.get("mini");
        sScale = submods.get("scale");
        sTinyX = submods.get("tinyX");
        sTinyY = submods.get("tinyY");
        sScaleX = submods.get("scaleX");
        sScaleY = submods.get("scaleY");
        sStretch = submods.get("stretch");
        sSquish = submods.get("squish");
        cTinyX = bindColumn('tiny', 'X');
        cTinyY = bindColumn('tiny', 'Y');
        cScaleX = bindColumn('scale', 'X');
        cScaleY = bindColumn('scale', 'Y');
        cStretch = bindColumn('stretch');
        cSquish = bindColumn('squish');
    }

    var _sx:Float = 1;
    var _sy:Float = 1;

    function computeScale(baseX:Float, baseY:Float, isSustain:Bool, data:Int, player:Int) {
        var x = baseX;
        var y = baseY;

        var zoom = subVal(sZoom, player);
        var mini = subVal(sMini, player);
        var zoomMult = 1 + (zoom - (mini * 0.5));

        x *= zoomMult;
        y *= zoomMult;

        x *= 1 - getValue(player);
        y *= 1 - getValue(player);

        x *= subVal(sScale, player);
        y *= subVal(sScale, player);

        var tinyX = subVal(sTinyX, player) + colVal(cTinyX, data, player);
        var tinyY = subVal(sTinyY, player) + colVal(cTinyY, data, player);

        x *= 1 - tinyX;
        y *= 1 - tinyY;

        var scaleX = subVal(sScaleX, player) + colVal(cScaleX, data, player);
        var scaleY = subVal(sScaleY, player) + colVal(cScaleY, data, player);

        x *= scaleX;
        y *= scaleY;

        var stretch = subVal(sStretch, player) + colVal(cStretch, data, player);
        var squish = subVal(sSquish, player) + colVal(cSquish, data, player);

        var stretchX = lerp(1, 0.5, stretch);
        var stretchY = lerp(1, 2, stretch);
        var squishX = lerp(1, 2, squish);
        var squishY = lerp(1, 0.5, squish);

        x *= squishX * stretchX;
        y *= squishY * stretchY;
        
        if (isSustain)
            y = baseY;

        _sx = x;
        _sy = y;
    }
    
    override function shouldExecute(player:Int, val:Float) return true;
    override function ignorePos() return false;
    override function ignoreUpdateReceptor() return false;
    override function ignoreUpdateNote() return false;

    override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int) {
        computeScale(note.defScale.x, note.defScale.y, note.isSustainNote, note.noteData, player);
        if(note.isSustainNote) _sy = note.defScale.y;
        
        note.scale.set(_sx, _sy);
    }

    override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int) {
        computeScale(receptor.defScale.x, receptor.defScale.y, false, receptor.noteData, player);
        receptor.scale.set(_sx, _sy);
    }

    private var _origin:Vector3 = new Vector3(); 

    private function getFieldOrigin(field:PlayField):Vector3 {
        final FKC = field.keyCount;
        if (FKC % 2 == 0) {
            final RKN = Math.floor(FKC / 2);
            final LKN = RKN - 1;
            _origin.x = (field.members[LKN].x + field.members[RKN].x) * 0.5;
        } else {
            _origin.x = field.members[Math.floor(FKC / 2)].x;
        }
        _origin.y = flixel.FlxG.height * 0.5; 
        return _origin;
    }

    override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite) {
        var zoom = subVal(sZoom, player);
        var mini = subVal(sMini, player);

        if (zoom != 0 || mini != 0) {
            var zoomMult = 1 + (zoom - (mini * 0.5));
            var origin = getFieldOrigin(PlayField.fields[player]);

            pos.x = origin.x + (pos.x - origin.x) * zoomMult;
            pos.y = origin.y + (pos.y - origin.y) * zoomMult;
        }

        return pos;
    }

    override function getSubmods() {
        var subMods:Array<String> = ["mini", "zoom", "squish", "stretch", "tinyX", "tinyY", "scale", "scaleX", "scaleY"];
        for (i in 0...PlayState.SONG.mania) {
            subMods.push('tiny${i}X');
            subMods.push('tiny${i}Y');
            subMods.push('squish${i}');
            subMods.push('stretch${i}');
        }
        return subMods;
    }
}