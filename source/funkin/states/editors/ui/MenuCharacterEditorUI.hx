package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import flixel.text.FlxText;

@:access(funkin.states.editors.MenuCharacterEditorState)
class MenuCharacterEditorUI extends FlxSpriteContainer implements UIEventHandler.UIEvent
{
	private var menuCharEditor:MenuCharacterEditorState;

	public var UI_typebox:UIBox;
	public var UI_mainbox:UIBox;

	public var characterTypeRadio:UIRadioGroup;

	public var imageInputText:UIInputText;
	public var idleInputText:UIInputText;
	public var confirmInputText:UIInputText;
	public var scaleStepper:UINumericStepper;
	public var flipXCheckbox:UICheckBox;

	public function new(menuCharEditor:MenuCharacterEditorState)
	{
		super();
		this.menuCharEditor = menuCharEditor;
	}

	public function createUI()
	{
		addEditorBox();
	}

	function addEditorBox() {
		UI_typebox = new UIBox(100, FlxG.height - 230, 120, 180, ['Character Type']);
		UI_typebox.scrollFactor.set();
		addTypeUI();
		add(UI_typebox);

		
		UI_mainbox = new UIBox(FlxG.width - 340, FlxG.height - 265, 240, 215, ['Character']);
		UI_mainbox.scrollFactor.set();
		addCharacterUI();
		add(UI_mainbox);

		var loadButton:UIButton = new UIButton(0, 480, "Load Character", function() {
			menuCharEditor.loadCharacter();
		});
		loadButton.screenCenter(X);
		loadButton.x -= 60;
		add(loadButton);
	
		var saveButton:UIButton = new UIButton(0, 480, "Save Character", function() {
			menuCharEditor.saveCharacter();
		});
		saveButton.screenCenter(X);
		saveButton.x += 60;
		add(saveButton);
	}

	function addTypeUI() {
		var tab_group = UI_typebox.getTab('Character Type').menu;

		characterTypeRadio = new UIRadioGroup(10, 20, ['Opponent', 'Boyfriend', 'Girlfriend'], 40);
		characterTypeRadio.checked = 0;
		characterTypeRadio.onClick = menuCharEditor.updateCharacters;
		tab_group.add(characterTypeRadio);
	}

	function addCharacterUI() {
		var tab_group = UI_mainbox.getTab('Character').menu;
		
		imageInputText = new UIInputText(10, 20, 80, menuCharEditor.characterFile.image, 8);
		idleInputText = new UIInputText(10, imageInputText.y + 35, 100, menuCharEditor.characterFile.idle_anim, 8);
		confirmInputText = new UIInputText(10, idleInputText.y + 35, 100, menuCharEditor.characterFile.confirm_anim, 8);

		flipXCheckbox = new UICheckBox(10, confirmInputText.y + 30, "Flip X", 100);
		flipXCheckbox.onClick = function()
		{
			menuCharEditor.grpWeekCharacters.members[characterTypeRadio.checked].flipX = flipXCheckbox.checked;
			menuCharEditor.characterFile.flipX = flipXCheckbox.checked;
		};

		var reloadImageButton:UIButton = new UIButton(140, confirmInputText.y + 30, "Reload Char", function() {
			menuCharEditor.reloadSelectedCharacter();
		});
		
		scaleStepper = new UINumericStepper(140, imageInputText.y, 0.05, 1, 0.1, 30, 2);

		var confirmDescText = new FlxText(10, confirmInputText.y - 18, 0, 'Start Press animation on the .XML:');
		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(10, idleInputText.y - 18, 0, 'Idle animation on the .XML:'));
		tab_group.add(new FlxText(scaleStepper.x, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(flipXCheckbox);
		tab_group.add(reloadImageButton);
		tab_group.add(confirmDescText);
		tab_group.add(imageInputText);
		tab_group.add(idleInputText);
		tab_group.add(confirmInputText);
		tab_group.add(scaleStepper);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if(id == UICheckBox.CLICK_EVENT)
			menuCharEditor.unsavedProgress = true;

		if(id == UIInputText.CHANGE_EVENT && (sender is UIInputText)) {
			if(sender == imageInputText) {
				menuCharEditor.characterFile.image = imageInputText.text;
				menuCharEditor.unsavedProgress = true;
			} else if(sender == idleInputText) {
				menuCharEditor.characterFile.idle_anim = idleInputText.text;
				menuCharEditor.unsavedProgress = true;
			} else if(sender == confirmInputText) {
				menuCharEditor.characterFile.confirm_anim = confirmInputText.text;
				menuCharEditor.unsavedProgress = true;
			}
		} else if(id == UINumericStepper.CHANGE_EVENT && (sender is UINumericStepper)) {
			if (sender == scaleStepper) {
				menuCharEditor.characterFile.scale = scaleStepper.value;
				menuCharEditor.reloadSelectedCharacter();
				menuCharEditor.unsavedProgress = true;
			}
		}
	}
}
