package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import openfl.utils.Assets;

import funkin.objects.Character.CharacterFile;
import funkin.objects.Character.AnimArray;

import funkin.states.editors.CharacterEditorState;

@:access(funkin.states.editors.CharacterEditorState)
class CharacterEditorUI extends FlxSpriteContainer implements UIEventHandler.UIEvent
{
	private var editor:CharacterEditorState;

	public var ghostAlpha:Float = 0.6;

	var UI_Box:UIBox;
	var UI_CharacterBox:UIBox;

	public var check_player:UICheckBox;
	var charDropDown:UIDropDownMenu;
	var characterList:Array<String> = [];

	public var animationDropDown:UIDropDownMenu;
	var animationInputText:UIInputText;
	var animationNameInputText:UIInputText;
	var animationIndicesInputText:UIInputText;
	var animationFramerate:UINumericStepper;
	var animationLoopCheckBox:UICheckBox;

	var imageInputText:UIInputText;
	var healthIconInputText:UIInputText;
	var vocalsInputText:UIInputText;
	var singDurationStepper:UINumericStepper;
	var scaleStepper:UINumericStepper;
	var positionXStepper:UINumericStepper;
	var positionYStepper:UINumericStepper;
	var positionCameraXStepper:UINumericStepper;
	var positionCameraYStepper:UINumericStepper;
	var flipXCheckBox:UICheckBox;
	var noAntialiasingCheckBox:UICheckBox;
	public var healthColorHSV:UIHSVPicker;

	public function new(editor:CharacterEditorState)
	{
		super();

		this.editor = editor;
	}

	public function createUI()
	{
		UI_Box = new UIBox(FlxG.width - 275, 25, 250, 120, ['Ghost', 'Settings']);
		UI_Box.scrollFactor.set();

		UI_CharacterBox = new UIBox(UI_Box.x - 100, UI_Box.y + UI_Box.height + 10, 350, 280, ['Animations', 'Character']);
		UI_CharacterBox.scrollFactor.set();
		add(UI_CharacterBox);
		add(UI_Box);

		addGhostUI();
		addSettingsUI();
		addAnimationsUI();
		addCharacterUI();

		UI_Box.selectedName = 'Settings';
		UI_CharacterBox.selectedName = 'Character';
	}

	function addGhostUI()
	{
		var tab_group = UI_Box.getTab('Ghost').menu;

		var makeGhostButton:UIButton = new UIButton(25, 15, "Make Ghost", function() {
			var anim = editor.anims[editor.curAnim];
			if(!editor.character.isAnimationNull())
			{
				var myAnim = editor.anims[editor.curAnim];
				if(!editor.character.isAnimateAtlas)
				{
					editor.ghost.loadGraphic(editor.character.graphic);
					editor.ghost.frames.frames = editor.character.frames.frames;
					editor.ghost.animation.copyFrom(editor.character.animation);
					editor.ghost.animation.play(editor.character.animation.curAnim.name, true, false, editor.character.animation.curAnim.curFrame);
					editor.ghost.animation.pause();
				}
				else if(myAnim != null) //This is VERY unoptimized and bad, I hope to find a better replacement that loads only a specific frame as bitmap in the future.
				{
					if(editor.animateGhost == null) //If I created the animateGhost on create() and you didn't load an atlas, it would crash the game on destroy, so we create it here
					{
						editor.animateGhost = new FlxAnimate(editor.ghost.x, editor.ghost.y);
						editor.insert(editor.members.indexOf(editor.ghost), editor.animateGhost);
						editor.animateGhost.active = false;
					}

					if(editor.animateGhost == null || editor.animateGhostImage != editor.character.imageFile)
						editor.animateGhost.frames = Paths.getTextureAtlas(editor.character.imageFile);

					if(myAnim.indices != null && myAnim.indices.length > 0)
						editor.animateGhost.anim.addBySymbolIndices('anim', myAnim.name, myAnim.indices, 0, false);
					else
						editor.animateGhost.anim.addBySymbol('anim', myAnim.name, 0, false);

					editor.animateGhost.anim.play('anim', true, false, editor.character.anim.frameIndex);
					editor.animateGhost.anim.pause();

					editor.animateGhostImage = editor.character.imageFile;
				}

				var spr:FlxSprite = !editor.character.isAnimateAtlas ? editor.ghost : editor.animateGhost;
				if(spr != null)
				{
					spr.setPosition(editor.character.x, editor.character.y);
					spr.antialiasing = editor.character.antialiasing;
					spr.flipX = editor.character.flipX;
					spr.alpha = ghostAlpha;

					spr.scale.set(editor.character.scale.x, editor.character.scale.y);
					spr.updateHitbox();

					spr.offset.set(editor.character.offset.x, editor.character.offset.y);
					spr.visible = true;

					var otherSpr:FlxSprite = (spr == editor.animateGhost) ? editor.ghost : editor.animateGhost;
					if(otherSpr != null) otherSpr.visible = false;
				}
				trace('created ghost image');
			}
		});

		var highlightGhost:UICheckBox = new UICheckBox(20 + makeGhostButton.x + makeGhostButton.width, makeGhostButton.y, "Highlight Ghost", 100);
		highlightGhost.onClick = function()
		{
			var value = highlightGhost.checked ? 125 : 0;
			editor.ghost.colorTransform.redOffset = value;
			editor.ghost.colorTransform.greenOffset = value;
			editor.ghost.colorTransform.blueOffset = value;
			if(editor.animateGhost != null)
			{
				editor.animateGhost.colorTransform.redOffset = value;
				editor.animateGhost.colorTransform.greenOffset = value;
				editor.animateGhost.colorTransform.blueOffset = value;
			}
		};

		var ghostAlphaSlider:UISlider = new UISlider(15, makeGhostButton.y + 25, function(v:Float)
		{
			ghostAlpha = v;
			editor.ghost.alpha = ghostAlpha;
			if(editor.animateGhost != null) editor.animateGhost.alpha = ghostAlpha;

		}, ghostAlpha, 0, 1);
		ghostAlphaSlider.label = 'Opacity:';

		tab_group.add(makeGhostButton);
		tab_group.add(highlightGhost);
		tab_group.add(ghostAlphaSlider);
	}

	function addSettingsUI()
	{
		var tab_group = UI_Box.getTab('Settings').menu;

		check_player = new UICheckBox(10, 60, "Playable Character", 100);
		check_player.checked = editor.character.isPlayer;
		check_player.onClick = function()
		{
			editor.character.isPlayer = !editor.character.isPlayer;
			editor.character.flipX = !editor.character.flipX;
			editor.updateCharacterPositions();
			editor.updatePointerPos(false);
		};

		var reloadCharacter:UIButton = new UIButton(140, 20, "Reload Char", function()
		{
			editor.addCharacter(true);
			editor.updatePointerPos();
			reloadCharacterOptions();
			reloadCharacterDropDown();
		});

		var templateCharacter:UIButton = new UIButton(140, 50, "Load Template", function()
		{
			final _template:CharacterFile =
			{
				animations: [
					editor.newAnim('idle', 'BF idle dance'),
					editor.newAnim('singLEFT', 'BF NOTE LEFT0'),
					editor.newAnim('singDOWN', 'BF NOTE DOWN0'),
					editor.newAnim('singUP', 'BF NOTE UP0'),
					editor.newAnim('singRIGHT', 'BF NOTE RIGHT0')
				],
				no_antialiasing: false,
				flip_x: false,
				healthicon: 'face',
				image: 'characters/BOYFRIEND',
				sing_duration: 4,
				scale: 1,
				healthbar_colors: [161, 161, 161],
				camera_position: [0, 0],
				position: [0, 0],
				vocals_file: null
			};

			editor.character.loadCharacterFile(_template);
			editor.character.color = FlxColor.WHITE;
			editor.character.alpha = 1;
			editor.reloadAnimList();
			reloadCharacterOptions();
			editor.updateCharacterPositions();
			editor.updatePointerPos();
			reloadCharacterDropDown();
			editor.updateHealthBar();
		});
		templateCharacter.normalStyle.bgColor = FlxColor.RED;
		templateCharacter.normalStyle.textColor = FlxColor.WHITE;

		charDropDown = new UIDropDownMenu(10, 30, [''], function(index:Int, intended:String)
		{
			if(intended == null || intended.length < 1) return;

			var isJSON:Bool = true;
			var characterPath:String = 'characters/$intended.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (!FileSystem.exists(path))
			#else
			if (!Assets.exists(path))
			#end
			{
				characterPath = 'characters/$intended.xml';
				path = Paths.getPath(characterPath, TEXT);
				isJSON = false;
			}
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				editor._char = intended;
				check_player.checked = editor.character.isPlayer;
				editor.addCharacter();
				reloadCharacterOptions();
				reloadCharacterDropDown();
				editor.updatePointerPos();
			}
			else
			{
				reloadCharacterDropDown();
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
		});
		reloadCharacterDropDown();
		charDropDown.selectedLabel = editor._char;

		tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 18, 80, 'Character:'));
		tab_group.add(check_player);
		tab_group.add(reloadCharacter);
		tab_group.add(templateCharacter);
		tab_group.add(charDropDown);
	}

	function addAnimationsUI()
	{
		var tab_group = UI_CharacterBox.getTab('Animations').menu;

		animationInputText = new UIInputText(15, 85, 80, '', 8);
		animationNameInputText = new UIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new UIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new UINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new UICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, "Should it Loop?", 100);

		animationDropDown = new UIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = editor.character.animationsArray[selectedAnimation];
			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		var addUpdateButton:UIButton = new UIButton(70, animationIndicesInputText.y + 60, "Add/Update", function() {
			var indices:Array<Int> = [];
			var indicesStr:Array<String> = animationIndicesInputText.text.trim().split(',');
			if(indicesStr.length > 1) {
				for (i in 0...indicesStr.length) {
					var index:Int = Std.parseInt(indicesStr[i]);
					if(indicesStr[i] != null && indicesStr[i] != '' && !Math.isNaN(index) && index > -1) {
						indices.push(index);
					}
				}
			}

			var lastAnim:String = (editor.character.animationsArray[editor.curAnim] != null) ? editor.character.animationsArray[editor.curAnim].anim : '';
			var lastOffsets:Array<Int> = [0, 0];
			for (anim in editor.character.animationsArray)
				if(animationInputText.text == anim.anim) {
					lastOffsets = anim.offsets;
					if(editor.character.animOffsets.exists(animationInputText.text))
					{
						if(!editor.character.isAnimateAtlas) editor.character.animation.remove(animationInputText.text);
						else @:privateAccess editor.character.anim._animations.remove(animationInputText.text);
					}
					editor.character.animationsArray.remove(anim);
				}

			var addedAnim:AnimArray = editor.newAnim(animationInputText.text, animationNameInputText.text);
			addedAnim.fps = Math.round(animationFramerate.value);
			addedAnim.loop = animationLoopCheckBox.checked;
			addedAnim.indices = indices;
			addedAnim.offsets = lastOffsets;
			editor.addAnimation(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop, addedAnim.indices);
			editor.character.animationsArray.push(addedAnim);

			editor.reloadAnimList();
			editor.curAnim = Std.int(Math.max(0, editor.character.animationsArray.indexOf(addedAnim)));
			editor.character.playAnim(addedAnim.anim, true);
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:UIButton = new UIButton(180, animationIndicesInputText.y + 60, "Remove", function() {
			for (anim in editor.character.animationsArray)
				if(animationInputText.text == anim.anim)
				{
					var resetAnim:Bool = false;
					if(anim.anim == editor.character.getAnimationName()) resetAnim = true;
					if(editor.character.animOffsets.exists(anim.anim))
					{
						if(!editor.character.isAnimateAtlas) editor.character.animation.remove(anim.anim);
						else @:privateAccess editor.character.anim._animations.remove(anim.anim);
						editor.character.animOffsets.remove(anim.anim);
						editor.character.animationsArray.remove(anim);
					}

					if(resetAnim && editor.character.animationsArray.length > 0) {
						editor.curAnim = FlxMath.wrap(editor.curAnim, 0, editor.anims.length-1);
						editor.character.playAnim(editor.anims[editor.curAnim].anim, true);
						editor.updateTextColors();
					}
					editor.reloadAnimList();
					trace('Removed animation: ' + animationInputText.text);
					break;
				}
		});
		editor.reloadAnimList();
		animationDropDown.selectedLabel = editor.anims[0] != null ? editor.anims[0].anim : '';

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 100, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 100, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 100, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 150, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 170, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	function addCharacterUI()
	{
		var tab_group = UI_CharacterBox.getTab('Character').menu;

		imageInputText = new UIInputText(15, 30, 200, editor.character.imageFile, 8);
		var reloadImage:UIButton = new UIButton(imageInputText.x + 210, imageInputText.y - 3, "Reload Image", function(){
			var lastAnim = editor.character.getAnimationName();
			editor.character.imageFile = imageInputText.text;
			editor.reloadCharacterImage();
			if(!editor.character.isAnimationNull()) {
				editor.character.playAnim(lastAnim, true);
			}
		});

		var decideIconColor:UIButton = new UIButton(reloadImage.x, reloadImage.y + 30, "Get Icon Color", function(){
			var coolColor:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(editor.healthIcon));
			editor.character.healthColorArray[0] = coolColor.red;
			editor.character.healthColorArray[1] = coolColor.green;
			editor.character.healthColorArray[2] = coolColor.blue;
			editor.updateHealthBar();
		});

		healthIconInputText = new UIInputText(15, imageInputText.y + 35, 75, editor.healthIcon.getCharacter(), 8);

		vocalsInputText = new UIInputText(15, healthIconInputText.y + 35, 75, editor.character.vocalsFile != null ? editor.character.vocalsFile : '', 8);

		singDurationStepper = new UINumericStepper(15, vocalsInputText.y + 45, 0.1, 4, 0, 999, 1);

		scaleStepper = new UINumericStepper(15, singDurationStepper.y + 40, 0.1, 1, 0.05, 10, 2);

		flipXCheckBox = new UICheckBox(singDurationStepper.x + 80, singDurationStepper.y, "Flip X", 50);
		flipXCheckBox.checked = editor.character.flipX;
		if(editor.character.isPlayer) flipXCheckBox.checked = !flipXCheckBox.checked;
		flipXCheckBox.onClick = function() {
			editor.character.originalFlipX = !editor.character.originalFlipX;
			editor.character.flipX = (editor.character.originalFlipX != editor.character.isPlayer);
		};

		noAntialiasingCheckBox = new UICheckBox(flipXCheckBox.x, flipXCheckBox.y + 40, "No Antialiasing", 80);
		noAntialiasingCheckBox.checked = editor.character.noAntialiasing;
		noAntialiasingCheckBox.onClick = function() {
			editor.character.antialiasing = false;
			if(!noAntialiasingCheckBox.checked && ClientPrefs.data.antialiasing) {
				editor.character.antialiasing = true;
			}
			editor.character.noAntialiasing = noAntialiasingCheckBox.checked;
		};

		positionXStepper = new UINumericStepper(flipXCheckBox.x + 110, flipXCheckBox.y, 10, editor.character.positionArray[0], -9000, 9000, 0);
		positionYStepper = new UINumericStepper(positionXStepper.x + 70, positionXStepper.y, 10, editor.character.positionArray[1], -9000, 9000, 0);

		positionCameraXStepper = new UINumericStepper(positionXStepper.x, positionXStepper.y + 40, 10, editor.character.cameraPosition[0], -9000, 9000, 0);
		positionCameraYStepper = new UINumericStepper(positionYStepper.x, positionYStepper.y + 40, 10, editor.character.cameraPosition[1], -9000, 9000, 0);

		var saveCharacterButton:UIButton = new UIButton(reloadImage.x, noAntialiasingCheckBox.y + 40, "Save Character", function() {
			editor.saveCharacter();
		});

		healthColorHSV = new UIHSVPicker(singDurationStepper.x, saveCharacterButton.y - 5);
		healthColorHSV.onChange = function() {
			editor.character.healthColorArray = healthColorHSV.value;
			editor.updateHealthBar();
			editor.unsavedProgress = true;
		}

		tab_group.add(new FlxText(15, imageInputText.y - 18, 100, 'Image file name:'));
		tab_group.add(new FlxText(15, healthIconInputText.y - 18, 100, 'Health icon name:'));
		tab_group.add(new FlxText(15, vocalsInputText.y - 18, 100, 'Vocals File Postfix:'));
		tab_group.add(new FlxText(15, singDurationStepper.y - 18, 120, 'Sing Animation length:'));
		tab_group.add(new FlxText(15, scaleStepper.y - 18, 100, 'Scale:'));
		tab_group.add(new FlxText(positionXStepper.x, positionXStepper.y - 18, 100, 'Character X/Y:'));
		tab_group.add(new FlxText(positionCameraXStepper.x, positionCameraXStepper.y - 18, 100, 'Camera X/Y:'));
		tab_group.add(imageInputText);
		tab_group.add(reloadImage);
		tab_group.add(decideIconColor);
		tab_group.add(healthIconInputText);
		tab_group.add(vocalsInputText);
		tab_group.add(singDurationStepper);
		tab_group.add(scaleStepper);
		tab_group.add(flipXCheckBox);
		tab_group.add(noAntialiasingCheckBox);
		tab_group.add(positionXStepper);
		tab_group.add(positionYStepper);
		tab_group.add(positionCameraXStepper);
		tab_group.add(positionCameraYStepper);
		tab_group.add(healthColorHSV);
		tab_group.add(saveCharacterButton);
	}

	function reloadCharacterDropDown() {
		characterList = Mods.mergeAllTextsNamed('data/characterList.txt', Paths.getSharedPath());
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json') || file.toLowerCase().endsWith('.xml'))
				{
					var charToCheck:String = file.substr(0, file.length - (file.toLowerCase().endsWith('.json') ? 5 : 4));
					if(!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if(characterList.length < 1) characterList.push('');
		charDropDown.list = characterList;
		charDropDown.selectedLabel = editor._char;
	}

	public function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in editor.anims) animList.push(anim.anim);
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

	function reloadCharacterOptions() {
		if(UI_CharacterBox == null) return;

		check_player.checked = editor.character.isPlayer;
		imageInputText.text = editor.character.imageFile;
		healthIconInputText.text = editor.character.healthIcon;
		vocalsInputText.text = editor.character.vocalsFile != null ? editor.character.vocalsFile : '';
		singDurationStepper.value = editor.character.singDuration;
		scaleStepper.value = editor.character.jsonScale;
		flipXCheckBox.checked = editor.character.originalFlipX;
		noAntialiasingCheckBox.checked = editor.character.noAntialiasing;
		positionXStepper.value = editor.character.positionArray[0];
		positionYStepper.value = editor.character.positionArray[1];
		positionCameraXStepper.value = editor.character.cameraPosition[0];
		positionCameraYStepper.value = editor.character.cameraPosition[1];
		reloadAnimationDropDown();
		editor.updateHealthBar();
	}

	public function UIEvent(id:String, sender:Dynamic) {
		if(id == UICheckBox.CLICK_EVENT)
			editor.unsavedProgress = true;

		if(id == UIInputText.CHANGE_EVENT)
		{
			if(sender == healthIconInputText) {
				var lastIcon = editor.healthIcon.getCharacter();
				editor.healthIcon.changeIcon(healthIconInputText.text, false);
				editor.character.healthIcon = healthIconInputText.text;
				if(lastIcon != editor.healthIcon.getCharacter()) editor.updatePresence();
				editor.unsavedProgress = true;
			}
			else if(sender == vocalsInputText)
			{
				editor.character.vocalsFile = vocalsInputText.text;
				editor.unsavedProgress = true;
			}
			else if(sender == imageInputText)
			{
				editor.character.imageFile = imageInputText.text;
				editor.unsavedProgress = true;
			}
		}
		else if(id == UINumericStepper.CHANGE_EVENT)
		{
			if (sender == scaleStepper)
			{
				editor.reloadCharacterImage();
				editor.character.jsonScale = sender.value;
				editor.character.scale.set(editor.character.jsonScale, editor.character.jsonScale);
				editor.character.updateHitbox();
				editor.updatePointerPos(false);
				editor.unsavedProgress = true;
			}
			else if(sender == positionXStepper)
			{
				editor.character.positionArray[0] = positionXStepper.value;
				editor.updateCharacterPositions();
				editor.unsavedProgress = true;
			}
			else if(sender == positionYStepper)
			{
				editor.character.positionArray[1] = positionYStepper.value;
				editor.updateCharacterPositions();
				editor.unsavedProgress = true;
			}
			else if(sender == singDurationStepper)
			{
				editor.character.singDuration = singDurationStepper.value;
				editor.unsavedProgress = true;
			}
			else if(sender == positionCameraXStepper)
			{
				editor.character.cameraPosition[0] = positionCameraXStepper.value;
				editor.updatePointerPos();
				editor.unsavedProgress = true;
			}
			else if(sender == positionCameraYStepper)
			{
				editor.character.cameraPosition[1] = positionCameraYStepper.value;
				editor.updatePointerPos();
				editor.unsavedProgress = true;
			}
		}
	}
}
