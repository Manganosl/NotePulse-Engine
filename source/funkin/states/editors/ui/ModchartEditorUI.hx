package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import funkin.objects.notes.PlayField;
import flixel.util.FlxStringUtil;

@:access(funkin.states.editors.ModchartEditorState)
class ModchartEditorUI extends FlxSpriteContainer {
    var modcharter:ModchartEditorState;

    public var isFullScreen:Bool = false;
	public var pHeadIsDragging:Bool = false;
	public var pHeadWasPlaying:Bool = false;

	public var playbarHead:PsychUIBar;
    public var infoText:FlxText;

    public var modchartBox:PsychUIBox;

	public var modifierInput:PsychUIInputText;
	public var actionsDropdown:PsychUIDropDownMenu;
	public var timeStepper:PsychUINumericStepper;
	public var valueStepper:PsychUINumericStepper;
	public var easeInput:PsychUIInputText;
	public var playerStepper:PsychUINumericStepper;
    
	public var sustainSegmentsStepper:PsychUINumericStepper;

    public function new(modcharter:ModchartEditorState){
        super();

        this.modcharter = modcharter;

        createPlaybar();
        createUIBox();
    }

    function createUIBox(){
		modchartBox = new PsychUIBox(10, 40, 300, 280, ['Modchart', 'Song']);
		modchartBox.selectedName = 'Modchart';
		modchartBox.scrollFactor.set();
		add(modchartBox);

        addModchartTab();
        addSongTab();
    }

	function addModchartTab():Void {
		var tabGroupModchart = modchartBox.getTab('Modchart').menu;
		var posX = 10;
		var posY = 30;

		modifierInput = new PsychUIInputText(posX+150, posY, 120, '', 8);
    	modifierInput.onChange = function(old:String, cur:String){
			modcharter.updateModEvV1();
		}

		var modifierLabelText = new FlxText(modifierInput.x, modifierInput.y - 15, 80, 'Modifier:');

		actionsDropdown = new PsychUIDropDownMenu(posX, posY, ["Set", "Ease"], function(index:Int, name:String){
			modcharter.updateModEvV1();
		});

		var actionsLabelText = new FlxText(actionsDropdown.x, actionsDropdown.y - 15, 80, 'Action:');

		posY += 60;

		timeStepper = new PsychUINumericStepper(posX, posY, 0.01, 0, 0, 9999, 2);
		timeStepper.onValueChange = function() {
			modcharter.updateModEvV1();
		};

		valueStepper = new PsychUINumericStepper(posX + 150, posY, 0.01, 0, -999999, 999999, 2);
		valueStepper.onValueChange = function() {
			modcharter.updateModEvV1();
		};

		posY += 60;

		easeInput = new PsychUIInputText(posX, posY, 120, '', 8);
		easeInput.onChange = function(old:String, cur:String){
			modcharter.updateModEvV1();
		}

		playerStepper = new PsychUINumericStepper(posX + 150, posY, 1, -1, -1, (PlayState.SONG.lanes - 1), 0);
		playerStepper.onValueChange = function() {
			modcharter.updateModEvV1();
		};

		var timeLabelText = new FlxText(timeStepper.x, timeStepper.y - 15, 80, 'Time (beats):');
		var valueLabelText = new FlxText(valueStepper.x, valueStepper.y - 15, 80, 'Value:');
		var easeLabelText = new FlxText(easeInput.x, easeInput.y - 15, 80, 'Ease (if ease):');
		var playerLabelText = new FlxText(playerStepper.x, playerStepper.y - 15, 80, 'Player:');

		tabGroupModchart.add(modifierInput);
		tabGroupModchart.add(modifierLabelText);
		tabGroupModchart.add(actionsLabelText);
		tabGroupModchart.add(timeStepper);
		tabGroupModchart.add(valueStepper);
		tabGroupModchart.add(easeInput);
		tabGroupModchart.add(playerStepper);
		tabGroupModchart.add(timeLabelText);
		tabGroupModchart.add(valueLabelText);
		tabGroupModchart.add(easeLabelText);
		tabGroupModchart.add(playerLabelText);
		tabGroupModchart.add(actionsDropdown);
	}

	function addSongTab():Void {
		var tabGroup = modchartBox.getTab('Song').menu;
		var posX = 10;
		var posY = 25;

		var saveButton:PsychUIButton = new PsychUIButton(posX, posY, 'Save Modchart', function(){
			modcharter.saveChart();
		}, 100);
		saveButton.normalStyle.bgColor = FlxColor.GREEN;
		saveButton.normalStyle.textColor = FlxColor.WHITE;
		tabGroup.add(saveButton);

		posY += 40;
		var sustainSegmentsLabelText = new FlxText(posX, posY - 15, 150, 'Sustain Segments:');
		sustainSegmentsStepper = new PsychUINumericStepper(posX, posY, 1, 4, 1, 999, 0);
		sustainSegmentsStepper.onValueChange = function() {
			for (field in PlayField.fields) field.sustainSegments = Std.int(sustainSegmentsStepper.value);
		};

		tabGroup.add(sustainSegmentsLabelText);
		tabGroup.add(sustainSegmentsStepper);
	}

	function createPlaybar(){
		var playbar:FlxSpriteGroup = new FlxSpriteGroup();
		playbar.scrollFactor.set();

		var playbarBG:FlxSprite = new FlxSprite(0, FlxG.height-125).makeGraphic(FlxG.width, 125, FlxColor.BLACK);
		playbarBG.alpha = 0.6;
		playbarBG.blend = OVERLAY;
		playbar.add(playbarBG);

		var songLen:Float = (FlxG.sound.music != null ? FlxG.sound.music.length : 0.0001);
		playbarHead = new PsychUIBar(0, playbarBG.y, null, Conductor.songPosition, 0, songLen, FlxG.width, 0xFF4D4D4D, FlxColor.WHITE);
		playbarHead.y = playbarBG.y;
		playbarHead.valueText.visible = false;
		playbarHead.minText.visible = false;
		playbarHead.maxText.visible = false;

		playbarHead.onDragStart = (v:Float) -> {
			pHeadIsDragging = true;
			if(!modcharter.paused) pHeadWasPlaying = true;
			modcharter.setSongPlaying(false);
		}
		
		playbarHead.onDrag = (v:Float) -> {
			if(pHeadIsDragging){
				if(FlxG.sound.music != null) FlxG.sound.music.time = v;
				if(modcharter.vocals != null) modcharter.vocals.time = v;
				if(modcharter.opponentVocals != null) modcharter.opponentVocals.time = v;
				Conductor.songPosition = v;

				modcharter.applyNoteStates(v);
			}
		}

		playbarHead.onDragEnd = (v:Float) -> {
			pHeadIsDragging = false;
			if(pHeadWasPlaying){
				pHeadWasPlaying = false;
				modcharter.setSongPlaying(true);
			}
			modcharter.reloadManager();
		}
		playbar.add(playbarHead);

		infoText = new FlxText(25, playbarHead.y + 25, FlxG.width);
		infoText.setFormat(null, 13, FlxColor.WHITE, LEFT);
		infoText.borderColor = FlxColor.BLACK;
		infoText.borderSize = 1;
		infoText.active = false;
		playbar.add(infoText);

		var fullScreenBtn:PsychUIButton;
		fullScreenBtn = new PsychUIButton(0, 0, '>', null, 100);
		fullScreenBtn.onClick = () -> {  // To remove that annoying warning
			fullScreenBtn.text.angle += 180;
			if(!isFullScreen){
				FlxTween.cancelTweensOf(playbar, ["y"]);
				FlxTween.tween(playbar, {y: 100}, 1, {ease: FlxEase.circOut});

				FlxTween.cancelTweensOf(modcharter.camHUD);
				FlxTween.tween(modcharter.camHUD, {zoom: 1, y: 0}, 1, {ease: FlxEase.circOut});

				FlxTween.cancelTweensOf(modcharter.boxHUD);
				FlxTween.tween(modcharter.boxHUD, {alpha: 0}, 1, {ease: FlxEase.circOut});
			} else {
				FlxTween.cancelTweensOf(playbar, ["y"]);
				FlxTween.tween(playbar, {y: 0}, 1, {ease: FlxEase.circOut});

				FlxTween.cancelTweensOf(modcharter.camHUD);
				FlxTween.tween(modcharter.camHUD, {zoom: 0.4, y:-125}, 1, {ease: FlxEase.circOut});

				FlxTween.cancelTweensOf(modcharter.boxHUD);
				FlxTween.tween(modcharter.boxHUD, {alpha: 1}, 1, {ease: FlxEase.circOut});
			}
			isFullScreen = !isFullScreen;
		}
		fullScreenBtn.screenCenter();
		fullScreenBtn.text.angle -= 90;
		fullScreenBtn.scrollFactor.set(0, 0);
		fullScreenBtn.y = FlxG.height - fullScreenBtn.height;
		add(fullScreenBtn);  // We dont want this to move with the playbar

		add(playbar);
	}

    override public function update(elapsed:Float){
		var curTime:String = FlxStringUtil.formatTime(Conductor.songPosition / 1000, true);
		var songLength:String = (FlxG.sound.music != null) ? FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, true) : '???';
		var str:String =  '$curTime / $songLength' +
						  '\n\nSection: ${modcharter.curSec}' +
						  '\nBeat: ${modcharter.curBeat}' +
						  '\nStep: ${modcharter.curStep}';

		if(str != infoText.text){
			infoText.text = str;
			if(infoText.autoSize) infoText.autoSize = false;
		}

		super.update(elapsed);
    }
}