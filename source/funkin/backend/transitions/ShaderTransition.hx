package funkin.backend.transitions;

import funkin.backend.CustomFadeTransition;
import openfl.filters.ShaderFilter;
import funkin.game.shaders.MadnessTrans;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class ShaderTransition extends MusicBeatSubstate
{
    var isTransIn:Bool;
    var duration:Float;
    var shader:MadnessTrans;
    var transCamera:FlxCamera;

    public function new(duration:Float, isTransIn:Bool)
    {
        this.duration = duration;
        this.isTransIn = isTransIn;
        super();
    }

    override function create()
    {
        transCamera = new FlxCamera();
        transCamera.bgColor = 0x00000000;
        FlxG.cameras.add(transCamera, false);
        cameras = [transCamera];

        shader = new MadnessTrans();
        shader.fade = isTransIn ? 0 : 1;

        if (transCamera.filters == null)
            transCamera.filters = [];

        transCamera.filters.push(new ShaderFilter(shader));

        if (CustomFadeTransition.transitionTween != null)
        {
            CustomFadeTransition.transitionTween.cancel();
            CustomFadeTransition.transitionTween = null;
        }

        CustomFadeTransition.transitionTween = FlxTween.tween(shader, 
            { fade: isTransIn ? 1 : 0 }, 
            duration,
            {
                onComplete: function(_) finishTrans()
            });

        super.create();
    }

    function finishTrans()
    {
        var func = CustomFadeTransition.finishCallback;
        CustomFadeTransition.finishCallback = null;

        if (func != null)
            func();

        new FlxTimer().start(0.01, function(_)
        {
            CustomFadeTransition.transitionTween = null;

            if (transCamera != null)
            {
                FlxG.cameras.remove(transCamera, true);
                transCamera.destroy();
                transCamera = null;
            }

            close();
        });
    }
}