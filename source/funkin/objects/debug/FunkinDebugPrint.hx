package funkin.objects.debug;

import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import funkin.game.shaders.OutlineShader;

class FunkinDebugPrint extends Sprite {
	public var messagesList:Array<LogMessage> = [];
	public var marginEdge:Float = 10;
	public var spacing:Float = 2;
	
	var baseHeight:Float = 0;
	
	public function new() {
		super();
		
		var dummyMsg:LogMessage = displayLog('!');
		baseHeight = dummyMsg.boxHeight;
		dummyMsg.visible = false;
	}
	
	public override function __enterFrame(elapsedTime:Float) {
		for (msgItem in messagesList)
			msgItem.refresh(elapsedTime);
	}
	
	public function displayLog(content:String = 'null', tint:FlxColor = FlxColor.WHITE, fontSize:Int = 15):LogMessage {
		var msgElement:LogMessage = null;
		for (msgItem in messagesList) {
			if (!msgItem.visible) {
				msgElement = msgItem;
				break;
			}
		}
		msgElement ??= new LogMessage();
		
		msgElement.opacityFactor = msgElement.alpha = 1;
		msgElement.textStyle.color = tint.rgb;
		msgElement.textStyle.size = fontSize;
		msgElement.visible = true;
		msgElement.lifespanTimer = 0;
		msgElement.text = content;
		
		msgElement.recalculateWidth();
		msgElement.defaultTextFormat = msgElement.textStyle;
		msgElement.boxHeight = Math.max(baseHeight, msgElement.textHeight);
		
		messagesList.remove(msgElement);
		messagesList.insert(0, msgElement);
		
		if (!contains(msgElement))
			addChild(msgElement);
		
		refreshAlignments();
		
		return msgElement;
	}
	
	public function refreshAlignments():Void {
		var verticalPos:Float = marginEdge;
		for (msgItem in messagesList) {
			if (msgItem.visible) {
				if (verticalPos + msgItem.boxHeight - marginEdge > FlxG.stage.window.height) {
					msgItem.lifespanTimer = 99999;
					msgItem.visible = false;
					break;
				}
				
				msgItem.recalculateWidth();
				msgItem.y = verticalPos;
				msgItem.x = marginEdge;
				verticalPos += msgItem.boxHeight + spacing;
			}
		}
	}
}

class LogMessage extends TextField {
	static var sharedShader:OutlineShader;
	
	public var textStyle:TextFormat = new TextFormat(Paths.font('vcr.ttf'));
	public var opacityFactor:Float = 1;
	public var lifespanTimer:Float = 0;
	public var cachedWidth:Float = 0;
	public var boxHeight:Float = 0;
	
	public function new() {
		super();
		
		defaultTextFormat = textStyle;
		textStyle.letterSpacing = -.5;
		textStyle.leading = -2;
		multiline = true;
		wordWrap = true;
		
		sharedShader ??= new OutlineShader();
		shader = sharedShader;
	}
	
	public function refresh(elapsedTime:Float) {
		if (!visible) return;
		
		lifespanTimer += elapsedTime;
		
		if (lifespanTimer >= 5000) {
			if (lifespanTimer < 5000 + 2000) {
				alpha = (1 - (lifespanTimer - 5000) / 2000) * opacityFactor;
			} else {
				visible = false;
			}
		}
		
		recalculateWidth();
	}
	
	public function recalculateWidth():Void {
		var intendedWidth:Float = FlxG.stage.window.width - x * 2;
		if (cachedWidth != intendedWidth)
			cachedWidth = width = intendedWidth;
	}
}