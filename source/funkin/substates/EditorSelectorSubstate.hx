package funkin.substates;

import funkin.states.editors.content.Prompt.BasePrompt;
import funkin.states.editors.ModSelectorState;

typedef EditorOption = {
	var label:String;
	var ?color:FlxColor;
}

class EditorSelectorSubstate extends MusicBeatSubstate {
	static final OPTIONS:Array<EditorOption> = [
		{ label: "Chart Editor" },
		{ label: "Character Editor" },
		{ label: "Week Editor" },
		{ label: "Dialogue Editor" },
		{ label: "Dialogue Character Editor" },
		{ label: "Stage Editor", color: 0xFFFFCC55 },
		{ label: "Modchart Editor" },
		{ label: "Note Splash Debug" },
		{ label: "Mod Config Editor", color: 0xFFAADDFF },
	];

	var grpAlph:FlxTypedGroup<Alphabet>;
	var bg:FlxSprite;
	var titleText:FlxText;

	var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var holdTime:Float = 0;
	var velXtra:Float = 0;

	var backdrop:flixel.addons.display.FlxBackdrop;

	static inline final DRAW_DIST:Int = 5;
	var _lastVisibles:Array<Int> = [];

	public function new() {
		super();
	}

	override public function create() {
		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0.65;
		bg.scrollFactor.set();
		add(bg);

		backdrop = new flixel.addons.display.FlxBackdrop(Paths.image('grid'));
		backdrop.velocity.set(40, 25);
		backdrop.alpha = 0.18;
		add(backdrop);

		grpAlph = new FlxTypedGroup<Alphabet>();
		add(grpAlph);

		var bar = new FlxSprite().makeGraphic(FlxG.width, 50, 0xFF000000);
		bar.alpha = 0.7;
		bar.scrollFactor.set();
		add(bar);

		titleText = new FlxText(0, 8, FlxG.width, "Editor Selector", 30);
		titleText.setFormat(Paths.font("default.ttf"), 30, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		add(titleText);

		for (i in 0...OPTIONS.length) {
			var opt = OPTIONS[i];
			var txt = new Alphabet(90, 320, opt.label, true);
			txt.targetY = i;
			txt.scaleX = Math.min(1, 980 / txt.width);
			txt.snapToPosition();
			txt.isMenuItem = false;
			txt.visible = txt.active = false;
			txt.x += 40;
			txt.screenCenter(X);
            txt.scrollFactor.set();
			if (opt.color != null) txt.color = opt.color;
			grpAlph.add(txt);
		}

		changeSelection();
		updateList();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		if (controls.UI_UP_P){
			changeSelection(-shiftMult);
			holdTime = 0;
		}
		if (controls.UI_DOWN_P){
			changeSelection(shiftMult);
			holdTime = 0;
		}

		if (controls.UI_UP || controls.UI_DOWN) {
			var prevHold = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var newHold  = Math.floor((holdTime - 0.5) * 10);
			if (holdTime > 0.5 && newHold - prevHold > 0)
				changeSelection((newHold - prevHold) * (controls.UI_UP ? -shiftMult : shiftMult));
		}

		if (FlxG.mouse.wheel != 0) {
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
			changeSelection(-shiftMult * FlxG.mouse.wheel, false);
		}

		if (controls.ACCEPT) onAccept();
		if (controls.BACK) close();

		updateList(elapsed);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true) {
		if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var len = grpAlph.length;
		if (len == 0) return;

		if (change == -1) velXtra += 450;
		else if (change == 1) velXtra -= 450;

		curSelected = (curSelected + change + len) % len;

		for (i in 0...len)
			grpAlph.members[i].alpha = (i == curSelected) ? 1.0 : 0.55;
	}

	function updateList(elapsed:Float = 0) {
		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));

		for (i in _lastVisibles)
			if (i < grpAlph.length)
				grpAlph.members[i].visible = grpAlph.members[i].active = false;
		_lastVisibles = [];

		velXtra = CoolUtil.fpsLerp(velXtra, 0, 0.01);
		backdrop.velocity.set(40, 25 + velXtra);

		var len = grpAlph.length;
		var min = Std.int(Math.max(0, Math.min(len, lerpSelected - DRAW_DIST)));
		var max = Std.int(Math.max(0, Math.min(len, lerpSelected + DRAW_DIST)));

		for (i in min...max) {
			if (i >= grpAlph.length) continue;
			var item = grpAlph.members[i];
			item.visible = item.active = true;

			var usableHeight = FlxG.height - 120;
			var offset = i - lerpSelected;
			var y = (usableHeight / 2) + 90 + (offset * 128);
			item.y = y;
			item.x = -50 + Math.abs(Math.cos(offset / DRAW_DIST * Math.PI * 0.5)) * 140;

			_lastVisibles.push(i);
		}
	}

	function onAccept() {
		switch (curSelected) {
			case 0: // Chart Editor
				MusicBeatState.switchState(new ModSelectorState(funkin.states.editors.ChartingState, []));
			case 1: // Character Editor
				MusicBeatState.switchState(new ModSelectorState(funkin.states.editors.CharacterEditorState, [null, false]));
			case 2: // Week Editor
				MusicBeatState.switchState(new ModSelectorState(funkin.states.editors.WeekEditorState, []));
			case 3:
				MusicBeatState.switchState(new funkin.states.editors.DialogueEditorState());
			case 4:
				MusicBeatState.switchState(new funkin.states.editors.DialogueCharacterEditorState());
			case 5: // Stage Editor
				MusicBeatState.switchState(new ModSelectorState(funkin.states.editors.StageEditorState, []));
			case 6: // Modchart Editor
				MusicBeatState.switchState(new ModSelectorState(funkin.states.editors.ModchartEditorState, []));
			case 7: // Note Splash Debug
				MusicBeatState.switchState(new ModSelectorState(funkin.states.editors.NoteSplashDebugState, []));
			case 8: // Mod Config Editor
				MusicBeatState.switchState(new ModSelectorState(BasePrompt, []));
		}
	}
}
