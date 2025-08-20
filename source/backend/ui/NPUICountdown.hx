package backend.ui;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.mouse.FlxMouseEventManager;

class NPUICountdown extends FlxSpriteGroup
{
    public var bg:FlxSprite;
    public var label:FlxText;
    public var countdownText:FlxText;
    public var progressBar:FlxSprite;

    var totalTime:Float;
    var remainingTime:Float;
    var onFinish:Void->Void;
    var onCancel:Void->Void;

    var boxWidth:Int;
    var boxHeight:Int;
    var finished:Bool = false;
    var cancelled:Bool = false;

    /**
     * Creates a countdown UI box.
     * @param x X position
     * @param y Y position
     * @param width Width of the box
     * @param height Height of the box
     * @param text The message to display
     * @param seconds Countdown time in seconds
     * @param callback Function to call when finished
     */
    public function new(x:Float, y:Float, width:Int, height:Int, text:String, seconds:Float, callback:Void->Void, cancelledCallback:Void->Void = null)
    {
        super(x, y);

        boxWidth = width;
        boxHeight = height;
        totalTime = seconds;
        remainingTime = seconds;
        onFinish = callback;
        onCancel = cancelledCallback;

        bg = new FlxSprite().makeGraphic(width, height, FlxColor.BLACK);
        bg.alpha = 0.6;
        add(bg);

        progressBar = new FlxSprite(0 - (bg.width/2), 0).makeGraphic(width, 4, FlxColor.WHITE);
        add(progressBar);

        label = new FlxText(0, height / 2 - 20, width, text);
        label.setFormat(null, 16, FlxColor.WHITE, "center");
        add(label);

        countdownText = new FlxText(0, height / 2 + 5, width, Std.string(Std.int(seconds)));
        countdownText.setFormat(null, 14, FlxColor.WHITE, "center");
        add(countdownText);
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!finished && FlxG.mouse.justPressed && FlxG.mouse.overlaps(bg, camera))
        {
            cancelled = true;
            finish(false);
            onCancel();
        }

        if (!finished && !cancelled && remainingTime > 0)
        {
            remainingTime -= elapsed;
            if (remainingTime < 0) remainingTime = 0;

            countdownText.text = Std.string(Math.ceil(remainingTime));

            var progress:Float = remainingTime / totalTime;
            progressBar.scale.x = progress;
            progressBar.updateHitbox();

            progressBar.x = ((boxWidth*2) - progressBar.width) / 2;
        }
        else if (!finished && !cancelled)
        {
            finish(true);
        }
    }

    function finish(callCallback:Bool):Void
    {
        finished = true;

        if (callCallback && onFinish != null)
            onFinish();

        FlxTween.tween(this, {alpha: 0}, 0.5, {ease: FlxEase.quadOut, onComplete: function(_) {
            this.kill();
            this.destroy();
        }});
    }
}
