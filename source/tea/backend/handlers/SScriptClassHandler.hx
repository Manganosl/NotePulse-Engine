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

    public function hnew(args:Array<Dynamic>):Dynamic {
        var instInterp = new Interp();
        instInterp.variables = new Map<String, Dynamic>();
        try {
            for(k in parentInterp.variables.keys()) instInterp.variables.set(k, parentInterp.variables.get(k));
        } catch(e:Dynamic) {}

        var host:Dynamic = null;
        var extendName:String = null;
        if (extend != null && extend.length > 0) {
            extendName = extend.join(".");
        }

        var extendedHandler:Dynamic = null;
        if (extendName != null) {
            try {
                if (Interp.customClasses.exists(extendName)) extendedHandler = Interp.customClasses.get(extendName);
            } catch(e:Dynamic) {}
            if (extendedHandler == null) {
                var last = extend[extend.length - 1];
                try {
                    if (Interp.customClasses.exists(last)) extendedHandler = Interp.customClasses.get(last);
                } catch(e:Dynamic) {}
            }
        }

        if (extendedHandler == null && extendName != null) {
            try {
                var hxClass = Type.resolveClass(extendName);
                if (hxClass == null && extend.length > 0) {
                    hxClass = Type.resolveClass(extend[extend.length - 1]);
                }
                if (hxClass != null) {
                    host = Type.createInstance(hxClass, args);
                }
            } catch(e:Dynamic) {}
        }

        if (host == null) host = new TemplateInstance();
        if (extendName != null) {
            var resolved = this.parentInterp.resolve(extendName);
            if (resolved != null) {
                var hnewFn = Reflect.field(resolved, "hnew");
                if (hnewFn != null) {
                    try {
                        var superInst = Reflect.callMethod(resolved, hnewFn, [[]]);
                        if (superInst != null) {
                            Reflect.setField(host, "__super", superInst);
                            var supInterp = Reflect.field(superInst, "__interp");
                            if (supInterp != null && instInterp != null) {
                                Reflect.setField(instInterp, "__parentInterp", supInterp);
                            }
                        }
                    } catch (e:Dynamic) {}
                }
                else {
                    try {
                        var hxClass = Type.resolveClass(extendName);
                        if (hxClass != null) {
                            var nativeSuper = Type.createInstance(hxClass, []);
                            var wrapper = {
                                __orig: nativeSuper,
                                getField: function(n:String) {
                                    var fn = Reflect.field(nativeSuper, n);
                                    if (fn != null && Reflect.isFunction(fn)) return Reflect.callMethod(nativeSuper, fn, []);
                                    return Reflect.getProperty(nativeSuper, n);
                                },
                                setField: function(n:String, v:Dynamic) {
                                    Reflect.setProperty(nativeSuper, n, v);
                                    return v;
                                }
                            };
                            Reflect.setField(host, "__super", wrapper);
                        }
                    } catch (e:Dynamic) {}
                }
            } else {
                try {
                    var hxClass2 = Type.resolveClass(extendName);
                    if (hxClass2 != null) {
                        var nativeSuper2 = Type.createInstance(hxClass2, []);
                        var wrapper2 = {
                            __orig: nativeSuper2,
                            getField: function(n:String) {
                                var fn = Reflect.field(nativeSuper2, n);
                                if (fn != null && Reflect.isFunction(fn)) return Reflect.callMethod(nativeSuper2, fn, []);
                                return Reflect.getProperty(nativeSuper2, n);
                            },
                            setField: function(n:String, v:Dynamic) {
                                Reflect.setProperty(nativeSuper2, n, v);
                                return v;
                            }
                        };
                        Reflect.setField(host, "__super", wrapper2);
                    }
                } catch (e:Dynamic) {}
            }
        }
        host.__interp = instInterp;
        try { instInterp.variables.set("this", host); } catch(e:Dynamic) {}
        instInterp.variables = new Map<String, Dynamic>();
        var ancestorHandlers:Array<Dynamic> = [];
        if (extendedHandler != null) {
            var cur = extendedHandler;
            var seen = new Map<String,Bool>();
            while (cur != null) {
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
                ancestorHandlers.unshift(cur);
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
                if (Interp.customClasses.exists(nextName)) {
                    cur = Interp.customClasses.get(nextName);
                } else {
                    break;
                }
            }
        }

        var ancestorCtors:Array<Dynamic> = [];
        for (ah in ancestorHandlers) {
            var aFields:Array<Expr> = Reflect.field(ah, "fields");
            if (aFields == null) continue;
            for (f in aFields) {
                try {
                    instInterp.expr(f);
                } catch(e:Dynamic) {
                    Log.trace("SScript: ancestor field init failed in class '" + name + "': " + Std.string(e));
                    throw e;
                }
                if (instInterp.variables.exists("new")) {
                    var cand = instInterp.variables.get("new");
                    if (cand != null) ancestorCtors.push(cand);
                }
            }
        }

        for (f in fields) {
            try {
                instInterp.expr(f);
            } catch (e:Dynamic) {
                Log.trace("SScript: class field init failed in class '" + name + "': " + Std.string(e));
                throw e;
            }
        }

        for (k in instInterp.variables.keys()) {
            try {
                var val = instInterp.variables.get(k);
                Reflect.setField(host, k, val);
            } catch(e:Dynamic) {
            }
        }

        for (ctor in ancestorCtors) {
            try {
                Reflect.callMethod(ctor, ctor, args == null ? [] : args);
            } catch (e:Dynamic) {
                Log.trace("SScript: ancestor ctor threw: " + Std.string(e));
            }
        }

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

        Reflect.setField(host, "getField", Reflect.field(this, "getField"));
        Reflect.setField(host, "setField", Reflect.field(this, "setField"));

        return host;
    }

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
        var resolver = Reflect.field(o, "resolve");
        if (resolver != null) return Reflect.callMethod(o, resolver, [f]);
        return Reflect.field(o, f);
    }

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
            inst.variables.set(f, v);
            Reflect.setField(o, f, v);
            return v;
        }

        Reflect.setField(o, f, v);
        return v;
    }

    public function getField(f:String):Dynamic {
        return hGet(this, f);
    }
    public function setField(f:String, v:Dynamic):Dynamic {
        return hSet(this, f, v);
    }
}

class TemplateInstance implements SScriptCustomBehavior {
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

    public function hGet(o:Dynamic, f:String):Dynamic {
        return getField(f);
    }

    public function hSet(o:Dynamic, f:String, v:Dynamic):Dynamic {
        return setField(f, v);
    }
}
