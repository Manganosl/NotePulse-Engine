package funkin.game.modchart.modifiers;

class FreezeModifier extends NoteModifier {
    override function getName() return 'freeze';

    var sRate:Modifier;
    var sMove:Modifier;
    var sOffset:Modifier;
    var xmodNames:Array<String> = [];

    var _k:Float = 0.45;

    var _bPos:Float = -1e30;
    var _bBeat:Float = 0;

    override function bind() {
        sRate = submods.get("freezeRate");
        sMove = submods.get("freezeMove");
        sOffset = submods.get("freezeOffset");
    }

    inline function getXmodName(data:Int):String {
        xmodNames[data] ??= 'xmod$data';
        return xmodNames[data];
    }

    inline function songBeat():Float {
        var p = Conductor.songPosition;
        if (p != _bPos) {
            _bPos = p;
            _bBeat = Conductor.getStep(p) / 4;
        }
        return _bBeat;
    }

    override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:DrawInstruction, data:Int, player:Int, obj:FlxSprite) {
        var amount = getValue(player);
        if (amount == 0 || !(obj is Note)) return pos;

        var note:Note = cast obj;
        if (note.wasGoodHit) return pos;

        var rate = subVal(sRate, player);
        rate = rate == 0 ? 1 : Math.abs(rate);

        var moveVal = subVal(sMove, player);
        var move = moveVal <= 0 ? 0.1 : MathUtil.clamp(moveVal, 0.001, 1);

        var cycles = (songBeat() + subVal(sOffset, player)) * rate;
        var phase = cycles - Math.floor(cycles);

        var lag = phase < move ? (1 - move) * (1 - phase / move) : phase - move;
        var lagMs = (lag / rate) * Conductor.crochet;

        var k:Float;
        if (Math.abs(timeDiff) > 1) {
            k = visualDiff / timeDiff;
            _k = k;
        } else {
            var pf:Dynamic = note.createdFrom;
            var s:Dynamic = pf != null ? pf.songSpeed : null;
            k = s != null ? 0.45 * cast(s, Float) : _k;
        }

        var speed = modMgr.getValue('xmod', player) * modMgr.getValue(getXmodName(data), player) * note.multSpeed;

        var rev = modMgr.reverseMod;
        var reversePercent = rev != null ? rev.getReverseValue(data, player) : 0;
        var mult = MathUtil.scale(reversePercent, 0, 1, 1, -1);

        pos.y += k * lagMs * amount * speed * mult;

        return pos;
    }

    override function getSubmods() {
        return ["freezeRate", "freezeMove", "freezeOffset"];
    }
}