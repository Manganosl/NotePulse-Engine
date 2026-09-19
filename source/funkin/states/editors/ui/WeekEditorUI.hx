package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import flixel.text.FlxText;
import lime.system.Clipboard;

import funkin.states.editors.WeekEditorState.WeekEditorFreeplayState;

@:access(funkin.states.editors.WeekEditorState)
class WeekEditorUI extends FlxSpriteContainer implements UIEventHandler.UIEvent
{
	private var weekEditor:WeekEditorState;

	public var UI_box:UIBox;

	public var songsInputText:UIInputText;
	public var backgroundInputText:UIInputText;
	public var displayNameInputText:UIInputText;
	public var weekNameInputText:UIInputText;
	public var weekFileInputText:UIInputText;

	public var opponentInputText:UIInputText;
	public var boyfriendInputText:UIInputText;
	public var girlfriendInputText:UIInputText;

	public var hideCheckbox:UICheckBox;

	public var weekBeforeInputText:UIInputText;
	public var difficultiesInputText:UIInputText;
	public var lockedCheckbox:UICheckBox;
	public var hiddenUntilUnlockCheckbox:UICheckBox;

	public function new(weekEditor:WeekEditorState)
	{
		super();
		this.weekEditor = weekEditor;
	}

	public function createUI()
	{
		addEditorBox();
	}

	function addEditorBox() {
		UI_box = new UIBox(FlxG.width, FlxG.height, 250, 375, ['Other', 'Week']);
		UI_box.x -= UI_box.width;
		UI_box.y -= UI_box.height;
		UI_box.scrollFactor.set();
		add(UI_box);
		addOtherUI();
		addWeekUI();
		
		UI_box.selectedName = 'Week';
		add(UI_box);

		var loadWeekButton:UIButton = new UIButton(0, 650, "Load Week", function() WeekEditorState.loadWeek());
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var freeplayButton:UIButton = new UIButton(0, 650, "Freeplay", function() MusicBeatState.switchState(new WeekEditorFreeplayState(weekEditor.weekFile)));
		freeplayButton.screenCenter(X);
		add(freeplayButton);
	
		var saveWeekButton:UIButton = new UIButton(0, 650, "Save Week", function() WeekEditorState.saveWeek(weekEditor.weekFile));
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}

	function addWeekUI() {
		var tab_group = UI_box.getTab('Week').menu;

		songsInputText = new UIInputText(10, 30, 200, '', 8);

		opponentInputText = new UIInputText(10, songsInputText.y + 40, 70, '', 8);
		boyfriendInputText = new UIInputText(opponentInputText.x + 75, opponentInputText.y, 70, '', 8);
		girlfriendInputText = new UIInputText(boyfriendInputText.x + 75, opponentInputText.y, 70, '', 8);

		backgroundInputText = new UIInputText(10, opponentInputText.y + 40, 120, '', 8);
		displayNameInputText = new UIInputText(10, backgroundInputText.y + 60, 200, '', 8);
		weekNameInputText = new UIInputText(10, displayNameInputText.y + 60, 150, '', 8);
		weekFileInputText = new UIInputText(10, weekNameInputText.y + 40, 100, '', 8);
		weekEditor.reloadWeekThing();

		hideCheckbox = new UICheckBox(10, weekFileInputText.y + 40, "Hide Week from Story Mode?", 100);
		hideCheckbox.onClick = function()
		{
			weekEditor.weekFile.hideStoryMode = hideCheckbox.checked;
			WeekEditorState.unsavedProgress = true;
		};

		tab_group.add(new FlxText(songsInputText.x, songsInputText.y - 18, 0, 'Songs:'));
		tab_group.add(new FlxText(opponentInputText.x, opponentInputText.y - 18, 0, 'Characters:'));
		tab_group.add(new FlxText(backgroundInputText.x, backgroundInputText.y - 18, 0, 'Background Asset:'));
		tab_group.add(new FlxText(displayNameInputText.x, displayNameInputText.y - 18, 0, 'Display Name:'));
		tab_group.add(new FlxText(weekNameInputText.x, weekNameInputText.y - 18, 0, 'Week Name (for Reset Score Menu):'));
		tab_group.add(new FlxText(weekFileInputText.x, weekFileInputText.y - 18, 0, 'Week File:'));

		tab_group.add(songsInputText);
		tab_group.add(opponentInputText);
		tab_group.add(boyfriendInputText);
		tab_group.add(girlfriendInputText);
		tab_group.add(backgroundInputText);

		tab_group.add(displayNameInputText);
		tab_group.add(weekNameInputText);
		tab_group.add(weekFileInputText);
		tab_group.add(hideCheckbox);
	}

	function addOtherUI() {
		var tab_group = UI_box.getTab('Other').menu;

		lockedCheckbox = new UICheckBox(10, 30, "Week starts Locked", 100);
		lockedCheckbox.onClick = function()
		{
			weekEditor.weekFile.startUnlocked = !lockedCheckbox.checked;
			weekEditor.lock.visible = lockedCheckbox.checked;
			hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);
			WeekEditorState.unsavedProgress = true;
		};

		hiddenUntilUnlockCheckbox = new UICheckBox(10, lockedCheckbox.y + 25, "Hidden until Unlocked", 110);
		hiddenUntilUnlockCheckbox.onClick = function()
		{
			weekEditor.weekFile.hiddenUntilUnlocked = hiddenUntilUnlockCheckbox.checked;
			WeekEditorState.unsavedProgress = true;
		};
		hiddenUntilUnlockCheckbox.alpha = 0.4;

		weekBeforeInputText = new UIInputText(10, hiddenUntilUnlockCheckbox.y + 55, 100, '', 8);
		difficultiesInputText = new UIInputText(10, weekBeforeInputText.y + 60, 200, '', 8);
		
		tab_group.add(new FlxText(weekBeforeInputText.x, weekBeforeInputText.y - 28, 0, 'Week File name of the Week you have\nto finish for Unlocking:'));
		tab_group.add(new FlxText(difficultiesInputText.x, difficultiesInputText.y - 20, 0, 'Difficulties:'));
		tab_group.add(new FlxText(difficultiesInputText.x, difficultiesInputText.y + 20, 0, 'Default difficulties are "Easy, Normal, Hard"\nwithout quotes.'));
		tab_group.add(weekBeforeInputText);
		tab_group.add(difficultiesInputText);
		tab_group.add(hiddenUntilUnlockCheckbox);
		tab_group.add(lockedCheckbox);
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if(id == UICheckBox.CLICK_EVENT)
			WeekEditorState.unsavedProgress = true;

		if(id == UIInputText.CHANGE_EVENT && (sender is UIInputText)) {
			if(sender == weekFileInputText) {
				WeekEditorState.weekFileName = weekFileInputText.text.trim();
				WeekEditorState.unsavedProgress = true;
				weekEditor.reloadWeekThing();
			} else if(sender == opponentInputText || sender == boyfriendInputText || sender == girlfriendInputText) {
				weekEditor.weekFile.weekCharacters[0] = opponentInputText.text.trim();
				weekEditor.weekFile.weekCharacters[1] = boyfriendInputText.text.trim();
				weekEditor.weekFile.weekCharacters[2] = girlfriendInputText.text.trim();
				WeekEditorState.unsavedProgress = true;
				weekEditor.updateText();
			} else if(sender == backgroundInputText) {
				weekEditor.weekFile.weekBackground = backgroundInputText.text.trim();
				WeekEditorState.unsavedProgress = true;
				weekEditor.reloadBG();
			} else if(sender == displayNameInputText) {
				weekEditor.weekFile.storyName = displayNameInputText.text.trim();
				WeekEditorState.unsavedProgress = true;
				weekEditor.updateText();
			} else if(sender == weekNameInputText) {
				weekEditor.weekFile.weekName = weekNameInputText.text.trim();
				WeekEditorState.unsavedProgress = true;
			} else if(sender == songsInputText) {
				var splittedText:Array<String> = songsInputText.text.trim().split(',');
				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				while(splittedText.length < weekEditor.weekFile.songs.length) {
					weekEditor.weekFile.songs.pop();
				}

				for (i in 0...splittedText.length) {
					if(i >= weekEditor.weekFile.songs.length) { //Add new song
						weekEditor.weekFile.songs.push([splittedText[i], 'face', [146, 113, 253]]);
					} else { //Edit song
						weekEditor.weekFile.songs[i][0] = splittedText[i];
						if(weekEditor.weekFile.songs[i][1] == null || weekEditor.weekFile.songs[i][1]) {
							weekEditor.weekFile.songs[i][1] = 'face';
							weekEditor.weekFile.songs[i][2] = [146, 113, 253];
						}
					}
				}
				weekEditor.updateText();
				WeekEditorState.unsavedProgress = true;
			} else if(sender == weekBeforeInputText) {
				weekEditor.weekFile.weekBefore = weekBeforeInputText.text.trim();
				WeekEditorState.unsavedProgress = true;
			} else if(sender == difficultiesInputText) {
				weekEditor.weekFile.difficulties = difficultiesInputText.text.trim();
				WeekEditorState.unsavedProgress = true;
			}
		}
	}
}

@:access(funkin.states.editors.WeekEditorFreeplayState)
class WeekEditorFreeplayUI extends FlxSpriteContainer implements UIEventHandler.UIEvent
{
	private var weekEditor:WeekEditorFreeplayState;

	public var UI_box:UIBox;

	public var bgColorStepperR:UINumericStepper;
	public var bgColorStepperG:UINumericStepper;
	public var bgColorStepperB:UINumericStepper;
	public var iconInputText:UIInputText;

	public function new(weekEditor:WeekEditorFreeplayState)
	{
		super();
		this.weekEditor = weekEditor;
	}

	public function createUI()
	{
		addEditorBox();
	}

	function addEditorBox() {
		var tabs = [
			{name: 'Freeplay', label: 'Freeplay'},
		];
		UI_box = new UIBox(FlxG.width, FlxG.height, 250, 200, ['Freeplay']);
		UI_box.x -= UI_box.width + 100;
		UI_box.y -= UI_box.height + 60;
		UI_box.scrollFactor.set();
		addFreeplayUI();
		add(UI_box);

		var blackBlack:FlxSprite = new FlxSprite(0, 670).makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		blackBlack.alpha = 0.6;
		add(blackBlack);

		var loadWeekButton:UIButton = new UIButton(0, 685, "Load Week", function() {
			WeekEditorState.loadWeek();
		});
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var storyModeButton:UIButton = new UIButton(0, 685, "Story Mode", function() {
			MusicBeatState.switchState(new WeekEditorState(weekEditor.weekFile));
			
		});
		storyModeButton.screenCenter(X);
		add(storyModeButton);
	
		var saveWeekButton:UIButton = new UIButton(0, 685, "Save Week", function() {
			WeekEditorState.saveWeek(weekEditor.weekFile);
		});
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}
	
	public function UIEvent(id:String, sender:Dynamic)
	{
		if(id == UICheckBox.CLICK_EVENT)
			WeekEditorState.unsavedProgress = true;

		if(id == UIInputText.CHANGE_EVENT && (sender is UIInputText))
		{
			weekEditor.weekFile.songs[weekEditor.curSelected][1] = iconInputText.text;
			weekEditor.iconArray[weekEditor.curSelected].changeIcon(iconInputText.text);
		}
		else if(id == UINumericStepper.CHANGE_EVENT && (sender is UINumericStepper))
		{
			if(sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB)
				weekEditor.updateBG();
		}
	}

	function addFreeplayUI() {
		var tab_group = UI_box.getTab('Freeplay').menu;

		bgColorStepperR = new UINumericStepper(10, 40, 20, 255, 0, 255, 0);
		bgColorStepperG = new UINumericStepper(80, 40, 20, 255, 0, 255, 0);
		bgColorStepperB = new UINumericStepper(150, 40, 20, 255, 0, 255, 0);

		var copyColor:UIButton = new UIButton(10, bgColorStepperR.y + 25, "Copy Color", function() Clipboard.text = weekEditor.bg.color.red + ',' + weekEditor.bg.color.green + ',' + weekEditor.bg.color.blue);

		var pasteColor:UIButton = new UIButton(140, copyColor.y, "Paste Color", function()
		{
			if(Clipboard.text != null)
			{
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');
				for (i in 0...splitted.length)
				{
					var toPush:Int = Std.parseInt(splitted[i]);
					if(!Math.isNaN(toPush))
					{
						if(toPush > 255) toPush = 255;
						else if(toPush < 0) toPush *= -1;
						leColor.push(toPush);
					}
				}

				if(leColor.length > 2)
				{
					bgColorStepperR.value = leColor[0];
					bgColorStepperG.value = leColor[1];
					bgColorStepperB.value = leColor[2];
					weekEditor.updateBG();
				}
			}
		});

		iconInputText = new UIInputText(10, bgColorStepperR.y + 70, 100, '', 8);

		var hideFreeplayCheckbox:UICheckBox = new UICheckBox(10, iconInputText.y + 30, "Hide Week from Freeplay?", 100);
		hideFreeplayCheckbox.checked = weekEditor.weekFile.hideFreeplay;
		hideFreeplayCheckbox.onClick = function()
		{
			weekEditor.weekFile.hideFreeplay = hideFreeplayCheckbox.checked;
			WeekEditorState.unsavedProgress = true;
		};
		
		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(10, iconInputText.y - 18, 0, 'Selected icon:'));
		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);
		tab_group.add(copyColor);
		tab_group.add(pasteColor);
		tab_group.add(iconInputText);
		tab_group.add(hideFreeplayCheckbox);
	}
}
