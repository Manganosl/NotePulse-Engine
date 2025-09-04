package tea;

import hscriptBase.Interp;
import tea.backend.SScriptCustomBehavior;

class InterpDyn extends Interp {
    public function new() {
        super();
    }

    #if (hscript_pos)
    override public function get(o:Dynamic, f:String, p:Dynamic):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.hGet(o, f);
        }
        return super.get(o, f, p);
    }
    #else
    override public function get(o:Dynamic, f:String):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.hGet(o, f);
        }
        return super.get(o, f);
    }
    #end

    #if (hscript_pos)
    override public function set(o:Dynamic, f:String, v:Dynamic, p:Dynamic):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.hSet(o, f, v);
        }
        return super.set(o, f, v, p);
    }
    #else
    override public function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.hSet(o, f, v);
        }
        return super.set(o, f, v);
    }
    #end
}
