package funkin.backend.transitions;

import funkin.backend.CustomFadeTransition;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import sys.FileSystem;

typedef StickerData = {
    name:String,
    position:Array<Float>,
    angle:Float,
    index:Int,
    isSecret:Bool,
}

class StickerTransition extends MusicBeatSubstate
{
    public static var stickerHell:Array<StickerData> = null;

    var isTransIn:Bool = false;
    var duration:Float;
    var stickerGrp:FlxTypedGroup<FlxSprite>;
    var transCamera:FlxCamera;

    var maxStickers:Int = 75;
    var time:Float = 0.01;

    public function new(duration:Float, isTransIn:Bool) {
        this.duration = duration;
        this.isTransIn = isTransIn;
        super();
    }

    override function create() {
        transCamera = new FlxCamera();
        transCamera.bgColor = 0x00000000;
        FlxG.cameras.add(transCamera, false);
        cameras = [transCamera];

        stickerGrp = new FlxTypedGroup<FlxSprite>();
        add(stickerGrp);

        createStickerLogic();
        super.create();
    }

    function createStickerLogic() {
        var xPos:Float = -100;
        var yPos:Float = -100;
        var prevIDs:Array<Int> = [-1];

        if (!isTransIn) {
            stickerHell = [];
            var packPath = 'assets/shared/images/stickers';

            if (FileSystem.exists(packPath)) {
                var pack = FileSystem.readDirectory(packPath);
                var choice:Int = 0;

                for (i in 0...maxStickers) {
                    choice = FlxG.random.int(0, pack.length - 1, [choice]);
                    var stickerName = pack[choice];
                    var zIndex = FlxG.random.int(0, maxStickers, prevIDs);
                    prevIDs.push(zIndex);

                    var sticky = newSticker(stickerName, xPos, yPos, zIndex, FlxG.random.int(-60, 70), false);
                    stickerGrp.add(sticky);

                    if (xPos <= FlxG.width) {
                        xPos += sticky.width * 0.5;
                        if (xPos >= FlxG.width) {
                            if (yPos <= FlxG.height) {
                                xPos = -100;
                                yPos += FlxG.random.float(90, 140);
                            }
                        }
                    }

                    stickerHell.push({
                        name: StringTools.replace(stickerName, '.png', ''),
                        position: [sticky.x, sticky.y],
                        angle: sticky.angle,
                        index: zIndex,
                        isSecret: false,
                    });
                }
            }
        } else {
            if (stickerHell != null) {
                for (data in stickerHell) {
                    var sticky = newSticker(data.name, data.position[0], data.position[1], data.index, data.angle, data.isSecret);
                    stickerGrp.add(sticky);
                }
            }
        }
        stickerGrp.sort(function(order:Int, a:FlxSprite, b:FlxSprite) {
            return FlxSort.byValues(FlxSort.ASCENDING, a.ID, b.ID);
        });

        for (i in stickerGrp.members) {
            if (i == null) continue;

            if (!isTransIn) {
                i.visible = false;
                new FlxTimer().start(time * i.ID, function(t:FlxTimer) {
                    if (i != null && i.exists) {
                        i.visible = true;
                        i.scale.set(0.85, 0.85);
                        FlxTween.tween(i.scale, {x: 0.8, y: 0.8}, 0.125, {ease: FlxEase.cubeOut});
                        playStickerSound();
                    }
                });
            } else {
                i.visible = true;
                new FlxTimer().start(time * i.ID, function(t:FlxTimer) {
                    if (i != null && i.exists) {
                        i.visible = false;
                        playStickerSound();
                    }
                });
            }
        }

        new FlxTimer().start(duration+0.3, function(t:FlxTimer) {
            finishTrans();
        });
    }

    function newSticker(graphic:String, x:Float, y:Float, index:Int, angle:Float, isSecret:Bool):FlxSprite {
        var sticker = new FlxSprite(x, y);
        var name = StringTools.replace(graphic, '.png', '');
        
        var path = 'stickers/$name';
        
        sticker.loadGraphic(Paths.image(path));
        sticker.antialiasing = true;
        sticker.ID = index;
        sticker.angle = angle;
        sticker.scale.set(0.8, 0.8);
        sticker.updateHitbox();
        sticker.scrollFactor.set(0, 0);
        return sticker;
    }

    function playStickerSound() {
        var soundNum = FlxG.random.int(1, 9, [6]);
        FlxG.sound.play(Paths.sound('keys/keyClick' + soundNum), 0.6);
    }

    function finishTrans() {
        if (CustomFadeTransition.finishCallback != null) {
            CustomFadeTransition.finishCallback();
            CustomFadeTransition.finishCallback = null;
        }

        new FlxTimer().start(0.005, function(t:FlxTimer) {
            if (transCamera != null) {
                FlxG.cameras.remove(transCamera, true);
                transCamera.destroy();
            }
            close();
        });
    }
}