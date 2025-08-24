package modchart;

import flixel.FlxBasic;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.util.FlxSort;
import haxe.ds.Vector;
import modchart.backend.core.ArrowData;
import modchart.backend.core.ModifierParameters;
import modchart.backend.core.Node.NodeFunction;
import modchart.backend.core.VisualParameters;
import modchart.backend.graphics.renderers.*;
import modchart.backend.util.ModchartUtil;
import modchart.engine.modifiers.list.*;
import modchart.events.*;
import modchart.events.types.*;

@:allow(modchart.backend.ModifierGroup)
@:access(modchart.engine.PlayField)
#if !openfl_debug
@:fileXml('tags="haxe,release"') @:noDebug
#end
final class Manager extends FlxBasic {
    public static var instance:Manager;

    @:deprecated("Use `Config.RENDER_ARROW_PATHS` instead.")
    public var renderArrowPaths:Bool = false;

    public var playfields:Vector<PlayField> = new Vector<PlayField>(16);
    private var playfieldCount:Int = 0;

    public function new() {
        super();
        instance = this;

        Adapter.init();
        Adapter.instance.onModchartingInitialization();

        addPlayfield();
    }

    /**
     * Apply a function to all playfields or a specific one.
     */
    @:noCompletion
    private inline function __forEachPlayfield(func:PlayField->Void, player:Int = -1) {
        if (playfieldCount <= 1 || player != -1) {
            var pf = playfields[player != -1 ? player : 0];
            if (pf != null) func(pf);
            return;
        }

        for (i in 0...playfieldCount) {
            var pf = playfields[i];
            if (pf != null) func(pf);
        }
    }

    public inline function addModifier(name:String, field:Int = -1)
        __forEachPlayfield((pf) -> pf.addModifier(name), field);

    public inline function addScriptedModifier(name:String, instance:Modifier, field:Int = -1)
        __forEachPlayfield((pf) -> pf.addScriptedModifier(name, instance), field);

    public inline function setPercent(name:String, value:Float, player:Int = -1, field:Int = -1)
        __forEachPlayfield((pf) -> pf.setPercent(name, value, player), field);

    public inline function getPercent(name:String, player:Int = 0, field:Int = 0):Float {
        final possiblePlayfield = playfields[field];
        if (possiblePlayfield != null)
            return possiblePlayfield.getPercent(name, player);
        return 0.;
    }

    public inline function addEvent(event:Event, field:Int = -1)
        __forEachPlayfield((pf) -> pf.addEvent(event), field);

    public inline function set(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1)
        __forEachPlayfield((pf) -> pf.set(name, beat, value, player), field);

    public inline function ease(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1)
        __forEachPlayfield((pf) -> pf.ease(name, beat, length, value, easeFunc, player), field);

    public inline function doEase(name:String, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1)
        __forEachPlayfield((pf) -> pf.doEase(name, value, easeFunc, player), field);

    public inline function add(name:String, beat:Float, length:Float, value:Float = 1, easeFunc:EaseFunction, player:Int = -1, field:Int = -1)
        __forEachPlayfield((pf) -> pf.add(name, beat, length, value, easeFunc, player), field);

    public inline function setAdd(name:String, beat:Float, value:Float, player:Int = -1, field:Int = -1)
        __forEachPlayfield((pf) -> pf.setAdd(name, beat, value, player), field);

    public inline function repeater(beat:Float, length:Float, callback:Event->Void, field:Int = -1)
        __forEachPlayfield((pf) -> pf.repeater(beat, length, callback), field);

    public inline function callback(beat:Float, callback:Event->Void, field:Int = -1)
        __forEachPlayfield((pf) -> pf.callback(beat, callback), field);

    public inline function node(input:Array<String>, output:Array<String>, func:NodeFunction, field:Int = -1)
        __forEachPlayfield((pf) -> pf.node(input, output, func), field);

    public inline function alias(name:String, alias:String, field:Int)
        __forEachPlayfield((pf) -> pf.alias(name, alias), field);

    /**
     * Safely add a new playfield.
     */
    public inline function addPlayfield() {
        if (playfieldCount >= playfields.length) {
            throw 'Too many playfields! Max = ${playfields.length}';
        }
        playfields[playfieldCount++] = new PlayField();
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);
        __forEachPlayfield(pf -> pf.update(elapsed));
    }

    override function draw():Void {
        var total = 0;
        __forEachPlayfield(pf -> {
            pf.draw();
            total += pf.drawCB.length;
        });

        var drawQueue:Vector<Funny> = new Vector<Funny>(total);
        var j = 0;

        __forEachPlayfield(pf -> {
            for (x in pf.drawCB) {
                if (x != null && x.callback != null) {
                    drawQueue[j++] = x;
                }
            }
        });

        if (j > 1) {
            var temp:Array<Funny> = [];
            for (i in 0...j) temp.push(drawQueue[i]);
            temp.sort((a, b) -> FlxSort.byValues(FlxSort.DESCENDING, a.z, b.z));
            for (i in 0...j) drawQueue[i] = temp[i];
        }

        for (i in 0...j) {
            var item = drawQueue[i];
            if (item != null && item.callback != null) {
                item.callback();
            }
        }
    }

    override function destroy():Void {
        super.destroy();
        __forEachPlayfield(pf -> pf.destroy());
    }

    public static var HOLD_SIZE:Float = 50 * 0.7;
    public static var HOLD_SIZEDIV2:Float = (50 * 0.7) * 0.5;
    public static var ARROW_SIZE:Float = 160 * 0.7;
    public static var ARROW_SIZEDIV2:Float = (160 * 0.7) * 0.5;
}

typedef Funny = {callback:Void->Void, z:Float};
