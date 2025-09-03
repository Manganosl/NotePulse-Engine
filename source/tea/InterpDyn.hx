package tea;

import hscriptBase.Interp;

/**
 * InterpDyn extends the base interpreter to add safe fallbacks:
 * - If base resolution fails, consult the SScript host (if it implements
 *   SScriptCustomBehavior) and/or the target object's getField/setField/resolve.
 */
class InterpDyn extends Interp {
    public function new() {
        super();
    }

    #if (hscript_pos)
    override public function get(o:Dynamic, f:String, p:Dynamic):Dynamic {
        try {
            return super.get(o, f, p);
        } catch (_:Dynamic) {
        }
        return fallbackGet(o, f);
    }
    #else
    override public function get(o:Dynamic, f:String):Dynamic {
        try {
            return super.get(o, f);
        } catch (_:Dynamic) {
        }
        return fallbackGet(o, f);
    }
    #end

    #if (hscript_pos)
    override public function set(o:Dynamic, f:String, v:Dynamic, p:Dynamic):Dynamic {
        if (Reflect.hasField(o, f)) {
            return super.set(o, f, v, p);
        }
        return fallbackSet(o, f, v);
    }
    #else
    override public function set(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (Reflect.hasField(o, f)) {
            return super.set(o, f, v);
        }
        return fallbackSet(o, f, v);
    }
    #end

    function fallbackGet(o:Dynamic, f:String):Dynamic {
        var scr:Dynamic = Reflect.field(this, "scr");
        if (scr != null && Std.isOfType(scr, tea.backend.SScriptCustomBehavior)) {
            try {
                if (Std.isOfType(scr, tea.backend.SScriptCustomBehavior)) {
                    var handler:tea.backend.SScriptCustomBehavior = cast scr;
                    return handler.customGet(o, f);
                }
            } catch (_:Dynamic) {}
        }

        var fn = Reflect.field(o, "getField");
        if (fn != null) return Reflect.callMethod(o, fn, [f]);
        var res = Reflect.field(o, "resolve");
        if (res != null) return Reflect.callMethod(o, res, [f]);

        return Reflect.field(o, f);
    }

    function fallbackSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
        var scr:Dynamic = Reflect.field(this, "scr");
        if (scr != null && Std.isOfType(scr, tea.backend.SScriptCustomBehavior)) {
            try {
                if (Std.isOfType(scr, tea.backend.SScriptCustomBehavior)) {
                    var handler:tea.backend.SScriptCustomBehavior = cast scr;
                    return handler.customSet(o, f, v);
                }
            } catch (_:Dynamic) {}
        }

        var fn = Reflect.field(o, "setField");
        if (fn != null) return Reflect.callMethod(o, fn, [f, v]);

        Reflect.setField(o, f, v);
        return v;
    }
}
