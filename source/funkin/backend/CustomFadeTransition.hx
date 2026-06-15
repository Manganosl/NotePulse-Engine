package funkin.backend;

import flixel.FlxG;
import funkin.backend.transitions.*;
import funkin.states.scripted.ScriptedSubstate;

class CustomFadeTransition extends MusicBeatSubstate {
    public static var transitionTween:FlxTween;
    public static var finishCallback:Void->Void;
    public static var duration:Float;
    public static var isTransIn:Bool;

    public function new(duration:Float, isTransIn:Bool) {
        super();
        CustomFadeTransition.duration = duration;
        CustomFadeTransition.isTransIn = isTransIn;
    }

    override public function create() {
        var modPack = Mods.modPack;
        if (modPack != null && modPack.customTransition != null) {
            openSubState(new ScriptedSubstate(modPack.customTransition));
        } else {
            openSubState(new VanillaTransition());
        }

        super.create();
    }

    override function closeSubState() {
        super.closeSubState();
        close();
    }
}