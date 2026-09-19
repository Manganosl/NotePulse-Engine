package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import flixel.math.FlxRect;
import funkin.objects.Character;
import funkin.scripting.LuaUtils;

import flixel.addons.transition.FlxTransitionableState;

import funkin.data.StageData;

import flixel.util.FlxDestroyUtil;

import funkin.scripting.objects.ModchartSprite;

import flash.net.FileFilter;

import funkin.states.editors.StageEditorState;
import funkin.states.editors.StageEditorState.StageEditorMetaSprite;
import funkin.states.editors.content.PreloadListSubState;

@:access(funkin.states.editors.StageEditorState)
class StageEditorUI extends FlxSpriteContainer implements UIEventHandler.UIEvent
{
	private var editor:StageEditorState;

	public var UI_stagebox:UIBox;
	public var UI_box:UIBox;
	public var spriteList_box:UIBox;

	public var spriteListRadioGroup:UIRadioGroup;
	public var focusRadioGroup:UIRadioGroup;

	var directoryDropDown:UIDropDownMenu;
	var uiInputText:UIInputText;
	var hideGirlfriendCheckbox:UICheckBox;
	var zoomStepper:UINumericStepper;
	var cameraSpeedStepper:UINumericStepper;
	var camDadStepperX:UINumericStepper;
	var camDadStepperY:UINumericStepper;
	var camGfStepperX:UINumericStepper;
	var camGfStepperY:UINumericStepper;
	var camBfStepperX:UINumericStepper;
	var camBfStepperY:UINumericStepper;

	var colorInputText:UIInputText;
	var nameInputText:UIInputText;
	var imgTxt:FlxText;

	var scaleStepperX:UINumericStepper;
	var scaleStepperY:UINumericStepper;
	var scrollStepperX:UINumericStepper;
	var scrollStepperY:UINumericStepper;
	var angleStepper:UINumericStepper;
	var alphaStepper:UINumericStepper;

	var antialiasingCheckbox:UICheckBox;
	var flipXCheckBox:UICheckBox;
	var flipYCheckBox:UICheckBox;
	var lowQualityCheckbox:UICheckBox;
	var highQualityCheckbox:UICheckBox;

	var oppDropdown:UIDropDownMenu;
	var gfDropdown:UIDropDownMenu;
	var plDropdown:UIDropDownMenu;
	var stageDropDown:UIDropDownMenu;

	public var outputTxt:FlxText;
	public var outputTime:Float = 0;

	public var posTxt:FlxText;

	public var createPopup:FlxSpriteGroup;

	public var curFilters:LoadFilters = (LOW_QUALITY)|(HIGH_QUALITY);

	public function new(editor:StageEditorState)
	{
		super();

		this.editor = editor;
	}

	public function createUI()
	{
		screenUI();
		spriteCreatePopup();
		editorUI();
	}

	function screenUI()
	{
		var lowQualityCheckbox:UICheckBox = null;
		var highQualityCheckbox:UICheckBox = null;
		function visibilityFilterUpdate()
		{
			curFilters = 0;
			if(lowQualityCheckbox.checked) curFilters |= LOW_QUALITY;
			if(highQualityCheckbox.checked) curFilters |= HIGH_QUALITY;
		}

		spriteList_box = new UIBox(25, 40, 250, 200, ['Sprite List']);
		spriteList_box.scrollFactor.set();
		spriteList_box.cameras = [editor.camHUD];
		add(spriteList_box);
		addSpriteListBox();

		var bg:FlxSprite = new FlxSprite(0, FlxG.height - 60).makeGraphic(1, 1, FlxColor.BLACK);
		bg.cameras = [editor.camHUD];
		bg.alpha = 0.4;
		bg.scale.set(FlxG.width, FlxG.height - bg.y);
		bg.updateHitbox();
		add(bg);
		
		var tipText:FlxText = new FlxText(0, FlxG.height - 44, 300, 'Press F1 for Help', 20);
		tipText.alignment = CENTER;
		tipText.cameras = [editor.camHUD];
		tipText.scrollFactor.set();
		tipText.screenCenter(X);
		tipText.active = false;
		add(tipText);

		var targetTxt:FlxText = new FlxText(30, FlxG.height - 52, 300, 'Camera Target', 16);
		targetTxt.alignment = CENTER;
		targetTxt.cameras = [editor.camHUD];
		targetTxt.scrollFactor.set();
		targetTxt.active = false;
		add(targetTxt);

		focusRadioGroup = new UIRadioGroup(targetTxt.x, FlxG.height - 24, ['dad', 'boyfriend', 'gf'], 10, 0, true);
		focusRadioGroup.onClick = function() {
			//trace('Changed focus to $target');
			var point = editor.focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
			editor.camFollow.setPosition(point.x, point.y);
			FlxG.camera.target = editor.camFollow;
		}
		focusRadioGroup.radios[0].label = 'Opponent';
		focusRadioGroup.radios[1].label = 'Boyfriend';
		focusRadioGroup.radios[2].label = 'Girlfriend';

		for (radio in focusRadioGroup.radios)
			radio.text.size = 11;
		
		focusRadioGroup.cameras = [editor.camHUD];
		add(focusRadioGroup);

		lowQualityCheckbox = new UICheckBox(FlxG.width - 240, FlxG.height - 36, 'Can see Low Quality Sprites?', 90);
		lowQualityCheckbox.cameras = [editor.camHUD];
		lowQualityCheckbox.onClick = visibilityFilterUpdate;
		lowQualityCheckbox.checked = false;
		add(lowQualityCheckbox);

		highQualityCheckbox = new UICheckBox(FlxG.width - 120, FlxG.height - 36, 'Can see High Quality Sprites?', 90);
		highQualityCheckbox.cameras = [editor.camHUD];
		highQualityCheckbox.onClick = visibilityFilterUpdate;
		highQualityCheckbox.checked = true;
		add(highQualityCheckbox);
		visibilityFilterUpdate();

		posTxt = new FlxText(0, 50, 500, 'X: 0\nY: 0', 24);
		posTxt.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		posTxt.borderSize = 2;
		posTxt.cameras = [editor.camHUD];
		posTxt.screenCenter(X);
		posTxt.visible = false;
		add(posTxt);

		outputTxt = new FlxText(0, 0, 800, '', 24);
		outputTxt.alignment = CENTER;
		outputTxt.borderStyle = OUTLINE_FAST;
		outputTxt.borderSize = 1;
		outputTxt.cameras = [editor.camHUD];
		outputTxt.screenCenter();
		outputTxt.alpha = 0;
		add(outputTxt);
	}

	function addSpriteListBox()
	{
		var tab_group = spriteList_box.getTab('Sprite List').menu;
		spriteListRadioGroup = new UIRadioGroup(10, 10, [], 25, 18, false, 200);
		spriteListRadioGroup.cameras = [editor.camHUD];
		spriteListRadioGroup.onClick = function() {
			Log.info('Selected sprite: ${spriteListRadioGroup.checkedRadio.label}');
			updateSelectedUI();
		}
		tab_group.add(spriteListRadioGroup);
		
		var buttonX = spriteList_box.x + spriteList_box.width - 10;
		var buttonY = spriteListRadioGroup.y - 30;
		var buttonMoveUp:UIButton = new UIButton(buttonX, buttonY, 'Move Up', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = editor.stageSprites[selected];
			if(spr == null) return;

			var newSel:Int = Std.int(Math.min(editor.stageSprites.length-1, selected + 1));
			editor.stageSprites.remove(spr);
			editor.stageSprites.insert(newSel, spr);

			updateSpriteListRadio();
		});
		buttonMoveUp.cameras = [editor.camHUD];
		tab_group.add(buttonMoveUp);

		var buttonMoveDown:UIButton = new UIButton(buttonX, buttonY + 30, 'Move Down', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = editor.stageSprites[selected];
			if(spr == null) return;

			var newSel:Int = Std.int(Math.max(0, selected - 1));
			editor.stageSprites.remove(spr);
			editor.stageSprites.insert(newSel, spr);

			updateSpriteListRadio();
		});
		buttonMoveDown.cameras = [editor.camHUD];
		tab_group.add(buttonMoveDown);
		
		var buttonCreate:UIButton = new UIButton(buttonX, buttonY + 60, 'New', function() createPopup.visible = createPopup.active = true);
		buttonCreate.cameras = [editor.camHUD];
		buttonCreate.normalStyle.bgColor = FlxColor.GREEN;
		buttonCreate.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonCreate);

		var buttonDuplicate:UIButton = new UIButton(buttonX, buttonY + 90, 'Duplicate', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = editor.stageSprites[selected];
			if(spr == null || StageData.reservedNames.contains(spr.type)) return;

			var copiedSpr = new ModchartSprite();
			var copiedMeta:StageEditorMetaSprite = new StageEditorMetaSprite(null, copiedSpr);
			for (field in Reflect.fields(spr))
			{
				if(field == 'sprite') continue; //do NOT copy sprite or it might get messy

				try
				{
					var fld:Dynamic = Reflect.getProperty(spr, field);
					if(fld is Array)
					{
						var arr:Array<Dynamic> = fld;
						arr = arr.copy();
						if(arr != null)
						{
							for (k => v in arr)
							{
								var indices:Array<Int> = v.indices;
								if(indices != null) indices = indices.copy();
	
								var offs:Array<Int> = v.offsets;
								if(offs != null) offs = offs.copy();

								fld[k] = {
									anim: v.anim,
									name: v.name,
									fps: v.fps,
									loop: v.loop,
									indices: indices,
									offsets: offs
								}
							}
						}
						fld = arr;
					}

					Reflect.setProperty(copiedMeta, field, fld);
					//trace('success? $field');
				}
				catch(e:Dynamic)
				{
					//trace('failed: $field');
				}
			}

			if(copiedMeta.animations != null)
			{
				for (num => anim in copiedMeta.animations)
				{
					if(anim == null || anim.anim == null) continue;
	
					if(anim.indices != null && anim.indices.length > 0)
						copiedSpr.animation.addByIndices(anim.anim, anim.name, anim.indices, '', anim.fps, anim.loop);
					else
						copiedSpr.animation.addByPrefix(anim.anim, anim.name, anim.fps, anim.loop);
	
					if(anim.offsets != null && anim.offsets.length > 1)
						copiedSpr.addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
	
					if(copiedSpr.animation.curAnim == null || copiedMeta.firstAnimation == anim.anim)
						copiedSpr.playAnim(anim.anim, true);
				}
			}
			copiedMeta.setScale(copiedMeta.scale[0], copiedMeta.scale[1]);
			copiedMeta.setScrollFactor(copiedMeta.scroll[0], copiedMeta.scroll[1]);
			copiedMeta.name = findUnoccupiedName('${copiedMeta.name}_copy');
			insertMeta(copiedMeta, 1);
		});
		buttonDuplicate.cameras = [editor.camHUD];
		buttonDuplicate.normalStyle.bgColor = FlxColor.BLUE;
		buttonDuplicate.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonDuplicate);
	
		var buttonDelete:UIButton = new UIButton(buttonX, buttonY + 120, 'Delete', function()
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected < 0) return;

			var selected:Int = spriteListRadioGroup.labels.length - selected - 1;
			var spr = editor.stageSprites[selected];
			if(spr == null || StageData.reservedNames.contains(spr.type)) return;

			editor.stageSprites.remove(spr);
			spr.sprite = FlxDestroyUtil.destroy(spr.sprite);

			updateSpriteListRadio();
		});
		buttonDelete.cameras = [editor.camHUD];
		buttonDelete.normalStyle.bgColor = FlxColor.RED;
		buttonDelete.normalStyle.textColor = FlxColor.WHITE;
		tab_group.add(buttonDelete);
	}

	public function showOutput(txt:String, isError:Bool = false)
	{
		outputTxt.color = isError ? FlxColor.RED : FlxColor.WHITE;
		outputTxt.text = txt;
		outputTime = 3;
		
		if(isError) FlxG.sound.play(Paths.sound('cancelMenu'), 0.4);
		else FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	public function findUnoccupiedName(prefix = 'sprite')
	{
		var num:Int = 1;
		var name:String = 'unnamed';
		while(true)
		{
			var cantUseName:Bool = false;
			
			name = prefix + num;
			for (basic in editor.stageSprites)
			{
				if(basic.name == name)
				{
					cantUseName = true;
					break;
				}
			}
			
			if(cantUseName)
			{
				num++;
				continue;
			}
			break;
		}
		return name;
	}

	public function insertMeta(meta, insertOffset:Int = 0)
	{
		var num:Int = Std.int(Math.max(0, Math.min(spriteListRadioGroup.labels.length, spriteListRadioGroup.labels.length - spriteListRadioGroup.checked - 1 + insertOffset)));
		editor.stageSprites.insert(num, meta);
		updateSpriteListRadio();
		createPopup.visible = createPopup.active = false;
		spriteListRadioGroup.checked = spriteListRadioGroup.labels.length - num - 1;
		updateSelectedUI();
		editor.unsavedProgress = true;
	}

	function spriteCreatePopup()
	{
		createPopup = new FlxSpriteGroup();
		createPopup.cameras = [editor.camHUD];
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scale.set(300, 240);
		bg.updateHitbox();
		bg.screenCenter();
		createPopup.add(bg);

		var txt:FlxText = new FlxText(0, bg.y + 10, 180, 'New Sprite', 24);
		txt.screenCenter(X);
		txt.alignment = CENTER;
		createPopup.add(txt);

		var btnY = 320;
		var btn:UIButton = new UIButton(0, btnY, 'No Animation', function() editor.loadImage('sprite'));
		btn.screenCenter(X);
		createPopup.add(btn);

		btnY += 50;
		var btn:UIButton = new UIButton(0, btnY, 'Animated', function() editor.loadImage('animatedSprite'));
		btn.screenCenter(X);
		createPopup.add(btn);

		btnY += 50;
		var btn:UIButton = new UIButton(0, btnY, 'Solid Color', function() {
			var meta:StageEditorMetaSprite = new StageEditorMetaSprite({type: 'square', scale: [200, 200], name: findUnoccupiedName()}, new ModchartSprite());
			meta.setScale(200, 200);
			meta.sprite.screenCenter();
			insertMeta(meta);
		});
		btn.screenCenter(X);
		createPopup.add(btn);
		add(createPopup);
		createPopup.visible = createPopup.active = false;
	}
	
	public function updateSpriteListRadio()
	{
		var _sel:String = (spriteListRadioGroup.checkedRadio != null ? spriteListRadioGroup.checkedRadio.label : null);
		var nameList:Array<String> = [];
		for (spr in editor.stageSprites)
		{
			if(spr == null) continue;

			switch(spr.type)
			{
				case 'gf':
					nameList.push('- Girlfriend -');
				case 'boyfriend':
					nameList.push('- Boyfriend -');
				case 'dad':
					nameList.push('- Opponent -');
				default:
					nameList.push(spr.name);
			}
		}
		nameList.reverse();
		
		spriteListRadioGroup.labels = nameList;
		for (radio in spriteListRadioGroup.radios)
		{
			if(radio.label == _sel)
			{
				spriteListRadioGroup.checkedRadio = radio;
				break;
			}
		}

		final maxNum:Int = 19;
		spriteList_box.resize(250, Std.int(Math.min(maxNum, spriteListRadioGroup.labels.length) * 25 + 35));
	}

	function editorUI()
	{
		UI_box = new UIBox(FlxG.width - 225, 10, 200, 400, ['Meta', 'Data', 'Object']);
		UI_box.cameras = [editor.camHUD];
		UI_box.scrollFactor.set();
		add(UI_box);
		UI_box.selectedName = 'Data';

		UI_stagebox = new UIBox(FlxG.width - 275, 25, 250, 100, ['Stage']);
		UI_stagebox.cameras = [editor.camHUD];
		UI_stagebox.scrollFactor.set();
		add(UI_stagebox);
		UI_box.y += UI_stagebox.y + UI_stagebox.height;

		addDataTab();
		addObjectTab();
		addMetaTab();
		addStageTab();
	}

	function addDataTab()
	{
		var tab_group = UI_box.getTab('Data').menu;

		var objX = 10;
		var objY = 20;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Compiled Assets:'));

		var folderList:Array<String> = [''];
		#if sys
		for (folder in FileSystem.readDirectory('assets/'))
			if(FileSystem.isDirectory('assets/$folder') && folder != 'shared' && !Mods.ignoreModFolders.contains(folder))
				folderList.push(folder);
		#end

		var saveButton:UIButton = new UIButton(UI_box.width - 90, UI_box.height - 50, 'Save', function() {
			editor.saveData();
		});
		tab_group.add(saveButton);

		directoryDropDown = new UIDropDownMenu(objX, objY, folderList, function(sel:Int, selected:String) {
			editor.stageJson.directory = selected;
			editor.saveObjectsToJson();
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new StageEditorState(editor.lastLoadedStage, editor.stageJson));
		});
		directoryDropDown.selectedLabel = editor.stageJson.directory;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'UI Style:'));
		uiInputText = new UIInputText(objX, objY, 100, editor.stageJson.stageUI != null ? editor.stageJson.stageUI : '', 8);
		uiInputText.onChange = function(old:String, cur:String) editor.stageJson.stageUI = uiInputText.text;

		objY += 30;
		hideGirlfriendCheckbox = new UICheckBox(objX, objY, 'Hide Girlfriend?', 100);
		hideGirlfriendCheckbox.onClick = function()
		{
			editor.stageJson.hide_girlfriend = hideGirlfriendCheckbox.checked;
			editor.gf.visible = !hideGirlfriendCheckbox.checked;
			if(focusRadioGroup.checked > -1)
			{
				var point = editor.focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
				editor.camFollow.setPosition(point.x, point.y);
			}
		};
		hideGirlfriendCheckbox.checked = !editor.gf.visible;

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Offsets:'));

		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Opponent:'));

		var cx:Float = 0;
		var cy:Float = 0;
		if(editor.stageJson.camera_opponent != null && editor.stageJson.camera_opponent.length > 1)
		{
			cx = editor.stageJson.camera_opponent[0];
			cy = editor.stageJson.camera_opponent[1];
		}
		camDadStepperX = new UINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camDadStepperY = new UINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camDadStepperX.onValueChange = camDadStepperY.onValueChange = function() {
			if(editor.stageJson.camera_opponent == null) editor.stageJson.camera_opponent = [0, 0];
			editor.stageJson.camera_opponent[0] = camDadStepperX.value;
			editor.stageJson.camera_opponent[1] = camDadStepperY.value;
			_updateCamera();
		};

		objY += 40;
		var cx:Float = 0;
		var cy:Float = 0;
		if(editor.stageJson.camera_girlfriend != null && editor.stageJson.camera_girlfriend.length > 1)
		{
			cx = editor.stageJson.camera_girlfriend[0];
			cy = editor.stageJson.camera_girlfriend[1];
		}
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Girlfriend:'));
		camGfStepperX = new UINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camGfStepperY = new UINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camGfStepperX.onValueChange = camGfStepperY.onValueChange = function() {
			if(editor.stageJson.camera_girlfriend == null) editor.stageJson.camera_girlfriend = [0, 0];
			editor.stageJson.camera_girlfriend[0] = camGfStepperX.value;
			editor.stageJson.camera_girlfriend[1] = camGfStepperY.value;
			_updateCamera();
		};

		objY += 40;
		var cx:Float = 0;
		var cy:Float = 0;
		if(editor.stageJson.camera_boyfriend != null && editor.stageJson.camera_boyfriend.length > 1)
		{
			cx = editor.stageJson.camera_boyfriend[0];
			cy = editor.stageJson.camera_boyfriend[1];
		}
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Boyfriend:'));
		camBfStepperX = new UINumericStepper(objX, objY, 50, cx, -10000, 10000, 0);
		camBfStepperY = new UINumericStepper(objX + 80, objY, 50, cy, -10000, 10000, 0);
		camBfStepperX.onValueChange = camBfStepperY.onValueChange = function() {
			if(editor.stageJson.camera_boyfriend == null) editor.stageJson.camera_boyfriend = [0, 0];
			editor.stageJson.camera_boyfriend[0] = camBfStepperX.value;
			editor.stageJson.camera_boyfriend[1] = camBfStepperY.value;
			_updateCamera();
		};

		objY += 50;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Camera Data:'));
		objY += 20;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Zoom:'));
		zoomStepper = new UINumericStepper(objX, objY, 0.05, editor.stageJson.defaultZoom, editor.minZoom, editor.maxZoom, 2);
		zoomStepper.onValueChange = function() {
			editor.stageJson.defaultZoom = zoomStepper.value;
			FlxG.camera.zoom = editor.stageJson.defaultZoom;
		};

		tab_group.add(new FlxText(objX + 80, objY - 18, 100, 'Speed:'));
		cameraSpeedStepper = new UINumericStepper(objX + 80, objY, 0.1, editor.stageJson.camera_speed != null ? editor.stageJson.camera_speed : 1, 0, 10, 2);
		cameraSpeedStepper.onValueChange = function() {
			editor.stageJson.camera_speed = cameraSpeedStepper.value;
			FlxG.camera.followLerp = 0.04 * editor.stageJson.camera_speed;
		};
		FlxG.camera.followLerp = 0.04 * cameraSpeedStepper.value;

		tab_group.add(hideGirlfriendCheckbox);
		tab_group.add(camDadStepperX);
		tab_group.add(camDadStepperY);
		tab_group.add(camGfStepperX);
		tab_group.add(camGfStepperY);
		tab_group.add(camBfStepperX);
		tab_group.add(camBfStepperY);
		tab_group.add(zoomStepper);
		tab_group.add(cameraSpeedStepper);
		
		tab_group.add(uiInputText);
		tab_group.add(directoryDropDown);
	}
	
	public function _updateCamera()
	{
		if(focusRadioGroup.checked > -1)
		{
			var point = editor.focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
			editor.camFollow.setPosition(point.x, point.y);
		}
	}

	public function getSelected(blockReserved:Bool = true)
	{
		var selected:Int = spriteListRadioGroup.checked;
		if(selected >= 0)
		{
			var spr = editor.stageSprites[spriteListRadioGroup.labels.length - selected - 1];
			if(spr != null && (!blockReserved || !StageData.reservedNames.contains(spr.type)))
				return spr;
		}
		return null;
	}

	function addObjectTab()
	{
		var tab_group = UI_box.getTab('Object').menu;

		var objX = 10;
		var objY = 30;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Name (for Lua/HScript):'));
		nameInputText = new UIInputText(objX, objY, 120, '', 8);
		nameInputText.customFilterPattern = ~/[^a-zA-Z0-9_\-]*/g;
		nameInputText.onChange = function(old:String, cur:String) {
			// change name
			var selected = getSelected();
			if(selected != null)
			{
				var changedName:String = nameInputText.text;
				if(changedName.length < 1)
				{
					showOutput('Sprite name cannot be empty!', true);
					return;
				}
				
				if(StageData.reservedNames.contains(changedName))
				{
					showOutput('To avoid conflicts, this name cannot be used!', true);
					return;
				}

				for (basic in editor.stageSprites)
				{
					if (selected != basic && basic.name == changedName)
					{
						showOutput('Name "$changedName" is already in use!', true);
						return;
					}
				}

				selected.name = changedName;
				spriteListRadioGroup.checkedRadio.label = selected.name;
				outputTime = 0;
				outputTxt.alpha = 0;
			}
		};
		tab_group.add(nameInputText);

		objY += 35;
		imgTxt = new FlxText(objX, objY - 15, 200, 'Image: ', 8);
		var imgButton:UIButton = new UIButton(objX, objY, 'Change Image', function() {
			Log.info('attempt to load image');
			editor.loadImage();
		});
		tab_group.add(imgButton);
		tab_group.add(imgTxt);
		
		var animationsButton:UIButton = new UIButton(objX + 90, objY, 'Animations', function() {
			var selected = getSelected();
			if(selected == null)
				return;

			if(selected.type != 'animatedSprite')
			{
				showOutput('Only Animated Sprites can hold Animation data.', true);
				return;
			}

			editor.destroySubStates = false;
			editor.persistentDraw = false;
			editor.animationEditor.target = selected;
			editor.unsavedProgress = true;
			editor.openSubState(editor.animationEditor);
		});
		tab_group.add(animationsButton);
		
		objY += 45;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Color:'));
		colorInputText = new UIInputText(objX, objY, 80, 'FFFFFF', 8);
		colorInputText.filterMode = ONLY_ALPHANUMERIC;
		colorInputText.onChange = function(old:String, cur:String) {
			// change color
			var selected = getSelected();
			if(selected != null)
				selected.color = colorInputText.text;
		};
		tab_group.add(colorInputText);

		function updateScale()
		{
			// scale
			var selected = getSelected();
			if(selected != null)
				selected.setScale(scaleStepperX.value, scaleStepperY.value);
		}
		
		objY += 45;
		tab_group.add(new FlxText(objX, objY - 18, 100, 'Scale (X/Y):'));
		scaleStepperX = new UINumericStepper(objX, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperY = new UINumericStepper(objX + 70, objY, 0.05, 1, 0.05, 10, 2);
		scaleStepperX.onValueChange = scaleStepperY.onValueChange = updateScale;
		tab_group.add(scaleStepperX);
		tab_group.add(scaleStepperY);

		function updateScroll()
		{
			// scroll factor
			var selected = getSelected();
			if(selected != null)
				selected.setScrollFactor(scrollStepperX.value, scrollStepperY.value);
		}

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 150, 'Scroll Factor (X/Y):'));
		scrollStepperX = new UINumericStepper(objX, objY, 0.05, 1, 0, 10, 2);
		scrollStepperY = new UINumericStepper(objX + 70, objY, 0.05, 1, 0, 10, 2);
		scrollStepperX.onValueChange = scrollStepperY.onValueChange = updateScroll;
		tab_group.add(scrollStepperX);
		tab_group.add(scrollStepperY);
		
		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Opacity:'));
		alphaStepper = new UINumericStepper(objX, objY, 0.1, 1, 0, 1, 2, true);
		alphaStepper.onValueChange = function() {
			// alpha/opacity
			var selected = getSelected();
			if(selected != null)
				selected.alpha = alphaStepper.value;
		};
		tab_group.add(alphaStepper);

		antialiasingCheckbox = new UICheckBox(objX + 90, objY, 'Anti-Aliasing', 80);
		antialiasingCheckbox.onClick = function()
		{
			// antialiasing
			var selected = getSelected();
			if(selected != null)
			{
				if(selected.type != 'square')
					selected.antialiasing = antialiasingCheckbox.checked;
				else
				{
					antialiasingCheckbox.checked = false;
					selected.antialiasing = false;
				}
			}
		};
		tab_group.add(antialiasingCheckbox);

		objY += 40;
		tab_group.add(new FlxText(objX, objY - 18, 80, 'Angle:'));
		angleStepper = new UINumericStepper(objX, objY, 10, 0, 0, 360, 0);
		angleStepper.onValueChange = function() {
			// alpha/opacity
			var selected = getSelected();
			if(selected != null)
				selected.angle = angleStepper.value;
		};
		tab_group.add(angleStepper);

		function updateFlip()
		{
			//flip X and flip Y
			var selected = getSelected();
			if(selected != null)
			{
				if(selected.type != 'square')
				{
					selected.flipX = flipXCheckBox.checked;
					selected.flipY = flipYCheckBox.checked;
				}
				else
				{
					flipXCheckBox.checked = flipYCheckBox.checked = false;
					selected.flipX = selected.flipY = false;
				}
			}
		}

		objY += 25;
		flipXCheckBox = new UICheckBox(objX, objY, 'Flip X', 60);
		flipXCheckBox.onClick = updateFlip;
		flipYCheckBox = new UICheckBox(objX + 90, objY, 'Flip Y', 60);
		flipYCheckBox.onClick = updateFlip;
		tab_group.add(flipXCheckBox);
		tab_group.add(flipYCheckBox);

		objY += 45;
		function recalcFilter()
		{
			// low and/or high quality
			var selected = getSelected();
			if(selected != null)
			{
				var filt = 0;
				if(lowQualityCheckbox.checked) filt |= LOW_QUALITY;
				if(highQualityCheckbox.checked) filt |= HIGH_QUALITY;
				selected.filters = filt;
			}
		};
		tab_group.add(new FlxText(objX + 60, objY - 18, 100, 'Visible in:'));
		lowQualityCheckbox = new UICheckBox(objX, objY, 'Low Quality', 70);
		highQualityCheckbox = new UICheckBox(objX + 90, objY, 'High Quality', 70);
		lowQualityCheckbox.onClick = recalcFilter;
		highQualityCheckbox.onClick = recalcFilter;
		tab_group.add(lowQualityCheckbox);
		tab_group.add(highQualityCheckbox);
	}

	function addMetaTab()
	{
		var tab_group = UI_box.getTab('Meta').menu;

		var characterList = Mods.mergeAllTextsNamed('data/characterList.txt');
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'characters/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var charToCheck:String = file.substr(0, file.length - 5);
					if(!characterList.contains(charToCheck))
						characterList.push(charToCheck);
				}

		if(characterList.length < 1) characterList.push(''); //Prevents crash
		
		var objX = 10;
		var objY = 20;

		var openPreloadButton:UIButton = new UIButton(objX, objY, 'Preload List', function() {
			var lockedList:Array<String> = [];
			var currentMap:Map<String, LoadFilters> = [];
			for (spr in editor.stageSprites)
			{
				if(spr == null || StageData.reservedNames.contains(spr.type)) continue;

				switch(spr.type)
				{
					case 'sprite', 'animatedSprite':
						if(spr.image != null && spr.image.length > 0 && !lockedList.contains(spr.image))
							lockedList.push(spr.image);
				}
			}

			if(editor.stageJson.preload != null)
			{
				for (field in Reflect.fields(editor.stageJson.preload))
				{
					if(!currentMap.exists(field) && !lockedList.contains(field))
						currentMap.set(field, Reflect.field(editor.stageJson.preload, field));
				}
			}

			editor.destroySubStates = true;
			editor.openSubState(new PreloadListSubState(function(newSave:Map<String, LoadFilters>)
			{
				var len:Int = 0;
				for (name in newSave.keys())
					len++;

				editor.stageJson.preload = {};
				for (key => value in newSave)
				{
					Reflect.setField(editor.stageJson.preload, key, value);
				}
				editor.unsavedProgress = true;
				showOutput('Saved new Preload List with $len files/folders!');
			}, lockedList, currentMap));
		});

		function setMetaData(data:String, char:String)
		{
			if(editor.stageJson._editorMeta == null) editor.stageJson._editorMeta = {dad: 'dad', gf: 'gf', boyfriend: 'bf'};
			Reflect.setField(editor.stageJson._editorMeta, data, char);
		}

		objY += 60;
		oppDropdown = new UIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if(selected == null || selected.length < 1) return;
			editor.dad.changeCharacter(selected);
			setMetaData('dad', selected);
			editor.repositionDad();
		});
		oppDropdown.selectedLabel = editor.dad.curCharacter;

		objY += 60;
		gfDropdown = new UIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if(selected == null || selected.length < 1) return;
			editor.gf.changeCharacter(selected);
			setMetaData('gf', selected);
			editor.repositionGirlfriend();
		});
		gfDropdown.selectedLabel = editor.gf.curCharacter;

		objY += 60;
		plDropdown = new UIDropDownMenu(objX, objY, characterList, function(sel:Int, selected:String)
		{
			if(selected == null || selected.length < 1) return;
			editor.boyfriend.changeCharacter(selected);
			setMetaData('boyfriend', selected);
			editor.repositionBoyfriend();
		});
		plDropdown.selectedLabel = editor.boyfriend.curCharacter;

		tab_group.add(openPreloadButton);
		tab_group.add(new FlxText(plDropdown.x, plDropdown.y - 18, 100, 'Player:'));
		tab_group.add(plDropdown);
		tab_group.add(new FlxText(gfDropdown.x, gfDropdown.y - 18, 100, 'Girlfriend:'));
		tab_group.add(gfDropdown);
		tab_group.add(new FlxText(oppDropdown.x, oppDropdown.y - 18, 100, 'Opponent:'));
		tab_group.add(oppDropdown);
	}

	function addStageTab()
	{
		var tab_group = UI_stagebox.getTab('Stage').menu;
		var reloadStage:UIButton = new UIButton(140, 10, 'Reload', function()
		{
			#if DISCORD_ALLOWED
			DiscordClient.changePresence('Stage Editor', 'Stage: ' + editor.lastLoadedStage);
			#end

			editor.stageJson = StageData.getStageFile(editor.lastLoadedStage);
			editor.updateSpriteList();
			updateStageDataUI();
			reloadCharacters();
			reloadStageDropDown();
		});

		var dummyStage:UIButton = new UIButton(140, 40, 'Load Template', function()
		{
			#if DISCORD_ALLOWED
			DiscordClient.changePresence('Stage Editor', 'New Stage');
			#end

			editor.stageJson = StageData.dummy();
			editor.updateSpriteList();
			updateStageDataUI();
			reloadCharacters();
		});
		dummyStage.normalStyle.bgColor = FlxColor.RED;
		dummyStage.normalStyle.textColor = FlxColor.WHITE;

		stageDropDown = new UIDropDownMenu(10, 30, [''], function(sel:Int, selected:String)
		{
			var characterPath:String = 'stages/$selected.json';
			var path:String = Paths.getPath(characterPath, TEXT, null, true);
			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				editor.stageJson = StageData.getStageFile(selected);
				editor.lastLoadedStage = selected;
				#if DISCORD_ALLOWED
				DiscordClient.changePresence('Stage Editor', 'Stage: ' + editor.lastLoadedStage);
				#end
				editor.updateSpriteList();
				updateStageDataUI();
				reloadCharacters();
				reloadStageDropDown();
			}
			else
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				reloadStageDropDown();
			}
		});
		reloadStageDropDown();

		tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 18, 60, 'Stage:'));
		tab_group.add(reloadStage);
		tab_group.add(dummyStage);
		tab_group.add(stageDropDown);
	}
	
	function updateStageDataUI()
	{
		//input texts
		uiInputText.text = (editor.stageJson.stageUI != null ? editor.stageJson.stageUI : '');
		//checkboxes
		hideGirlfriendCheckbox.checked = (editor.stageJson.hide_girlfriend);
		editor.gf.visible = !hideGirlfriendCheckbox.checked;
		//steppers
		zoomStepper.value = FlxG.camera.zoom = editor.stageJson.defaultZoom;
		
		if(editor.stageJson.camera_speed != null) cameraSpeedStepper.value = editor.stageJson.camera_speed;
		else cameraSpeedStepper.value = 1;
		FlxG.camera.followLerp = 0.04 * cameraSpeedStepper.value;

		if(editor.stageJson.camera_opponent != null && editor.stageJson.camera_opponent.length > 1)
		{
			camDadStepperX.value = editor.stageJson.camera_opponent[0];
			camDadStepperY.value = editor.stageJson.camera_opponent[1];
		}
		else camDadStepperX.value = camDadStepperY.value = 0;

		if(editor.stageJson.camera_girlfriend != null && editor.stageJson.camera_girlfriend.length > 1)
		{
			camGfStepperX.value = editor.stageJson.camera_girlfriend[0];
			camGfStepperY.value = editor.stageJson.camera_girlfriend[1];
		}
		else camGfStepperX.value = camGfStepperY.value = 0;

		if(editor.stageJson.camera_boyfriend != null && editor.stageJson.camera_boyfriend.length > 1)
		{
			camBfStepperX.value = editor.stageJson.camera_boyfriend[0];
			camBfStepperY.value = editor.stageJson.camera_boyfriend[1];
		}
		else camBfStepperX.value = camBfStepperY.value = 0;

		if(focusRadioGroup.checked > -1)
		{
			var point = editor.focusOnTarget(focusRadioGroup.labels[focusRadioGroup.checked]);
			editor.camFollow.setPosition(point.x, point.y);
		}
		editor.loadJsonAssetDirectory();
	}

	public function updateSelectedUI()
	{
		posTxt.visible = false;
		var selected = getSelected(false);
		if(selected == null) return;

		var displayX:Float = Math.round(selected.x);
		var displayY:Float = Math.round(selected.y);

		if(StageData.reservedNames.contains(selected.type))
		{
			var char:Character = cast selected.sprite;
			if(char != null)
			{
				displayX -= char.positionArray[0];
				displayY -= char.positionArray[1];
			}
		}

		posTxt.text = 'X: $displayX\nY: $displayY';
		posTxt.visible = true;

		var selected = getSelected();
		if(selected == null) return;

		// Texts/Input Texts
		colorInputText.text = selected.color;
		nameInputText.text = selected.name;
		imgTxt.text = 'Image: ' + selected.image;

		// Steppers
		if (selected.type != 'square')
		{
			scaleStepperX.decimals = scaleStepperY.decimals = 2;
			scaleStepperX.max = scaleStepperY.max = 10;
			scaleStepperX.min = scaleStepperY.min = 0.05;
			scaleStepperX.step = scaleStepperY.step = 0.05;
		}
		else
		{
			scaleStepperX.decimals = scaleStepperY.decimals = 0;
			scaleStepperX.max = scaleStepperY.max = 10000;
			scaleStepperX.min = scaleStepperY.min = 50;
			scaleStepperX.step = scaleStepperY.step = 50;
		}
		scaleStepperX.value = selected.scale[0];
		scaleStepperY.value = selected.scale[1];
		scrollStepperX.value = selected.scroll[0];
		scrollStepperY.value = selected.scroll[1];
		angleStepper.value = selected.angle;
		alphaStepper.value = selected.alpha;

		// Checkboxes
		antialiasingCheckbox.checked = selected.antialiasing;
		flipXCheckBox.checked = selected.flipX;
		flipYCheckBox.checked = selected.flipY;
		lowQualityCheckbox.checked = (selected.filters & LOW_QUALITY) == LOW_QUALITY;
		highQualityCheckbox.checked = (selected.filters & HIGH_QUALITY) == HIGH_QUALITY;
	}

	function reloadCharacters()
	{
		if(editor.stageJson._editorMeta != null)
		{
			editor.gf.changeCharacter(editor.stageJson._editorMeta.gf);
			editor.dad.changeCharacter(editor.stageJson._editorMeta.dad);
			editor.boyfriend.changeCharacter(editor.stageJson._editorMeta.boyfriend);
		}
		editor.repositionGirlfriend();
		editor.repositionDad();
		editor.repositionBoyfriend();

		focusRadioGroup.checked = -1;
		FlxG.camera.target = null;
		var point = editor.focusOnTarget('boyfriend');
		FlxG.camera.scroll.set(point.x - FlxG.width/2, point.y - FlxG.height/2);
		FlxG.camera.zoom = editor.stageJson.defaultZoom;
		oppDropdown.selectedLabel = editor.dad.curCharacter;
		gfDropdown.selectedLabel = editor.gf.curCharacter;
		plDropdown.selectedLabel = editor.boyfriend.curCharacter;
	}
	
	function reloadStageDropDown()
	{
		var stageList:Array<String> = [];
		var foldersToCheck:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'stages/');
		for (folder in foldersToCheck)
			for (file in FileSystem.readDirectory(folder))
				if(file.toLowerCase().endsWith('.json'))
				{
					var stageToCheck:String = file.substr(0, file.length - '.json'.length);
					if(!stageList.contains(stageToCheck))
						stageList.push(stageToCheck);
				}

		if(stageList.length < 1) stageList.push('');
		stageDropDown.list = stageList;
		stageDropDown.selectedLabel = editor.lastLoadedStage;
		directoryDropDown.selectedLabel = editor.stageJson.directory;
	}

	public function checkUIOnObject()
	{
		if(UI_box.selectedName == 'Object')
		{
			var selected:Int = spriteListRadioGroup.checked;
			if(selected >= 0)
			{
				var spr = editor.stageSprites[spriteListRadioGroup.labels.length - selected - 1];
				if(spr != null && StageData.reservedNames.contains(spr.type))
					UI_box.selectedName = 'Data';
			}
			else UI_box.selectedName = 'Data';
		}
	}

	public function UIEvent(id:String, sender:Dynamic)
	{
		switch(id)
		{
			case UIRadioGroup.CLICK_EVENT, UIBox.CLICK_EVENT:
				if(sender == spriteListRadioGroup || sender == UI_box)
					checkUIOnObject();
				
			case UICheckBox.CLICK_EVENT:
				editor.unsavedProgress = true;

			case UIInputText.CHANGE_EVENT, UINumericStepper.CHANGE_EVENT:
				editor.unsavedProgress = true;
		}
	}
}
