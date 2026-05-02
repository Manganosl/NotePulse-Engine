package modchart.modifiers;

import flixel.FlxSprite;
import ui.*;
import modchart.*;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.FlxG;
import math.Vector3;
import math.*;
import funkin.backend.utils.CoolUtil;
import funkin.backend.utils.CoolUtil.triangle;
import funkin.backend.utils.CoolUtil.square;

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

  override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite) {
    var outPos = pos.clone();

    if (getValue(player) != 0) {
      var vDiff = -timeDiff;
      var progress = (vDiff / -moveSpeed) * totalDists[data];
      var daPath = pathData[data];

      if (progress <= 0) {
        outPos = pos.lerp(daPath[0].position, getValue(player));
      } else {
        var idx:Int = 0;
        while (idx < daPath.length) {
          var cData = daPath[idx];
          var nData = daPath[idx + 1];
          if (nData != null && cData != null) {
            if (progress > cData.start && progress < cData.end) {
              var alpha = (cData.start - progress) / cData.dist;
              var interpPos:Vector3 = cData.position.lerp(nData.position, alpha);
              outPos = pos.lerp(interpPos, getValue(player));
            }
          }
          idx++;
        }
      }
    }

    var diff = visualDiff;
    var column = data;
    var keyCunt:Int = PlayState.SONG.mania;
    var keyCount:Int = keyCunt + 1;

    var zigzag = getSubmodValue("zigzag", player);
    if (zigzag != 0) {
      var offset = getSubmodValue("zigzagOffset", player);
      var period = getSubmodValue("zigzagPeriod", player);
      var result:Float = triangle((Math.PI * (1 / (period + 1)) * ((diff + 100 * offset) / Note.swagWidth)));
      outPos.x += (zigzag * (Note.swagWidth * 0.5)) * result;
    }

    var zigzagZ = getSubmodValue("zigzagZ", player);
    if (zigzagZ != 0) {
      var offset = getSubmodValue("zigzagZOffset", player);
      var period = getSubmodValue("zigzagZPeriod", player);
      var result:Float = triangle((Math.PI * (1 / (period + 1)) * ((diff + 100 * offset) / Note.swagWidth)));
      outPos.z += (zigzagZ * (Note.swagWidth * 0.5)) * result;
    }

    var sawtooth = getSubmodValue("sawtooth", player);
    if (sawtooth != 0) {
      var period = getSubmodValue("sawtoothPeriod", player) + 1;
      var p = (0.5 / period * diff) / Note.swagWidth;
      outPos.x += (sawtooth * Note.swagWidth) * (p - Math.floor(p));
    }

    var squareVal = getSubmodValue("square", player);
    if (squareVal != 0) {
      var offset = getSubmodValue("squareOffset", player);
      var period = getSubmodValue("squarePeriod", player);
      var cum = (Math.PI * (diff + offset) / (Note.swagWidth + (period * Note.swagWidth)));
      outPos.x += squareVal * (Note.swagWidth * 0.5) * square(cum);
    }

    var bounceVal = getSubmodValue("bounce", player);
    if (bounceVal != 0) {
      var offset = getSubmodValue("bounceOffset", player);
      var period = getSubmodValue("bouncePeriod", player);
      if (period != -1.0) {
        var bounce = Math.abs(Math.sin((diff + offset) / (90.0 + 90.0 * period)));
        outPos.x += bounceVal * (Note.swagWidth * 0.5) * bounce;
      }
    }

    var bounceZVal = getSubmodValue("bounceZ", player);
    if (bounceZVal != 0) {
      var offset = getSubmodValue("bounceZOffset", player);
      var period = getSubmodValue("bounceZPeriod", player);
      if (period != -1.0) {
        var bounce = Math.abs(Math.sin((diff + offset) / (90.0 + 90.0 * period)));
        outPos.z += bounceZVal * (Note.swagWidth * 0.5) * bounce;
      }
    }

    var xmode = getSubmodValue("xmode", player);
    if (xmode != 0) {
      var mod = (player + 1) * 2 - 3;
      outPos.x += xmode * (diff * mod);
    }

    var tornadoVal = getSubmodValue("tornado", player);
    if (tornadoVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoOffset", player);
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.cos(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.cos(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.x += offsetX * tornadoVal;
    }

    var tornadoTanVal = getSubmodValue("tornadoTan", player);
    if (tornadoTanVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoTanOffset", player);
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoTanPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.cos(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.tan(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.x += offsetX * tornadoTanVal;
    }

    var tornadoZVal = getSubmodValue("tornadoZ", player);
    if (tornadoZVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoZOffset", player);
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoZPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.sin(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.sin(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.z += offsetX * tornadoZVal;
    }

    var tornadoTanZVal = getSubmodValue("tornadoTanZ", player);
    if (tornadoTanZVal != 0) {
      var playerColumn = column % keyCount;
      var columnPhaseShift = (playerColumn * PI_THIRD) + getSubmodValue("tornadoTanZOffset", player) + Math.PI;
      var phaseShift = (diff / 135) * (1 + getSubmodValue("tornadoTanZPeriod", player));
      var returnReceptorToZeroOffsetX = (-Math.sin(-columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt;
      var offsetX = (-Math.tan(phaseShift - columnPhaseShift) + 1) * (Note.swagWidth * 0.5) * keyCunt - returnReceptorToZeroOffsetX;
      outPos.z += offsetX * tornadoTanZVal;
    }

    var itgTornadoVal = getSubmodValue("itgTornado", player);
    var itgTornadoTanVal = getSubmodValue("itgTornadoTan", player);

    if (itgTornadoVal != 0 || itgTornadoTanVal != 0) {
      var wide = keyCount > 4;
      var width = wide ? 2 : 3;
      var startColumn:Int = Std.int(CoolUtil.boundTo(column - width, 0, keyCount - 1));
      var endColumn:Int = Std.int(CoolUtil.boundTo(column + width, 0, keyCount - 1));

      var minX = startColumn * Note.swagWidth;
      var maxX = endColumn * Note.swagWidth;
      var realPixel = column * Note.swagWidth;

      var posBetween = CoolUtil.scale(realPixel, minX, maxX, -1, 1);

      if (itgTornadoVal != 0) {
        var rads = Math.acos(posBetween);
        var period = getSubmodValue("itgTornadoPeriod", player);
        var offset = getSubmodValue("itgTornadoOffset", player);
        rads += (diff + offset) * (6 + period * 6) / FlxG.height;
        var adjusted = CoolUtil.scale(Math.cos(rads), -1, 1, minX, maxX);
        outPos.x += (adjusted - realPixel) * itgTornadoVal;
      }

      if (itgTornadoTanVal != 0) {
        var rads = Math.acos(posBetween);
        var period = getSubmodValue("itgTornadoTanPeriod", player);
        var offset = getSubmodValue("itgTornadoTanOffset", player);
        rads += (diff + offset) * (6 + period * 6) / FlxG.height;
        var adjusted = CoolUtil.scale(Math.tan(rads), -1, 1, minX, maxX);
        outPos.x += (adjusted - realPixel) * itgTornadoTanVal;
      }
    }

    var digitalVal = getSubmodValue("digital", player);
    if (digitalVal > 0) {
      var steps = this.getSubmodValue("digitalSteps", player) + 1;
      var period = this.getSubmodValue("digitalPeriod", player);
      var offset = this.getSubmodValue("digitalOffset", player);

      outPos.x += (digitalVal * (Note.swagWidth * 0.5)) * Math.floor(0.5 + (steps * Math.sin(getDigitalAngle(diff, offset, period)))) / steps;
    }

    var digitalZVal = getSubmodValue("digitalZ", player);
    if (digitalZVal > 0) {
      var steps = this.getSubmodValue("digitalZSteps", player) + 1;
      var period = this.getSubmodValue("digitalZPeriod", player);
      var offset = this.getSubmodValue("digitalZOffset", player);

      outPos.z += (digitalZVal * (Note.swagWidth * 0.5)) * Math.floor(0.5 + (steps * Math.sin(getDigitalAngle(diff, offset, period)))) / steps;
    }

    return outPos;
  }

  override function getSubmods() {
    return [
      'tornado',
      'xmode',
      'zigzag',
      'zigzagPeriod',
      'zigzagOffset',
      'sawtooth',
      'sawtoothPeriod',
      'square',
      'squareOffset',
      'squarePeriod',
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
  }
}