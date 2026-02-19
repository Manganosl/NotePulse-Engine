package funkin.backend;

import openfl.filters.ShaderFilter;
import funkin.shaders.MadnessTrans;
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

        if (ClientPrefs.data.trans == "Stickers") {
            createStickerTransition();
        } else {
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

            daTween = FlxTween.tween(shader, {fade: isTransIn ? 1 : 0}, duration, {
                onComplete: function(twn:FlxTween) {
                    finishTrans();
                }
            });
        }

        super.create();
    }

    function createStickerTransition() {
        stickerGrp = new FlxTypedGroup<FlxSprite>();
        add(stickerGrp);

        var path:String = 'assets/shared/images/stickers';
        if (!FileSystem.exists(path)) {
            finishTrans();
            return;
        }

        var pack:Array<String> = FileSystem.readDirectory(path);

        if (!isTransIn) {
            FlxG.save.data.stickerData = [];

            var cellWidth:Int = 110; 
            var cellHeight:Int = 110;
            var cols:Int = Math.ceil(FlxG.width / cellWidth) + 2;
            var rows:Int = Math.ceil(FlxG.height / cellHeight) + 2;
            
            maxStickers = cols * rows;
            stickerTime = duration / maxStickers;

            var positions:Array<{x:Float, y:Float}> = [];
            for (r in 0...rows) {
                for (c in 0...cols) {
                    var baseX = (c * cellWidth) - 120;
                    var baseY = (r * cellHeight) - 120;
                    var randomX = baseX + FlxG.random.float(-30, 30);
                    var randomY = baseY + FlxG.random.float(-30, 30);

                    positions.push({x: randomX, y: randomY});
                }
            }

            FlxG.random.shuffle(positions);
            var indices:Array<Int> = [];
            for (i in 0...maxStickers) indices.push(i);
            FlxG.random.shuffle(indices); 

            for (i in 0...maxStickers) {
                var graphic:String = pack[FlxG.random.int(0, pack.length - 1)];
                var pos = positions[i];
                var angle:Float = FlxG.random.float(-45, 45);
                var randScale:Float = FlxG.random.float(0.8, 1.2);
                var sticky:FlxSprite = newSticker(graphic, pos.x, pos.y, angle);

                sticky.scale.set(randScale, randScale);
                sticky.updateHitbox();
                sticky.visible = false;
                stickerGrp.add(sticky);

                FlxG.save.data.stickerData.push({
                    name: StringTools.replace(graphic, '.png', ''),
                    position: [sticky.x, sticky.y],
                    angle: sticky.angle,
                    scale: randScale,
                    order: indices[i]
                });
            }
            FlxG.save.flush();

            var stickerData:Array<Dynamic> = FlxG.save.data.stickerData;
            for (i in 0...stickerData.length) {
                var item = stickerData[i];
                var sprite = stickerGrp.members[i];
                
                new FlxTimer().start(stickerTime * item.order, function(tmr:FlxTimer) {
                    sprite.visible = true;
                    var finalScale:Float = item.scale;
                    sprite.scale.set(finalScale + 0.2, finalScale + 0.2);
                    FlxTween.tween(sprite.scale, {x: finalScale, y: finalScale}, 0.1, {ease: FlxEase.backOut});
                    FlxG.sound.play(Paths.sound('keys/keyClick' + FlxG.random.int(1, 9, [6])), 0.6);
                });
            }

        } else {
            var dataList:Array<Dynamic> = FlxG.save.data.stickerData;
            if (dataList != null) {
                maxStickers = dataList.length;
                stickerTime = duration / maxStickers;

                for (i in 0...dataList.length) {
                    var data = dataList[i];
                    var sticky:FlxSprite = newSticker(data.name, data.position[0], data.position[1], data.angle);
                    
                    var savedScale:Float = (data.scale != null) ? data.scale : 0.8;
                    sticky.scale.set(savedScale, savedScale);
                    sticky.updateHitbox();
                    
                    sticky.visible = true;
                    stickerGrp.add(sticky);

                    new FlxTimer().start(stickerTime * data.order, function(tmr:FlxTimer) {
                        if (sticky != null) sticky.visible = false;
                        FlxG.sound.play(Paths.sound('keys/keyClick' + FlxG.random.int(1, 9, [6])), 0.6);
                    });
                }
            }
        }

        new FlxTimer().start(duration + 0.2, function(tmr:FlxTimer) {
            finishTrans();
        });
    }

    function newSticker(graphic:String, x:Float, y:Float, angle:Float):FlxSprite {
        var name:String = StringTools.replace(graphic, '.png', '');

        var sticker = new FlxSprite(x, y).loadGraphic(Paths.image('stickers/' + name));

        sticker.scrollFactor.set(0, 0);
        sticker.zoomFactor = 0;

        sticker.scale.set(0.8, 0.8);

        sticker.updateHitbox();
        sticker.antialiasing = ClientPrefs.data.antialiasing;
        sticker.angle = angle;

        return sticker;
    }

    function finishTrans() {
        var func = finishCallback;
        finishCallback = null; 

        if (func != null)
            func();
            
        new FlxTimer().start(0.01, function(tmr:FlxTimer) {
        	daTween = null;

        	if (transCamera != null) {
            		FlxG.cameras.remove(transCamera, true);
            		transCamera.destroy();
            		transCamera = null;
        	}

        	close();
        });
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (dont) {
            dont = false;
            finishTrans();
        }
    }
}
