package funkin.game.modchart.modifiers;

class ExtrasModifier extends NoteModifier {
  override function getName() return 'extras';

  inline function getDigitalAngle(yOffset:Float, offset:Float, period:Float) {
    return Math.PI * (yOffset + (1 * offset)) / (Note.swagWidth + (period * Note.swagWidth));
  }

  inline function getT(name:String, diff:Float, player:Int):Float {
    return (diff + getSubmodValue(name + "Offset", player)) / Math.max(1, 100 * (1 + getSubmodValue(name + "Period", player)));
  }

  inline function parabola(t:Float):Float {
    return t * t;
  }

  inline function cubic(t:Float):Float {
    return t * t * t;
  }

  inline function exponential(t:Float):Float {
    return Math.exp(MathUtil.clamp(t, -20, 20)) - 1;
  }

  inline function logarithm(t:Float):Float {
    return (t < 0 ? -1 : 1) * Math.log(1 + Math.abs(t));
  }

  inline function root(t:Float):Float {
    return (t < 0 ? -1 : 1) * Math.sqrt(Math.abs(t));
  }

  inline function gaussian(t:Float):Float {
    return Math.exp(-t * t);
  }

  inline function hyperbola(t:Float):Float {
    return t == 0 ? 0 : MathUtil.clamp(1 / t, -10, 10);
  }

  inline function circle(t:Float):Float {
    return Math.sqrt(1 - MathUtil.clamp(t, -1, 1) * MathUtil.clamp(t, -1, 1));
  }

  inline function sigmoid(t:Float):Float {
    return 2 / (1 + Math.exp(-MathUtil.clamp(t, -20, 20))) - 1;
  }

  inline function catenary(t:Float):Float {
    return (Math.exp(MathUtil.clamp(t, -20, 20)) + Math.exp(-MathUtil.clamp(t, -20, 20))) / 2 - 1;
  }

  inline function sinc(t:Float):Float {
    return t == 0 ? 1 : Math.sin(t) / t;
  }

  inline function damped(t:Float):Float {
    return Math.exp(-Math.abs(t)) * Math.sin(t * Math.PI * 2);
  }

  var sParabolaX:Modifier;
  var sParabolaY:Modifier;
  var sParabolaZ:Modifier;
  var sCubicX:Modifier;
  var sCubicY:Modifier;
  var sCubicZ:Modifier;
  var sExponentialX:Modifier;
  var sExponentialY:Modifier;
  var sExponentialZ:Modifier;
  var sLogarithmX:Modifier;
  var sLogarithmY:Modifier;
  var sLogarithmZ:Modifier;
  var sRootX:Modifier;
  var sRootY:Modifier;
  var sRootZ:Modifier;
  var sGaussianX:Modifier;
  var sGaussianY:Modifier;
  var sGaussianZ:Modifier;
  var sHyperbolaX:Modifier;
  var sHyperbolaY:Modifier;
  var sHyperbolaZ:Modifier;
  var sCircleX:Modifier;
  var sCircleY:Modifier;
  var sCircleZ:Modifier;
  var sSigmoidX:Modifier;
  var sSigmoidY:Modifier;
  var sSigmoidZ:Modifier;
  var sCatenaryX:Modifier;
  var sCatenaryY:Modifier;
  var sCatenaryZ:Modifier;
  var sSincX:Modifier;
  var sSincY:Modifier;
  var sSincZ:Modifier;
  var sDampedX:Modifier;
  var sDampedY:Modifier;
  var sDampedZ:Modifier;
  var sAttenuateX:Modifier;
  var sAttenuateY:Modifier;
  var sAttenuateZ:Modifier;
  var sZigzagY:Modifier;
  var sSawtoothY:Modifier;
  var sSawtoothZ:Modifier;
  var sSquareY:Modifier;
  var sSquareZ:Modifier;
  var sBounceY:Modifier;
  var sDigitalY:Modifier;
  var sBoomerang:Modifier;

  override function bind() {
    sParabolaX = submods.get("parabolaX");
    sParabolaY = submods.get("parabolaY");
    sParabolaZ = submods.get("parabolaZ");
    sCubicX = submods.get("cubicX");
    sCubicY = submods.get("cubicY");
    sCubicZ = submods.get("cubicZ");
    sExponentialX = submods.get("exponentialX");
    sExponentialY = submods.get("exponentialY");
    sExponentialZ = submods.get("exponentialZ");
    sLogarithmX = submods.get("logarithmX");
    sLogarithmY = submods.get("logarithmY");
    sLogarithmZ = submods.get("logarithmZ");
    sRootX = submods.get("rootX");
    sRootY = submods.get("rootY");
    sRootZ = submods.get("rootZ");
    sGaussianX = submods.get("gaussianX");
    sGaussianY = submods.get("gaussianY");
    sGaussianZ = submods.get("gaussianZ");
    sHyperbolaX = submods.get("hyperbolaX");
    sHyperbolaY = submods.get("hyperbolaY");
    sHyperbolaZ = submods.get("hyperbolaZ");
    sCircleX = submods.get("circleX");
    sCircleY = submods.get("circleY");
    sCircleZ = submods.get("circleZ");
    sSigmoidX = submods.get("sigmoidX");
    sSigmoidY = submods.get("sigmoidY");
    sSigmoidZ = submods.get("sigmoidZ");
    sCatenaryX = submods.get("catenaryX");
    sCatenaryY = submods.get("catenaryY");
    sCatenaryZ = submods.get("catenaryZ");
    sSincX = submods.get("sincX");
    sSincY = submods.get("sincY");
    sSincZ = submods.get("sincZ");
    sDampedX = submods.get("dampedX");
    sDampedY = submods.get("dampedY");
    sDampedZ = submods.get("dampedZ");
    sAttenuateX = submods.get("attenuateX");
    sAttenuateY = submods.get("attenuateY");
    sAttenuateZ = submods.get("attenuateZ");
    sZigzagY = submods.get("zigzagY");
    sSawtoothY = submods.get("sawtoothY");
    sSawtoothZ = submods.get("sawtoothZ");
    sSquareY = submods.get("squareY");
    sSquareZ = submods.get("squareZ");
    sBounceY = submods.get("bounceY");
    sDigitalY = submods.get("digitalY");
    sBoomerang = submods.get("boomerang");
  }

  override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:DrawInstruction, data:Int, player:Int, obj:FlxSprite) {
    var outPos = pos.clone();

    var diff = visualDiff;
    var column = data;
    var keyCount:Int = PlayState.SONG.mania + 1;

    var parabolaX = subVal(sParabolaX, player);
    var parabolaY = subVal(sParabolaY, player);
    var parabolaZ = subVal(sParabolaZ, player);
    if (parabolaX != 0 || parabolaY != 0 || parabolaZ != 0) {
      var f = parabola(getT("parabola", diff, player));
      outPos.x += parabolaX * f;
      outPos.y += parabolaY * f;
      outPos.z += (parabolaZ * f) / 1280;
    }

    var cubicX = subVal(sCubicX, player);
    var cubicY = subVal(sCubicY, player);
    var cubicZ = subVal(sCubicZ, player);
    if (cubicX != 0 || cubicY != 0 || cubicZ != 0) {
      var f = cubic(getT("cubic", diff, player));
      outPos.x += cubicX * f;
      outPos.y += cubicY * f;
      outPos.z += (cubicZ * f) / 1280;
    }

    var exponentialX = subVal(sExponentialX, player);
    var exponentialY = subVal(sExponentialY, player);
    var exponentialZ = subVal(sExponentialZ, player);
    if (exponentialX != 0 || exponentialY != 0 || exponentialZ != 0) {
      var f = exponential(getT("exponential", diff, player));
      outPos.x += exponentialX * f;
      outPos.y += exponentialY * f;
      outPos.z += (exponentialZ * f) / 1280;
    }

    var logarithmX = subVal(sLogarithmX, player);
    var logarithmY = subVal(sLogarithmY, player);
    var logarithmZ = subVal(sLogarithmZ, player);
    if (logarithmX != 0 || logarithmY != 0 || logarithmZ != 0) {
      var f = logarithm(getT("logarithm", diff, player));
      outPos.x += logarithmX * f;
      outPos.y += logarithmY * f;
      outPos.z += (logarithmZ * f) / 1280;
    }

    var rootX = subVal(sRootX, player);
    var rootY = subVal(sRootY, player);
    var rootZ = subVal(sRootZ, player);
    if (rootX != 0 || rootY != 0 || rootZ != 0) {
      var f = root(getT("root", diff, player));
      outPos.x += rootX * f;
      outPos.y += rootY * f;
      outPos.z += (rootZ * f) / 1280;
    }

    var gaussianX = subVal(sGaussianX, player);
    var gaussianY = subVal(sGaussianY, player);
    var gaussianZ = subVal(sGaussianZ, player);
    if (gaussianX != 0 || gaussianY != 0 || gaussianZ != 0) {
      var f = gaussian(getT("gaussian", diff, player));
      outPos.x += gaussianX * f;
      outPos.y += gaussianY * f;
      outPos.z += (gaussianZ * f) / 1280;
    }

    var hyperbolaX = subVal(sHyperbolaX, player);
    var hyperbolaY = subVal(sHyperbolaY, player);
    var hyperbolaZ = subVal(sHyperbolaZ, player);
    if (hyperbolaX != 0 || hyperbolaY != 0 || hyperbolaZ != 0) {
      var f = hyperbola(getT("hyperbola", diff, player));
      outPos.x += hyperbolaX * f;
      outPos.y += hyperbolaY * f;
      outPos.z += (hyperbolaZ * f) / 1280;
    }

    var circleX = subVal(sCircleX, player);
    var circleY = subVal(sCircleY, player);
    var circleZ = subVal(sCircleZ, player);
    if (circleX != 0 || circleY != 0 || circleZ != 0) {
      var f = circle(getT("circle", diff, player));
      outPos.x += circleX * f;
      outPos.y += circleY * f;
      outPos.z += (circleZ * f) / 1280;
    }

    var sigmoidX = subVal(sSigmoidX, player);
    var sigmoidY = subVal(sSigmoidY, player);
    var sigmoidZ = subVal(sSigmoidZ, player);
    if (sigmoidX != 0 || sigmoidY != 0 || sigmoidZ != 0) {
      var f = sigmoid(getT("sigmoid", diff, player));
      outPos.x += sigmoidX * f;
      outPos.y += sigmoidY * f;
      outPos.z += (sigmoidZ * f) / 1280;
    }

    var catenaryX = subVal(sCatenaryX, player);
    var catenaryY = subVal(sCatenaryY, player);
    var catenaryZ = subVal(sCatenaryZ, player);
    if (catenaryX != 0 || catenaryY != 0 || catenaryZ != 0) {
      var f = catenary(getT("catenary", diff, player));
      outPos.x += catenaryX * f;
      outPos.y += catenaryY * f;
      outPos.z += (catenaryZ * f) / 1280;
    }

    var sincX = subVal(sSincX, player);
    var sincY = subVal(sSincY, player);
    var sincZ = subVal(sSincZ, player);
    if (sincX != 0 || sincY != 0 || sincZ != 0) {
      var f = sinc(getT("sinc", diff, player));
      outPos.x += sincX * f;
      outPos.y += sincY * f;
      outPos.z += (sincZ * f) / 1280;
    }

    var dampedX = subVal(sDampedX, player);
    var dampedY = subVal(sDampedY, player);
    var dampedZ = subVal(sDampedZ, player);
    if (dampedX != 0 || dampedY != 0 || dampedZ != 0) {
      var f = damped(getT("damped", diff, player));
      outPos.x += dampedX * f;
      outPos.y += dampedY * f;
      outPos.z += (dampedZ * f) / 1280;
    }

    var attenuateX = subVal(sAttenuateX, player);
    var attenuateY = subVal(sAttenuateY, player);
    var attenuateZ = subVal(sAttenuateZ, player);
    if (attenuateX != 0 || attenuateY != 0 || attenuateZ != 0) {
      var t = diff / Note.swagWidth;
      var f = t * t * (column % keyCount - (keyCount - 1) / 2);
      outPos.x += attenuateX * f;
      outPos.y += attenuateY * f;
      outPos.z += (attenuateZ * f) / 1280;
    }

    var zigzagY = subVal(sZigzagY, player);
    if (zigzagY != 0) {
      var offset = getSubmodValue("zigzagYOffset", player);
      var period = getSubmodValue("zigzagYPeriod", player);
      if (period != -1) {
        var result:Float = MathUtil.triangle(Math.PI * (1 / (period + 1)) * ((diff + 100 * offset) / Note.swagWidth));
        outPos.y += (zigzagY * (Note.swagWidth * 0.5)) * result;
      }
    }

    var sawtoothY = subVal(sSawtoothY, player);
    if (sawtoothY != 0) {
      var offset = getSubmodValue("sawtoothYOffset", player);
      var period = getSubmodValue("sawtoothYPeriod", player);
      if (period != -1) {
        var p = (0.5 / (period + 1) * (diff + 100 * offset)) / Note.swagWidth;
        outPos.y += (sawtoothY * Note.swagWidth) * (p - Math.floor(p));
      }
    }

    var sawtoothZ = subVal(sSawtoothZ, player);
    if (sawtoothZ != 0) {
      var offset = getSubmodValue("sawtoothZOffset", player);
      var period = getSubmodValue("sawtoothZPeriod", player);
      if (period != -1) {
        var p = (0.5 / (period + 1) * (diff + 100 * offset)) / Note.swagWidth;
        outPos.z += ((sawtoothZ * Note.swagWidth) * (p - Math.floor(p))) / 1280;
      }
    }

    var squareY = subVal(sSquareY, player);
    if (squareY != 0) {
      var offset = getSubmodValue("squareYOffset", player);
      var period = getSubmodValue("squareYPeriod", player);
      var per = 60 + (period * 60);
      if (per != 0) {
        var cum:Float = Math.PI * (diff + 100 * offset) / per;
        outPos.y += squareY * (Note.swagWidth * 0.5) * MathUtil.square(cum) * Math.min(1, Math.abs(diff) / 200);
      }
    }

    var squareZ = subVal(sSquareZ, player);
    if (squareZ != 0) {
      var offset = getSubmodValue("squareZOffset", player);
      var period = getSubmodValue("squareZPeriod", player);
      var per = 60 + (period * 60);
      if (per != 0) {
        var cum:Float = Math.PI * (diff + 100 * offset) / per;
        outPos.z += (squareZ * (Note.swagWidth * 0.5) * MathUtil.square(cum) * Math.min(1, Math.abs(diff) / 200)) / 1280;
      }
    }

    var bounceY = subVal(sBounceY, player);
    if (bounceY != 0) {
      var offset = getSubmodValue("bounceYOffset", player);
      var period = getSubmodValue("bounceYPeriod", player);
      if (period != -1) {
        var bounce = Math.abs(Math.sin((diff + offset) / (90.0 + 90.0 * period)));
        outPos.y += bounceY * (Note.swagWidth * 0.5) * bounce;
      }
    }

    var digitalY = subVal(sDigitalY, player);
    if (digitalY != 0) {
      var offset = getSubmodValue("digitalYOffset", player);
      var period = getSubmodValue("digitalYPeriod", player);
      var steps = getSubmodValue("digitalYSteps", player) + 1;
      if (steps != 0 && period != -1) {
        outPos.y += (digitalY * (Note.swagWidth * 0.5)) * Math.floor(0.5 + (steps * Math.sin(getDigitalAngle(diff, offset, period)))) / steps;
      }
    }

    var boomerang = subVal(sBoomerang, player);
    if (boomerang != 0) {
      var rev = modMgr.reverseMod;
      var reversePercent = rev != null ? rev.getReverseValue(data, player) : 0;
      var mult = MathUtil.scale(reversePercent, 0, 1, 1, -1);
      outPos.y += boomerang * (0.5 * diff - diff * diff / FlxG.height) * mult;
    }

    return outPos;
  }

  override function getSubmods() {
    return [
      "parabolaX",
      "parabolaY",
      "parabolaZ",
      "parabolaPeriod",
      "parabolaOffset",
      "cubicX",
      "cubicY",
      "cubicZ",
      "cubicPeriod",
      "cubicOffset",
      "exponentialX",
      "exponentialY",
      "exponentialZ",
      "exponentialPeriod",
      "exponentialOffset",
      "logarithmX",
      "logarithmY",
      "logarithmZ",
      "logarithmPeriod",
      "logarithmOffset",
      "rootX",
      "rootY",
      "rootZ",
      "rootPeriod",
      "rootOffset",
      "gaussianX",
      "gaussianY",
      "gaussianZ",
      "gaussianPeriod",
      "gaussianOffset",
      "hyperbolaX",
      "hyperbolaY",
      "hyperbolaZ",
      "hyperbolaPeriod",
      "hyperbolaOffset",
      "circleX",
      "circleY",
      "circleZ",
      "circlePeriod",
      "circleOffset",
      "sigmoidX",
      "sigmoidY",
      "sigmoidZ",
      "sigmoidPeriod",
      "sigmoidOffset",
      "catenaryX",
      "catenaryY",
      "catenaryZ",
      "catenaryPeriod",
      "catenaryOffset",
      "sincX",
      "sincY",
      "sincZ",
      "sincPeriod",
      "sincOffset",
      "dampedX",
      "dampedY",
      "dampedZ",
      "dampedPeriod",
      "dampedOffset",
      "attenuateX",
      "attenuateY",
      "attenuateZ",
      "zigzagY",
      "zigzagYPeriod",
      "zigzagYOffset",
      "sawtoothY",
      "sawtoothYPeriod",
      "sawtoothYOffset",
      "sawtoothZ",
      "sawtoothZPeriod",
      "sawtoothZOffset",
      "squareY",
      "squareYPeriod",
      "squareYOffset",
      "squareZ",
      "squareZPeriod",
      "squareZOffset",
      "bounceY",
      "bounceYPeriod",
      "bounceYOffset",
      "digitalY",
      "digitalYPeriod",
      "digitalYOffset",
      "digitalYSteps",
      "boomerang"
    ];
  }
}
