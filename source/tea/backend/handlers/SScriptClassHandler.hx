package tea.backend.handlers;

import tea.hscriptBase.Interp;
import tea.hscriptBase.Expr;
import tea.hscriptBase.Parser; 
import tea.hscriptBase.Tools;
import haxe.ds.StringMap; 
import haxe.ds.Map;

// Handler that is stored in the interpreter when a script `class X { ... }` is defined.
// The interpreter will call handler.hnew(args) when `new X(...)` is executed.
class SScriptClassHandler {
    public var parentInterp:Interp;
    public var name:String;
    public var fields:Array<Expr>;
    public var extend:Array<String>;

    public function new(parent:Interp, name:String, fields:Array<Expr>, ?extend:Array<String>) {
        this.parentInterp = parent;
        this.name = name;
        this.fields = fields;
        this.extend = extend;
    }

public function hnew(args:Array<Dynamic>):Dynamic {
    var instInterp = new Interp();

    // Robust copy of parent interpreter variables into instance interpreter.
    try {
        for (k in (parentInterp.variables.keys() : Iterator<String>)) {
            instInterp.variables.set(k, parentInterp.variables.get(k));
        }
    } catch (e:Dynamic) {
        try {
            var it:Iterator<String> = cast parentInterp.variables.keys();
            while (it.hasNext()) {
                var k:String = it.next();
                instInterp.variables.set(k, parentInterp.variables.get(k));
            }
        } catch (e2:Dynamic) {
            for (k in Reflect.fields(parentInterp.variables)) {
                var v = Reflect.field(parentInterp.variables, k);
                instInterp.variables.set(k, v);
            }
        }
    }

    var inst = new SScriptTemplate(instInterp, null);

    // Provide 'this' reference for methods.
    instInterp.variables.set("this", inst);

    // Helper to robustly get keys from a variables map
    inline function getKeys(map:Dynamic):Array<String> {
        var keys:Array<String> = [];
        try {
            for (k in (map.keys() : Iterator<String>)) keys.push(k);
        } catch (e:Dynamic) {
            try {
                var it:Iterator<String> = cast map.keys();
                while (it.hasNext()) keys.push(it.next());
            } catch (e2:Dynamic) {
                keys = Reflect.fields(map);
            }
        }
        return keys;
    }

    // Build ancestor handler chain (root -> nearest)
    var ancestorHandlers:Array<Dynamic> = [];
    var processed = new Map<String,Bool>();

    function collectAncestors(name:String) {
        if (processed.exists(name)) return;
        var base = parentInterp.variables.get(name);
        if (base == null) return;
        var bext:Dynamic = Reflect.field(base, "extend");
        if (bext != null) {
            for (bn in (bext : Array<String>)) collectAncestors(bn);
        }
        ancestorHandlers.push(base);
        processed.set(name, true);
    }

    if (extend != null) {
        for (bn in extend) collectAncestors(bn);
    }

    // Evaluate ancestor fields and capture ancestor-provided items into superMap.
    var superMap = new Map<String,Dynamic>();
    var ancestorCtors:Array<Dynamic> = [];

    for (b in ancestorHandlers) {
        var before = getKeys(instInterp.variables);
        var bfields:Dynamic = Reflect.field(b, "fields");
        if (bfields != null) {
            for (bf in (bfields : Array<Expr>)) instInterp.expr(bf);
        }
        var after = getKeys(instInterp.variables);

        for (k in after) {
            superMap.set(k, instInterp.variables.get(k));
        }

        if (superMap.exists("new")) {
            ancestorCtors.push(superMap.get("new"));
        }
    }

    // Evaluate this class' own fields (child overrides ancestor names here)
    for (f in fields) instInterp.expr(f);

    // Build a plain Haxe object holding ancestor implementations for 'super'
    var superObj = {};
    for (k in superMap.keys()) {
        Reflect.setField(superObj, k, superMap.get(k));
    }

    instInterp.variables.set("super", superObj);
    inst._super = superObj;

    // Call ancestor constructors (root -> nearest)
    for (ctor in ancestorCtors) {
        try {
            ctor([]);
        } catch (e:Dynamic) {
            // ignore ancestor constructor errors
        }
    }

    // Finally call this class's constructor (if present)
    if (instInterp.variables.exists("new")) {
        var ctor = instInterp.variables.get("new");
        ctor(args);
    }

    return inst;
}

}

class SScriptTemplate implements SScriptCustomBehavior {
    public var __interp:Interp;
    public var _host:Dynamic;
    public var _super:Dynamic;

    public function new(interp:Interp, ?host:Dynamic) {
        this.__interp = interp;
        this._host = host;
    }

public function hGet(o:Dynamic, f:String):Dynamic {
    var gname = "get_" + f;
    if (__interp.variables.exists(gname)) {
        var getter = __interp.variables.get(gname);
        return getter([]);
    }

    if (__interp.variables.exists(f)) {
        return __interp.variables.get(f);
    }

    // Allow direct access to super object if defined
    if (__interp.variables.exists("super")) {
        var s = __interp.variables.get("super");
        var maybe = Reflect.field(s, f);
        if (maybe != null) return maybe;
    }

    if (_host != null) {
        var hostGet = Reflect.field(_host, "getField");
        if (hostGet != null) return Reflect.callMethod(_host, hostGet, [f]);
        return Reflect.getProperty(_host, f);
    }

    return null;
}

public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
    var sname = "set_" + f;
    if (__interp.variables.exists(sname)) {
        var setter = __interp.variables.get(sname);
        return setter([v]);
    }

    if (_host != null) {
        var hostSet = Reflect.field(_host, "setField");
        if (hostSet != null) return Reflect.callMethod(_host, hostSet, [f, v]);
        Reflect.setField(_host, f, v);
        return v;
    }

    __interp.variables.set(f, v);
    return v;
}

    public function getField(f:String):Dynamic {
        return hGet(this, f);
    }
    public function setField(f:String, v:Dynamic):Dynamic {
        return hSet(this, f, v);
    }
}
