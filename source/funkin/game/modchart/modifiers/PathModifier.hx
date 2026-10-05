package funkin.game.modchart.modifiers;

import flixel.math.FlxAngle;

typedef PathInfo = {
  var position:Vector3;
  var dist:Float;
  var start:Float;
  var end:Float;
}

class PathModifier extends NoteModifier {
  var moveSpeed:Float;
  var pathData:Array<Array<PathInfo>> = [];
  var totalDists:Array<Float> = [];

  static final PI_THIRD:Float = Math.PI / 3.0;

  override function getName() return 'basePath';

  inline function getDigitalAngle(yOffset:Float, offset:Float, period:Float) {
    return Math.PI * (yOffset + (1 * offset)) / (Note.swagWidth + (period * Note.swagWidth));
  }

  public function getMoveSpeed() {
    return 5000;
  }

  public function getPath():Array<Array<Vector3>> {
    return [];
  }

  public function new(modMgr:ModManager, ?parent:Modifier) {
    super(modMgr, parent);
    moveSpeed = getMoveSpeed();
    var path:Array<Array<Vector3>> = getPath();
    for (dir in 0...path.length) {
      var idx = 0;
      totalDists[dir] = 0;
      pathData[dir] = [];
      while (idx < path[dir].length) {
        var pos = path[dir][idx];

        if (idx != 0) {
          var last = pathData[dir][idx - 1];
          totalDists[dir] += Math.abs(Vector3.distance(last.position, pos));
          var totalDist = totalDists[dir];
          last.end = totalDist;
          last.dist = last.start - totalDist;
        }

        pathData[dir].push({
          position: pos.add(new Vector3(-Note.swagWidth / 2, -Note.swagWidth / 2)),
          start: totalDists[dir],
          end: 0,
          dist: 0
        });
        idx++;
      }
    }
  }

  inline function lerpInto(pos:Vector3, gx:Float, gy:Float, gz:Float, ga:Float, gg:Float, t:Float) {
    var rx = t * gx + pos.x * (1 - t);
    var ry = t * gy + pos.y * (1 - t);
    var rz = t * gz + pos.z * (1 - t);
    var ra = t * ga + pos.alpha * (1 - t);
    var rg = t * gg + pos.glow * (1 - t);
    pos.setTo(rx, ry, rz, ra, rg);
  }

  var sZigzag:Modifier;
  var sZigzagZ:Modifier;
  var sSawtooth:Modifier;
  var sSquare:Modifier;
  var sBounce:Modifier;
  var sBounceZ:Modifier;
  var sXmode:Modifier;
  var sZmode:Modifier;
  var sTornado:Modifier;
  var sTornadoTan:Modifier;
  var sTornadoZ:Modifier;
  var sTornadoTanZ:Modifier;
  var sItg:Modifier;
  var sItgTan:Modifier;
  var sDigital:Modifier;
  var sDigitalZ:Modifier;
  var cXmode:Array<Modifier>;
  var cZmode:Array<Modifier>;

  override function bind() {
    sZigzag = submods.get("zigzag");
    sZigzagZ = submods.get("zigzagZ");
    sSawtooth = submods.get("sawtooth");
    sSquare = submods.get("square");
    sBounce = submods.get("bounce");
    sBounceZ = submods.get("bounceZ");
    sXmode = submods.get("xmode");
    sZmode = submods.get("zmode");
    sTornado = submods.get("tornado");
    sTornadoTan = submods.get("tornadoTan");
    sTornadoZ = submods.get("tornadoZ");
    sTornadoTanZ = submods.get("tornadoTanZ");
    sItg = submods.get("itgTornado");
    sItgTan = submods.get("itgTornadoTan");
    sDigital = submods.get("digital");
    sDigitalZ = submods.get("digitalZ");
    cXmode = bindColumn("xmode");
    cZmode = bindColumn("zmode");
  }

  override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite) {
    var outPos = pos.clone();

    var pathVal = getValue(player);
    if (pathVal != 0) {
      var vDiff = -timeDiff;
      var progress = (vDiff / -moveSpeed) * totalDists[data];
      var daPath = pathData[data];

      if (daPath != null && daPath.length > 0) {
        if (progress <= 0) {
          var g = daPath[0].position;
          lerpInto(outPos, g.x, g.y, g.z, g.alpha, g.glow, pathVal);
        } else {
          var idx:Int = 0;
          while (idx < daPath.length) {
            var cData = daPath[idx];
            var nData = daPath[idx + 1];
            if (nData != null && cData != null) {
              if (progress > cData.start && progress < cData.end) {
                var alpha = (cData.start - progress) / cData.dist;
                var c = cData.position;
                var n = nData.position;

                var ix = alpha * n.x + c.x * (1 - alpha);
                var iy = alpha * n.y + c.y * (1 - alpha);
                var iz = alpha * n.z + c.z * (1 - alpha);
                var ia = alpha * n.alpha + c.alpha * (1 - alpha);
                var ig = alpha * n.glow + c.glow * (1 - alpha);
                lerpInto(outPos, ix, iy, iz, ia, ig, pathVal);
                break;
              }
            }
            idx++;
          }
        }
      }
    }

    var diff = visualDiff;
    var column = data;
    var keyCunt:Int = PlayState.SONG.mania;
    var keyCount:Int = keyCunt + 1;

    var zigzag = subVal(sZigzag, player);
    if (zigzag != 0) {
      var offset = getSubmodValue("zigzagOffset", player);
      var period = getSubmodValue("zigzagPeriod", player);
      var result:Float = MathUtil.triangle((Math.PI * (1 / (period + 1)) * ((diff + 100 * offset) / Note.swagWidth)));
      outPos.x += (zigzag * (Note.swagWidth * 0.5)) * result;
    }

    var zigzagZ = subVal(sZigzagZ, player);
    if (zigzagZ != 0) {
      var offset = getSubmodValue("zigzagZOffset", player);
      var period = getSubmodValue("zigzagZPeriod", player);
      var result:Float = MathUtil.triangle((Math.PI * (1 / (period + 1)) * ((diff + 100 * offset) / Note.swagWidth)));
      outPos.z += ((zigzagZ * (Note.swagWidth * 0.5)) * result) / 1280;
    }

    var sawtooth = subVal(sSawtooth, player);
    if (sawtooth != 0) {
      var period = getSubmodValue("sawtoothPeriod", player) + 1;
      var p = (0.5 / period * diff) / Note.swagWidth;
      outPos.x += (sawtooth * Note.swagWidth) * (p - Math.floor(p));
    }

    var squareVal = subVal(sSquare, player);
    if(squareVal != 0){
      var offset = getSubmodPercent("squareOffset", player) * 100;
      var period = 60 + (getSubmodPercent("squarePeriod", player) * 60);
      var cum:Float = (Math.PI * (visualDiff + offset) / period);
      outPos.x += squareVal * MathUtil.square(cum) * getSubmodValue("squareAmp", player) * Math.min(1, Math.abs(visualDiff) / 200);
    }

    var bounceVal = subVal(sBounce, player);
    if (bounceVal != 0) {
      var offset = getSubmodValue("bounceOffset", player);
      var period = getSubmodValue("bouncePeriod", player);
      if (period != -1.0) {
        var bounce = Math.abs(Math.sin((diff + offset) / (90.0 + 90.0 * period)));
        outPos.x += bounceVal * (Note.swagWidth * 0.5) * bounce;
      }
    }

    var bounceZVal = subVal(sBounceZ, player);
    if (bounceZVal != 0) {
      var offset = getSubmodValue("bounceZOffset", player);
      var period = getSubmodValue("bounceZPeriod", player);
      if (period != -1.0) {
        var bounce = Math.abs(Math.sin((diff + offset) / (90.0 + 90.0 * period)));
        outPos.z += (bounceZVal * (Note.swagWidth * 0.5) * bounce) / 1280;
      }
    }

    // I'll use this mod to handle Psych's note directions
    var xmode = subVal(sXmode, player) + colVal(cXmode, data, player);
    var noteDegrees:Float = xmode != 0 ? (PlayField.fields[player].members[data].direction - 90) : 0;
    if (xmode != 0 && noteDegrees != 0) {
      var mod = (player + 1) * 2 - 3;
      if(obj is Note) noteDegrees += cast(obj, Note).offsetDirection;
      outPos.x += (xmode + FlxAngle.asRadians(noteDegrees)) * (diff * mod);
    }

    var zmode = subVal(sZmode, player) + colVal(cZmode, data, player);
    if (zmode != 0) {
      var mod = (player + 1) * 2 - 3;
      outPos.z += (zmode * (diff * mod)) / 1280;
    }

    var tornadoVal = subVal(sTornado, player);
    if (tornadoVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoOffset", player);
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.cos(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.cos(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.x += offsetX * tornadoVal;
    }

    var tornadoTanVal = subVal(sTornadoTan, player);
    if (tornadoTanVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoTanOffset", player);
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoTanPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.cos(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.tan(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.x += offsetX * tornadoTanVal;
    }

    var tornadoZVal = subVal(sTornadoZ, player);
    if (tornadoZVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoZOffset", player);
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoZPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.sin(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.sin(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.z += (offsetX * tornadoZVal) / 1280;
    }

    var tornadoTanZVal = subVal(sTornadoTanZ, player);
    if (tornadoTanZVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoTanZOffset", player) + Math.PI;
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoTanZPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.sin(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.tan(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.z += (offsetX * tornadoTanZVal) / 1280;
    }

    var itgTornadoVal = subVal(sItg, player);
    var itgTornadoTanVal = subVal(sItgTan, player);

    if (itgTornadoVal != 0 || itgTornadoTanVal != 0) {
      var wide = keyCount > 4;
      var width = wide ? 2 : 3;
      var startColumn:Int = Std.int(MathUtil.boundTo(column - width, 0, keyCount - 1));
      var endColumn:Int = Std.int(MathUtil.boundTo(column + width, 0, keyCount - 1));

      var minX = startColumn * Note.swagWidth;
      var maxX = endColumn * Note.swagWidth;
      var realPixel = column * Note.swagWidth;

      var posBetween = MathUtil.scale(realPixel, minX, maxX, -1, 1);

      if (itgTornadoVal != 0) {
        var rads = Math.acos(posBetween);
        var period = getSubmodValue("itgTornadoPeriod", player);
        var offset = getSubmodValue("itgTornadoOffset", player);
        rads += (diff + offset) * (6 + period * 6) / FlxG.height;
        var adjusted = MathUtil.scale(Math.cos(rads), -1, 1, minX, maxX);
        outPos.x += (adjusted - realPixel) * itgTornadoVal;
      }

      if (itgTornadoTanVal != 0) {
        var rads = Math.acos(posBetween);
        var period = getSubmodValue("itgTornadoTanPeriod", player);
        var offset = getSubmodValue("itgTornadoTanOffset", player);
        rads += (diff + offset) * (6 + period * 6) / FlxG.height;
        var adjusted = MathUtil.scale(Math.tan(rads), -1, 1, minX, maxX);
        outPos.x += (adjusted - realPixel) * itgTornadoTanVal;
      }
    }

    var digitalVal = subVal(sDigital, player);
    if (digitalVal > 0) {
      var steps = this.getSubmodValue("digitalSteps", player) + 1;
      var period = this.getSubmodValue("digitalPeriod", player);
      var offset = this.getSubmodValue("digitalOffset", player);

      outPos.x += (digitalVal * (Note.swagWidth * 0.5)) * Math.floor(0.5 + (steps * Math.sin(getDigitalAngle(diff, offset, period)))) / steps;
    }

    var digitalZVal = subVal(sDigitalZ, player);
    if (digitalZVal > 0) {
      var steps = this.getSubmodValue("digitalZSteps", player) + 1;
      var period = this.getSubmodValue("digitalZPeriod", player);
      var offset = this.getSubmodValue("digitalZOffset", player);

      outPos.z += ((digitalZVal * (Note.swagWidth * 0.5)) * Math.floor(0.5 + (steps * Math.sin(getDigitalAngle(diff, offset, period)))) / steps) / 1280;
    }

    return outPos;
  }

  override function getSubmods(){
    var submods = [
      'tornado',
      'xmode',
      'ymode',
      'zmode',
      'zigzag',
      'zigzagPeriod',
      'zigzagOffset',
      'sawtooth',
      'sawtoothPeriod',
      'square',
      'squareOffset',
      'squarePeriod',
      'squareAmp',
      'bounce',
      'bounceOffset',
      'bouncePeriod',
      'zigzagZ',
      'zigzagZPeriod',
      'zigzagZOffset',
      'bounceZ',
      'bounceZOffset',
      'bounceZPeriod',
      'digital',
      'digitalSteps',
      'digitalOffset',
      'digitalPeriod',
      'digitalZ',
      'digitalZSteps',
      'digitalZOffset',
      'digitalZPeriod',
      'tornadoPeriod',
      'tornadoOffset',
      'tornadoZ',
      'tornadoZPeriod',
      'tornadoZOffset',
      'tornadoTan',
      'tornadoTanPeriod',
      'tornadoTanOffset',
      'tornadoTanZ',
      'tornadoTanZPeriod',
      'tornadoTanZOffset',
      'itgTornado',
      'itgTornadoTan',
      'itgTornadoOffset',
      'itgTornadoPeriod',
      'itgTornadoTanOffset',
      'itgTornadoTanPeriod'
    ];
    for(i in 0...PlayState.SONG.mania+1){
      submods.push('xmode$i');
      submods.push('ymode$i');
      submods.push('zmode$i');
    }
    return submods;
  }
}