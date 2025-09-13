package objects;

import flixel.system.ui.FlxSoundTray;

#if FLX_SOUND_SYSTEM
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.system.FlxAssets;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import backend.Paths;

class VolumeTray extends FlxSoundTray
{
  var graphicScale:Float = 0.30;
  var lerpYPos:Float = 0;
  var alphaTarget:Float = 0;
  var volumeMaxSound:String;

  var _progressBg:Sprite;
  var _progressFill:Sprite;
  var targetFill:Float = 0; // target scaleX for smooth lerp

  public function new()
  {
    super();
    removeChildren();

    // Box that holds the bar (kept original size)
    var bg:Bitmap = new Bitmap(FlxAssets.getBitmapData("assets/shared/images/engineStuff/main/soundtray/volumebox.png"));
    bg.scaleX = graphicScale;
    bg.scaleY = graphicScale;
    addChild(bg);

    y = -height;
    visible = false;

    // Slim rectangle bar
    _progressBg = new Sprite();
    _progressBg.graphics.beginFill(0x666666);
    _progressBg.graphics.drawRect(0, 0, 60, 6);
    _progressBg.graphics.endFill();
    _progressBg.x = 9;
    _progressBg.y = 8;
    addChild(_progressBg);

    _progressFill = new Sprite();
    _progressFill.graphics.beginFill(0xFFFFFF);
    _progressFill.graphics.drawRect(0, 0, 60, 6);
    _progressFill.graphics.endFill();
    _progressFill.x = 9;
    _progressFill.y = 8;
    addChild(_progressFill);

    _progressFill.scaleX = 0;

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
    if (_progressFill != null)
    {
      _progressFill.scaleX = FlxMath.lerp(_progressFill.scaleX, targetFill, 0.2);
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
    targetFill = (globalVolume / 10);
  }
}
#end
