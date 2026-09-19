package funkin.states.editors;

import funkin.data.StageData;
import funkin.objects.Character;
import funkin.scripting.LuaUtils;

import flixel.addons.transition.FlxTransitionableState;

import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import openfl.display.Sprite;

import openfl.net.FileReference;

import openfl.events.Event;
import openfl.events.IOErrorEvent;

import funkin.scripting.objects.ModchartSprite;
import flash.net.FileFilter;

import funkin.states.editors.content.Prompt;
import funkin.states.editors.content.PreloadListSubState;

import funkin.states.editors.ui.StageEditorUI;

class StageEditorState extends MusicBeatState
{
	public final minZoom = 0.1;
	public final maxZoom = 2;

	var gf:Character;
	var dad:Character;
	var boyfriend:Character;
	var stageJson:StageFile;

	var camGame:FlxCamera;
	public var camHUD:FlxCamera;

	var UI:StageEditorUI;

	var stageSprites:Array<StageEditorMetaSprite> = [];
	public function new(stageToLoad:String = 'stage', cachedJson:StageFile = null){
		lastLoadedStage = stageToLoad;
		stageJson = cachedJson;
		super();
	}

	var lastLoadedStage:String;
	var camFollow:FlxObject = new FlxObject(0, 0, 1, 1);

	var helpBg:FlxSprite;
	var helpTexts:FlxSpriteGroup;

	var animationEditor:StageEditorAnimationSubstate;
	var unsavedProgress:Bool = false;
	
	var selectionSprites:FlxSpriteGroup = new FlxSpriteGroup();
	override function create(){
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		UI = new StageEditorUI(this);
		UI.cameras = [camHUD];
		UI.scrollFactor.set();
		add(UI);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Stage Editor', 'Stage: ' + lastLoadedStage);
		#end

		if(stageJson == null) stageJson = StageData.getStageFile(lastLoadedStage);
		FlxG.camera.follow(null, LOCKON, 0);

		loadJsonAssetDirectory();
		gf = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.gf : 'gf');
		gf.visible = !(stageJson.hide_girlfriend);
		gf.scrollFactor.set(0.95, 0.95);
		dad = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.dad : 'dad');
		boyfriend = new Character(0, 0, stageJson._editorMeta != null ? stageJson._editorMeta.boyfriend : 'bf', true);

		for (i in 0...4){
			var spr:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.LIME);
			spr.alpha = 0.8;
			selectionSprites.add(spr);
		}

		FlxG.camera.zoom = stageJson.defaultZoom;
		repositionGirlfriend();
		repositionDad();
		repositionBoyfriend();
		var point = focusOnTarget('boyfriend');
		FlxG.camera.scroll.set(point.x - FlxG.width/2, point.y - FlxG.height/2);

		UI.createUI();
		
		add(camFollow);
		updateSpriteList();

		addHelpScreen();
		FlxG.mouse.visible = true;
		animationEditor = new StageEditorAnimationSubstate();

		super.create();
	}

	function loadJsonAssetDirectory(){
		var directory:String = 'shared';
		var weekDir:String = stageJson.directory;
		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
	}

	var showSelectionQuad:Bool = true;
	function addHelpScreen(){
		#if FLX_DEBUG
		var btn = 'F3';
		#else
		var btn = 'F2';
		#end

		var str:Array<String> = ["E/Q - Camera Zoom In/Out",
			"J/K/L/I - Move Camera",
			"R - Reset Camera Zoom",
			"Arrow Keys/Mouse & Right Click - Move Object",
			"",
			'$btn - Toggle HUD',
			"F12 - Toggle Selection Rectangle",
			"Hold Shift - Move Objects and Camera 4x faster",
			"Hold Control - Move Objects pixel-by-pixel and Camera 4x slower"
		];

		helpBg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		helpBg.scale.set(FlxG.width, FlxG.height);
		helpBg.updateHitbox();
		helpBg.alpha = 0.6;
		helpBg.cameras = [camHUD];
		helpBg.active = helpBg.visible = false;
		add(helpBg);

		helpTexts = new FlxSpriteGroup();
		helpTexts.cameras = [camHUD];
		for (i => txt in str)
		{
			if(txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 680, txt, 16);
			helpText.setFormat(null, 16, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length/2) * 32) + 16;
			helpText.active = false;
			helpTexts.add(helpText);
		}
		helpTexts.active = helpTexts.visible = false;
		add(helpTexts);
	}

	function updateSpriteList(){
		for (spr in stageSprites)
			if(spr != null && !StageData.reservedNames.contains(spr.type))
				spr.sprite = FlxDestroyUtil.destroy(spr.sprite);

		stageSprites = [];
		var list:Map<String, FlxSprite> = [];
		if(stageJson.objects != null && stageJson.objects.length > 0)
		{
			list = StageData.addObjectsToState(stageJson.objects, gf, dad, boyfriend, null, true);
			for (key => spr in list)
				stageSprites[spr.ID] = new StageEditorMetaSprite(stageJson.objects[spr.ID], spr);

			/*for (num => spr in stageSprites)
				trace('$num: ${spr.type}, ${spr.name}');*/
		}

		for (character in ['gf', 'dad', 'boyfriend'])
			if(!list.exists(character))
				stageSprites.push(new StageEditorMetaSprite({type: character}, Reflect.field(this, character)));

		UI.updateSpriteListRadio();
	}

	override function update(elapsed:Float){
		if(FlxG.mouse.justPressed || FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle) FlxG.sound.play(Paths.sound('chartingSounds/ClickDown'));
		if(FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight || FlxG.mouse.justReleasedMiddle) FlxG.sound.play(Paths.sound('chartingSounds/ClickUp'));
		if(FlxG.keys.justPressed.ANY) FlxG.sound.play(Paths.sound('chartingSounds/keyboard${FlxG.random.int(1,3)}'));

		if(UI.createPopup.visible && (FlxG.mouse.justPressedRight || (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(UI.createPopup, camHUD))))
			UI.createPopup.visible = UI.createPopup.active = false;

		for (basic in stageSprites)
			basic.update(UI.curFilters, elapsed);

		super.update(elapsed);
		
		UI.outputTime = Math.max(0, UI.outputTime - elapsed);
		UI.outputTxt.alpha = UI.outputTime;

		if(UIInputText.focusOn != null) return;

		if(FlxG.keys.justPressed.ESCAPE){
			if(!unsavedProgress){
				MusicBeatState.switchState(new funkin.states.MainMenuState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
			else openSubState(new ExitConfirmationPrompt());
			return;
		}

		if(FlxG.keys.justPressed.W){
			UI.spriteListRadioGroup.checked = FlxMath.wrap(UI.spriteListRadioGroup.checked - 1, 0, UI.spriteListRadioGroup.labels.length-1);
			trace(UI.spriteListRadioGroup.checked);
			UI.checkUIOnObject();
			UI.updateSelectedUI();
		} else if(FlxG.keys.justPressed.S){
			UI.spriteListRadioGroup.checked = FlxMath.wrap(UI.spriteListRadioGroup.checked + 1, 0, UI.spriteListRadioGroup.labels.length-1);
			trace(UI.spriteListRadioGroup.checked);
			UI.checkUIOnObject();
			UI.updateSelectedUI();
		}

		if(FlxG.keys.justPressed.F1 || (helpBg.visible && FlxG.keys.justPressed.ESCAPE)){
			helpBg.visible = !helpBg.visible;
			helpTexts.visible = helpBg.visible;
		}

		#if FLX_DEBUG
		if(FlxG.keys.justPressed.F3)
		#else
		if(FlxG.keys.justPressed.F2)
		#end
		{
			UI.UI_box.visible = !UI.UI_box.visible;
			UI.UI_box.active = !UI.UI_box.active;

			var objs = [UI.UI_stagebox, UI.spriteListRadioGroup, UI.spriteList_box];
			for (obj in objs){
				obj.visible = UI.UI_box.visible;
				if(!(obj is FlxText)) obj.active = UI.UI_box.active;
			}
			UI.spriteListRadioGroup.updateRadioItems();
		}
		
		if(FlxG.keys.justPressed.F12)
			showSelectionQuad = !showSelectionQuad;
		
		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 4;
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// CAMERA CONTROLS
		var camX:Float = 0;
		var camY:Float = 0;
		var camMove:Float = elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.J) camX -= camMove;
		if (FlxG.keys.pressed.K) camY += camMove;
		if (FlxG.keys.pressed.L) camX += camMove;
		if (FlxG.keys.pressed.I) camY -= camMove;

		if(camX != 0 || camY != 0)
		{
			FlxG.camera.scroll.x += camX;
			FlxG.camera.scroll.y += camY;
			if(FlxG.camera.target != null) FlxG.camera.target = null;
			if(UI.focusRadioGroup.checked > -1) UI.focusRadioGroup.checked = -1;
		}

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL)
			FlxG.camera.zoom = stageJson.defaultZoom;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < maxZoom)
			FlxG.camera.zoom = Math.min(maxZoom, FlxG.camera.zoom + elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > minZoom)
			FlxG.camera.zoom = Math.max(minZoom, FlxG.camera.zoom - elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
		
		// SPRITE X/Y
		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 4;
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.2;

		var moveX:Float = 0;
		var moveY:Float = 0;
		if (FlxG.keys.justPressed.LEFT) moveX -= 5 * shiftMult * ctrlMult;
		if (FlxG.keys.justPressed.RIGHT) moveX += 5 * shiftMult * ctrlMult;
		if (FlxG.keys.justPressed.UP) moveY -= 5 * shiftMult * ctrlMult;
		if (FlxG.keys.justPressed.DOWN) moveY += 5 * shiftMult * ctrlMult;

		if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0)){
			moveX += FlxG.mouse.deltaScreenX * ctrlMult;
			moveY += FlxG.mouse.deltaScreenY * ctrlMult;
			UI._updateCamera();
		}

		if(moveX != 0 || moveY != 0){
			var selected:Int = UI.spriteListRadioGroup.checked;
			if(selected < 0) return;

			var spr = stageSprites[UI.spriteListRadioGroup.labels.length - selected - 1];
			if(spr != null)
			{
				var displayX:Float, displayY:Float;
				spr.x = displayX = Math.round(spr.x + moveX);
				spr.y = displayY = Math.round(spr.y + moveY);
				var char:Character = cast spr.sprite;
				switch(spr.type)
				{
					case 'boyfriend':
						stageJson.boyfriend[0] = displayX = spr.x - char.positionArray[0];
						stageJson.boyfriend[1] = displayY = spr.y - char.positionArray[1];
					case 'gf':
						stageJson.girlfriend[0] = displayX = spr.x - char.positionArray[0];
						stageJson.girlfriend[1] = displayY = spr.y - char.positionArray[1];
					case 'dad':
						stageJson.opponent[0] = displayX = spr.x - char.positionArray[0];
						stageJson.opponent[1] = displayY = spr.y - char.positionArray[1];
				}
				UI.posTxt.text = 'X: $displayX\nY: $displayY';
			}
		}
	}

	override function draw(){
		if(persistentDraw || subState == null)
		{

			for (basic in stageSprites)
				if(basic.visible)
					basic.draw(UI.curFilters);
	
			if(showSelectionQuad && UI.spriteListRadioGroup.checkedRadio != null)
			{
				var spr = stageSprites[UI.spriteListRadioGroup.labels.length - UI.spriteListRadioGroup.checked - 1];
				if(spr != null) drawDebugOnCamera(spr.sprite);
			}
		}

		super.draw();
	}

	function focusOnTarget(target:String){
		var focusPoint:FlxPoint = FlxPoint.weak(0, 0);
		switch(target)
		{
			case 'boyfriend':
				focusPoint.x += boyfriend.getMidpoint().x - boyfriend.cameraPosition[0] - 100;
				focusPoint.y += boyfriend.getMidpoint().y + boyfriend.cameraPosition[1] - 100;
				if(stageJson.camera_boyfriend != null && stageJson.camera_boyfriend.length > 1)
				{
					focusPoint.x += stageJson.camera_boyfriend[0];
					focusPoint.y += stageJson.camera_boyfriend[1];
				}
			case 'dad':
				focusPoint.x += dad.getMidpoint().x + dad.cameraPosition[0] + 150;
				focusPoint.y += dad.getMidpoint().y + dad.cameraPosition[1] - 100;
				if(stageJson.camera_opponent != null && stageJson.camera_opponent.length > 1)
				{
					focusPoint.x += stageJson.camera_opponent[0];
					focusPoint.y += stageJson.camera_opponent[1];
				}
			case 'gf':
				if(gf.visible)
				{
					focusPoint.x += gf.getMidpoint().x + gf.cameraPosition[0];
					focusPoint.y += gf.getMidpoint().y + gf.cameraPosition[1];
				}

				if(stageJson.camera_girlfriend != null && stageJson.camera_girlfriend.length > 1)
				{
					focusPoint.x += stageJson.camera_girlfriend[0];
					focusPoint.y += stageJson.camera_girlfriend[1];
				}
		}
		return focusPoint;
	}

	function repositionGirlfriend(){
		gf.setPosition(stageJson.girlfriend[0], stageJson.girlfriend[1]);
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
	}

	function repositionDad(){
		dad.setPosition(stageJson.opponent[0], stageJson.opponent[1]);
		dad.x += dad.positionArray[0];
		dad.y += dad.positionArray[1];
	}

	function repositionBoyfriend(){
		boyfriend.setPosition(stageJson.boyfriend[0], stageJson.boyfriend[1]);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
	}

	public function drawDebugOnCamera(spr:FlxSprite):Void {
		if (spr == null || !spr.isOnScreen(FlxG.camera))
			return;

		@:privateAccess
		var lineSize:Int = Std.int(Math.max(2, Math.floor(3 / FlxG.camera.zoom)));

		var sprX:Float = spr.x - spr.offset.x;
		var sprY:Float = spr.y - spr.offset.y;
		var sprWidth:Int = Std.int(spr.frameWidth * spr.scale.x);
		var sprHeight:Int = Std.int(spr.frameHeight * spr.scale.y);
		for (num => sel in selectionSprites.members)
		{
			sel.x = sprX;
			sel.y = sprY;
			switch(num)
			{
				case 0: //Top
					sel.setGraphicSize(sprWidth, lineSize);
				case 1: //Bottom
					sel.setGraphicSize(sprWidth, lineSize);
					sel.y += sprHeight - lineSize;
				case 2: //Left
					sel.setGraphicSize(lineSize, sprHeight);
				case 3: //Right
					sel.setGraphicSize(lineSize, sprHeight);
					sel.x += sprWidth - lineSize;
			}
			sel.updateHitbox();
			sel.scrollFactor.set(spr.scrollFactor.x, spr.scrollFactor.y);
		}
		selectionSprites.draw();
	}
	// save

	function saveObjectsToJson(){
		stageJson.objects = [];
		for (basic in stageSprites)
			stageJson.objects.push(basic.formatToJson());
	}

	function saveData(){
		if(_file != null) return;

		saveObjectsToJson();
		var data = haxe.Json.stringify(stageJson, '\t');
		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, '$lastLoadedStage.json');
		}
	}

	var _file:FileReference;
	function onSaveComplete(_):Void	{
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice('Successfully saved file.');
	}

	/**
	* Called when the save file dialog is cancelled.
	*/
	function onSaveCancel(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	* Called if there is an error while saving the gameplay recording.
	*/
	function onSaveError(_):Void {
		if(_file == null) return;
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error('Problem saving file');
	}

	var _makeNewSprite = null;
	public function loadImage(onNewSprite:String = null) {
		if(_file != null) return;

		_makeNewSprite = onNewSprite;
		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		final filters = [new FileFilter('PNG (Image)', '*.png'), new FileFilter('XML (Sparrow)', '*.xml'), new FileFilter('JSON (Aseprite)', '*.json'), new FileFilter('TXT (Packer)', '*.txt')];
		_file.browse(#if !mac filters #else [] #end);
	}

	private function onLoadComplete(_):Void {
		if(_file == null) return;
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		function loadSprite(imageToLoad:String)
		{
				if(_makeNewSprite != null)
			{
				if(_makeNewSprite == 'animatedSprite' && !Paths.fileExists('images/$imageToLoad.xml', TEXT) &&
					!Paths.fileExists('images/$imageToLoad.json', TEXT) && !Paths.fileExists('images/$imageToLoad.txt', TEXT))
				{
					UI.showOutput('No Animation file found with the same name of the image!', true);
					_makeNewSprite = null;
					_file = null;
					return;
				}
				UI.insertMeta(new StageEditorMetaSprite({type: _makeNewSprite, name: UI.findUnoccupiedName()}, new ModchartSprite()));
			}
			var selected = UI.getSelected();
			tryLoadImage(selected, imageToLoad);
			
			if(_makeNewSprite != null)
			{
				selected.sprite.x = Math.round(FlxG.camera.scroll.x + FlxG.width/2 - selected.sprite.width/2);
				selected.sprite.y = Math.round(FlxG.camera.scroll.y + FlxG.height/2 - selected.sprite.height/2);
				UI.posTxt.visible = true;
				UI.posTxt.text = 'X: ${selected.sprite.x}\nY: ${selected.sprite.y}';
			}
			_makeNewSprite = null;
		}
		_file = null;

		if(fullPath != null)
		{
			fullPath = fullPath.replace('\\', '/');
			var exePath = Sys.getCwd().replace('\\', '/');
			if(fullPath.startsWith(exePath))
			{
				fullPath = fullPath.substr(exePath.length);
				if((fullPath.startsWith('assets/') #if MODS_ALLOWED || fullPath.startsWith('mods/') #end) && fullPath.contains('/images/'))
				{
					loadSprite(fullPath.substring(fullPath.indexOf('/images/') + '/images/'.length, fullPath.lastIndexOf('.')));
					//trace('Inside Psych Engine Folder');
					return;
				}
			}

			UI.createPopup.visible = UI.createPopup.active = false;
			#if MODS_ALLOWED
			var modFolder:String = (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0) ? Paths.mods('${Mods.currentModDirectory}/images/') : Paths.mods('images/');
			openSubState(new BasePrompt(480, 160, 'This file is not inside Psych Engine.', function(state:BasePrompt)
			{
				var txt:FlxText = new FlxText(0, state.bg.y + 60, 460, 'Copy to: "$modFolder"?', 11);
				txt.alignment = CENTER;
				txt.screenCenter(X);
				txt.cameras = state.cameras;
				state.add(txt);
				
				var btnY = 390;
				var btn:UIButton = new UIButton(0, btnY, 'OK', function() {
					var fileName:String = fullPath.substring(fullPath.lastIndexOf('/') + 1, fullPath.lastIndexOf('.'));
					var pathNoExt:String = fullPath.substring(0, fullPath.lastIndexOf('.'));
					function saveFile(ext:String)
					{
						var p1:String = '$pathNoExt.$ext';
						var p2:String = modFolder + '$fileName.$ext';
						trace(p1, p2);
						if(FileSystem.exists(p1))
							File.saveBytes(p2, File.getBytes(p1));
					}

					FileSystem.createDirectory(modFolder);
					saveFile('png');
					saveFile('xml');
					saveFile('txt');
					saveFile('json');
					loadSprite(fileName);
					state.close();
				});
				btn.normalStyle.bgColor = FlxColor.GREEN;
				btn.normalStyle.textColor = FlxColor.WHITE;
				btn.screenCenter(X);
				btn.x -= 100;
				btn.cameras = state.cameras;
				state.add(btn);

				var btn:UIButton = new UIButton(0, btnY, 'Cancel', function()
				{
					_makeNewSprite = null;
					state.close();
				});
				btn.screenCenter(X);
				btn.x += 100;
				btn.cameras = state.cameras;
				state.add(btn);
			}));
			#else
			UI.showOutput('ERROR! File cannot be used, move it to "assets" and recompile.', true);
			#end
		}
		_file = null;
		#else
		trace('File couldn\'t be loaded! You aren\'t on Desktop, are you?');
		#end
	}

	function tryLoadImage(spr:StageEditorMetaSprite, imgPath:String){
		if(spr == null || StageData.reservedNames.contains(spr.type) || spr.type == 'square' || imgPath == null) return;

		spr.image = imgPath;
		UI.updateSelectedUI();
	}

	/**
	* Called when the save file dialog is cancelled.
	*/
	private function onLoadCancel(_):Void {
		if(_file == null) return;
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		
		if(_makeNewSprite != null){
			UI.createPopup.visible = UI.createPopup.active = false;
			_makeNewSprite = null;
		}
		trace('Cancelled file loading.');
	}

	/**
	* Called if there is an error while saving the gameplay recording.
	*/
	private function onLoadError(_):Void {
		if(_file == null) return;
		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;

		if(_makeNewSprite != null)
		{
			UI.createPopup.visible = UI.createPopup.active = false;
			_makeNewSprite = null;
		}
		trace('Problem loading file');
	}

	override function destroy(){
		destroySubStates = true;
		animationEditor.destroy();
		super.destroy();
	}
}

class StageEditorMetaSprite
{
	public var sprite:FlxSprite;
	public var visible(get, set):Bool;
	function get_visible() return sprite.visible;
	function set_visible(v:Bool) return (sprite.visible = v);

	// basic variables for all types
	public var type:String;

	// variables for all types that aren't Character
	public var name:String;
	public var filters:LoadFilters = (LOW_QUALITY)|(HIGH_QUALITY);
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var alpha(get, set):Float;
	public var angle(get, set):Float;
	function get_x() return sprite.x;
	function set_x(v:Float) return (sprite.x = v);
	function get_y() return sprite.y;
	function set_y(v:Float) return (sprite.y = v);
	function get_alpha() return sprite.alpha;
	function set_alpha(v:Float) return (sprite.alpha = v);
	function get_angle() return sprite.angle;
	function set_angle(v:Float) return (sprite.angle = v);

	public var color(default, set):String = 'FFFFFF';
	function set_color(v:String)
	{
		sprite.color = CoolUtil.colorFromString(v);
		return (color = v);
	}
	public var image(default, set):String = 'unknown';
	function set_image(v:String)
	{
		try
		{
			switch(type)
			{
				case 'sprite':
					sprite.loadGraphic(Paths.image(v));
				case 'animatedSprite':
					sprite.frames = Paths.getAtlas(v);
			}
		}
		catch (e:Dynamic) {}
		sprite.updateHitbox();
		return (image = v);
	}

	public var scroll:Array<Float> = [1, 1];
	public function setScrollFactor(scrX:Null<Float> = null, scrY:Null<Float> = null)
	{
		scroll[0] = (scrX != null ? scrX : scroll[0]);
		scroll[1] = (scrY != null ? scrY : scroll[1]);
		sprite.scrollFactor.set(scroll[0], scroll[1]);
	}

	public var scale:Array<Float> = [1, 1];
	public var antialiasing(default, set):Bool = true;
	function set_antialiasing(v:Bool)
	{
		sprite.antialiasing = (v && ClientPrefs.data.antialiasing);
		return (antialiasing = v);
	}

	public function setScale(wid:Null<Float> = null, hei:Null<Float> = null)
	{
		scale[0] = (wid != null ? wid : scale[0]);
		scale[1] = (hei != null ? hei : scale[1]);

		if(type == 'square')
		{
			sprite.makeGraphic(Std.int(Math.max(1, scale[0])), Std.int(Math.max(1, scale[1])), FlxColor.WHITE);
			sprite.scale.set(1, 1);
		}
		else sprite.scale.set(scale[0], scale[1]);

		sprite.updateHitbox();
	}
	
	public var flipX(get, set):Bool;
	public var flipY(get, set):Bool;
	function get_flipX() return sprite.flipX;
	function set_flipX(v:Bool) return (sprite.flipX = (v && type != 'square'));
	function get_flipY() return sprite.flipY;
	function set_flipY(v:Bool) return (sprite.flipY = (v && type != 'square'));

	// "animatedSprite" only variables
	public var firstAnimation:String;
	public var animations:Array<AnimArray>;

	public function new(data:Dynamic, spr:FlxSprite)
	{
		this.sprite = spr;
		if(data == null) return;

		this.type = data.type;
		switch(this.type)
		{
			case 'sprite', 'square', 'animatedSprite':
				for (v in ['name', 'image', 'scale', 'scroll', 'color', 'filters', 'antialiasing'])
				{
					var dat:Dynamic = Reflect.field(data, v);
					if(dat != null) Reflect.setField(this, v, dat);
				}

				if(this.type == 'animatedSprite')
				{
					this.animations = data.animations;
					this.firstAnimation = data.firstAnimation;
				}
		}
	}

	public function formatToJson()
	{
		var obj:Dynamic = {type: type};
		switch(type)
		{
			case 'square', 'sprite', 'animatedSprite':
				obj.name = name;
				obj.x = x;
				obj.y = y;
				obj.scale = scale;
				obj.scroll = scroll;
				obj.alpha = alpha;
				obj.angle = angle;
				obj.color = color;
				obj.filters = filters;

				if(type != 'square')
				{
					obj.flipX = flipX;
					obj.flipY = flipY;
					obj.image = image;
					obj.antialiasing = antialiasing;
					if(type == 'animatedSprite')
					{
						obj.animations = animations;
						obj.firstAnimation = firstAnimation;
					}
				}
		}
		return obj;
	}

	public function update(curFilters:LoadFilters, elapsed:Float)
	{
		if((curFilters & filters) != 0 || StageData.reservedNames.contains(type))
			sprite.update(elapsed);
	}

	public function draw(curFilters:LoadFilters)
	{
		if((curFilters & filters) != 0 || StageData.reservedNames.contains(type))
			sprite.draw();
	}
}

class StageEditorAnimationSubstate extends MusicBeatSubstate {
	var bg:FlxSprite;
	var originalZoom:Float;
	var originalCamPoint:FlxPoint;
	var originalPosition:FlxPoint;
	var originalCamTarget:FlxObject;
	var originalAlpha:Float = 1;
	public var target:StageEditorMetaSprite;
	
	var curAnim:Int = 0;
	var animsTxtGroup:FlxTypedGroup<FlxText>;

	var UI_animationbox:UIBox;
	var camHUD:FlxCamera = cast(FlxG.state, StageEditorState).camHUD;
	public function new()
	{
		super();

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(50, 50, 100, 100, true, 0xFFAAAAAA, 0xFF666666));
		add(grid);
		
		animsTxtGroup = new FlxTypedGroup<FlxText>();
		animsTxtGroup.cameras = [camHUD];
		add(animsTxtGroup);
		
		UI_animationbox = new UIBox(FlxG.width - 320, 20, 300, 250, ['Animations']);
		UI_animationbox.cameras = [camHUD];
		UI_animationbox.scrollFactor.set();
		add(UI_animationbox);
		addAnimationsUI();

		openCallback = function()
		{
			curAnim = 0;
			originalZoom = FlxG.camera.zoom;
			originalCamPoint = FlxPoint.weak(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			originalPosition = FlxPoint.weak(target.x, target.y);
			originalCamTarget = FlxG.camera.target;
			originalAlpha = target.alpha;
			FlxG.camera.zoom = 0.5;
			FlxG.camera.scroll.set(0, 0);

			target.alpha = 1;
			target.sprite.screenCenter();
			add(target.sprite);
			reloadAnimList();
			trace('Opened substate');
		};

		closeCallback = function()
		{
			FlxG.camera.zoom = originalZoom;
			FlxG.camera.scroll.set(originalCamPoint.x, originalCamPoint.y);
			FlxG.camera.target = originalCamTarget;

			target.x = originalPosition.x;
			target.y = originalPosition.y;
			target.alpha = originalAlpha;
			remove(target.sprite);

			if(target.animations.length > 0)
			{
				if(target.firstAnimation == null) target.firstAnimation = target.animations[0].anim;
				playAnim(target.firstAnimation);
			}
		};
	}

	var animationDropDown:UIDropDownMenu;
	var animationInputText:UIInputText;
	var animationNameInputText:UIInputText;
	var animationIndicesInputText:UIInputText;
	var animationFramerate:UINumericStepper;
	var animationLoopCheckBox:UICheckBox;
	var mainAnimTxt:FlxText;
	function addAnimationsUI()
	{
		var tab_group = UI_animationbox.getTab('Animations').menu;

		animationInputText = new UIInputText(15, 85, 80, '', 8);
		animationNameInputText = new UIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		animationIndicesInputText = new UIInputText(animationNameInputText.x, animationNameInputText.y + 40, 250, '', 8);
		animationFramerate = new UINumericStepper(animationInputText.x + 170, animationInputText.y, 1, 24, 0, 240, 0);
		animationLoopCheckBox = new UICheckBox(animationNameInputText.x + 170, animationNameInputText.y - 1, 'Should it Loop?', 100);

		animationDropDown = new UIDropDownMenu(15, animationInputText.y - 55, [''], function(selectedAnimation:Int, pressed:String) {
			var anim:AnimArray = target.animations[selectedAnimation];
			if(anim == null) return;

			animationInputText.text = anim.anim;
			animationNameInputText.text = anim.name;
			animationLoopCheckBox.checked = anim.loop;
			animationFramerate.value = anim.fps;

			var indicesStr:String = anim.indices.toString();
			animationIndicesInputText.text = indicesStr.substr(1, indicesStr.length - 2);
		});

		mainAnimTxt = new FlxText(160, animationDropDown.y - 18, 0, 'Main Anim.: ');
		var initAnimButton:UIButton = new UIButton(160, animationDropDown.y, 'Main Animation', function() {
			var anim:AnimArray = target.animations[curAnim];
			if(anim == null) return;

			mainAnimTxt.text = 'Main Anim.: ${anim.anim}';
			target.firstAnimation = anim.anim;
		});
		tab_group.add(mainAnimTxt);
		tab_group.add(initAnimButton);

		var addUpdateButton:UIButton = new UIButton(40, animationIndicesInputText.y + 35, 'Add/Update', function() {
			if(animationInputText.text == '') return;

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

			var lastAnim:String = (target.animations[curAnim] != null) ? target.animations[curAnim].anim : '';
			var lastOffsets:Array<Int> = null;
			for (anim in target.animations)
				if(animationInputText.text == anim.anim)
				{
					lastOffsets = anim.offsets;
					cast (target.sprite, ModchartSprite).animOffsets.remove(animationInputText.text);
					target.sprite.animation.remove(animationInputText.text);
					target.animations.remove(anim);
				}

			var addedAnim:AnimArray = {
				anim: animationInputText.text,
				name: animationNameInputText.text,
				fps: Math.round(animationFramerate.value),
				loop: animationLoopCheckBox.checked,
				indices: indices,
				offsets: lastOffsets
			};

			if(addedAnim.indices != null && addedAnim.indices.length > 0)
				target.sprite.animation.addByIndices(addedAnim.anim, addedAnim.name, addedAnim.indices, '', addedAnim.fps, addedAnim.loop);
			else
				target.sprite.animation.addByPrefix(addedAnim.anim, addedAnim.name, addedAnim.fps, addedAnim.loop);

			target.animations.push(addedAnim);
			reloadAnimList();
			playAnim(addedAnim.anim, true);

			curAnim = target.animations.length - 1;
			updateTextColors();
			trace('Added/Updated animation: ' + animationInputText.text);
		});

		var removeButton:UIButton = new UIButton(160, animationIndicesInputText.y + 35, 'Remove', function()
		{
			for (anim in target.animations)
			{
				if(animationInputText.text == anim.anim)
				{
					var targetSprite:ModchartSprite = cast (target.sprite, ModchartSprite);
					var resetAnim:Bool = false;
					if(targetSprite.animation.curAnim != null && anim.anim == targetSprite.animation.curAnim.name) resetAnim = true;

					if(targetSprite.animOffsets.exists(anim.anim))
						targetSprite.animOffsets.remove(anim.anim);

					target.animations.remove(anim);
					targetSprite.animation.remove(anim.anim);

					if(resetAnim && target.animations.length > 0)
					{
						curAnim = FlxMath.wrap(curAnim, 0, target.animations.length-1);
						playAnim(target.animations[curAnim].anim, true);
						updateTextColors();
					}
					else if(target.animations.length < 1)
						target.sprite.animation.curAnim = null;

					trace('Removed animation: ' + animationInputText.text);
					reloadAnimList();
					break;
				}
			}
		});

		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(animationFramerate.x, animationFramerate.y - 18, 0, 'Framerate:'));
		tab_group.add(new FlxText(animationNameInputText.x, animationNameInputText.y - 18, 0, 'Animation Symbol Name/Tag:'));
		tab_group.add(new FlxText(animationIndicesInputText.x, animationIndicesInputText.y - 18, 0, 'ADVANCED - Animation Indices:'));

		tab_group.add(animationInputText);
		tab_group.add(animationNameInputText);
		tab_group.add(animationIndicesInputText);
		tab_group.add(animationFramerate);
		tab_group.add(animationLoopCheckBox);
		tab_group.add(addUpdateButton);
		tab_group.add(removeButton);
		tab_group.add(animationDropDown);
	}

	function reloadAnimList()
	{
		if(target.animations == null) target.animations = [];
		else if(target.animations.length > 0) playAnim(target.animations[0].anim, true);
		curAnim = 0;

		for (text in animsTxtGroup)
			text.kill();

		var spr:ModchartSprite = cast (target.sprite, ModchartSprite);
		if(target.animations.length > 0)
		{
			if(target.firstAnimation == null || !target.sprite.animation.exists(target.firstAnimation))
				target.firstAnimation = target.animations[0].anim;

			mainAnimTxt.text = 'Main Anim.: ${target.firstAnimation}';
		}
		else
		{
			target.firstAnimation = null;
			mainAnimTxt.text = '(No Main Animation)';
		}

		for (num => anim in target.animations)
		{
			var text:FlxText = animsTxtGroup.recycle(FlxText);
			text.x = 10;
			text.y = 32 + (20 * num);
			text.fieldWidth = 400;
			text.fieldHeight = 20;
			if(anim.offsets != null)
				text.text = '${anim.anim}: ${spr.animOffsets.get(anim.anim)}';
			else
				text.text = '${anim.anim}: No offsets';

			text.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE_FAST, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1;
			animsTxtGroup.add(text);
		}
		updateTextColors();
		reloadAnimationDropDown();
	}
	
	function reloadAnimationDropDown() {
		var animList:Array<String> = [];
		for (anim in target.animations) animList.push(anim.anim);
		if(animList.length < 1) animList.push('NO ANIMATIONS'); //Prevents crash

		animationDropDown.list = animList;
	}

	inline function updateTextColors()
	{
		for (num => text in animsTxtGroup)
		{
			text.color = FlxColor.WHITE;
			if(num == curAnim) text.color = FlxColor.LIME;
		}
	}

	function playAnim(name:String, force:Bool = false)
	{
		var spr:ModchartSprite = cast (target.sprite, ModchartSprite);
		spr.playAnim(name, force);
		if(!spr.animOffsets.exists(name)) spr.updateHitbox();
	}
	
	final minZoom = 0.25;
	final maxZoom = 2;
	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var holdingFrameTime:Float = 0;
	var holdingFrameElapsed:Float = 0;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(UIInputText.focusOn != null) return;

		// ANIMATION SCROLLING
		if(target.animations.length > 1)
		{
			var changedAnim:Bool = false;
			if(FlxG.keys.justPressed.W && (changedAnim = true)) curAnim--;
			else if(FlxG.keys.justPressed.S && (changedAnim = true)) curAnim++;
			else if(FlxG.keys.justPressed.SPACE) changedAnim = true;

			if(changedAnim)
			{
				curAnim = FlxMath.wrap(curAnim, 0, target.animations.length-1);
				playAnim(target.animations[curAnim].anim, true);
				updateTextColors();
			}
		}

		var shiftMult:Float = 1;
		var ctrlMult:Float = 1;
		var shiftMultBig:Float = 1;
		if(FlxG.keys.pressed.SHIFT)
		{
			shiftMult = 4;
			shiftMultBig = 10;
		}
		if(FlxG.keys.pressed.CONTROL) ctrlMult = 0.25;

		// OFFSET
		if(target.sprite.animation.curAnim != null)
		{
			var spr:ModchartSprite = cast (target.sprite, ModchartSprite);
			var anim:String = spr.animation.curAnim.name;
			var changedOffset = false;
			var moveKeysP = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.DOWN];
			var moveKeys = [FlxG.keys.pressed.LEFT, FlxG.keys.pressed.RIGHT, FlxG.keys.pressed.UP, FlxG.keys.pressed.DOWN];
			if(moveKeysP.contains(true))
			{
				if(spr.animOffsets.get(anim) != null)
				{
					spr.offset.x += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * shiftMultBig;
					spr.offset.y += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * shiftMultBig;
				}
				else spr.offset.x = spr.offset.y = 0;
				changedOffset = true;
			}
	
			if(moveKeys.contains(true))
			{
				holdingArrowsTime += elapsed;
				if(holdingArrowsTime > 0.6)
				{
					holdingArrowsElapsed += elapsed;
					while(holdingArrowsElapsed > (1/60))
					{
						if(spr.animOffsets.get(anim) != null)
						{
							spr.offset.x += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * shiftMultBig;
							spr.offset.y += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * shiftMultBig;
						}
						else spr.offset.x = spr.offset.y = 0;
						holdingArrowsElapsed -= (1/60);
						changedOffset = true;
					}
				}
			}
			else holdingArrowsTime = 0;
	
			if(FlxG.mouse.pressedRight && (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0))
			{
				spr.offset.x -= FlxG.mouse.deltaScreenX;
				spr.offset.y -= FlxG.mouse.deltaScreenY;
				changedOffset = true;
			}

			if (FlxG.keys.justPressed.R && FlxG.keys.pressed.CONTROL)
			{
				target.animations[curAnim].offsets = null;
				spr.animOffsets.remove(anim);
				spr.updateHitbox();
				animsTxtGroup.members[curAnim].text = '${anim}: No offsets';
			}
			
			if(changedOffset)
			{
				var offX = Math.round(spr.offset.x);
				var offY = Math.round(spr.offset.y);

				spr.addOffset(anim, offX, offY);
				target.animations[curAnim].offsets = [offX, offY];
				animsTxtGroup.members[curAnim].text = '${anim}: ${spr.animOffsets.get(anim)}';
			}
		}
		else
		{
			holdingArrowsTime = 0;
			holdingArrowsElapsed = 0;
		}

		// CAMERA CONTROLS
		var camX:Float = 0;
		var camY:Float = 0;
		var camMove:Float = elapsed * 500 * shiftMult * ctrlMult;
		if (FlxG.keys.pressed.J) camX -= camMove;
		if (FlxG.keys.pressed.K) camY += camMove;
		if (FlxG.keys.pressed.L) camX += camMove;
		if (FlxG.keys.pressed.I) camY -= camMove;

		if(camX != 0 || camY != 0)
		{
			FlxG.camera.scroll.x += camX;
			FlxG.camera.scroll.y += camY;
		}

		var lastZoom = FlxG.camera.zoom;
		if(FlxG.keys.justPressed.R && !FlxG.keys.pressed.CONTROL)
			FlxG.camera.zoom = 0.5;
		else if (FlxG.keys.pressed.E && FlxG.camera.zoom < maxZoom)
			FlxG.camera.zoom = Math.min(maxZoom, FlxG.camera.zoom + elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);
		else if (FlxG.keys.pressed.Q && FlxG.camera.zoom > minZoom)
			FlxG.camera.zoom = Math.max(minZoom, FlxG.camera.zoom - elapsed * FlxG.camera.zoom * shiftMult * ctrlMult);

		if(FlxG.keys.justPressed.ESCAPE)
		{
			persistentDraw = true;
			close();
		}
	}
}
