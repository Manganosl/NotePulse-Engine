package funkin.game.modchart.modifiers;

class ScaleModifier extends NoteModifier {
    override function getName() return 'tiny';
    override function getOrder() return PRE_REVERSE;

    function getScale(sprite:Dynamic, scale:FlxPoint, data:Int, player:Int) {
        var y = scale.y;

        var zoom = getSubmodValue("zoom", player);
        var mini = getSubmodValue("mini", player);
        var zoomMult = 1 + (zoom - (mini * 0.5));

        scale.x *= zoomMult;
        scale.y *= zoomMult;

        scale.x *= 1 - getValue(player);
        scale.y *= 1 - getValue(player);

        scale.x *= getSubmodValue("scale", player);
        scale.y *= getSubmodValue("scale", player);

        var tinyX = getSubmodValue("tinyX", player) + getSubmodValue('tiny${data}X', player);
        var tinyY = getSubmodValue("tinyY", player) + getSubmodValue('tiny${data}Y', player);

        scale.x *= 1 - tinyX;
        scale.y *= 1 - tinyY;

        var scaleX = getSubmodValue("scaleX", player) + getSubmodValue('scale${data}X', player);
        var scaleY = getSubmodValue("scaleY", player) + getSubmodValue('scale${data}Y', player);

        scale.x *= scaleX;
        scale.y *= scaleY;

        var stretch = getSubmodValue("stretch", player) + getSubmodValue('stretch${data}', player);
        var squish = getSubmodValue("squish", player) + getSubmodValue('squish${data}', player);

        var stretchX = lerp(1, 0.5, stretch);
        var stretchY = lerp(1, 2, stretch);
        var squishX = lerp(1, 2, squish);
        var squishY = lerp(1, 0.5, squish);

        scale.x *= squishX * stretchX;
        scale.y *= squishY * stretchY;
        
        if ((sprite is Note) && sprite.isSustainNote)
            scale.y = y;

        return scale;
    }
    
    override function shouldExecute(player:Int, val:Float) return true;
    override function ignorePos() return false;
    override function ignoreUpdateReceptor() return false;
    override function ignoreUpdateNote() return false;

    override function updateNote(beat:Float, note:Note, pos:Vector3, player:Int) {
        var scale = getScale(note, FlxPoint.weak(note.defScale.x, note.defScale.y), note.noteData, player);
        if(note.isSustainNote) scale.y = note.defScale.y;
        
        note.scale.copyFrom(scale);
        scale.putWeak();
    }

    override function updateReceptor(beat:Float, receptor:StrumNote, pos:Vector3, player:Int) {
        var scale = getScale(receptor, FlxPoint.weak(receptor.defScale.x, receptor.defScale.y), receptor.noteData, player);
        receptor.scale.copyFrom(scale);
        scale.putWeak();
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
        var zoom = getSubmodValue("zoom", player);
        var mini = getSubmodValue("mini", player);

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