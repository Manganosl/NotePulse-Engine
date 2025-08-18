package states;

import flixel.FlxG;
import psychlua.HScript;
import sys.io.File;
import sys.FileSystem;

class CustomState extends MusicBeatState
{
    public var hscript:HScript;
    public var statePath:String;

    public function new(scriptPath:String)
    {
        super();
        statePath = scriptPath;
    }

    override public function create():Void
    {
        super.create();

        if (!FileSystem.exists(statePath))
        {
            FlxG.log.error('HScript file does not exist: ' + statePath);
            FlxG.switchState(new MainMenuState());
            return;
        }

        try
        {
            var scriptContent:String = File.getContent(statePath);
            hscript = new HScript(null, pathToOrigin(statePath));
            hscript.doString(scriptContent);

            hscript.set("thisState", this);

            if (hscript.exists("onCreate"))
                hscript.call("onCreate");
        }
        catch (e:Dynamic)
        {
            FlxG.log.error('Error loading custom state: ' + e);
            FlxG.switchState(new MainMenuState());
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (hscript != null && hscript.exists("onUpdate"))
            hscript.call("onUpdate", [elapsed]);
    }

    override public function destroy():Void
    {
        if (hscript != null)
        {
            if (hscript.exists("onDestroy"))
                hscript.call("onDestroy");

            hscript.destroy();
        }

        super.destroy();
    }

    function pathToOrigin(path:String):String
    {
        var parts = path.split('/');
        return parts[parts.length - 1];
    }
}
