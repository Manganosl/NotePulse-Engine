package tea;

import hscriptBase.Interp;
import tea.backend.SScriptCustomBehavior;

/**
 * InterpDyn: route field access and assignment through SScriptCustomBehavior
 * (customGet/customSet) when the target object implements it, mirroring the
 * way Funkin's Interp handles IHScriptCustomBehaviour (hget/hset).
 *
 * This version gives priority to the object's custom behaviour, then falls
 * back to the normal Interp get/set logic.
 */
class InterpDyn extends Interp {
    public function new() {
        super();
    }

    // ---------------- GET ----------------
    #if (hscript_pos)
    override public function get(o:Dynamic, f:String, p:Dynamic):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.customGet(o, f);
        }
        return super.get(o, f, p);
    }
    #else
    override public function get(o:Dynamic, f:String):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.customGet(o, f);
        }
        return super.get(o, f);
    }
    #end

    // ---------------- SET ----------------
    #if (hscript_pos)
    override public function set(o:Dynamic, f:String, v:Dynamic, p:Dynamic):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.customSet(o, f, v);
        }
        return super.set(o, f, v, p);
    }
    #else
    override public function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (o != null && Std.isOfType(o, SScriptCustomBehavior)) {
            var b:SScriptCustomBehavior = cast o;
            return b.customSet(o, f, v);
        }
        return super.set(o, f, v);
    }
    #end
}
