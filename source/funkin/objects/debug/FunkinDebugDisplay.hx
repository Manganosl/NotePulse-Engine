package funkin.objects.debug;

import flixel.util.FlxStringUtil;
import funkin.objects.debug.stats.FunkinStatsGraph;
import funkin.backend.utils.MemoryUtil;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

enum abstract FunkinDebugDisplayMode(Int) from Int to Int
{
  var SIMPLE;
  var ADVANCED;
  var DEBUG;
}

/**
 * A debug overlay showing useful info.
 */
#if cpp
@:access(lime._internal.backend.native.NativeCFFI)
#end
class FunkinDebugDisplay extends Sprite
{
  static final UPDATE_DELAY:Int = 100;
  static final INNER_RECT_DIFF:Int = 3;
  static final OUTER_RECT_DIMENSIONS:Array<Int> = [234, 201];
  static final OTHERS_OFFSET:Int = 8;
  static final DEBUG_BOX_GAP:Int = 6;
  static final DEBUG_BOX_MIN_HEIGHT:Int = 20;

  /**
   * The current display mode. See `FunkinDebugDisplayMode`.
   */
  public var mode(default, set):FunkinDebugDisplayMode = SIMPLE;

  public var isAdvanced(get, set):Bool;

  /**
   * The opacity of the debug display's background(s).
   */
  public var backgroundOpacity(default, set):Float = 0.5;

  var currentFPS:Int;
  var deltaTimeout:Float;
  var times:Array<Float>;
  var color:Int;

  #if !html5
  var gcMem:Float;
  var gcMemPeak:Float;

  var taskMem:Float;
  var taskMemPeak:Float;
  #end

  var background:Shape;

  var fpsGraph:FunkinStatsGraph;
  var gcMemGraph:FunkinStatsGraph;
  var taskMemGraph:FunkinStatsGraph;

  var infoDisplay:TextField;

  // Cool Debug info box thingy
  var debugBackground:Shape;
  var debugInfoDisplay:TextField;
  var debugBoxWidth:Float;
  var debugBoxY:Float;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000):Void
  {
    super();

    this.x = x;
    this.y = y;
    this.currentFPS = 0;
    this.deltaTimeout = 0.0;
    #if !html5
    this.gcMem = 0.0;
    this.gcMemPeak = 0.0;
    this.taskMem = 0.0;
    this.taskMemPeak = 0.0;
    #end
    this.times = [];
    this.color = color;
    this.backgroundOpacity = ClientPrefs.data.alphaFPS;
    this.mode = SIMPLE;
  }

  /**
   * Cycles through SIMPLE -> ADVANCED -> DEBUG -> SIMPLE ...
   */
  public function cycleMode():Void
  {
    mode = switch (mode)
    {
      case SIMPLE: ADVANCED;
      case ADVANCED: DEBUG;
      case DEBUG: SIMPLE;
      default: SIMPLE;
    }
  }

  function buildDebugDisplay(mode:FunkinDebugDisplayMode):Void
  {
    removeChildren(0, numChildren);
    debugBackground = null;
    debugInfoDisplay = null;

    final advanced:Bool = mode != SIMPLE;

    final BG_WIDTH_MULTIPLIER:Float = #if html5 advanced ? 1 : 0.3 #else 1 #end;

    #if html5
    final BG_HEIGHT_MULTIPLIER:Float = advanced ? 0.45 : 0.15;
    #else
    final BG_HEIGHT_MULTIPLIER:Float = advanced ? 1 : (MemoryUtil.supportsTaskMem()) ? 0.3 : 0.2;
    #end

    final bgWidth:Float = (OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER) + (INNER_RECT_DIFF * 2);
    final bgHeight:Float = (OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER) + (INNER_RECT_DIFF * 2);

    background = new Shape();
    background.graphics.beginFill(0x3d3f41, 1);
    background.graphics.drawRect(0, 0, bgWidth, bgHeight);
    background.graphics.endFill();
    background.graphics.beginFill(0x2c2f30, 1);
    background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER,
      OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER);
    background.graphics.endFill();
    background.alpha = backgroundOpacity;
    addChild(background);

    if (advanced)
    {
      createAdvancedElements();
      updateAdvancedDisplay();
    }
    else
    {
      createSimpleElements();
      updateSimpleDisplay();
    }

    if (mode == DEBUG){  // Only update the thingy on DEBUG mode to prevent lag
      createDebugElements(bgHeight);
      updateDebugDisplay();
    }
  }

  function createAdvancedElements():Void
  {
    final graphsWidth:Int = OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2) - (OTHERS_OFFSET * 3);
    final graphsHeight:Int = 25;

    fpsGraph = new FunkinStatsGraph(OTHERS_OFFSET, OTHERS_OFFSET + 49, graphsWidth, graphsHeight, color);
    fpsGraph.textDisplay.y = -49;
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    #if !html5
    gcMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (fpsGraph.y + fpsGraph.axisHeight) + 22), graphsWidth, graphsHeight, color);
    gcMemGraph.minValue = 0;
    addChild(gcMemGraph);

    if (MemoryUtil.supportsTaskMem())
    {
      taskMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (gcMemGraph.y + gcMemGraph.axisHeight) + 22), graphsWidth, graphsHeight,
        color);
      taskMemGraph.minValue = 0;
      addChild(taskMemGraph);
    }
    #end
  }

  function createSimpleElements():Void
  {
    infoDisplay = new TextField();
    infoDisplay.x = OTHERS_OFFSET;
    infoDisplay.y = OTHERS_OFFSET;
    infoDisplay.width = 500;
    infoDisplay.selectable = false;
    infoDisplay.mouseEnabled = false;
    infoDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, color, JUSTIFY);
    infoDisplay.antiAliasType = NORMAL;
    infoDisplay.multiline = true;
    addChild(infoDisplay);
  }

  /**
   * Builds the extra box shown under the simple/advanced display when `mode == DEBUG`.
   * Its own size is computed dynamically in `redrawDebugBox()` based on the text content.
   * @param prevBoxHeight  Height of the box directly above, so this one is placed right under it.
   */
  function createDebugElements(prevBoxHeight:Float):Void
  {
    debugBoxY = prevBoxHeight + DEBUG_BOX_GAP;

    debugBackground = new Shape();
    debugBackground.y = debugBoxY;
    addChild(debugBackground);

    debugInfoDisplay = new TextField();
    debugInfoDisplay.x = OTHERS_OFFSET;
    debugInfoDisplay.selectable = false;
    debugInfoDisplay.mouseEnabled = false;
    debugInfoDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, color, JUSTIFY);
    debugInfoDisplay.antiAliasType = NORMAL;
    debugInfoDisplay.multiline = true;
    debugInfoDisplay.wordWrap = false;
    debugInfoDisplay.autoSize = LEFT;
    addChild(debugInfoDisplay);

    redrawDebugBox();
  }

  function redrawDebugBox():Void
  {
    if (debugBackground == null || debugInfoDisplay == null) return;

    final textWidth:Float = Math.max(debugInfoDisplay.width, 1);
    final textHeight:Float = Math.max(debugInfoDisplay.textHeight, DEBUG_BOX_MIN_HEIGHT - (OTHERS_OFFSET * 2));

    final boxWidth:Float = textWidth + (OTHERS_OFFSET * 2);
    final boxHeight:Float = textHeight + (OTHERS_OFFSET * 2);

    debugBoxWidth = boxWidth;
    debugInfoDisplay.y = debugBoxY + OTHERS_OFFSET;

    debugBackground.graphics.clear();
    debugBackground.graphics.beginFill(0x3d3f41, 1);
    debugBackground.graphics.drawRect(0, 0, boxWidth, boxHeight);
    debugBackground.graphics.endFill();
    debugBackground.graphics.beginFill(0x2c2f30, 1);
    debugBackground.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, boxWidth - (INNER_RECT_DIFF * 2), boxHeight - (INNER_RECT_DIFF * 2));
    debugBackground.graphics.endFill();
    debugBackground.alpha = backgroundOpacity;
  }

  override function __enterFrame(deltaTime:Int):Void
  {
    #if cpp
    final currentTime:Float = lime.system.System.getTimer();
    #elseif html5
    final currentTime:Float = js.Browser.window.performance.now();
    #else
    final currentTime:Float = haxe.Timer.stamp() * 1000;
    #end

    times.push(currentTime);

    while (times[0] < currentTime - 1000)
    {
      times.shift();
    }

    if (deltaTimeout < UPDATE_DELAY)
    {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length;

    #if !html5
    gcMem = MemoryUtil.getGCMemory();

    if (gcMem > gcMemPeak) gcMemPeak = gcMem;

    if (MemoryUtil.supportsTaskMem())
    {
      taskMem = MemoryUtil.getTaskMemory();

      if (taskMem > taskMemPeak) taskMemPeak = taskMem;
    }
    #end

    if (mode == SIMPLE)
    {
      updateSimpleDisplay();
    }
    else
    {
      updateAdvancedDisplay();

      if (mode == DEBUG)
      {
        updateDebugDisplay();
      }
    }

    deltaTimeout = 0.0;
  }

  function updateAdvancedDisplay():Void
  {
    updateFPSGraph();
    #if !html5
    updateGcMemGraph();
    updateTaskMemGraph();
    #end

    final info:Array<String> = [];
    info.push('FPS: $currentFPS');
    info.push('AVG FPS: ${Math.floor(fpsGraph.average())}');
    info.push('1% LOW FPS: ${Math.floor(fpsGraph.lowest())}');
    fpsGraph.textDisplay.text = info.join('\n');

    #if !html5
    gcMemGraph.textDisplay.text = 'GC MEM: ${FlxStringUtil.formatBytes(gcMem).toUpperCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toUpperCase()}';

    if (taskMemGraph != null)
    {
      taskMemGraph.textDisplay.text = 'TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toUpperCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toUpperCase()}';
    }
    #end
  }

  function updateSimpleDisplay():Void
  {
    if (infoDisplay != null)
    {
      final info:Array<String> = [];

      info.push('FPS: $currentFPS');

      #if !html5
      info.push('GC MEM: ${FlxStringUtil.formatBytes(gcMem).toUpperCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toUpperCase()}');

      if (MemoryUtil.supportsTaskMem())
        info.push('TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toUpperCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toUpperCase()}');
      #end

      infoDisplay.text = info.join('\n');
    }
  }

  function updateDebugDisplay():Void
  {
    if (debugInfoDisplay == null) return;

    final info:Array<String> = [];

    final stateName:String = FlxG.state != null ? Type.getClassName(Type.getClass(FlxG.state)) : 'null';
    final subStateName:String = FlxG.state != null && FlxG.state.subState != null ? Type.getClassName(Type.getClass(FlxG.state.subState)) : 'none';

    @:privateAccess
    if(stateName != 'funkin.states.scripted.ScriptedState')
      info.push('State: $stateName');
    else
      info.push('State: ${funkin.states.scripted.ScriptedState.lastScriptPath}');
    @:privateAccess
    if(stateName != 'funkin.states.scripted.ScriptedSubstate')
      info.push('Substate: $subStateName');
    else
      info.push('Substate: ${funkin.states.scripted.ScriptedSubstate.lastScriptPath}');
    info.push('Members: ${FlxG.state != null ? FlxG.state.members.length : 0}');
    info.push('Cameras: ${FlxG.cameras.list.length}');
    info.push('Sounds: ${FlxG.sound.list.length}');
    info.push('Elapsed: ${Math.round(FlxG.elapsed * 1000)}ms');
    info.push('');
    info.push('Step: ${Conductor.curStep}');
    info.push('Beat: ${Conductor.curBeat}');
    info.push('Song Position: ${Math.round(Conductor.songPosition)}');
    info.push('BPM: ${Conductor.bpm}');
    info.push('Crochet: ${Conductor.crochet}');

    #if FLX_DEBUG
    if (FlxG.watch != null) info.push('WATCH ENTRIES: ${FlxG.watch.entries.length}');
    if (FlxG.log != null) info.push('LOG ENTRIES: ${FlxG.log.data.length}');
    #end

    debugInfoDisplay.text = info.join('\n');

    redrawDebugBox();
  }

  function updateFPSGraph(?currentFPS:Int = 0):Void
  {
    fpsGraph.maxValue = FlxG.drawFramerate;
    fpsGraph.update(times.length);
  }

  #if !html5
  function updateGcMemGraph(?currentFPS:Int = 0):Void
  {
    gcMemGraph.maxValue = gcMemPeak;
    gcMemGraph.update(gcMem);
  }

  function updateTaskMemGraph(?currentFPS:Int = 0):Void
  {
    if (taskMemGraph != null)
    {
      taskMemGraph.maxValue = taskMemPeak;
      taskMemGraph.update(taskMem);
    }
  }
  #end

  function set_mode(value:FunkinDebugDisplayMode):FunkinDebugDisplayMode
  {
    buildDebugDisplay(value);

    return mode = value;
  }

  function get_isAdvanced():Bool
  {
    return mode != SIMPLE;
  }

  function set_isAdvanced(value:Bool):Bool
  {
    mode = value ? ADVANCED : SIMPLE;

    return value;
  }

  function set_backgroundOpacity(value:Float):Float
  {
    if (background != null) background.alpha = value;
    if (debugBackground != null) debugBackground.alpha = value;

    return backgroundOpacity = value;
  }
}
