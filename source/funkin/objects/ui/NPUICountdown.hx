package funkin.objects.ui;

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

        FlxG.sound.play(Paths.sound('chartingSounds/openWindow'));
    }

    private var isPointer:Bool = true;
    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!finished && FlxG.mouse.overlaps(bg, camera)){
            isPointer = true;
            Mouse.cursor = MouseCursor.POINTER;
            if(FlxG.mouse.justPressed){
                cancelled = true;
                FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
                finish(false);
                if(onCancel != null) onCancel();
            }
        } else if(isPointer){
            Mouse.cursor = MouseCursor.DEFAULT;
            isPointer = false;
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
