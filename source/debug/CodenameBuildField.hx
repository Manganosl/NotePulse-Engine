package debug;

import openfl.text.TextFormat;
import openfl.display.Sprite;
import openfl.text.TextField;

class CodenameBuildField extends Sprite {
	public var codenameTextField:TextField;
	public static var engineName:String = "NotePulse Engine "+states.MainMenuState.npeVersion;
	public static var oldEName:String = engineName;
	public function new() {
		super();
		codenameTextField = new TextField();
		codenameTextField.defaultTextFormat = Framerate.textFormat;
		codenameTextField.autoSize = LEFT;
		codenameTextField.multiline = codenameTextField.wordWrap = false;
		codenameTextField.text = engineName;
		//codenameTextField.text += '\nRunning alpha';
		codenameTextField.selectable = false;
		addChild(codenameTextField);
	}
	public override function __enterFrame(t:Int) {
		super.__enterFrame(t);
		if (oldEName != engineName) {
			oldEName = engineName;
			codenameTextField.text = engineName;
		}
	}
}
