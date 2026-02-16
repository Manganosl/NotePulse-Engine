package backend;

import openfl.filters.ShaderFilter;
import shaders.MadnessTrans;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import sys.FileSystem;

class CustomFadeTransition extends MusicBeatSubstate
{
    public static var finishCallback:Void->Void;
    public static var dont:Bool = false;
    public static var daTween:FlxTween;

    var isTransIn:Bool = false;
    var duration:Float;
    var shader:MadnessTrans;

    var stickerGrp:FlxTypedGroup<FlxSprite>;
    var maxStickers:Int = 75;
    var stickerTime:Float = 0.01;

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

        if (ClientPrefs.data.trans == "Stickers")
        {
            createStickerTransition();
        }
        else
        {
            shader = new MadnessTrans();
            shader.fade = isTransIn ? 0 : 1;

            if (transCamera.filters == null)
                transCamera.filters = [];

            transCamera.filters.push(new ShaderFilter(shader));

            if (daTween != null)
            {
                daTween.cancel();
                daTween = null;
            }

            daTween = FlxTween.tween(shader, {fade: isTransIn ? 1 : 0}, duration,
            {
                onComplete: function(twn:FlxTween)
                {
                    finishTrans();
                }
            });
        }

        super.create();
    }

    function createStickerTransition()
    {
        stickerGrp = new FlxTypedGroup<FlxSprite>();
        add(stickerGrp);

        var packChoice:Int = FlxG.save.data.packChoice;
        if (!isTransIn)
        {
            packChoice = FlxG.random.int(1, 3);
            FlxG.save.data.packChoice = packChoice;
        }

        var path:String = 'assets/shared/images/stickers/pack ' + packChoice;
        var pack:Array<String> = FileSystem.readDirectory(path);

        var xPos:Float = -100;
        var yPos:Float = -100;

        stickerTime = duration / maxStickers;

        if (!isTransIn)
        {
            FlxG.save.data.stickerHell = [];

            for (i in 0...maxStickers)
            {
                var graphic:String = pack[FlxG.random.int(0, pack.length - 1)];
                var angle:Float = FlxG.random.float(-60, 70);

                var sticky:FlxSprite = newSticker(packChoice, graphic, xPos, yPos, angle);
                sticky.visible = false;
                stickerGrp.add(sticky);

                if (xPos <= FlxG.width)
                {
                    xPos += sticky.width * 0.5;
                    if (xPos >= FlxG.width)
                    {
                        if (yPos <= FlxG.height)
                        {
                            xPos = -100;
                            yPos += FlxG.random.float(90, 140);
                        }
                    }
                }

                FlxG.save.data.stickerHell.push({
                    name: StringTools.replace(graphic, '.png', ''),
                    position: [sticky.x, sticky.y],
                    angle: sticky.angle
                });
            }

            FlxG.save.flush();

            for (i in 0...stickerGrp.members.length)
            {
                var sprite = stickerGrp.members[i];
                new FlxTimer().start(stickerTime * i, function(tmr:FlxTimer)
                {
                    sprite.visible = true;
                    sprite.scale.set(0.85, 0.85);
                    FlxTween.tween(sprite.scale, {x: 0.8, y: 0.8}, 0.1);
                    FlxG.sound.play(Paths.sound('keys/keyClick' + FlxG.random.int(1, 9, [6])));
                });
            }
        }
        else
        {
            var dataList:Array<Dynamic> = FlxG.save.data.stickerHell;

            for (i in 0...dataList.length)
            {
                var data = dataList[i];

                var sticky:FlxSprite = newSticker(
                    packChoice,
                    data.name,
                    data.position[0],
                    data.position[1],
                    data.angle
                );

                sticky.visible = true;
                stickerGrp.add(sticky);

                new FlxTimer().start(stickerTime * i, function(tmr:FlxTimer)
                {
                    sticky.visible = false;
                    FlxG.sound.play(Paths.sound('keys/keyClick' + FlxG.random.int(1, 9, [6])));
                });
            }
        }

        new FlxTimer().start(duration + 0.1, function(tmr:FlxTimer)
        {
            finishTrans();
        });
    }

    function newSticker(pack:Int, graphic:String, x:Float, y:Float, angle:Float):FlxSprite
    {
        var name:String = StringTools.replace(graphic, '.png', '');

        var sticker = new FlxSprite(x, y)
            .loadGraphic(Paths.image('stickers/pack ' + pack + '/' + name));

        sticker.scrollFactor.set(0, 0);

        sticker.scale.set(0.8 / transCamera.zoom, 0.8 / transCamera.zoom);

        sticker.updateHitbox();
        sticker.antialiasing = ClientPrefs.data.antialiasing;
        sticker.angle = angle;

        return sticker;
    }

    function finishTrans()
    {
        if (finishCallback != null)
            finishCallback();

        finishCallback = null;
        daTween = null;

        if (transCamera != null)
        {
            FlxG.cameras.remove(transCamera, true);
            transCamera.destroy();
            transCamera = null;
        }

        close();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (dont)
        {
            dont = false;
            finishTrans();
        }
    }
}
