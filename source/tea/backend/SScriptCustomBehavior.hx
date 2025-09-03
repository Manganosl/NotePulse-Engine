package tea.backend;
// Hi, it's Manganos. I don't care if you steal any of this custom SScript, but give credits :P

/**
 * Custom behavior hooks for SScript field resolution.
 * 
 * Keep SScript's default behavior, but when an object field is missing,
 * allow a fallback into per-object hooks (getField/setField/resolve).
 */
interface SScriptCustomBehavior {
    public function customGet(o:Dynamic, f:String):Dynamic;
    public function customSet(o:Dynamic, f:String, v:Dynamic):Dynamic;
}

class DefaultSScriptCustomBehavior implements SScriptCustomBehavior {
    public function new() {}

    public function customGet(o:Dynamic, f:String):Dynamic {
        var fn = Reflect.field(o, "getField");
        if (fn != null) return Reflect.callMethod(o, fn, [f]);

        var res = Reflect.field(o, "resolve");
        if (res != null) return Reflect.callMethod(o, res, [f]);

        return Reflect.field(o, f);
    }

    public function customSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
        var fn = Reflect.field(o, "setField");
        if (fn != null) return Reflect.callMethod(o, fn, [f, v]);

        Reflect.setField(o, f, v);
        return v;
    }
}
