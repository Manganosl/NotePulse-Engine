package objects;

import flixel.system.ui.FlxSoundTray;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.geom.ColorTransform;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import haxe.ds.Map;

#if flash
import openfl.text.AntiAliasType;
import openfl.text.GridFitType;
#end

import backend.Paths;

class VolumeTray extends FlxSoundTray
{
  var graphicScale:Float = 0.30;
  var lerpYPos:Float = 0;
  var alphaTarget:Float = 0;
  var volumeMaxSound:String;

  var _barTweens:Map<Bitmap, { r:Float, g:Float, b:Float, t:Float, phase:Int }> = new Map();
  var _barTargets:Map<Bitmap, { r:Float, g:Float, b:Float }> = new Map();

  public function new()
  {
    super();
    removeChildren();

    var bg:Bitmap = new Bitmap(FlxAssets.getBitmapData("assets/shared/images/engineStuff/main/soundtray/volumebox.png"));
    bg.scaleX = graphicScale;
    bg.scaleY = graphicScale;
    addChild(bg);

    y = -height;
    visible = false;

    var backingBar:Bitmap = new Bitmap(FlxAssets.getBitmapData("assets/shared/images/engineStuff/main/soundtray/bars_10.png"));
    backingBar.x = 9;
    backingBar.y = 5;
    backingBar.scaleX = graphicScale;
    backingBar.scaleY = graphicScale;
    backingBar.alpha = 0.4;
    addChild(backingBar);

    _bars = [];

    for (i in 1...11)
    {
      var bar:Bitmap = new Bitmap(FlxAssets.getBitmapData("assets/shared/images/engineStuff/main/soundtray/bars_" + i + ".png"));
      bar.x = 9;
      bar.y = 5;
      bar.scaleX = graphicScale;
      bar.scaleY = graphicScale;
      addChild(bar);
      _bars.push(bar);
    }

    y = -height;
    screenCenter();

    volumeUpSound = "assets/shared/sounds/soundtray/Volup.ogg";
    volumeDownSound = "assets/shared/sounds/soundtray/Voldown.ogg";
    volumeMaxSound = "assets/shared/sounds/soundtray/VolMAX.ogg";

    Paths.sound('soundtray/Volup');
    Paths.sound('soundtray/Voldown');
    Paths.sound('soundtray/VolMAX');
  }

  override public function update(MS:Float):Void
  {
    y = FlxMath.lerp(y, lerpYPos, 0.1);
    alpha = FlxMath.lerp(alpha, alphaTarget, 0.25);

    if (_timer > 0)
    {
      _timer -= (MS / 1000);
      alphaTarget = 1;
    }
    else if (y >= -height)
    {
      lerpYPos = -height - 10;
      alphaTarget = 0;
    }

    if (y <= -height)
    {
      visible = false;
      active = false;

      #if FLX_SAVE
      if (FlxG.save.isBound)
      {
        FlxG.save.data.mute = FlxG.sound.muted;
        FlxG.save.data.volume = FlxG.sound.volume;
        FlxG.save.flush();
      }
      #end
    }

    for (bar in _barTweens.keys())
    {
      var tweenData = _barTweens.get(bar);
      var target = _barTargets.get(bar);
      if (tweenData == null || target == null) continue;

      var speed = MS / 50;

      tweenData.t += speed;
      if (tweenData.t > 1) tweenData.t = 1;

      if (tweenData.phase == 0)
      {
        var r = tweenData.r + (1 - tweenData.r) * tweenData.t;
        var g = tweenData.g + (1 - tweenData.g) * tweenData.t;
        var b = tweenData.b + (1 - tweenData.b) * tweenData.t;

        bar.transform.colorTransform = new ColorTransform(r, g, b, 1);

        if (tweenData.t >= 1)
        {
          tweenData.phase = 1;
          tweenData.t = 0;
          tweenData.r = 1;
          tweenData.g = 1;
          tweenData.b = 1;
        }
      }
      else
      {
        var r = tweenData.r + (target.r - tweenData.r) * tweenData.t;
        var g = tweenData.g + (target.g - tweenData.g) * tweenData.t;
        var b = tweenData.b + (target.b - tweenData.b) * tweenData.t;

        bar.transform.colorTransform = new ColorTransform(r, g, b, 1);

        if (tweenData.t >= 1)
        {
          _barTweens.remove(bar);
          _barTargets.remove(bar);
        }
      }
    }
  }

  override public function show(up:Bool = false):Void
  {
    _timer = 1;
    lerpYPos = 10;
    visible = true;
    active = true;

    var globalVolume:Int = Math.round(FlxG.sound.volume * 10);
    if (FlxG.sound.muted) globalVolume = 0;

    if (!silent)
    {
      var sound = up ? volumeUpSound : volumeDownSound;
      if (globalVolume == 10) sound = volumeMaxSound;
      if (sound != null) FlxG.sound.load(sound).play();
    }

    for (i in 0..._bars.length)
    {
      var bar = _bars[i];

      if (i < globalVolume)
      {
        bar.visible = true;

        var color = FlxColor.RED;
        if (globalVolume <= 3) color = FlxColor.BLUE;
        else if (globalVolume <= 6) color = FlxColor.GREEN;
        else if (globalVolume <= 9) color = FlxColor.YELLOW;

        var current = bar.transform.colorTransform;
        var startR = current.redMultiplier;
        var startG = current.greenMultiplier;
        var startB = current.blueMultiplier;

        var targetR = color.red / 255;
        var targetG = color.green / 255;
        var targetB = color.blue / 255;

        _barTweens.set(bar, { r: startR, g: startG, b: startB, t: 0, phase: 0 });
        _barTargets.set(bar, { r: targetR, g: targetG, b: targetB });
      }
      else
      {
        bar.visible = false;
      }
    }
  }
}
#end
