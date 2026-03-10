package funkin.states.editors.content;

import openfl.filters.ShaderFilter;
import funkin.states.editors.*;

import flixel.util.FlxDestroyUtil;

// Exit confirmation prompt used on all editors, for convenience
class ExitConfirmationPrompt extends Prompt
{
	public function new(?finishCallback:Void->Void)
	{
		super('There\'s unsaved progress,\nare you sure you want to exit?', function()
		{
			FlxG.mouse.visible = false;
			MusicBeatState.switchState(new funkin.states.MainMenuState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			if(finishCallback != null) finishCallback();
		}, 'Exit');
	}
}

// A Simple Prompt with "OK" and "Cancel" that covers most case usages
class Prompt extends BasePrompt
{
	var yesFunction:Void->Void;
	var noFunction:Void->Void;
	var _yesTxt:String = 'OK';
	var _noTxt:String = 'Cancel';
	public function new(title:String, yesFunction:Void->Void, ?noFunction:Void->Void, ?_yesTxt:String, ?_noTxt:String)
	{
		if(_yesTxt != null) this._yesTxt = _yesTxt;
		if(_noTxt != null) this._noTxt = _noTxt;
		this.yesFunction = yesFunction;
		this.noFunction = noFunction;
		super(title, promptCreate);
	}

	function promptCreate(_)
	{
		var btnY = 390;
		var btn:PsychUIButton = new PsychUIButton(0, btnY, _yesTxt, function() {
			yesFunction();
			close();
		});
		btn.normalStyle.bgColor = FlxColor.RED;
		btn.normalStyle.textColor = FlxColor.WHITE;
		btn.screenCenter(X);
		btn.x -= 100;
		btn.cameras = cameras;
		add(btn);

		var btn:PsychUIButton = new PsychUIButton(0, btnY, _noTxt, close);
		btn.screenCenter(X);
		btn.x += 100;
		btn.cameras = cameras;
		add(btn);
	}

	override function close()
	{
		if(noFunction != null) noFunction();
		super.close();
	}
}

class BasePrompt extends MusicBeatSubstate
{
	var _sizeX:Float = 0;
	var _sizeY:Float = 0;
	var _title:String;

	public var onCreate:BasePrompt->Void;
	public var onUpdate:BasePrompt->Float->Void;
	public function new(?sizeX:Float = 420, ?sizeY:Float = 160, title:String, ?onCreate:BasePrompt->Void, ?onUpdate:BasePrompt->Float->Void)
	{
		this._sizeX = sizeX;
		this._sizeY = sizeY;
		this._title = title;
		this.onCreate = onCreate;
		this.onUpdate = onUpdate;
		super();
	}

	public var bg:FlxSprite;
	public var titleText:FlxText;

	public var promptCam:FlxCamera;
	var blurShader:funkin.shaders.BlurShader;
	override function create()
	{
		blurShader = new funkin.shaders.BlurShader();
		for(cam in FlxG.cameras.list)
		{
			if(cam.filters == null)
				cam.filters = [new ShaderFilter(blurShader)];
			else
				cam.filters.push(new ShaderFilter(blurShader));
		}
		FlxTween.num(0, 0.0075, 0.1, {ease: FlxEase.cubeOut}, function(v:Float) {
			blurShader.strength.value = [v];
		});
		promptCam = new FlxCamera();
		promptCam.bgColor = FlxColor.TRANSPARENT;
		FlxG.cameras.add(promptCam, false);

		cameras = [promptCam];

		// Center the background box
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = 0.8;
		bg.scale.set(_sizeX, _sizeY);
		bg.updateHitbox();
		bg.x = (FlxG.width - bg.width) / 2;
		bg.y = (FlxG.height - bg.height) / 2;
		bg.cameras = cameras;
		add(bg);

		// Center the title text inside the box
		titleText = new FlxText(0, 0, _sizeX - 40, _title, 16);
		titleText.x = bg.x + 20;
		titleText.y = bg.y + 30;
		titleText.alignment = CENTER;
		titleText.cameras = cameras;
		add(titleText);

		if(onCreate != null)
			onCreate(this);
		super.create();
	}

	var _blockInput:Float = 0.1;
	override function update(elapsed:Float)
	{
		if(FlxG.mouse.justPressed || FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle) FlxG.sound.play(Paths.sound('chartingSounds/ClickDown'));
		if(FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight || FlxG.mouse.justReleasedMiddle) FlxG.sound.play(Paths.sound('chartingSounds/ClickUp'));
		if(FlxG.keys.justPressed.ANY) FlxG.sound.play(Paths.sound('chartingSounds/keyboard${FlxG.random.int(1,3)}'));
		super.update(elapsed);

		_blockInput = Math.max(0, _blockInput - elapsed);
		if(_blockInput <= 0 && FlxG.keys.justPressed.ESCAPE)
		{
			close();
			return;
		}

		if(onUpdate != null)
			onUpdate(this, elapsed);
	}

	override function destroy()
	{
		if(promptCam != null)
		{
			FlxG.cameras.remove(promptCam, true);
			promptCam = null;
		}
		FlxTween.num(blurShader.strength.value[0], 0, 0.1, {ease: FlxEase.cubeOut, onComplete: function(tweener:FlxTween)
		{
			for(cam in FlxG.cameras.list)
			{
				if(cam.filters != null)
				{
					cam.filters = [for (f in cam.filters) if (!(f is ShaderFilter && cast(f, ShaderFilter).shader is funkin.shaders.BlurShader)) f];
					if (cam.filters.length == 0) cam.filters = null;
				}
			}
		}}, function(v:Float)
		{
			blurShader.strength.value = [v];
		});
		for (member in members) FlxDestroyUtil.destroy(member);
		super.destroy();
	}
}