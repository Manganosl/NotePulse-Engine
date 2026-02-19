package funkin.substates;

import funkin.states.editors.DialogueEditorState;
import flixel.math.FlxPoint;
import flixel.effects.FlxFlicker;

class EditorPicker extends MusicBeatSubstate {
	public var bg:FlxSprite;

	public var options:Array<Editor> = [
		{
			name: "Chart Editor",
			iconShit: "chart",
			state: funkin.states.editors.ModSelector,
			args: [funkin.states.editors.ChartingState]
		},
		{
			name: "Character Editor",
			iconShit: "character",
			state: funkin.states.editors.ModSelector,
			args: [funkin.states.editors.CharacterEditorState, [null, false]]
		},
		{
			name: "Week Editor",
			iconShit: "alphabet",
			state: funkin.states.editors.ModSelector,
			args: [funkin.states.editors.WeekEditorState]
		},
		{
			name: "Dialogue Editors",
			iconShit: "uiDebug",
			state: funkin.substates.EditorPicker.DialoguePicker,
			args: [null]
		},
		{
			name: "Note Splash Debug",
			iconShit: "noteskin",
			state: funkin.states.editors.ModSelector,
			args: [funkin.states.editors.NoteSplashDebugState]
		},
		{
			name: "Stage Editor",
			iconShit: "stage",
			state: funkin.states.editors.ModSelector,
			args: [funkin.states.editors.StageEditorState]
		},
		{
			name: "Modchart Editor",
			iconShit: "modchart",
			state: funkin.states.editors.ModSelector,
			args: [funkin.states.editors.ModchartEditor]
		},
		{
			name: "Mod Config Editor",
			iconShit: "debugOptions",
			state: funkin.states.editors.ModSelector,
			args: [funkin.states.editors.content.Prompt.BasePrompt]
		}
	];

	public var sprites:Array<EditorPickerOption> = [];

	public var curSelected:Int = 0;

	public var subCam:FlxCamera;
	public var oldMousePos:FlxPoint = FlxPoint.get();
	public var curMousePos:FlxPoint = FlxPoint.get();

	public var optionHeight:Float = 0;

	public var selected:Bool = false;

	public var camVelocity:Float = 0;

	public override function create() {
		Mouse.cursor = MouseCursor.POINTER;
		super.create();

		camera = subCam = new FlxCamera();
		subCam.bgColor = 0;
		FlxG.cameras.add(subCam, false);

		bg = new FlxSprite().makeGraphic(1, 1, 0xFF000000);
		bg.scrollFactor.set();
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		add(bg);

		optionHeight = FlxG.height / options.length;
		for(k=>o in options) {
			var spr = new EditorPickerOption(o.name, o.iconShit, optionHeight);
			spr.y = k * optionHeight;
			add(spr);
			sprites.push(spr);
		}
		sprites[0].selected = true;

		FlxG.mouse.getScreenPosition(subCam, oldMousePos);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);

		bg.alpha = CoolUtil.fpsLerp(bg.alpha, selected ? 1 : 0.5, 0.25);
		if (bg.alpha >= 0.95 && funkin.states.MainMenuState.block.visible == false) funkin.states.MainMenuState.block.visible = true;

		if (selected) {
			camVelocity += FlxG.width * elapsed * 2;
			subCam.scroll.x += camVelocity * elapsed;
			return;
		}
		changeSelection(-FlxG.mouse.wheel + (controls.UI_UP_P ? -1 : 0) + (controls.UI_DOWN_P ? 1 : 0));

		FlxG.mouse.getScreenPosition(subCam, curMousePos);
		if (curMousePos.x != oldMousePos.x || curMousePos.y != oldMousePos.y) {
			oldMousePos.set(curMousePos.x, curMousePos.y);
			curSelected = -1;
			changeSelection(Std.int(curMousePos.y / optionHeight)+1);
		}

		if (controls.ACCEPT || FlxG.mouse.justReleased) {
			if (options[curSelected].state != null) {
				selected = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				if (FlxG.sound.music != null)
					FlxG.sound.music.fadeOut(0.7, 0, function(n) {
						FlxG.sound.music.stop();
					});

				sprites[curSelected].flicker(function() {
					subCam.fade(0xFF000000, 0.25, false, function() {
						MusicBeatState.switchState(Type.createInstance(options[curSelected].state, options[curSelected].args));
					});
				});
			} else {
				//CoolUtil.openURL("https://www.youtube.com/watch?v=9Youam7GYdQ");
			}

		}
		if (controls.BACK)
			close();
	}

	override function destroy() {
		super.destroy();

		oldMousePos.put();
		curMousePos.put();

		if (FlxG.cameras.list.contains(subCam))
			FlxG.cameras.remove(subCam);

		Mouse.cursor = MouseCursor.DEFAULT;
	}

	public function changeSelection(change:Int) {
		if (change == 0) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, sprites.length-1);

		for(o in sprites)
			o.selected = false;
		sprites[curSelected].selected = true;
	}
}

class DialoguePicker extends EditorPicker {
	override public function create() {
		options = [
			{
				name: "Dialogue Editor",
				iconShit: "dialogue",
				state: funkin.states.editors.DialogueEditorState,
				args: [null]
			},
			{
				name: "Dialogue Character Editor",
				iconShit: "uiDebug",
				state: funkin.states.editors.DialogueCharacterEditorState,
				args: [null]
			}
		];

		super.create();
	}
}

typedef Editor = {
	var name:String;
	var iconShit:String;
	var state:Class<Dynamic>;
	var args:Array<Dynamic>;
}

class EditorPickerOption extends FlxTypedSpriteGroup<FlxSprite> {
	public var iconSpr:FlxSprite;
	public var label:Alphabet;

	public var selectionBG:FlxSprite;

	public var selected:Bool = false;

	public var selectionLerp:Float = 0;

	public var iconRotationCycle:Float = 0;
	public function new(name:String, iconShit:String, height:Float) {
		super();


		FlxG.mouse.visible = true;
		iconSpr = new FlxSprite();
		iconSpr.loadGraphic(Paths.image('editors/icons/'+iconShit), true, 128, 128);
		iconSpr.antialiasing = true;
		if (height < 150) {
			iconSpr.scale.set(height / 150, height / 150);
			iconSpr.updateHitbox();
		}
		iconSpr.x = 25 + ((height - iconSpr.width) / 2);
		iconSpr.y = (height - iconSpr.height) / 2;

		label = new Alphabet(25 + iconSpr.width + 25, 0, name, true);
		label.y = (height - label.height) / 2;

		selectionBG = new FlxSprite().makeGraphic(1, 1, -1);
		selectionBG.scale.set(FlxG.width, height);
		selectionBG.updateHitbox();
		selectionBG.alpha = 0;

		add(selectionBG);
		add(iconSpr);
		add(label);
	}

	public override function update(elapsed:Float) {
		super.update(elapsed);
		iconRotationCycle += elapsed;

		selectionLerp = CoolUtil.fpsLerp(selectionLerp, selected ? 1 : 0, 0.25);

		selectionBG.alpha = (iconSpr.alpha = FlxEase.cubeOut(selectionLerp)) * 0.5;
		selectionBG.x = FlxMath.lerp(-FlxG.width, 0, selectionLerp);

		label.x = FlxMath.lerp(10, 25 + iconSpr.width + 25, selectionLerp);
		iconSpr.x = label.x - 25 - iconSpr.width;
		iconSpr.angle = Math.sin(iconRotationCycle * 0.5) * 5;

		scrollFactor.set(FlxMath.lerp(1, 0.1, selectionLerp), 0);
		selectionBG.scrollFactor.set(0, 0);
	}

	public override function destroy() {
		super.destroy();
	}

	public function flicker(callback:Void->Void) {
		FlxFlicker.flicker(label, 0.5,/* Options.flashingMenu ?*/ 0.06/* : 0.15*/, false, false, function(t) {
			callback();
		});
	}
}
