package tea.backend;

import hscriptBase.Interp;
import hscriptBase.Expr;
import hscriptBase.Parser; 
import hscriptBase.Tools;
import haxe.ds.StringMap; 
import Type;
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

        var hostBacking:Dynamic = null;

        if (extend != null && extend.length > 0) {
            // support dotted paths: ["flixel","FlxSprite"] -> "flixel.FlxSprite"
            var parentName = extend.join(".");
            // also keep the short/simple name (last path component), e.g. "FlxSprite"
            var shortName = extend[extend.length - 1];

            // try a soft-coded parent handler (script-defined class)
            var softParent:Dynamic = null;
            try { softParent = parentInterp.customClasses.get(parentName); } catch(_) { softParent = null; }
            if (softParent == null && parentName != shortName) {
                try { softParent = parentInterp.customClasses.get(shortName); } catch(_) { softParent = null; }
            }

            if (softParent != null) {
                var hnewParent = Reflect.field(softParent, "hnew");
                if (hnewParent != null) hostBacking = Reflect.callMethod(softParent, hnewParent, args);
            } else {
                // try host/native class exposed in parentInterp.variables
                var exposed = parentInterp.variables.get(parentName);
                if (exposed == null) exposed = parentInterp.variables.get(shortName);

                if (exposed != null) {
                    try {
                        hostBacking = Type.createInstance(exposed, args);
                    } catch(e:Dynamic) {
                        // fallback: if 'exposed' is a factory function rather than a Class
                        try {
                            hostBacking = Reflect.callMethod(exposed, exposed, args);
                        } catch(e2:Dynamic) {
                            hostBacking = null;
                        }
                    }
                } else {
                    // fallback to Type.resolveClass() trying full and short names
                    var klass = Type.resolveClass(parentName);
                    if (klass == null && parentName != shortName) klass = Type.resolveClass(shortName);
                    if (klass != null) hostBacking = Type.createInstance(klass, args);
                }
            }
        }
        var inst = if (hostBacking != null) new SScriptTemplate(instInterp, hostBacking)
        else new SScriptTemplate(instInterp, null);
    
        if (hostBacking != null) {
            inst.parentInstance = hostBacking;
            inst.parentInterp   = parentInterp;
            try {
                trace("[SScriptClassHandler] linked native parent for " + name + " -> " + Std.string(Type.getClassName(Type.getClass(hostBacking))));
            } catch(_) {}
        }
        // inject a "super" function into the child interpreter
        var softParent:Dynamic = null;
        if (extend != null && extend.length > 0) {
            var parentName = extend.join(".");
            var shortName = extend[extend.length - 1];
            instInterp.variables.set("super", function(args:Array<Dynamic>) {
                var result:Dynamic = null;

                // try script-defined parent
                try softParent = parentInterp.customClasses.get(parentName) catch(_) {}
                if (softParent == null && parentName != shortName) {
                    try softParent = parentInterp.customClasses.get(shortName) catch(_) {}
                }

                if (softParent != null) {
                    var hnewParent = Reflect.field(softParent, "hnew");
                    if (hnewParent != null) result = Reflect.callMethod(softParent, hnewParent, args);
                } else if (hostBacking != null) {
                    result = hostBacking;
                }

                return result;
            });
        }

        var superProxy = new SScriptSuper(inst.parentInstance, (softParent == null ? null : softParent), parentInterp);
        instInterp.variables.set("super", superProxy);

        instInterp.variables.set("this", inst);
        instInterp.variables.set("self", inst);

        for (f in fields) {
            instInterp.expr(f);
        }

        if (instInterp.variables.exists("new")) {
            var ctor = instInterp.variables.get("new");
            Reflect.callMethod(inst, ctor, args);
        }
        return inst;
    }
}

class SScriptTemplate implements SScriptCustomBehavior {
public var __interp:Interp;
public var _host:Dynamic;
public var parentInterp:Interp;
public var parentInstance:Dynamic;

public function new(interp:Interp, ?host:Dynamic) {
    this.__interp = interp;
    this._host = host;
    this.parentInterp = null;
    this.parentInstance = null;
}

public function hGet(o:Dynamic, f:String):Dynamic {
    // Prefer script-defined getter: get_<name>
    var gname = "get_" + f;
    if (__interp.variables.exists(gname)) {
        var getter = __interp.variables.get(gname);
        return Reflect.callMethod(this, getter, []);
    }

    // Instance-local stored fields
    if (__interp.variables.exists(f)) {
        var instVal = __interp.variables.get(f);
        try {
            // If instance field is a function, bind it to the script instance
            if (Reflect.isFunction != null && Reflect.isFunction(instVal)) {
                var self = this;
                var fn = instVal;
                return function(args:Array<Dynamic>) {
                    return Reflect.callMethod(self, fn, args);
                };
            }
        } catch(_) {}
        return instVal;
    }

    // If there is a host backing object, check it and bind its methods
    if (_host != null) {
        var hostVal = Reflect.getProperty(_host, f);
        if (hostVal != null) {
            try {
                if (Reflect.isFunction != null && Reflect.isFunction(hostVal)) {
                    var hostRef = _host;
                    var hostFn = hostVal;
                    return function(args:Array<Dynamic>) {
                        return Reflect.callMethod(hostRef, hostFn, args);
                    };
                }
            } catch(_) {}
            return hostVal;
        }
    }

    // Descend to parentInstance (script or native parent)
    if (parentInstance != null) {
        var pval = Reflect.field(parentInstance, f);
        if (pval != null) {
            try {
                if (Reflect.isFunction != null && Reflect.isFunction(pval)) {
                    var pinst = parentInstance;
                    var pfn = pval;
                    return function(args:Array<Dynamic>) {
                        return Reflect.callMethod(pinst, pfn, args);
                    };
                }
            } catch(_) {}
            return pval;
        }
    }

    return null;
}

public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
    // Prefer script-defined setter: set_<name>
    var sname = "set_" + f;
    if (__interp.variables.exists(sname)) {
        var setter = __interp.variables.get(sname);
        return Reflect.callMethod(this, setter, [v]);
    }

    // Prefer calling parent/host setters
    if (parentInstance != null) {
        var psetter = Reflect.field(parentInstance, "set_" + f);
        if (psetter != null) return Reflect.callMethod(parentInstance, psetter, [v]);
        try {
            Reflect.setProperty(parentInstance, f, v);
            return v;
        } catch(_) {}
    }

    if (_host != null) {
        try {
            Reflect.setProperty(_host, f, v);
            return v;
        } catch(_) {}
    }

    // fallback: store on the script instance interpreter variables
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

// Simple runtime proxy that exposes parent methods as callable and handles constructor calls
class SScriptSuper implements SScriptCustomBehavior {
    public var parentInstance:Dynamic;
    public var parentHandler:Dynamic;
    public var parentInterp:Interp;

    public function new(?parentInstance:Dynamic, ?parentHandler:Dynamic, ?parentInterp:Interp) {
        this.parentInstance = parentInstance;
        this.parentHandler = parentHandler;
        this.parentInterp = parentInterp;
    }

    public function hGet(o:Dynamic, f:String):Dynamic {
        return function(args:Array<Dynamic>) {
            if (parentInstance != null) {
                var fn = Reflect.field(parentInstance, f);
                if (fn != null) return Reflect.callMethod(parentInstance, fn, args);
            }
            if (parentHandler != null && parentInterp != null) {
                if (f == "new") {
                    var hnew = Reflect.field(parentHandler, "hnew");
                    if (hnew != null) {
                        var created = Reflect.callMethod(parentHandler, hnew, args);
                        parentInstance = created;
                        return created;
                    }
                } else {
                    if (parentInterp.variables.exists(f)) {
                        var fn = parentInterp.variables.get(f);
                        return Reflect.callMethod(parentInstance, fn, args);
                    }
                    var getField = Reflect.field(parentInstance, "getField");
                    if (getField != null) {
                        var method = Reflect.callMethod(parentInstance, getField, [f]);
                        if (method != null) return Reflect.callMethod(parentInstance, method, args);
                    }
                }
            }
            return null;
        };
    }

    public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
        if (parentInstance != null) Reflect.setProperty(parentInstance, f, v);
        return v;
    }
}