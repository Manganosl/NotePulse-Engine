package funkin.states.handlers;

@:nullSafety
class CrashHandlerState extends MusicBeatState
{
	final warningMessage:String;
	
	final continueCallback:Void->Void;

	private var crashLines:Array<String> = [
		"Oops! That wasn’t supposed to happen.",
		"Well, this is embarrassing...",
		"Looks like something went wrong.",
		"Well… this is awkward.",
		"Oops! Something went wrong.",
		"You broke the game. Nice going.",
		"That wasn’t supposed to happen. What did you do?",
		"The cake was a lie.",
		"It works on my machine.",
		"Not a bug. A feature."
	];
	
	public function new(warningMessage:String, continueCallback:Void->Void)
	{
		this.continueCallback = continueCallback;
		this.warningMessage = warningMessage;
		super();
	}
	
	override function create()
	{
		var bg = new FlxSprite().loadGraphic(Paths.image('coconut'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);
		
		var error = new FlxText(0, 0, 0, crashLines[FlxG.random.int(0, crashLines.length-1)], 45);
		error.setFormat(Paths.font('vcr.ttf'), 45, FlxColor.RED, LEFT, OUTLINE, FlxColor.BLACK);
		error.screenCenter(X);
		error.y = 25;
		error.angle = -2;
		add(error);
		FlxTween.tween(error, {angle: 2}, 4, {ease: FlxEase.sineInOut, type: PINGPONG});
		
		var text = new FlxText(25, 0, FlxG.width - 50, warningMessage, 32);
		text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(text);
		text.screenCenter(Y);
		
		var text = new FlxText(0, FlxG.height - 25 - 32, FlxG.width, 'Press Confirm to continue.', 32);
		text.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(text);
		
		super.create();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.ACCEPT)
		{
			persistentUpdate = false;
			continueCallback();
		}
	}
}