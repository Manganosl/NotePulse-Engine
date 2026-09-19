package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import flixel.text.FlxText;

import funkin.game.cutscenes.DialogueCharacter;

@:access(funkin.states.editors.DialogueEditorState)
class DialogueEditorUI extends FlxSpriteContainer implements UIEventHandler.UIEvent
{
	private var dialogueEditor:DialogueEditorState;

	public var UI_box:UIBox;

	public var characterInputText:UIInputText;
	public var lineInputText:UIInputText;
	public var angryCheckbox:UICheckBox;
	public var speedStepper:UINumericStepper;
	public var soundInputText:UIInputText;

	public function new(dialogueEditor:DialogueEditorState)
	{
		super();
		this.dialogueEditor = dialogueEditor;
	}

	public function createUI()
	{
		addEditorBox();
	}

	function addEditorBox()
	{
		UI_box = new UIBox(FlxG.width - 260, 10, 250, 210, ['Dialogue Line']);
		UI_box.scrollFactor.set();
		addDialogueLineUI();
		add(UI_box);
	}

	function addDialogueLineUI() {
		var tab_group = UI_box.getTab('Dialogue Line').menu;

		characterInputText = new UIInputText(10, 20, 80, DialogueCharacter.DEFAULT_CHARACTER, 8);
		speedStepper = new UINumericStepper(10, characterInputText.y + 40, 0.005, 0.05, 0, 0.5, 3);

		angryCheckbox = new UICheckBox(speedStepper.x + 120, speedStepper.y, "Angry Textbox", 200);
		angryCheckbox.onClick = function()
		{
			dialogueEditor.updateTextBox();
			dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].boxState = (angryCheckbox.checked ? 'angry' : 'normal');
		};

		soundInputText = new UIInputText(10, speedStepper.y + 40, 150, '', 8);
		lineInputText = new UIInputText(10, soundInputText.y + 35, 200, DialogueEditorState.DEFAULT_TEXT, 8);
		lineInputText.onPressEnter = function(e)
		{
			if(e.shiftKey)
			{
				lineInputText.text += '\n';
				lineInputText.caretIndex++;
			}
			else UIInputText.focusOn = null;
		};

		var loadButton:UIButton = new UIButton(20, lineInputText.y + 25, "Load Dialogue", function() {
			dialogueEditor.loadDialogue();
		});
		var saveButton:UIButton = new UIButton(loadButton.x + 120, loadButton.y, "Save Dialogue", function() {
			dialogueEditor.saveDialogue();
		});

		tab_group.add(new FlxText(10, speedStepper.y - 18, 0, 'Interval/Speed (ms):'));
		tab_group.add(new FlxText(10, characterInputText.y - 18, 0, 'Character:'));
		tab_group.add(new FlxText(10, soundInputText.y - 18, 0, 'Sound file name:'));
		tab_group.add(new FlxText(10, lineInputText.y - 18, 0, 'Text:'));
		tab_group.add(characterInputText);
		tab_group.add(angryCheckbox);
		tab_group.add(speedStepper);
		tab_group.add(soundInputText);
		tab_group.add(lineInputText);
		tab_group.add(loadButton);
		tab_group.add(saveButton);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if(id == UICheckBox.CLICK_EVENT)
			dialogueEditor.unsavedProgress = true;

		if(id == UIInputText.CHANGE_EVENT && (sender is UIInputText)) {
			if (sender == characterInputText)
			{
				dialogueEditor.character.reloadCharacterJson(characterInputText.text);
				dialogueEditor.reloadCharacter();
				if(dialogueEditor.character.jsonFile.animations.length > 0) {
					dialogueEditor.curAnim = 0;
					if(dialogueEditor.character.jsonFile.animations.length > dialogueEditor.curAnim && dialogueEditor.character.jsonFile.animations[dialogueEditor.curAnim] != null) {
						dialogueEditor.character.playAnim(dialogueEditor.character.jsonFile.animations[dialogueEditor.curAnim].anim, dialogueEditor.daText.finishedText);
						dialogueEditor.animText.text = 'Animation: ' + dialogueEditor.character.jsonFile.animations[dialogueEditor.curAnim].anim + ' (' + (dialogueEditor.curAnim + 1) +' / ' + dialogueEditor.character.jsonFile.animations.length + ') - Press W or S to scroll';
					} else {
						dialogueEditor.animText.text = 'ERROR! NO ANIMATIONS FOUND';
					}
					dialogueEditor.characterAnimSpeed();
				}
				dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].portrait = characterInputText.text;
				dialogueEditor.reloadText(false);
				dialogueEditor.updateTextBox();
			}
			else if(sender == lineInputText)
			{
				dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].text = lineInputText.text;

				dialogueEditor.daText.text = lineInputText.text;
				if(dialogueEditor.daText.text == null) dialogueEditor.daText.text = '';
				dialogueEditor.reloadText(true);
			}
			else if(sender == soundInputText)
			{
				dialogueEditor.daText.finishText();
				dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].sound = soundInputText.text;
				dialogueEditor.daText.sound = soundInputText.text;
				if(dialogueEditor.daText.sound == null) dialogueEditor.daText.sound = '';
			}
			dialogueEditor.unsavedProgress = true;
		} else if(id == UINumericStepper.CHANGE_EVENT && (sender == speedStepper)) {
			dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].speed = speedStepper.value;
			if(Math.isNaN(dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].speed) || dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].speed == null || dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].speed < 0.001) {
				dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].speed = 0.0;
			}
			dialogueEditor.daText.delay = dialogueEditor.dialogueFile.dialogue[dialogueEditor.curSelected].speed;
			dialogueEditor.reloadText(false);
			dialogueEditor.unsavedProgress = true;
		}
	}
}
