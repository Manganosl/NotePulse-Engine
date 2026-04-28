package funkin.backend.utils;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Expr;
import haxe.macro.Context;
using haxe.macro.Tools;
using Lambda;
#end

//data5 data 5  data 5
class MacroUtil
{
	public static var compilerDefines(get, null):Map<String, Dynamic>;

	private static inline function get_compilerDefines() return __getDefines();

	private static macro function __getDefines() {
		#if display
		return macro $v{[]};
		#else
		return macro $v{Context.getDefines()};
		#end
	}
	
	//Adds any extra classes into the executable, no dce
	public static final addonClasses:Array<String> = [
		"funkin.backend",
        "funkin.game.shaders",

        "animate",

		//Lime library
		"lime.app", "lime.graphics",
		"lime.math", "lime.media", "lime.net",
		"lime.system", "lime.text", "lime.ui", "lime.util",

		//Openfl library
		"openfl",

        //Flixel library
        "flixel.animation", "flixel.effects", "flixel.math",
        "flixel.graphics", "flixel.group", "flixel.input",
        "flixel.path", "flixel.sound", "flixel.text",
        "flixel.tile", "flixel.tweens", "flixel.ui", "flixel.util",
        "flixel.system.debug", "flixel.system.frontEnds",
        "flixel.system.replay", "flixel.system.scaleModes",
        "flixel.system.ui", "flixel.addons.display",
        "flixel.addons.api", "flixel.addons.editors.ogmo",
        "flixel.addons.editors.pex", "flixel.addons.editors.tiled",
        "flixel.addons.effects", "flixel.addons.plugin",
        "flixel.addons.text", "flixel.addons.tile",
        "flixel.addons.transition", "flixel.addons.util",
        "flixel.addons.weapon", "flixel.addons.nape",
	];

	@:unreflective public static function compileMacros() {
		#if macro
		//doing this since using `#if 32bits` throws an error
		if(Context.defined("32bits"))
			Compiler.define("x86_BUILD", "1");

		if(Context.defined("hscript_improved_dev"))
			Compiler.define("hscript-improved", "1");

		for(classPackage in addonClasses) Compiler.include(classPackage);
		#end
	}

    /**
    * enforces the use of haxe 4.3 cuz i use alot of its null coalescents lol
    */
    public macro static function haxeVersionEnforcement()
    {
        #if (haxe_ver < 4.3)
        Context.fatalError('use haxe 4.3.0 or newer thx', (macro null).pos);
        #end
        return macro $v{0}
    }

    /**
    * returns the current Date as a string during compilation.
    */
    public static macro function getDate() 
    {
        return macro $v{Date.now().toString()};
    }

    /**
    * forces the compiler to include a class even if the dce kills it
    */
	public static macro function include(path:Expr) 
    {
		haxe.macro.Compiler.include(path.toString());
		return macro $v{0};
	}

    public static macro function buildAbstract(typePath:Expr,?exclude:Array<String>) {
        var type = Context.getType(typePath.toString());
        var expressions:Array<ObjectField> = [];

        if (exclude == null)
            exclude = ["NONE"];

        switch (type.follow())
        {
            case TAbstract(_.get() => ab, _):
                for (f in ab.impl.get().statics.get())
                {
                    switch (f.kind)
                    {
                        case FVar(AccInline, _):
                            switch (f.expr().expr)
                            {
                                case TCast(Context.getTypedExpr(_) => expr, _):    
                                    if (f.name.toUpperCase() == f.name && exclude.indexOf(f.name) == -1) // uppercase?
                                    {
                                        expressions.push({field: f.name,expr: expr});
                                    }

                                default:
                            }

                        default:
                    }
                }
            default:
        }


        var finalResult = {expr:EObjectDecl(expressions), pos: Context.currentPos()};
        return macro $b{[macro $finalResult]};
    }
	
	macro public static function generateReflectionLike(totalArguments:Int, funcName:String, argsName:String) {
		#if macro
		totalArguments++;

		var funcCalls = [];
		for(i in 0...totalArguments) {
			var args = [
				for(d in 0...i) macro $i{argsName}[$v{d}]
			];

			funcCalls.push(macro $i{funcName}($a{args}));
		}

		var expr = {
			pos: Context.currentPos(),
			expr: ESwitch(
				macro ($i{argsName}.length),
				[
					for(i in 0...totalArguments) {
						values: [macro $v{i}],
						expr: funcCalls[i],
						guard: null,
					}
				],
				macro throw "Too many arguments"
			)
		}
		return expr;
		#end
	}
}
