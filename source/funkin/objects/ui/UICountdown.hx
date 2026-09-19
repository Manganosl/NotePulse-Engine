package funkin.objects.ui;

class UICountdown extends FlxSpriteGroup
{
    public var border:FlxSprite;
    public var bg:FlxSprite;
    public var progressTrack:FlxSprite;
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

    public function new(x:Float, y:Float, width:Int, height:Int, text:String, seconds:Float, callback:Void->Void, cancelledCallback:Void->Void = null)
    {
        super(x, y);

        boxWidth = width;
        boxHeight = height;
        totalTime = seconds;
        remainingTime = seconds;
        onFinish = callback;
        onCancel = cancelledCallback;

        border = new FlxSprite(-1, -1).makeGraphic(1, 1, FlxColor.WHITE);
        border.color = 0xFF3A3F52;
        border.alpha = 0.55;
        border.scale.set(width + 2, height + 2);
        border.updateHitbox();
        add(border);

        bg = new FlxSprite().makeGraphic(width, height, FlxColor.WHITE);
        bg.color = 0xFF1C1F27;
        bg.alpha = 0.78;
        add(bg);

        progressTrack = new FlxSprite(0, 6).makeGraphic(width, 4, FlxColor.WHITE);
        progressTrack.color = 0xFF262A34;
        progressTrack.alpha = 0.7;
        add(progressTrack);

        progressBar = new FlxSprite(0, 6).makeGraphic(width, 4, FlxColor.WHITE);
        progressBar.color = 0xFFA855F7;
        add(progressBar);

        label = new FlxText(0, height / 2 - 20, width, text);
        label.setFormat(null, 16, 0xFFF1F1F5, "center");
        add(label);

        countdownText = new FlxText(0, height / 2 + 5, width, Std.string(Std.int(seconds)));
        countdownText.setFormat(null, 14, 0xFFF1F1F5, "center");
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
