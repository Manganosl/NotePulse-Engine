package funkin.substates.quickPanel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.substates.quickPanel.QuickPanelState;
import funkin.substates.quickPanel.QuickPanelGroup;
import funkin.game.shaders.BoilShader;
import funkin.backend.utils.PropertyAnimator;

/**
 * The interface for an item in the options menu.
 * Extended to provide specific input data types.
 */
class QuickPanelButton extends FlxSpriteGroup
{
  public static final ITEM_WIDTH:Int = 320;
  public static final ITEM_HEIGHT:Int = 100;
  public static final ICON_WIDTH:Int = 100;
  public static final TEXT_SIZE:Int = 38;
  public static final MIN_TEXT_SIZE:Int = 14;

  var boilShaderIcon:BoilShader;
  var boilShaderText:BoilShader;

  /**
   * How many frames should pass between each time the boilShader should move.
   * (the idle animation of the button changes visuals every 4 frames)
   */
  var BOIL_INTERVAL:Int = 4;

  var boilTimer:Float = 0;

  /**
   * The data assigned to this button.
   */
  public var data:QuickPanelButtonData;

  public var selected(default, set):Bool;

  function set_selected(value:Bool):Bool
  {
    selected = value;
    updateSelected();
    return selected;
  }

  /**
   * A hitbox for the button.
   */
  public var guide:FunkinSprite;

  public var bg:FunkinSprite;
  public var buttonText:FlxText;
  public var icon:FunkinSprite;
  public var paScale:PropertyAnimator;
  public var paFade:PropertyAnimator;

  var ICON_SCALE_X:Float;
  var ICON_SCALE_Y:Float;

  /**
   * Used when the panel has to fit more buttons than usual.
   */
  public var factor:Float = 1;

  var itemH:Int;
  var iconW:Int;

  // for mobile, when you tap this button itll force select this index
  public var curIndex:Int = 0;
  public var panelGroup:QuickPanelGroup;

  var left:Bool = true;
  // specifically cause i cant be bothered to make custom animations for disabled buttons
  var alphaMultiplier:Float = 0;

  public function repositionSide(_left:Bool = false)
  {
    left = _left;

    buttonText.x = guide.x + (left ? guide.width - (iconW + buttonText.width + 20) : iconW + 20);
    icon.x = guide.x + (left ? guide.width - iconW : 0);

    // makes sense... right?
    buttonText.alignment = left ? RIGHT : LEFT;
  }

  /**
   * Reduces the size of this text, and only this one, until it fits in a single line.
   */
  function fitText():Void
  {
    var available:Float = ITEM_WIDTH - (iconW + 20) - 4;
    var size:Int = Std.int(buttonText.size);

    buttonText.wordWrap = false;

    while (buttonText.textField.textWidth > available && size > MIN_TEXT_SIZE)
    {
      size -= 1;
      buttonText.size = size;
    }

    buttonText.wordWrap = true;
  }

  public function new(_data:QuickPanelButtonData, _factor:Float = 1)
  {
    super();

    data = _data;
    factor = _factor;

    itemH = Math.round(ITEM_HEIGHT * factor);
    iconW = Math.round(ICON_WIDTH * factor);

    alphaMultiplier = data.disabled ? 0.5 : 1.0;

    guide = new FunkinSprite(0, 0);
    guide.makeGraphic(ITEM_WIDTH, itemH, 0x00D1D1D1);
    guide.alpha = 0;
    guide.x = 0;
    guide.y = 0;
    add(guide);

    buttonText = new FlxText(0, 0, ITEM_WIDTH - (iconW + 20), '${data.text ?? 'NO TEXT'}', 30);
    buttonText.setFormat(Paths.font('FunkinOptions.otf'), TEXT_SIZE, 0xFFCCCCCC, LEFT);
    fitText();
    buttonText.x = iconW + 20;
    buttonText.y = (itemH / 2) - (buttonText.height / 2);
    buttonText.offset.y = -6 * factor;
    add(buttonText);

    icon = new FunkinSprite(0, 0);
    icon.loadGraphic(Paths.image('quick-panel/icons/${data.icon}'));
    add(icon);

    icon.antialiasing = true;
    icon.setGraphicSize(iconW, iconW);

    ICON_SCALE_X = icon.scale.x;
    ICON_SCALE_Y = icon.scale.y;

    icon.scale.x = ICON_SCALE_X;
    icon.scale.y = ICON_SCALE_Y;
    icon.updateHitbox();

    boilShaderIcon = new BoilShader();
    boilShaderIcon.bumpTimer();
    boilShaderIcon.amount = 100;

    boilShaderText = new BoilShader();
    boilShaderText.bumpTimer();
    boilShaderText.amount = 100;

    buttonText.shader = boilShaderText;
    icon.shader = boilShaderIcon;

    //resetOrigin();
    updateSelected();

    setupAnims();

    paFade.playAnimation('release');
  }

  /**
   * Sets up the animations for the fading and scale.
   */
  public function setupAnims()
  {
    paFade = new PropertyAnimator(this);

    paFade.addAnimationByName('fade', 24);

    paFade.addProperty('fade', 'alpha', [
      1.0 * alphaMultiplier,
      0.5 * alphaMultiplier,
      0.2 * alphaMultiplier,
      0.1 * alphaMultiplier,
      0.1 * alphaMultiplier,
      0.0 * alphaMultiplier
    ]);

    paFade.addAnimationByName('press', 24);

    paFade.addProperty('press', 'alpha', [0.7 * alphaMultiplier]);

    paFade.addAnimationByName('release', 24);

    paFade.addProperty('release', 'alpha', [1.0 * alphaMultiplier]);

    paFade.setDefaultProperties();

    paScale = new PropertyAnimator(this);

    var bumpValues:Array<Float> = [1.04, 1.04, 1.04, 1.04, 1.04, 1.04, 0.98, 0.98, 0.98, 0.98, 1];
    var bumpBigValues:Array<Float> = [1.2, 1.2, 1.2, 1.2, 1.2, 1.2, 0.95, 0.95, 0.95, 0.95, 1];

    paScale.addAnimationByName('bump', 30);

    paScale.addProperty('bump', 'icon.scale.x', bumpValues.map(v -> ICON_SCALE_X * v));
    paScale.addProperty('bump', 'icon.scale.y', bumpValues.map(v -> ICON_SCALE_Y * v));
    paScale.addProperty('bump', 'buttonText.scale.x', bumpValues);
    paScale.addProperty('bump', 'buttonText.scale.y', bumpValues);

    paScale.addAnimationByName('bumpBig', 30);

    paScale.addProperty('bumpBig', 'icon.scale.x', bumpBigValues.map(v -> ICON_SCALE_X * v));
    paScale.addProperty('bumpBig', 'icon.scale.y', bumpBigValues.map(v -> ICON_SCALE_Y * v));
    paScale.addProperty('bumpBig', 'buttonText.scale.x', bumpBigValues);
    paScale.addProperty('bumpBig', 'buttonText.scale.y', bumpBigValues);

    paScale.setDefaultProperties();

    icon.scale.x = ICON_SCALE_X;
    icon.scale.y = ICON_SCALE_Y;
  }

  /**
   * Updates the button visuals based on whether it is selected.
   */
  function updateSelected()
  {
    icon.color = selected ? FlxColor.BLACK : 0xFFCCCCCC;
    buttonText.color = selected ? FlxColor.BLACK : 0xFFCCCCCC;

    boilShaderIcon.amount = selected ? 1.5 : 0.5;
    boilShaderText.amount = selected ? 1.5 : 0.5;

    BOIL_INTERVAL = selected ? 4 : 8;

    if (paScale != null)
    {
      paScale.stop();

      buttonText.scale.x = 1;
      buttonText.scale.y = 1;
      icon.scale.x = ICON_SCALE_X;
      icon.scale.y = ICON_SCALE_Y;
    }

    if (selected)
    {
      paScale.playAnimation('bump');
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    boilTimer -= elapsed;

    if (boilTimer <= 0)
    {
      boilTimer = BOIL_INTERVAL / 24;
      boilShaderIcon.updateBoil();
      boilShaderText.updateBoil();
    }

    #if FEATURE_TOUCH_CONTROLS
    if (TouchUtil.justPressed && TouchUtil.overlaps(this))
    {
      paFade.playAnimation('press');

      FlxG.sound.play(Paths.sound('quick-panel/menu-press'), 0.1);
    }

    if (TouchUtil.justReleased)
    {
      paFade.playAnimation('release');

      if (TouchUtil.overlaps(this) && !panelGroup.lock)
      {
        panelGroup.changeSelection(curIndex, true);
      }
    }
    #end
  }

  /**
   * Calls the callback assinged in the data, if it exists.
   */
  public function doCallback()
  {
    if (data.callback != null) data.callback();
  }

  override function destroy():Void
  {
    FlxTween.cancelTweensOf(this);
    FlxTween.cancelTweensOf(this.scale);
    super.destroy();
  }
}