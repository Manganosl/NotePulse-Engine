package funkin.substates.quickPanel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import funkin.game.shaders.BoilShader;
import flixel.util.FlxTimer;
import funkin.backend.utils.PropertyAnimator;
import funkin.substates.quickPanel.QuickPanelState;
import funkin.substates.quickPanel.QuickPanelPullTab;
import flixel.FlxSubState;

class PanelBlockerSubState extends FlxSubState
{
  public function new()
  {
    super();
  }
}

enum PanelState
{
  CLOSED;
  OPENING;
  OPEN;
}

typedef QuickPanelButtonData =
{
  /**
   * The text shown on the button.
   */
  var text:Null<String>;

  /**
   * Callback function after clicking the button.
   * (should proooobably only be for the state to change)
   */
  var callback:Null<Void->Void>;

  /**
   * The icon to use for the button.
   * At the moment, it must be a valid icon in 'quick-panel/icons/_'
   */
  var icon:Null<String>;

  /**
   * If true, the button will not be able to be selected.
   * cause right now... online isnt done! teehee
   */
  var disabled:Null<Bool>;

  /**
   * The description for the button, when selected.
   */
  var description:Null<String>;
}

/**
 * The interface for an item in the options menu.
 * Extended to provide specific input data types.
 */
class QuickPanelGroup extends FlxSpriteGroup
{
  var mbState:Null<MusicBeatState> = null;

  static var shouldDecayTimer:Bool = true;
  static var tabFadeTimer:Float = 0;
  static final TAB_FADE_DELAY:Float = 3.0;
  static final TAB_FADE_DURATION:Float = 1.5;
  public static final TAB_MIN_ALPHA:Float = 0.25;

  /**
   * Lock user input
   */
  public var lock:Bool = false;

  /**
   * Whether the tab can be pulled, and whether the game will tell you to pull it.
   * Because some phones wont be able to support this... ughhhh
   */
  public var canPull:Bool = true;

  public var rememberedVolume:Float = 1;

  var quickPanelState:QuickPanelState;
  var panelBoilTimer:Float = 0;
  var controls(get, never):Controls;

  inline function get_controls():Controls return Controls.instance;

  /**
   * The edge of the screen.
   * this position is where the panel will be created.
   */
  var screenEdge:Float = 0;

  /**
   * The offset of the tab from the edge of the screen.
   */
  static var TAB_BASE_X:Float = -467;

  /**
   * How far you have to drag until the panel starts to be pulled.
   */
  static final GRAB_THRESHOLD:Float = 15;

  static final PANEL_BOIL_INTERVAL:Int = 4;
  static final HINT_COLOR_NORMAL:FlxColor = 0xFFEEEEEE;
  static final HINT_COLOR_DARK:FlxColor = 0xFFCCCCCC;

  /**
   * dedicated tween variable for the panel moving
   */
  var moveTween:FlxTween;

  /**
   * The current state of the panel.
   */
  public var curState:PanelState = CLOSED;

  var curSelected:Int = 0;
  var grpButtons:FlxTypedSpriteGroup<QuickPanelButton>;

  /**
   * utility var, this one gets our current button easily
   */
  public var currentButton(get, never):QuickPanelButton;

  function get_currentButton():QuickPanelButton
  {
    if (grpButtons.members.length == 0) return null;
    if (curSelected < 0 || curSelected >= grpButtons.members.length) return null;

    return grpButtons.members[curSelected];
  }

  public static function playMenuMusic():Void
  {
    /*FlxG.sound.playMusic('ui/main-menu/freaky-menu/freaky-menu', {
      overrideExisting: true,
      restartTrack: false,
      persist: true
    });*/
  }

  public static function stopMusic():Void
  {
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }
  }

  /**
   * The actual sprite for the panel.
   */
  var panel:FlxSprite;

  var panelShader:QuickPanelShader;

  /**
   * Helper object for clicling the pull tab.
   */
  var pullTabHitbox:FlxSprite;

  /**
   * The actual visible tab to pull.
   */
  public var pullTabVisual:QuickPanelPullTab;

  var pullExtra:FlxSprite;

  /**
   * Hint text to help the user know how to interact with the panel.
   */
  var pullHint:FlxText;

  public var inactivityTimer:Float = 0;

  var breatheTimer:Float = 0;
  var hintBreathe:Bool = false;
  var hintOpen:Bool = false;

  /**
   * Property animator for the scrolling animation on the panel shader.
   */
  var paScroll:PropertyAnimator;

  /**
   * Property animator for the color on the panel shader.
   */
  var paColor:PropertyAnimator;

  /**
   * Property animator for the hint text.
   */
  var paHint:PropertyAnimator;

  var pullAmt:Float = 0;
  var pullLerp:Float = 0;
  var pullOffset:Float = 0;
  var trackDist:Bool = false;
  var touchDist:Float = 0;
  var trackStartPos:FlxPoint = FlxPoint.get(0, 0);
  var left:Bool = true;
  var tickSound = new FlxSound();

  public function repositionSide(_left:Bool = false)
  {
    left = _left;

    screenEdge = left ? 0 : FlxG.width;
    TAB_BASE_X = left ? 467 : -467;

    pullTabVisual.x = x + (left ? 120 - pullTabVisual.width : -120);
    pullTabHitbox.x = x + (left ? 145 - pullTabHitbox.width : -145);

    panel.x = x + (left ? -panel.width : 0);
    pullExtra.x = x + (left ? -(pullExtra.width + panel.width) + 5 : panel.width - 5);

    panel.flipX = left;
    pullTabVisual.flipX = left;

    pullHint.x = x + (left ? 135 : -135 - pullHint.width);
    pullHint.alignment = left ? LEFT : RIGHT;

    repositionButtons();

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.volume = rememberedVolume;
    }

    switch (curState)
    {
      case OPEN:
        openPanel(true);
      case CLOSED:
        closePanel(true);
      case OPENING:
        closePanel(true);
    }
  }

  public function new(_state:QuickPanelState)
  {
    super();

    quickPanelState = _state;

    pullExtra = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
    pullExtra.scrollFactor.set(0, 0);
    pullExtra.scale.set(FlxG.width, FlxG.height);
    pullExtra.updateHitbox();

    // for some reason i have to scale both??? am i doing something wrong
    pullExtra.scale.x = FlxG.width;
    pullExtra.scale.y = FlxG.height;
    pullExtra.y = 0;
    add(pullExtra);

    panel = new FlxSprite();
    panel.frames = Paths.getSparrowAtlas('quick-panel/panel-bg');
    panel.animation.addByIndices('idle', 'thingidle instance 10', [
      0,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15
    ], '', 12, true);
    panel.animation.play('idle');
    panel.updateHitbox();
    panel.scrollFactor.set(0, 0);
    panel.y = 0;

    pullTabVisual = new QuickPanelPullTab(0, 0, #if FEATURE_TOUCH_CONTROLS false #else true #end);
    pullTabVisual.y = (FlxG.height / 2) - (pullTabVisual.height / 2);
    pullTabVisual.playIdle(curState);

    pullHint = new FlxText(0, 0, 600, "you're not supposed to see this! if you do, i seriously messed up!", 30);
    pullHint.setFormat(Paths.font('FunkinOptions.otf'), 38, HINT_COLOR_NORMAL, RIGHT);
    pullHint.y = (FlxG.height / 2) - (pullHint.height / 2);
    pullHint.offset.y = 0;
    pullHint.alpha = 0;
    add(pullHint);

    add(pullTabVisual);
    add(panel);

    panelShader = new QuickPanelShader();
    panel.shader = panelShader;

    panelShader.updateFrameInfo(panel.frame);

    pullTabHitbox = new FlxSprite().makeGraphic(200, 280, 0xFFFF9191);
    pullTabHitbox.scrollFactor.set(0, 0);
    pullTabHitbox.alpha = 0;
    pullTabHitbox.updateHitbox();
    pullTabHitbox.y = (FlxG.height / 2) - (pullTabHitbox.height / 2);
    add(pullTabHitbox);

    grpButtons = new FlxTypedSpriteGroup<QuickPanelButton>();
    add(grpButtons);

    tickSound.loadEmbedded(Paths.sound('quick-panel/tab-pull'));
    tickSound.volume = 1;

    FlxG.sound.defaultSoundGroup.add(tickSound);
    FlxG.sound.list.add(tickSound);

    setupAnims();

    populateButtons();

    changeSelection();

    repositionSide(left);

    refresh();
  }

  function handleTabFade(elapsed:Float):Void
  {
    #if FEATURE_TOUCH_CONTROLS
    if (trackDist)
    {
      tabFadeTimer = 0;
      pullTabVisual.alpha = 1.0;
      return;
    }
    #end

    if (curState != CLOSED || hintOpen) return;

    tabFadeTimer += elapsed;

    var fadeStart:Float = TAB_FADE_DELAY;
    var fadeEnd:Float = TAB_FADE_DELAY + TAB_FADE_DURATION;

    if (tabFadeTimer < fadeStart)
    {
      pullTabVisual.alpha = 1.0;
    }
    else if (tabFadeTimer < fadeEnd)
    {
      pullTabVisual.alpha = FlxMath.lerp(1.0, TAB_MIN_ALPHA, (tabFadeTimer - fadeStart) / TAB_FADE_DURATION);
    }
    else
    {
      pullTabVisual.alpha = TAB_MIN_ALPHA;
    }
  }

  function resetTabFade():Void
  {
    tabFadeTimer = 0;
    FlxTween.cancelTweensOf(pullTabVisual);
    FlxTween.tween(pullTabVisual, {
      alpha: 1.0
    }, 0.3, {
      ease: FlxEase.expoOut
    });
  }

  /**
   * Fade the pull tab in or out.
   * @param targetAlpha the target alpha to fade to.
   * @param duration the duration of the fade animation.
   */
  public function fadeTab(targetAlpha:Float, duration:Float = 0.3):Void
  {
    FlxTween.cancelTweensOf(pullTabVisual);
    FlxTween.tween(pullTabVisual, {
      alpha: targetAlpha
    }, duration, {
      ease: FlxEase.expoOut
    });
  }

  /**
   * Sets up the animations for the scrolling and colors.
   */
  public function setupAnims()
  {
    paHint = new PropertyAnimator(pullHint);

    paHint.addAnimationByName('slideLeft', 30);

    paHint.addProperty('slideLeft', 'offset.x', [
      -10,
      -10,
      -5,
      -5,
      -2,
      -2,
      -1,
      -1,
      -0.05,
      -0.05,
      -0,
      -0
    ]);

    paHint.addProperty('slideLeft', 'alpha', [
      0.0,
      0.0,
      0.5,
      0.5,
      0.7,
      0.7,
      0.9,
      0.9,
      0.95,
      0.95,
      1.0,
      1.0
    ]);

    paHint.addAnimationByName('slideRight', 30);

    paHint.addProperty('slideRight', 'offset.x', [
      10,
      10,
      5,
      5,
      2,
      2,
      1,
      1,
      0.05,
      0.05,
      0,
      0
    ]);

    paHint.addProperty('slideRight', 'alpha', [
      0.0,
      0.0,
      0.5,
      0.5,
      0.7,
      0.7,
      0.9,
      0.9,
      0.95,
      0.95,
      1.0,
      1.0
    ]);

    paHint.addAnimationByName('disappear', 30);

    paHint.addProperty('disappear', 'alpha', [
      1.0,
      1.0,
      0.95,
      0.95,
      0.9,
      0.9,
      0.7,
      0.7,
      0.5,
      0.5,
      0.0,
      0.0
    ]);

    paHint.addAnimationByName('breathe', 12, true);

    paHint.addProperty('breathe', 'alpha', [
      0.6,
      0.6,
      0.65,
      0.65,
      0.7,
      0.7,
      0.9,
      0.9,
      0.95,
      0.95,
      1.0,
      1.0,
      0.95,
      0.95,
      0.9,
      0.9,
      0.7,
      0.7,
      0.65,
      0.65,
      0.6,
      0.6
    ]);

    paHint.setDefaultProperties();

    paScroll = new PropertyAnimator(panelShader);

    paScroll.addAnimationByName('bumpUp', 30);

    paScroll.addProperty('bumpUp', 'dirExtra', [
      -0.2,
      -0.2,
      -0.03,
      -0.03,
      -0.01,
      -0.01,
      0
    ]);

    paScroll.addProperty('bumpUp', 'fatExtra', [
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      -0.25,
      -0.25,
      -0.05,
      -0.05,
      0
    ]);

    paScroll.addAnimationByName('bumpDown', 30);

    paScroll.addProperty('bumpDown', 'dirExtra', [
      0.2,
      0.2,
      0.03,
      0.03,
      0.01,
      0.01,
      0
    ]);

    paScroll.addProperty('bumpDown', 'fatExtra', [
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      -0.25,
      -0.25,
      -0.05,
      -0.05,
      0
    ]);

    paScroll.addAnimationByName('bumpNeutral', 30);

    paScroll.addProperty('bumpNeutral', 'fatExtra', [
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      0.3,
      -0.25,
      -0.25,
      -0.05,
      -0.05,
      0
    ]);

    paScroll.addAnimationByName('accept', 24);

    paScroll.addProperty('accept', 'fatExtra', [
      1.05,
      1.05,
      1.1,
      1.1,
      1,
      1,
      -0.05,
      -0.05,
      -0.05,
      -0.05,
      0
    ]);

    paScroll.addProperty('accept', 'sliceColor', [
      0xFFFF596A,
      0xFFFF596A,
      0xffF3E63A,
      0xffF3E63A,
      0xFFFF596A,
      0xFFFF596A,
      0xffF3E63A,
      0xffF3E63A,
      0xFFFF596A,
      0xFFFF596A,
      0xffF3E63A
    ]);

    paScroll.addAnimationByName('deny', 30);

    paScroll.addProperty('deny', 'sliceColor', [0xFF7C6969, 0xFF7C6969, 0xff6f6969, 0xff6f6969]);

    paScroll.addProperty('deny', 'dirExtra', [
      0.2,
      0.2,
      -0.2,
      -0.2,
      0.1,
      0.1,
      -0.1,
      -0.1,
      0
    ]);

    paScroll.setDefaultProperties();

    paColor = new PropertyAnimator(panelShader);

    paColor.addAnimationByName('breathe', 12, true);

    paColor.addProperty('breathe', 'sliceLerp', [
      0.0,
      0.0,
      0.1,
      0.1,
      0.2,
      0.2,
      0.5,
      0.5,
      0.8,
      0.8,
      0.9,
      0.9,
      1.0,
      1.0,
      0.9,
      0.9,
      0.8,
      0.8,
      0.5,
      0.5,
      0.2,
      0.2,
      0.1,
      0.1
    ]);

    paColor.setDefaultProperties();

    paColor.playAnimation('breathe');
  }

  /**
   * Create the buttons for the panel.
   */
  function populateButtons()
  {
    var index:Int = 0;
    for (button in quickPanelState.panelButtonData)
    {
      var buttonToCreate:QuickPanelButton = new QuickPanelButton(button);

      grpButtons.add(buttonToCreate);

      buttonToCreate.panelGroup = this;
      buttonToCreate.curIndex = index;

      index += 1;
    }
  }

  /**
   * Reposition and set the correct angles for the buttons.
   */
  function repositionButtons()
  {
    var count:Int = grpButtons.members.length;
    if (count == 0) return;

    var padding:Float = 20;
    var angleRange:Float = 5;
    var angleStep:Float = count > 1 ? (angleRange * 2) / (count - 1) : 0;
    var angleDistance:Float = 20;

    var span:Float = (QuickPanelButton.ITEM_HEIGHT + padding) * 4;
    var step:Float = count > 1 ? span / (count - 1) : 0;
    var startOffset = (FlxG.height / 2) - (count > 1 ? span / 2 : 0) - (QuickPanelButton.ITEM_HEIGHT / 2);

    for (blah => button in grpButtons.members)
    {
      var targetAngle = angleRange - (angleStep * blah);
      var dist = Math.abs(Math.cos(targetAngle) * angleDistance);
      var baseX = left ? -panel.width + 58 : 98;

      button.x = grpButtons.x + (left ? baseX + dist : baseX - dist);
      button.y = grpButtons.y + startOffset + (step * blah);

      button.angle = left ? -targetAngle : targetAngle;

      blah += 1;

      button.repositionSide(left);
    }
  }

  /**
   * Deselect all buttons and hide the shader slice.
   */
  function disableButtons()
  {
    for (index => button in grpButtons.members)
    {
      button.selected = false;
    }

    panelShader.sliceVisible = false;
  }

  /**
   * Show the shader slice and re-select the current button.
   */
  function enableButtons()
  {
    panelShader.sliceVisible = true;

    changeSelection();
  }

  /**
   * Orden de dibujado (equivale al zIndex del original):
   * pullExtra < pullHint < panel/pullTab < botones < hitbox.
   */
  var panelOnTop:Bool = true;

  function zOf(o:flixel.FlxBasic):Int
  {
    if (o == pullExtra) return 0;
    if (o == pullHint) return 1;
    if (o == panel) return panelOnTop ? 10 : 11;
    if (o == pullTabVisual) return panelOnTop ? 11 : 10;
    if (o == grpButtons) return 12;
    if (o == pullTabHitbox) return 200;
    return 100;
  }

  /**
   * Reordena los miembros por z sin quitar/anadir (remove+add desplazaria
   * los sprites con la x del grupo).
   */
  function refresh():Void
  {
    members.sort((a, b) -> zOf(a) - zOf(b));
  }

  function setTabOrder(top:Bool = false)
  {
    panelOnTop = top;
    refresh();
  }

  function grabPanel():Void
  {
    if (curState == OPEN)
    {
      pullLerp = left ? screenEdge - TAB_BASE_X : screenEdge + TAB_BASE_X;
    }
    else
    {
      pullLerp = screenEdge;
    }

    setTabOrder(true);
    pullTabVisual.grab(curState);

    disableButtons();

    curState = OPENING;
  }

  var blockerSubState:Null<PanelBlockerSubState> = null;

  function openBlocker():Void
  {
    if (blockerSubState != null) return;
    FlxG.state.persistentDraw = true;
    FlxG.state.persistentUpdate = false;
    if(FlxG.state.subState != null){
      FlxG.state.subState.persistentDraw = true;
      FlxG.state.subState.persistentUpdate = false;
    }
    blockerSubState = new PanelBlockerSubState();
    if (FlxG.state.topSubState != null)
    {
      var host = FlxG.state.topSubState;
      host.persistentDraw = true;
      host.persistentUpdate = (host == quickPanelState);
      host.openTopSubState(blockerSubState);
      if (host.topSubState != null && host.topSubState != blockerSubState) trace(
        "WARNING: QuickPanelGroup is opening a blocker substate while another substate is already open. This may cause issues."
      );
    }
    else
      FlxG.state.openTopSubState(blockerSubState);
  }

  function closeBlocker():Void
  {
    if (blockerSubState == null) return;
    FlxG.state.persistentUpdate = true;
    blockerSubState.close();
    if (FlxG.state.topSubState != null) FlxG.state.topSubState.persistentUpdate = true;
    if (FlxG.state.subState != null) FlxG.state.subState.persistentUpdate = true;
    blockerSubState = null;
  }

  function openPanel(instant:Bool = false):Void
  {
    curState = OPEN;
    openBlocker();
    rememberedVolume = FlxG.sound.music?.volume;

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.volume = rememberedVolume * 0.2;
    }

    if (moveTween != null) moveTween.cancel();

    if (instant)
    {
      this.x = screenEdge + TAB_BASE_X;
    }
    else
    {
      moveTween = FlxTween.tween(this, {
        x: screenEdge + TAB_BASE_X
      }, 0.4, {
        ease: FlxEase.expoOut
      });
    }

    setTabOrder(true);
    pullTabVisual.release(curState);

    enableButtons();

    quickPanelState.fadeScreen();
  }

  function closePanel(instant:Bool = false):Void
  {
    curState = CLOSED;
    closeBlocker();

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.volume = rememberedVolume;
    }

    if (moveTween != null) moveTween.cancel();

    if (instant)
    {
      this.x = screenEdge;
    }
    else
    {
      moveTween = FlxTween.tween(this, {
        x: screenEdge
      }, 0.4, {
        ease: FlxEase.expoOut
      });
    }

    setTabOrder(true);

    pullTabVisual.playIdle(curState);

    disableButtons();

    quickPanelState.fadeScreen(true);
  }

  function resolveHint(panelOpen:Bool):String
  {
    var action:String = 'PULL';

    action = #if FEATURE_TOUCH_CONTROLS canPull ? 'PULL' : 'TAP' #else 'TAB' #end;

    if (panelOpen)
    {
      return '($action) to close quick menu';
    }
    else
    {
      return '($action) to open quick menu';
    }
  }

  function handleHint(elapsed:Float):Void
  {
    if (inactivityTimer > 0 && shouldDecayTimer)
    {
      inactivityTimer -= elapsed;
    }

    if ((FlxG.keys.pressed.ANY))
    {
      inactivityTimer = 45;

      if (hintOpen)
      {
        hintOpen = false;
        hintBreathe = false;
        paHint.playAnimation('disappear');
      }

      pullHint.color = HINT_COLOR_NORMAL;
    }

    if (inactivityTimer < 0 && !hintOpen)
    {
      shouldDecayTimer = false;
      hintOpen = true;
      resetTabFade();
      pullHint.text = resolveHint(curState == OPEN);
      paHint.playAnimation(left ? 'slideRight' : 'slideLeft');

      breatheTimer = 0;

      paHint.onFinish = function()
      {
        hintBreathe = true;
      };

      pullHint.color = HINT_COLOR_NORMAL;
    }

    if (curState == CLOSED)
    {
      var targetAlpha = hintOpen ? 0.6 : 0;

      quickPanelState.bg.alpha = CoolUtil.fpsLerp(quickPanelState.bg.alpha, targetAlpha, 0.1);
    }
  }

  var soundDist:Float = 0;
  var prevDist:Float = 0;
  var soundDelay:Float = 0;

  function handleState(elapsed:Float):Void
  {
    var state:Dynamic = FlxG.state;

    // Prevent the panel from being opened during a transition
    //if (mbState == null && state is MusicBeatState) mbState = cast FlxG.state;
    //else if (mbState != null && mbState.default_trans_isTransitioning) return;

    if (trackDist)
    {
      soundDelay -= elapsed;

      touchDist = trackStartPos.dist(FlxPoint.get(0, trackStartPos.y));

      var moveDelta = Math.abs(prevDist - touchDist);

      soundDist += moveDelta;

      prevDist = touchDist;
    }

    switch (curState)
    {
      case CLOSED:
        if (FlxG.keys.justPressed.TAB)
        {
          resetTabFade();
          openPanel();
          FlxG.sound.play(Paths.sound('quick-panel/open-tab-click'));
          return;
        }

      case OPENING:
        if (left)
        {
          pullAmt = -(0 - screenEdge) + pullOffset;
        }
        else
        {
          pullAmt = (0 - screenEdge) - pullOffset;
        }

        var dist = left ? -TAB_BASE_X : TAB_BASE_X;

        var extraPull = pullAmt * 0.1;

        pullAmt = dist * FlxEase.sineOut(Math.min(pullAmt / dist, 1.0));
        pullAmt += extraPull;

        if (pullAmt > 0) pullAmt = 0;

        pullLerp = CoolUtil.fpsLerp(pullLerp, screenEdge + pullAmt, 0.1);
        quickPanelState.bg.alpha = CoolUtil.fpsLerp(quickPanelState.bg.alpha, FlxMath.lerp(0, 0.6, Math.min(pullAmt / dist, 1.0)), 0.1);

        this.x = left ? -pullLerp : pullLerp;

        if (soundDist > 40 && soundDelay < 0)
        {
          soundDist = 0;
          soundDelay = 0.08;

          tickSound.pitch = FlxMath.lerp(0.8, 1.25, Math.min(pullAmt / dist, 1.0));

          tickSound.pan = FlxMath.lerp(left ? -0.5 : 0.5, 0, Math.min(pullAmt / dist, 1.0));

          tickSound.play(true);
        }
      case OPEN:
        if (FlxG.keys.justPressed.TAB)
        {
          resetTabFade();
          closePanel();
          FlxG.sound.play(Paths.sound('quick-panel/close-tab-click'));
          return;
        }
      default:
    }
  }

  var spamTimer:Float = 0;
  var spamming:Bool = false;

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    panelShader.updateFrameInfo(panel.frame);

    // if (panelShader != null)
    // {
    //   panelShader.update(elapsed);
    // }

    panelBoilTimer -= elapsed;

    if (PANEL_BOIL_INTERVAL <= 0)
    {
      panelBoilTimer = PANEL_BOIL_INTERVAL / 24;
      panelShader.updateBoil();
    }

    handleHint(elapsed);
    handleTabFade(elapsed);
    handleState(elapsed);

    if (hintBreathe)
    {
      breatheTimer += elapsed;
      pullHint.color = FlxColor.interpolate(HINT_COLOR_DARK, HINT_COLOR_NORMAL, (Math.cos(breatheTimer * 2) / 2) + 0.5);
    }

    if (lock || curState != OPEN) return;

    final upP:Bool = controls.UI_UP_P;
    final downP:Bool = controls.UI_DOWN_P;

    if (controls.ACCEPT)
    {
      clickSelected();
    }

    if (upP || downP)
    {
      if (spamming)
      {
        if (spamTimer >= 0.12)
        {
          spamTimer = 0;
          changeSelection(upP ? -1 : 1);
        }
      }
      else if (spamTimer >= 0.4)
      {
        spamming = true;
      }
      else if (spamTimer <= 0)
      {
        changeSelection(upP ? -1 : 1);
      }

      spamTimer += elapsed;
    }
    else
    {
      spamming = false;
      spamTimer = 0;
    }
  }

  /**
   * Changes the selected button.
   * @param change How much to move the selection.
   * @param overrideSelection If true, the change will not be moved by the amount provided, and will snap to the value instead.
   */
  public function changeSelection(change:Int = 0, ?overrideSelection:Bool = false):Void
  {
    if (curState != OPEN) return;

    panelShader.doLerp = true;

    var prevSelected = curSelected;
    var amount = grpButtons.countLiving();

    if (overrideSelection)
    {
      curSelected = change;
      FlxG.sound.play(Paths.sound('quick-panel/menu-scroll'));
    }
    else
    {
      if (change != 0) FlxG.sound.play(Paths.sound('quick-panel/menu-scroll'));

      curSelected = FlxMath.wrap(curSelected + change, 0, amount - 1);
    }

    for (index => button in grpButtons.members)
    {
      button.selected = index == curSelected;

      index += 1;
    }

    var count:Int = grpButtons.members.length;
    var angleRange:Float = 4.45;
    var angleStep:Float = count > 1 ? (angleRange * 2) / (count - 1) : 0;
    var targetAngle = -90 + (angleRange - (angleStep * curSelected));

    panelShader.dir = targetAngle;

    quickPanelState.updateDescription(currentButton.data.description ?? 'bruh');

    if (currentButton.data.disabled)
    {
      panelShader.sliceColorStart = QuickPanelShader.START_COLOR_DISABLED;
      panelShader.sliceColorEnd = QuickPanelShader.END_COLOR_DISABLED;
    }
    else
    {
      panelShader.sliceColorStart = QuickPanelShader.START_COLOR_NORMAL;
      panelShader.sliceColorEnd = QuickPanelShader.END_COLOR_NORMAL;
    }

    if (overrideSelection)
    {
      if (change == prevSelected)
      {
        clickSelected();
      }
      else
      {
        paScroll.playAnimation(prevSelected > change ? 'bumpUp' : 'bumpDown');
      }
    }
    else
    {
      if (prevSelected == curSelected)
      {
        paScroll.playAnimation('bumpNeutral');
      }
      else
      {
        paScroll.playAnimation(change < 0 ? 'bumpUp' : 'bumpDown');
      }
    }
  }

  /**
   * Clicks the current button that is selected,
   * and calls the state to play the transition animation.
   */
  function clickSelected()
  {
    if (curState != OPEN) return;

    lock = true;

    if (currentButton.data.disabled)
    {
      panelShader.doLerp = false;
      paScroll.playAnimation('deny', true);
      FlxG.sound.play(Paths.sound('quick-panel/menu-deny'));

      paScroll.onFinish = function()
      {
        lock = false;
        panelShader.doLerp = true;
      };

      return;
    }

    paScroll.playAnimation('accept', true);
    FlxG.sound.play(Paths.sound('confirmMenu'));

    panelShader.doLerp = false;

    for (index => button in grpButtons.members)
    {
      if (button.selected)
      {
        button.paScale.playAnimation('bumpBig');
      }
      else
      {
        button.paFade.playAnimation('fade');
      }

      index += 1;
    }

    quickPanelState.startTransition(currentButton.data);
  }
}
