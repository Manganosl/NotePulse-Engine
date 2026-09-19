package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import flixel.text.FlxText;

import funkin.game.cutscenes.DialogueBoxPsych;
import funkin.game.cutscenes.DialogueCharacter;

@:access(funkin.states.editors.DialogueCharacterEditorState)
class DialogueCharacterEditorUI extends FlxSpriteContainer implements UIEventHandler.UIEvent
{
	private var dialogueEditor:DialogueCharacterEditorState;

	public var UI_typebox:UIBox;
	public var UI_mainbox:UIBox;

	public var characterTypeRadio:UIRadioGroup;

	public var animationArray:Array<String> = [];
	public var animationDropDown:UIDropDownMenu;
	public var animationInputText:UIInputText;
	public var loopInputText:UIInputText;
	public var idleInputText:UIInputText;

	public var imageInputText:UIInputText;
	public var scaleStepper:UINumericStepper;
	public var xStepper:UINumericStepper;
	public var yStepper:UINumericStepper;

	public function new(dialogueEditor:DialogueCharacterEditorState)
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
		UI_typebox = new UIBox(900, FlxG.height - 230, 120, 180, ['Character Type']);
		UI_typebox.scrollFactor.set();
		UI_typebox.cameras = [dialogueEditor.camHUD];
		addTypeUI();
		add(UI_typebox);

		UI_mainbox = new UIBox(UI_typebox.x + UI_typebox.width + 10, FlxG.height - 300, 200, 250, ['Animations', 'Character']);
		UI_mainbox.scrollFactor.set();
		UI_mainbox.cameras = [dialogueEditor.camHUD];
		addAnimationsUI();
		addCharacterUI();
		add(UI_mainbox);
		UI_mainbox.selectedName = 'Character';
		dialogueEditor.lastTab = UI_mainbox.selectedName;
	}

	function addTypeUI()
	{
		var tab_group = UI_typebox.getTab('Character Type').menu;

		characterTypeRadio = new UIRadioGroup(10, 20, ['Left', 'Center', 'Right'], 40);
		characterTypeRadio.checked = 0;
		characterTypeRadio.onClick = function()
		{
			switch (characterTypeRadio.checked)
			{
				case 0:
					dialogueEditor.character.jsonFile.dialogue_pos = 'left';
				case 1:
					dialogueEditor.character.jsonFile.dialogue_pos = 'center';
				case 2:
					dialogueEditor.character.jsonFile.dialogue_pos = 'right';
			}
			dialogueEditor.updateCharTypeBox();
		}
		tab_group.add(characterTypeRadio);
	}

	function addAnimationsUI()
	{
		var tab_group = UI_mainbox.getTab('Animations').menu;

		animationDropDown = new UIDropDownMenu(10, 30, [''], function(id:Int, animation:String)
		{
			if (dialogueEditor.character.dialogueAnimations.exists(animation))
			{
				dialogueEditor.ghostLoop.playAnim(animation);
				dialogueEditor.ghostIdle.playAnim(animation, true);

				dialogueEditor.curSelectedAnim = animation;
				var animShit:DialogueAnimArray = dialogueEditor.character.dialogueAnimations.get(dialogueEditor.curSelectedAnim);
				dialogueEditor.offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
				dialogueEditor.offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;

				animationInputText.text = animShit.anim;
				loopInputText.text = animShit.loop_name;
				idleInputText.text = animShit.idle_name;
			}
		});

		animationInputText = new UIInputText(15, 85, 80, '', 8);
		loopInputText = new UIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		idleInputText = new UIInputText(loopInputText.x, loopInputText.y + 40, 150, '', 8);

		var addUpdateButton:UIButton = new UIButton(10, idleInputText.y + 30, "Add/Update", function()
		{
			var theAnim:String = animationInputText.text.trim();
			if (dialogueEditor.character.dialogueAnimations.exists(theAnim)) // Update
			{
				for (i in 0...dialogueEditor.character.jsonFile.animations.length)
				{
					var animArray:DialogueAnimArray = dialogueEditor.character.jsonFile.animations[i];
					if (animArray.anim.trim() == theAnim)
					{
						animArray.loop_name = loopInputText.text;
						animArray.idle_name = idleInputText.text;
						break;
					}
				}

				dialogueEditor.character.reloadAnimations();
				dialogueEditor.ghostLoop.reloadAnimations();
				dialogueEditor.ghostIdle.reloadAnimations();
				if (dialogueEditor.curSelectedAnim == theAnim)
				{
					dialogueEditor.ghostLoop.playAnim(theAnim);
					dialogueEditor.ghostIdle.playAnim(theAnim, true);
				}
			}
			else // Add
			{
				var newAnim:DialogueAnimArray = {
					anim: theAnim,
					loop_name: loopInputText.text,
					loop_offsets: [0, 0],
					idle_name: idleInputText.text,
					idle_offsets: [0, 0]
				}
				dialogueEditor.character.jsonFile.animations.push(newAnim);

				var lastSelected:String = animationDropDown.selectedLabel;
				dialogueEditor.character.reloadAnimations();
				dialogueEditor.ghostLoop.reloadAnimations();
				dialogueEditor.ghostIdle.reloadAnimations();
				reloadAnimationsDropDown();
				animationDropDown.selectedLabel = lastSelected;
			}
		});

		var removeUpdateButton:UIButton = new UIButton(100, addUpdateButton.y, "Remove", function()
		{
			for (i in 0...dialogueEditor.character.jsonFile.animations.length)
			{
				var animArray:DialogueAnimArray = dialogueEditor.character.jsonFile.animations[i];
				if (animArray != null && animArray.anim.trim() == animationInputText.text.trim())
				{
					var lastSelected:String = animationDropDown.selectedLabel;
					dialogueEditor.character.jsonFile.animations.remove(animArray);
					dialogueEditor.character.reloadAnimations();
					dialogueEditor.ghostLoop.reloadAnimations();
					dialogueEditor.ghostIdle.reloadAnimations();
					reloadAnimationsDropDown();
					if (dialogueEditor.character.jsonFile.animations.length > 0 && lastSelected == animArray.anim.trim())
					{
						var animToPlay:String = dialogueEditor.character.jsonFile.animations[0].anim;
						dialogueEditor.ghostLoop.playAnim(animToPlay);
						dialogueEditor.ghostIdle.playAnim(animToPlay, true);
					}
					animationDropDown.selectedLabel = lastSelected;
					animationInputText.text = '';
					loopInputText.text = '';
					idleInputText.text = '';
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(loopInputText.x, loopInputText.y - 18, 0, 'Loop name on .XML file:'));
		tab_group.add(new FlxText(idleInputText.x, idleInputText.y - 18, 0, 'Idle/Finished name on .XML file:'));
		tab_group.add(animationInputText);
		tab_group.add(loopInputText);
		tab_group.add(idleInputText);
		tab_group.add(addUpdateButton);
		tab_group.add(removeUpdateButton);
		tab_group.add(animationDropDown);
		reloadAnimationsDropDown();
	}

	public function reloadAnimationsDropDown()
	{
		animationArray = [];
		for (anim in dialogueEditor.character.jsonFile.animations)
		{
			animationArray.push(anim.anim);
		}

		if (animationArray.length < 1)
			animationArray = [''];
		animationDropDown.list = animationArray;
	}

	function addCharacterUI()
	{
		var tab_group = UI_mainbox.getTab('Character').menu;

		imageInputText = new UIInputText(10, 30, 80, dialogueEditor.character.jsonFile.image, 8);
		xStepper = new UINumericStepper(imageInputText.x, imageInputText.y + 50, 10, dialogueEditor.character.jsonFile.position[0], -2000, 2000, 0);
		yStepper = new UINumericStepper(imageInputText.x + 80, xStepper.y, 10, dialogueEditor.character.jsonFile.position[1], -2000, 2000, 0);
		scaleStepper = new UINumericStepper(imageInputText.x, xStepper.y + 50, 0.05, dialogueEditor.character.jsonFile.scale, 0.1, 10, 2);

		var noAntialiasingCheckbox:UICheckBox = new UICheckBox(scaleStepper.x + 80, scaleStepper.y, "No Antialiasing", 100);
		noAntialiasingCheckbox.checked = (dialogueEditor.character.jsonFile.no_antialiasing == true);
		noAntialiasingCheckbox.onClick = function()
		{
			dialogueEditor.character.jsonFile.no_antialiasing = noAntialiasingCheckbox.checked;
			dialogueEditor.character.antialiasing = !dialogueEditor.character.jsonFile.no_antialiasing;
		};

		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(10, xStepper.y - 18, 0, 'Position Offset:'));
		tab_group.add(new FlxText(10, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(imageInputText);
		tab_group.add(xStepper);
		tab_group.add(yStepper);
		tab_group.add(scaleStepper);
		tab_group.add(noAntialiasingCheckbox);

		var reloadImageButton:UIButton = new UIButton(10, scaleStepper.y + 60, "Reload Image", function()
		{
			dialogueEditor.reloadCharacter();
		});

		var loadButton:UIButton = new UIButton(reloadImageButton.x + 100, reloadImageButton.y, "Load Character", function()
		{
			dialogueEditor.loadCharacter();
		});
		var saveButton:UIButton = new UIButton(loadButton.x, reloadImageButton.y - 25, "Save Character", function()
		{
			dialogueEditor.saveCharacter();
		});
		tab_group.add(reloadImageButton);
		tab_group.add(loadButton);
		tab_group.add(saveButton);
	}

	public function UIEvent(id:String, sender:Dynamic)
	{
		// trace(id, sender);
		if (id == UICheckBox.CLICK_EVENT)
			dialogueEditor.unsavedProgress = true;

		if (id == UIInputText.CHANGE_EVENT && sender == imageInputText)
		{
			dialogueEditor.character.jsonFile.image = imageInputText.text;
			dialogueEditor.unsavedProgress = true;
		}
		else if (id == UINumericStepper.CHANGE_EVENT && (sender is UINumericStepper))
		{
			if (sender == scaleStepper)
			{
				dialogueEditor.character.jsonFile.scale = scaleStepper.value;
				dialogueEditor.reloadCharacter();
			}
			else if (sender == xStepper)
			{
				dialogueEditor.character.jsonFile.position[0] = xStepper.value;
				dialogueEditor.reloadCharacter();
			}
			else if (sender == yStepper)
			{
				dialogueEditor.character.jsonFile.position[1] = yStepper.value;
				dialogueEditor.reloadCharacter();
			}
			dialogueEditor.unsavedProgress = true;
		}
	}
}
