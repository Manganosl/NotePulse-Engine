package substates;

import states.PlayState;
import states.menus.FreeplayState;

import flixel.util.FlxSpriteUtil;
import openfl.geom.Rectangle;

typedef NoteTypeColorData =
{
	epic:FlxColor,
	sick:FlxColor,
	good:FlxColor,
    bad:FlxColor,
    shit:FlxColor,
    miss:FlxColor
}


class ResultsScreen extends MusicBeatSubstate
{
	public var parent:PlayState = PlayState.instance;

	public var background:FlxSprite;	
    public var graphBG:FlxSprite;
    public var graphSizeUp:FlxSprite;
	public var graphSizeDown:FlxSprite;
	public var graphSizeLeft:FlxSprite;
	public var graphSizeRight:FlxSprite;
	
	public var graphJudgeCenter:FlxSprite;
	public var graphEpicUp:FlxSprite;
	public var graphEpicDown:FlxSprite;
	public var graphSickUp:FlxSprite;
	public var graphSickDown:FlxSprite;
	public var graphGoodUp:FlxSprite;
	public var graphGoodDown:FlxSprite;
	public var graphBadUp:FlxSprite;
	public var graphBadDown:FlxSprite;
	public var graphShitUp:FlxSprite;
	public var graphShitDown:FlxSprite;
    public var graphMiss:FlxSprite;
    
    public var clearText:FlxText;
	public var judgeText:FlxText;
	public var setGameText:FlxText;
	public var nextText:FlxText;
    
    public var NoteTypeColor:NoteTypeColorData;
    
    public var ColorArray:Array<FlxColor> = [];
    public var color:FlxColor;
	public function new(x:Float, y:Float)
	{
		super();
		ColorArray = [
		0xFFE100FF,
		0xFF00FFFF,
	    0xFF00FF00,
	    0xFFFF7F00,
	    0xFFFF5858,
	    0xFFFF0000
		];
		
		background = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.scrollFactor.set();
		background.alpha = 0;
		add(background);
		
		var graphWidth = 550;
		var graphHeight = 300;
		graphBG = new FlxSprite(FlxG.width - 550 - 50, 50).makeGraphic(550, 300, FlxColor.BLACK);
		graphBG.scrollFactor.set();
		graphBG.alpha = 0;		
		add(graphBG);
		
		var noteSpr = FlxSpriteUtil.flashGfx;		
		var _rect = new Rectangle(0, 0, graphWidth, graphHeight);
		graphBG.pixels.fillRect(_rect, 0xFF000000);
		FlxSpriteUtil.beginDraw(0xFFFFFFFF);
	    
	    var noteSize = 2.3;
	    var MoveSize = 0.6;
		for (i in 0...parent.noteTime.length){
		    if (Math.abs(parent.noteMs[i]) <= 200) color = ColorArray[5];
		    if (Math.abs(parent.noteMs[i]) <= 166) color = ColorArray[4];
		    if (Math.abs(parent.noteMs[i]) <= 135) color = ColorArray[3];
		    if (Math.abs(parent.noteMs[i]) <= 90) color = ColorArray[2];
		    if (Math.abs(parent.noteMs[i]) <= 45) color = ColorArray[1];
			if (Math.abs(parent.noteMs[i]) <= 20) color = ColorArray[0];
		    FlxSpriteUtil.beginDraw(color);
		    if (Math.abs(parent.noteMs[i]) <= 166){
    		noteSpr.drawCircle(graphWidth * (parent.noteTime[i] / parent.realSongLength) - noteSize / 2 , graphHeight * 0.5 + graphHeight * 0.5 * MoveSize * (parent.noteMs[i] / 166.6) /*- noteSize / 2*/, noteSize);
    		}
    		else{
    		noteSpr.drawCircle(graphWidth * (parent.noteTime[i] / parent.realSongLength) - noteSize / 2 , graphHeight * 0.5 + graphHeight * 0.5 * 0.8 /*- noteSize / 2*/, noteSize);		
    		}
    		
		    graphBG.pixels.draw(FlxSpriteUtil.flashGfxSprite);
		}
		
		var judgeHeight = 3;
		graphJudgeCenter = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, FlxColor.WHITE);
		graphJudgeCenter.scrollFactor.set();
		graphJudgeCenter.alpha = 0;		
		add(graphJudgeCenter);

		graphEpicUp = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - graphHeight * 0.5 * MoveSize * (ClientPrefs.data.epicWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[0]);
		graphEpicUp.scrollFactor.set();
		graphEpicUp.alpha = 0;		
		add(graphEpicUp);
		
		graphEpicDown = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 + graphHeight * 0.5 * MoveSize * (ClientPrefs.data.epicWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[0]);
		graphEpicDown.scrollFactor.set();
		graphEpicDown.alpha = 0;		
		add(graphEpicDown);
		
		graphSickUp = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - graphHeight * 0.5 * MoveSize * (ClientPrefs.data.sickWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[1]);
		graphSickUp.scrollFactor.set();
		graphSickUp.alpha = 0;		
		add(graphSickUp);
		
		graphSickDown = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 + graphHeight * 0.5 * MoveSize * (ClientPrefs.data.sickWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[1]);
		graphSickDown.scrollFactor.set();
		graphSickDown.alpha = 0;		
		add(graphSickDown);
		
		graphGoodUp = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - graphHeight * 0.5 * MoveSize * (ClientPrefs.data.goodWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[2]);
		graphGoodUp.scrollFactor.set();
		graphGoodUp.alpha = 0;		
		add(graphGoodUp);
		
		graphGoodDown = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 + graphHeight * 0.5 * MoveSize * (ClientPrefs.data.goodWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[2]);
		graphGoodDown.scrollFactor.set();
		graphGoodDown.alpha = 0;		
		add(graphGoodDown);
		
		graphBadUp = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - graphHeight * 0.5 * MoveSize * (ClientPrefs.data.badWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[3]);
		graphBadUp.scrollFactor.set();
		graphBadUp.alpha = 0;		
		add(graphBadUp);
		
		graphBadDown = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 + graphHeight * 0.5 * MoveSize * (ClientPrefs.data.badWindow / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[3]);
		graphBadDown.scrollFactor.set();
		graphBadDown.alpha = 0;		
		add(graphBadDown);
		
		graphShitUp = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - graphHeight * 0.5 * MoveSize * (166.6 / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[4]);
		graphShitUp.scrollFactor.set();
		graphShitUp.alpha = 0;		
		add(graphShitUp);
		
		graphShitDown = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 + graphHeight * 0.5 * MoveSize * (166.6 / 166.6) - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[4]);
		graphShitDown.scrollFactor.set();
		graphShitDown.alpha = 0;		
		add(graphShitDown);
		
		graphMiss = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 + graphHeight * 0.5 * 0.8 - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, ColorArray[5]);
		graphMiss.scrollFactor.set();
		graphMiss.alpha = 0;		
		add(graphMiss);
		
		graphJudgeCenter = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, FlxColor.WHITE);
		graphJudgeCenter.scrollFactor.set();
		graphJudgeCenter.alpha = 0;		
		add(graphJudgeCenter);
		
		graphJudgeCenter = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, FlxColor.WHITE);
		graphJudgeCenter.scrollFactor.set();
		graphJudgeCenter.alpha = 0;		
		add(graphJudgeCenter);
		
		graphJudgeCenter = new FlxSprite(graphBG.x, graphBG.y + graphHeight * 0.5 - judgeHeight * 0.5).makeGraphic(graphWidth, judgeHeight, FlxColor.WHITE);
		graphJudgeCenter.scrollFactor.set();
		graphJudgeCenter.alpha = 0;		
		add(graphJudgeCenter);
		
		graphSizeUp = new FlxSprite(graphBG.x, graphBG.y - 2).makeGraphic(graphWidth + 2, 2, FlxColor.WHITE);
		graphSizeUp.scrollFactor.set();
		graphSizeUp.alpha = 0;		
		add(graphSizeUp);
		
		graphSizeDown = new FlxSprite(graphBG.x - 2, graphBG.y + graphHeight).makeGraphic(graphWidth + 2, 2, FlxColor.WHITE);
		graphSizeDown.scrollFactor.set();
		graphSizeDown.alpha = 0;		
		add(graphSizeDown);
		
		graphSizeLeft = new FlxSprite(graphBG.x - 2, graphBG.y - 2).makeGraphic(2, graphHeight + 2, FlxColor.WHITE);
		graphSizeLeft.scrollFactor.set();
		graphSizeLeft.alpha = 0;		
		add(graphSizeLeft);
		
		graphSizeRight = new FlxSprite(graphBG.x + graphWidth, graphBG.y).makeGraphic(2, graphHeight + 2, FlxColor.WHITE);
		graphSizeRight.scrollFactor.set();
		graphSizeRight.alpha = 0;		
		add(graphSizeRight);		
		
		clearText = new FlxText(20, -155, 0, 'Song Cleared!\n' + PlayState.SONG.song + ' - ' + Difficulty.getString() + '\n');
		clearText.size = 34;
		clearText.font = Paths.font('vcr.ttf');
		clearText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		clearText.scrollFactor.set();
		clearText.antialiasing = ClientPrefs.data.antialiasing;
		add(clearText);		
	    
	    var ACC = Math.ceil(parent.ratingPercent * 10000) / 100;
		judgeText = new FlxText(-400, 200, 0, 
		'Epics: ' + parent.ratingsData[0].hits
		+ '\nSicks: ' + parent.ratingsData[1].hits
		+ '\nGoods: ' + parent.ratingsData[2].hits
		+ '\nBads: ' + parent.ratingsData[3].hits
		+ '\nShits: ' + parent.ratingsData[4].hits
		+ '\n\nMisses: ' + parent.songMisses
		+ '\nScore: ' + parent.songScore
		+ '\nAccuracy: ' + ACC + '%'
		);
		judgeText.size = 25;
		judgeText.font = Paths.font('vcr.ttf');
		judgeText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		judgeText.scrollFactor.set();
		judgeText.antialiasing = ClientPrefs.data.antialiasing;
		add(judgeText);

		setGameText = new FlxText(FlxG.width + 400, 420, 0, 
		'Health Gain: X' + ClientPrefs.getGameplaySetting('healthgain')
		+'\nHealth Loss: X' + ClientPrefs.getGameplaySetting('healthloss')
		+'\nScroll Speed: X' + ClientPrefs.getGameplaySetting('scrollspeed')
		+'\nPlayback Rate: X' + ClientPrefs.getGameplaySetting('songspeed')
		+(ClientPrefs.getGameplaySetting('practice')?'\n\nPractice Mode':'')
		);
		setGameText.size = 25;
		setGameText.alignment = RIGHT;
		setGameText.font = Paths.font('vcr.ttf');
		setGameText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		setGameText.scrollFactor.set();
		setGameText.antialiasing = ClientPrefs.data.antialiasing;
		add(setGameText);
		
		var Main:Float = 0;
		for (i in 0...parent.noteTime.length){
		Main = Main + Math.abs(parent.noteMs[i]);
		}
		Main = Math.ceil(Main / parent.noteTime.length * 100) / 100;	
		
		nextText = new FlxText(0, FlxG.height - 45, 0, 'Press Accept to continue.');
		nextText.size = 28;
		nextText.font = Paths.font('vcr.ttf');
		nextText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1, 1);
		nextText.scrollFactor.set();
		nextText.antialiasing = ClientPrefs.data.antialiasing;
	    nextText.alignment = RIGHT;
		add(nextText);		
		nextText.alpha = 0;
		nextText.x = FlxG.width - nextText.width - 20;

		FlxTween.tween(background, {alpha: 0.5}, 0.5);		
		
		new FlxTimer().start(0.5, function(tmr:FlxTimer){
			FlxTween.tween(clearText, {y: ClientPrefs.data.showFPS ? 60 : 5}, 0.5, {ease: FlxEase.backInOut});
		});
		
		new FlxTimer().start(1.5, function(tmr:FlxTimer){
		    FlxTween.tween(judgeText, {x: 20}, 0.5, {ease: FlxEase.backInOut});		
		    FlxTween.tween(setGameText, {x: FlxG.width - setGameText.width - 20}, 0.5, {ease: FlxEase.backInOut});		
		});
		
		new FlxTimer().start(2, function(tmr:FlxTimer){
			FlxTween.tween(graphBG, {alpha: 0.75}, 0.5);
			
			FlxTween.tween(graphJudgeCenter, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphSickUp, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphSickDown, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphGoodUp, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphGoodDown, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphBadUp, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphBadDown, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphShitUp, {alpha: 0.3}, 0.5);
			FlxTween.tween(graphShitDown, {alpha: 0.3}, 0.5);	
			FlxTween.tween(graphMiss, {alpha: 0.3}, 0.5);	
				
		    FlxTween.tween(graphSizeUp, {alpha: 0.75}, 0.5);
		    FlxTween.tween(graphSizeDown, {alpha: 0.75}, 0.5);
		    FlxTween.tween(graphSizeLeft, {alpha: 0.75}, 0.5);
		    FlxTween.tween(graphSizeRight, {alpha: 0.75}, 0.5);	
		});
		
		new FlxTimer().start(2.5, function(tmr:FlxTimer){
			FlxTween.tween(nextText, {alpha: 1}, 1);	
		});
		
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}
	
    
	override function update(elapsed:Float)
	{   
		if(controls.BACK || controls.ACCEPT)
		{
			MusicBeatState.switchState(new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu-'+ClientPrefs.data.menuMusic), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}
	}

	override function destroy()
	{

		super.destroy();
	}

	
	
}
