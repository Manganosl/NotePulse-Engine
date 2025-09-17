package tea.backend.handlers;

import tea.hscriptBase.Interp;
import tea.hscriptBase.Expr;
import tea.hscriptBase.Parser;
import tea.hscriptBase.Tools;
import haxe.ds.Map;
import Reflect;
import Type;
import Std;
import haxe.Log;

/**
 * SScriptClassHandler — adds RuleScript-style scripted classes to SScript.
 *
 * Behavior:
 *  - Instances get a per-instance Interp stored as __interp on the host object.
 *  - Methods/fields defined in the class are evaluated in that per-instance interp,
 *    so closures capture instance locals correctly and "this" is available.
 *  - Supports extending Haxe host classes or other scripted classes (scripted inheritance).
 *  - Getter/setter support via get_<name> / set_<name>.
 *
 * Usage: Interp.cnew will call handler.hnew(args) to construct an instance.
 */
class SScriptClassHandler {
    public static var staticHandler = {};

    public var parentInterp:Interp;
    public var name:String;
    public var fields:Array<Expr>;
    public var extend:Array<String>;

    public function new(parentInterp:Interp, name:String, fields:Array<Expr>, ?extend:Array<String>, ?interfaces:Array<String>) {
        this.parentInterp = parentInterp;
        this.name = name;
        this.fields = fields;
        this.extend = extend;
    }

    /**
     * Create an instance of this scripted class.
     * Steps:
     *  - create a fresh interpreter (instInterp) for the instance
     *  - prepare instInterp.locals and instInterp.variables (capture parent's scope)
     *  - if extending scripted ancestors, evaluate ancestor fields into instInterp (oldest first)
     *  - evaluate this class' fields into instInterp
     *  - attach all instance variables / methods to the host object
     *  - call ancestor constructors (oldest -> newest), then this class' constructor 'new' if present
     */
    public function hnew(args:Array<Dynamic>):Dynamic {
        // create instance interpreter
        var instInterp = new Interp();
        // try to preserve parent's error handler if present
        try {
            // no shared errorHandler available on this Interp implementation
        } catch(e:Dynamic) {}

        // duplicate parent's locals/variables so instance can see outer scope but keep its own map
        // keep instInterp.locals private (do not duplicate parent's locals)
        // Variables (globals) are duplicated to avoid accidental mutation of parent's map
        // duplicate parent variables manually if needed
        instInterp.variables = new Map<String, Dynamic>();
        // copy parent's variables (shallow)
        try {
            for(k in parentInterp.variables.keys()) instInterp.variables.set(k, parentInterp.variables.get(k));
        } catch(e:Dynamic) {}


        // Prepare host object
        var host:Dynamic = null;

        // resolve 'extend' if present
        var extendName:String = null;
        if (extend != null && extend.length > 0) {
            extendName = extend.join(".");
        }

        // If extend refers to a Haxe class, create instance using Type.createInstance first
        var extendedHandler:Dynamic = null;
        if (extendName != null) {
            // Try to resolve a scripted class handler from global customClasses or parent's variables
            try {
                if (Interp.customClasses.exists(extendName)) extendedHandler = Interp.customClasses.get(extendName);
            } catch(e:Dynamic) {}
            if (extendedHandler == null) {
                // try to resolve by last identifier
                var last = extend[extend.length - 1];
                try {
                    if (Interp.customClasses.exists(last)) extendedHandler = Interp.customClasses.get(last);
                } catch(e:Dynamic) {}
            }
        }

        // If extend resolves to a Haxe class (native), instantiate now (constructor will run on host)
        if (extendedHandler == null && extendName != null) {
            try {
                var hxClass = Type.resolveClass(extendName);
                if (hxClass == null && extend.length > 0) {
                    // try last segment
                    hxClass = Type.resolveClass(extend[extend.length - 1]);
                }
                if (hxClass != null) {
                    host = Type.createInstance(hxClass, args);
                }
            } catch(e:Dynamic) {
                // ignore, we'll fallback to TemplateInstance below
            }
        }

        // If no Haxe host created, use a TemplateInstance
        if (host == null) host = new TemplateInstance();

        // attach interpreter reference and ensure get/set helpers exist
        host.__interp = instInterp;

        // Ensure instInterp locals contain a 'this' binding so functions capture it
        // set "this" in instance variables so functions can access via variables map
        try { instInterp.variables.set("this", host); } catch(e:Dynamic) {}


        // instInterp.variables will be the per-instance storage for functions/fields
        instInterp.variables = new Map<String, Dynamic>();

        // Helper: collect scripted ancestor handlers (oldest first)
        var ancestorHandlers:Array<Dynamic> = [];
        if (extendedHandler != null) {
            // walk ancestor chain
            var cur = extendedHandler;
            var seen = new Map<String,Bool>();
            while (cur != null) {
                // avoid infinite loops
                var cname:String = null;
                try {
                    cname = Reflect.field(cur, "name");
                } catch(e:Dynamic) {
                    cname = null;
                }
                if (cname != null) {
                    if (seen.exists(cname)) break;
                    seen.set(cname, true);
                }
                ancestorHandlers.unshift(cur); // insert at beginning so oldest ends up first
                // try to follow cur.extend if present
                var nextExtend:Dynamic = null;
                try {
                    nextExtend = Reflect.field(cur, "extend");
                } catch(e:Dynamic) {
                    nextExtend = null;
                }
                if (nextExtend == null) break;
                var nextName:String = null;
                if (Std.is(nextExtend, Array)) {
                    var arr:Array<Dynamic> = cast nextExtend;
                    nextName = (arr.length > 0 ? cast arr[arr.length - 1] : null);
                } else {
                    nextName = Std.string(nextExtend);
                }

                if (nextName == null) break;
                // find next handler by name in Interp.customClasses
                if (Interp.customClasses.exists(nextName)) {
                    cur = Interp.customClasses.get(nextName);
                } else {
                    // stop if we cannot find further scripted parent
                    break;
                }
            }
        }

        // Evaluate ancestor fields in order (oldest -> nearest parent)
        var ancestorCtors:Array<Dynamic> = [];
        for (ah in ancestorHandlers) {
            var aFields:Array<Expr> = Reflect.field(ah, "fields");
            if (aFields == null) continue;
            for (f in aFields) {
                // evaluate field in instance interpreter
                try {
                    instInterp.expr(f);
                } catch(e:Dynamic) {
                    Log.trace("SScript: ancestor field init failed in class '" + name + "': " + Std.string(e));
                    throw e;
                }
                // if this evaluation just created a 'new' function, capture it as ancestor ctor
                if (instInterp.variables.exists("new")) {
                    var cand = instInterp.variables.get("new");
                    if (cand != null) ancestorCtors.push(cand);
                }
            }
        }

        // Evaluate this class' own fields (child overrides ancestor names here)
        for (f in fields) {
            try {
                instInterp.expr(f);
            } catch (e:Dynamic) {
                Log.trace("SScript: class field init failed in class '" + name + "': " + Std.string(e));
                throw e;
            }
        }

        // Attach instance variables (from instInterp.variables) to host object so Reflect.field works
        for (k in instInterp.variables.keys()) {
            try {
                var val = instInterp.variables.get(k);
                Reflect.setField(host, k, val);
            } catch(e:Dynamic) {
                // ignore single field attach errors
            }
        }

        // Call ancestor constructors in order
        for (ctor in ancestorCtors) {
            try {
                // call with the same args used for instance creation
                Reflect.callMethod(ctor, ctor, args == null ? [] : args);
            } catch (e:Dynamic) {
                Log.trace("SScript: ancestor ctor threw: " + Std.string(e));
            }
        }

        // Call this class constructor if present
        if (instInterp.variables.exists("new")) {
            var myctor = instInterp.variables.get("new");
            if (myctor != null) {
                try {
                    Reflect.callMethod(myctor, myctor, args == null ? [] : args);
                } catch (e:Dynamic) {
                    Log.trace("SScript: instance ctor threw in class '" + name + "': " + Std.string(e));
                    throw e;
                }
            }
        }

        // Attach helper getField/setField to host so external accessors can route to instInterp
        Reflect.setField(host, "getField", Reflect.field(this, "getField"));
        Reflect.setField(host, "setField", Reflect.field(this, "setField"));

        return host;
    }

    /**
     * Getter hook used for property lookup routing.
     * Prefers instance getter 'get_<name>', then instance variable, then host property.
     */
    public function hGet(o:Dynamic, f:String):Dynamic {
        if (o == null) return null;
        var inst:Interp = null;
        try {
            inst = o.__interp;
        } catch(e:Dynamic) {
            inst = null;
        }
        if (inst != null) {
            if (inst.variables.exists("get_" + f)) {
                var g = inst.variables.get("get_" + f);
                return Reflect.callMethod(g, g, []);
            }
            if (inst.variables.exists(f)) return inst.variables.get(f);
        }
        // fallback to host's resolve/getField if available
        var resolver = Reflect.field(o, "resolve");
        if (resolver != null) return Reflect.callMethod(o, resolver, [f]);
        return Reflect.field(o, f);
    }

    /**
     * Setter hook used for property assignments.
     * Prefers instance setter 'set_<name>', otherwise writes into instance variables and host field.
     */
    public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (o == null) return v;
        var inst:Interp = null;
        try {
            inst = o.__interp;
        } catch(e:Dynamic) {
            inst = null;
        }
        if (inst != null) {
            if (inst.variables.exists("set_" + f)) {
                var s = inst.variables.get("set_" + f);
                return Reflect.callMethod(s, s, [v]);
            }
            // write into instance variables map and host field for reflect
            inst.variables.set(f, v);
            Reflect.setField(o, f, v);
            return v;
        }

        Reflect.setField(o, f, v);
        return v;
    }

    // Simple wrappers for attaching to host objects
    public function getField(f:String):Dynamic {
        return hGet(this, f);
    }
    public function setField(f:String, v:Dynamic):Dynamic {
        return hSet(this, f, v);
    }
}

/**
 * TemplateInstance: default plain host when no Haxe host class is extended.
 */
class TemplateInstance {
    public var __interp:Interp;

    public function new() {}

    public function getField(name:String):Dynamic {
        var inst = __interp;
        if (inst == null) return Reflect.field(this, name);
        if (inst.variables.exists("get_" + name)) {
            var g = inst.variables.get("get_" + name);
            return Reflect.callMethod(g, g, []);
        }
        if (inst.variables.exists(name)) return inst.variables.get(name);
        return Reflect.field(this, name);
    }

    public function setField(name:String, v:Dynamic):Dynamic {
        var inst = __interp;
        if (inst == null) {
            Reflect.setField(this, name, v);
            return v;
        }
        if (inst.variables.exists("set_" + name)) {
            var s = inst.variables.get("set_" + name);
            return Reflect.callMethod(s, s, [v]);
        }
        inst.variables.set(name, v);
        Reflect.setField(this, name, v);
        return v;
    }
}
