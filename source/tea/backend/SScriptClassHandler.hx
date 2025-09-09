package tea.backend;

import hscriptBase.Interp;
import hscriptBase.Expr;
import hscriptBase.Parser; 
import hscriptBase.Tools;
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

        #if haxe3
        for (k in parentInterp.variables.keys()) {
            instInterp.variables.set(k, parentInterp.variables.get(k));
        }
        #else
        // adjust for alternative Map implementations (Im too lazy rn)
        #end

        var inst = new SScriptTemplate(instInterp, null);

        instInterp.variables.set("this", inst);

        for (f in fields) {
            instInterp.expr(f);
        }

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

        if (_host != null) return Reflect.getProperty(_host, f);

        return null;
    }

    public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
        var sname = "set_" + f;
        if (__interp.variables.exists(sname)) {
            var setter = __interp.variables.get(sname);
            return setter([v]);
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
