package tea.backend;

/**
 * Custom behavior hooks for SScript field resolution.
 */
interface SScriptCustomBehavior {
    public function hGet(o:Dynamic, f:String):Dynamic;
    public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic;
}

class HandleSScriptCustomBehavior implements SScriptCustomBehavior {
    public function new() {}

    public function hGet(o:Dynamic, f:String):Dynamic {
        var fn = Reflect.field(o, "getField");
        if (fn != null) return Reflect.callMethod(o, fn, [f]);

        var res = Reflect.field(o, "resolve");
        if (res != null) return Reflect.callMethod(o, res, [f]);

        return Reflect.field(o, f);
    }

    public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
        var fn = Reflect.field(o, "setField");
        if (fn != null) return Reflect.callMethod(o, fn, [f, v]);

        Reflect.setField(o, f, v);
        return v;
    }
}
