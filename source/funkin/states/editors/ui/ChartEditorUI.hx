package funkin.states.editors.ui;

import flixel.group.FlxSpriteContainer;
import flixel.util.FlxSave;
import funkin.objects.Character;
import funkin.backend.ExtraKeysHandler;
import flixel.util.FlxStringUtil;

import funkin.states.editors.content.MetaNote;
import funkin.states.editors.content.Prompt;
import funkin.states.editors.content.*;

import moonchart.formats.OsuMania;
import moonchart.formats.GuitarHero;
import moonchart.formats.StepMania;
import moonchart.formats.Quaver;
import moonchart.formats.fnf.legacy.FNFNotepulse;
import moonchart.formats.fnf.FNFCodename;
import moonchart.formats.fnf.FNFVSlice;

import haxe.Json;
import haxe.Exception;

import lime.utils.Assets;

import funkin.data.Song;
import funkin.data.StageData;
import funkin.backend.Difficulty;
import funkin.data.Section;

enum abstract WaveformTarget(String){
	var INST = 'inst';
	var PLAYER = 'voc';
	var OPPONENT = 'opp';
}

@:access(funkin.states.editors.ChartEditorState)
class ChartEditorUI extends FlxSpriteContainer implements PsychUIEventHandler.PsychUIEvent {
    private var charter:ChartEditorState;

	public var waveformTarget:WaveformTarget = INST;

	public var sliderIsDragging:Bool = false;
	public var sliderWasPlaying:Bool = false;

	public var eventsBox:PsychUIBox;
	public var songPosSlider:PsychUIVerticalSlider;
	public var mainBox:PsychUIBox;
	public var mainBoxPosition:FlxPoint = FlxPoint.get(920, 40);
	public var infoBox:PsychUIBox;
	public var infoBoxPosition:FlxPoint = FlxPoint.get(1000, 360);
	public var upperBox:PsychUIBox;

	public var infoText:FlxText;

	public var playerBoxes:Array<PsychUIBox> = [];
	public var characterDropdowns:Array<PsychUIDropDownMenu> = [];
	public var hitsoundSliders:Array<PsychUISlider> = [];
	public var lanesBox:PsychUIBox;

	public var characterBoxes:Array<PsychUIBox> = [];
	public var characters:Array<Character> = [];

	public var songNameInputText:PsychUIInputText;
	public var allowVocalsCheckBox:PsychUICheckBox;

	public var bpmStepper:PsychUINumericStepper;
	public var scrollSpeedStepper:PsychUINumericStepper;
	public var audioOffsetStepper:PsychUINumericStepper;

	public var stageDropDown:PsychUIDropDownMenu;
	public var playerDropDown:PsychUIDropDownMenu;
	public var opponentDropDown:PsychUIDropDownMenu;
	public var girlfriendDropDown:PsychUIDropDownMenu;
	public var lanesGfDropDown:PsychUIDropDownMenu;
	public var pendingLaneAdd:Bool = false;
	public var pendingLaneRemoveIndex:Int = -1;

	public var showLastGridButton:PsychUIButton;
	public var showNextGridButton:PsychUIButton;
	public var noteTypeLabelsButton:PsychUIButton;
	public var vortexEditorButton:PsychUIButton;

	public var playbackSlider:PsychUISlider;
	public var mouseSnapCheckBox:PsychUICheckBox;
	public var ignoreProgressCheckBox:PsychUICheckBox;
	public var metronomeStepper:PsychUINumericStepper;

	public var instVolumeStepper:PsychUINumericStepper;
	public var instMuteCheckBox:PsychUICheckBox;
	public var playerVolumeStepper:PsychUINumericStepper;
	public var playerMuteCheckBox:PsychUICheckBox;
	public var opponentVolumeStepper:PsychUINumericStepper;
	public var opponentMuteCheckBox:PsychUICheckBox;

	public var gameOverCharDropDown:PsychUIDropDownMenu;
	public var gameOverSndInputText:PsychUIInputText;
	public var gameOverLoopInputText:PsychUIInputText;
	public var gameOverRetryInputText:PsychUIInputText;
	public var noRGBCheckBox:PsychUICheckBox;
	public var pixel4kTextureCheckBox:PsychUICheckBox;
	public var noteTextureInputText:PsychUIInputText;
	public var noteSplashesInputText:PsychUIInputText;

	public var subdivisionsStepper:PsychUINumericStepper;
	public var modifierInput:PsychUIInputText;
	public var actionsDropdown:PsychUIDropDownMenu;
	public var timeStepper:PsychUINumericStepper;
	public var valueStepper:PsychUINumericStepper;
	public var easeInput:PsychUIInputText;
	public var playerStepper:PsychUINumericStepper;

	public var eventDropDown:PsychUIDropDownMenu;
	public var value1InputText:PsychUIInputText;
	public var value2InputText:PsychUIInputText;
	public var selectedEventText:FlxText;
	public var eventDescriptionText:FlxText;

	public var susLengthStepper:PsychUINumericStepper;
	public var strumTimeStepper:PsychUINumericStepper;
	public var noteTypeDropDown:PsychUIDropDownMenu;

	public var mustHitCheckBox:PsychUICheckBox;
	public var gfSectionCheckBox:PsychUICheckBox;
	public var altAnimSectionCheckBox:PsychUICheckBox;
	public var focusGFCheckBox:PsychUICheckBox;

	public var changeBpmCheckBox:PsychUICheckBox;
	public var changeBpmStepper:PsychUINumericStepper;
	public var beatsPerSecStepper:PsychUINumericStepper;

    public function new(charter:ChartEditorState){
        super();

        this.charter = charter;
    }

	public function createUI(){
        createSongSlider();
        createUIBoxes();
	}

	public var outputGroup:Array<FlxText> = [];
	public function showOutput(message:String, isError:Bool = false, isSave:Bool = false){
		var outputTxt = new FlxText(25, FlxG.height - 50, FlxG.width - 50, '', 20);
		outputTxt.borderSize = 2;
		outputTxt.borderStyle = OUTLINE_FAST;
		outputTxt.scrollFactor.set();
		outputTxt.alpha = 1;
		outputTxt.text = message;
		outputTxt.y = FlxG.height - outputTxt.height - 30;
		add(outputTxt);
		outputGroup.push(outputTxt);
		for(txt in outputGroup)
		{
			if(txt == null) continue;
			if(txt == outputTxt) continue;
			FlxTween.cancelTweensOf(txt, ["y"]);
			FlxTween.tween(txt, {y: txt.y - 35}, 0.2, {ease: FlxEase.cubeOut});
		}
		if(isError)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			outputTxt.color = FlxColor.RED;
		}
		else if(isSave)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
			outputTxt.color = FlxColor.GREEN;
		}
		else
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			outputTxt.color = FlxColor.WHITE;
		}
		FlxTween.tween(outputTxt, {alpha: 0}, 5, {ease: FlxEase.cubeIn, onComplete: function(twn:FlxTween)
		{
			outputGroup.remove(outputTxt);
			outputTxt.destroy();
		}});
	}

	public function isOverlapping():Bool {
		var overlapsUI:Bool = false;

		if(FlxG.mouse.overlaps(mainBox.bg, charter.camUI) || FlxG.mouse.overlaps(infoBox.bg, charter.camUI) || FlxG.mouse.overlaps(lanesBox.bg, FlxG.camera)) overlapsUI = true;
		for(box in playerBoxes) if(FlxG.mouse.overlaps(box.bg, FlxG.camera)) overlapsUI = true;
		for(box in characterBoxes) if(FlxG.mouse.overlaps(box.bg, charter.camUI)) overlapsUI = true;
		for(dropdown in characterDropdowns) if(FlxG.mouse.overlaps(dropdown.bg, FlxG.camera)) overlapsUI = true;
		if(lanesGfDropDown != null && FlxG.mouse.overlaps(lanesGfDropDown.bg, FlxG.camera)) overlapsUI = true;

		return overlapsUI;
	}
	
	function addSongTab()
	{
		var tab_group = mainBox.getTab('Song').menu;
		var objX = 10;
		var objY = 25;

		songNameInputText = new PsychUIInputText(objX, objY, 100, 'None', 8);
		songNameInputText.onChange = function(old:String, cur:String) PlayState.SONG.song = cur;

		allowVocalsCheckBox = new PsychUICheckBox(objX, objY + 20, 'Allow Vocals', 80, function()
		{
			PlayState.SONG.needsVoices = allowVocalsCheckBox.checked;
			charter.loadMusic();
		});
		var reloadAudioButton:PsychUIButton = new PsychUIButton(objX + 120, objY, 'Reload Audio', function() charter.loadMusic(true), 80);

		#if mac
		var reloadJsonButton:PsychUIButton = new PsychUIButton(objX + 205, objY, 'Reload JSON', function()
		{
			var cur = Paths.formatToSongPath(songNameInputText.text);
			var curdiff = Highscore.formatSong(cur, PlayState.storyDifficulty);
			var diff = false;
			var loadedChart:SwagSong = try {
				diff = true;
				Song.getChart(curdiff, cur);
			} catch (e) {
				diff = false;
				Song.getChart(cur, cur);
			}
			if(loadedChart == null || !Reflect.hasField(loadedChart, 'song')) //Check if chart is ACTUALLY a chart and valid
			{
				showOutput('Error: File loaded is not a Psych Engine/FNF 0.2.x.x chart.', true);
				return;
			}

			var func:Void->Void = function()
			{
				loadChart(loadedChart);
				Song.chartPath = diff ? curdiff : cur;
				reloadNotesDropdowns();
				prepareReload();
				showOutput('Opened chart "${diff ? curdiff : cur}" successfully!');
			}
					
			if(!ignoreProgressCheckBox.checked){
				FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
				openSubState(new Prompt('Warning: Any unsaved progress\nwill be lost.', func));
			} else func();
		}, 80);
		#end

		objY += 65;
		//(x:Float = 0, y:Float = 0, step:Float = 1, defValue:Float = 0, min:Float = -999, max:Float = 999, decimals:Int = 0, ?wid:Int = 60, ?isPercent:Bool = false)
		bpmStepper = new PsychUINumericStepper(objX, objY, 1, 1, 1, 400, 3);
		bpmStepper.onValueChange = function()
		{
			var oldTimes:Array<Float> = charter.cachedSectionTimes.copy();
			PlayState.SONG.bpm = bpmStepper.value;
			charter.adaptNotesToNewTimes(oldTimes);
		};

		scrollSpeedStepper = new PsychUINumericStepper(objX + 90, objY, 0.1, 1, 0.1, 10, 2);
		scrollSpeedStepper.onValueChange = function() PlayState.SONG.speed = scrollSpeedStepper.value;

		var stepperMania = new PsychUINumericStepper(objX + 180, objY, 1, PlayState.SONG.mania, ExtraKeysHandler.instance.data.minKeys, ExtraKeysHandler.instance.data.maxKeys, 1);
		stepperMania.value = PlayState.SONG.mania;
		stepperMania.onValueChange = function(){
			var oldColumns:Int = ChartEditorState.GRID_COLUMNS_PER_PLAYER;
			var newMania:Int = Std.int(stepperMania.value);
			var newColumns:Int = newMania + 1;

			if(oldColumns == newColumns) return;

			for (section in PlayState.SONG.notes){ // We need to remap the notes ig
				for (note in section.sectionNotes){
					if(note == null) continue;

					var daID:Int = (note[4] == null) ? Std.int(note[1] / oldColumns) : Std.int(note[4]);
					var daNoteData:Int = Std.int(note[1] % oldColumns);

					if(daNoteData >= newColumns) daNoteData = newColumns - 1;

					note[4] = daID;
					note[1] = daNoteData + (daID * newColumns);
				}
			}

			PlayState.SONG.mania = newMania;
			ChartEditorState.GRID_COLUMNS_PER_PLAYER = newColumns;
			charter.createGrids();
			charter.reloadNotes();
			charter.loadSection();
			remove(charter.mustHitIndicator); add(charter.mustHitIndicator);
		};

		audioOffsetStepper = new PsychUINumericStepper(objX, objY + 40, 1, 0, -500, 500, 0);
		audioOffsetStepper.onValueChange = function(){
			Reflect.setField(PlayState.SONG, "offset", audioOffsetStepper.value);
			Conductor.offset = audioOffsetStepper.value;
			charter.updateWaveform();
		};

		tab_group.add(new FlxText(songNameInputText.x, songNameInputText.y - 15, 80, 'Song Name:'));
		tab_group.add(songNameInputText);
		tab_group.add(allowVocalsCheckBox);
		tab_group.add(reloadAudioButton);
		#if mac
		tab_group.add(reloadJsonButton);
		#end

		// Find characters
		var characters:Array<String> = [];
		//
		
		objY += 40;
		stageDropDown = new PsychUIDropDownMenu(objX, objY + 40, [''], function(id:Int, stage:String)
		{
			PlayState.SONG.stage = stage;
			StageData.loadDirectory(PlayState.SONG);
		});
		
		tab_group.add(new FlxText(stepperMania.x, stepperMania.y - 15, 80, 'Mania:'));
		tab_group.add(new FlxText(bpmStepper.x, bpmStepper.y - 15, 50, 'BPM:'));
		tab_group.add(new FlxText(scrollSpeedStepper.x, scrollSpeedStepper.y - 15, 80, 'Scroll Speed:'));
		tab_group.add(new FlxText(audioOffsetStepper.x, audioOffsetStepper.y - 15, 100, 'Audio Offset (ms):'));
		tab_group.add(stepperMania);
		tab_group.add(bpmStepper);
		tab_group.add(scrollSpeedStepper);
		tab_group.add(audioOffsetStepper);
		tab_group.add(new FlxText(stageDropDown.x, stageDropDown.y - 15, 80, 'Stage:'));
		tab_group.add(stageDropDown);
	}

	function addFileTab()
	{
		var tab = upperBox.getTab('File');
		var tab_group = tab.menu;
		var btnX = tab.x - upperBox.x;
		var btnY = 1;
		var btnWid = Std.int(tab.width);

		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  New', function()
		{
			var func:Void->Void = function()
			{
				charter.openNewChart();
				reloadNotesDropdowns();
				charter.prepareReload();
			}

			if(!ignoreProgressCheckBox.checked){
				FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
				charter.openSubState(new Prompt('Are you sure you want to start over?', func));
			} else func();
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		if(ChartEditorState.SHOW_EVENT_COLUMN)
		{
			btnY++;
			btnY += 20;
			var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Open Events...', function()
			{
				if(!charter.fileDialog.completed) return;
				upperBox.isMinimized = true;
				upperBox.bg.visible = false;
	
				charter.fileDialog.open(function()
				{
					try
					{
						var filePath:String = charter.fileDialog.path.replace('\\', '/');
						var raw:Dynamic = Json.parse(charter.fileDialog.data);

						if (raw == null || raw.song == null || raw.song.events == null || raw.songSpeed != null)
						{
							showOutput('Error: File loaded is not a Psych Engine events file.', true);
							return;
						}
	
						var loadedEvents:Array<Dynamic> = raw.song.events;
						if(loadedEvents.length < 1)
						{
							showOutput('Events file loaded is empty.', true);
							return;
						}
	
						FlxG.sound.play(Paths.sound('chartingSounds/openWindow'));
						charter.openSubState(new BasePrompt('Events Found! Choose an action.',
							function(state:BasePrompt)
							{
								var btnY = 390;
								var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Replace All', function()
								{
									for (event in charter.events)
									{
										if(event != null)
										{
											event.destroy();
											charter.selectedNotes.remove(event);
										}
									}
									charter.undoActions = [];
									charter.events = [];
	
									for (event in loadedEvents)
										charter.events.push(charter.createEvent(event));
	
									charter.softReloadNotes();
									state.close();
									showOutput('Events loaded successfully!');
								});
								btn.normalStyle.bgColor = FlxColor.RED;
								btn.normalStyle.textColor = FlxColor.WHITE;
								btn.screenCenter(X);
								btn.x -= 125;
								btn.cameras = state.cameras;
								state.add(btn);
								
								var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Add', function()
								{
									for (event in loadedEvents)
										charter.events.push(charter.createEvent(event));
	
									charter.softReloadNotes();
									state.close();
									showOutput('Events added successfully!');
								});
								btn.screenCenter(X);
								btn.cameras = state.cameras;
								state.add(btn);
						
								var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Cancel', state.close);
								btn.screenCenter(X);
								btn.x += 125;
								btn.cameras = state.cameras;
								state.add(btn);
							}
						));
					}
					catch(e:Exception)
					{
						showOutput('Error: ${e.message}', true);
					}
				});
			}, btnWid);
			btn.text.alignment = LEFT;
			tab_group.add(btn);
		}

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save', function()
		{
			if(!charter.fileDialog.completed) return;
			upperBox.isMinimized = true;
			upperBox.bg.visible = false;

			charter.saveChart();
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save as...', function()
		{
			if(!charter.fileDialog.completed) return;
			upperBox.isMinimized = true;
			upperBox.bg.visible = false;

			charter.saveChart(false);
		},btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		if(ChartEditorState.SHOW_EVENT_COLUMN)
		{
			btnY += 20;
			var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Save Events...', function()
			{
				if(!charter.fileDialog.completed) return;
				upperBox.isMinimized = true;
	
				charter.updateChartData();
				charter.fileDialog.save('events.json', PsychJsonPrinter.print({events: PlayState.SONG.events, format: 'notepulse'}, ['events']),
					function() showOutput('Events saved successfully to: ${charter.fileDialog.path}', false, true), null,
					function() showOutput('Error on saving events!', true));
			}, btnWid);
			btn.text.alignment = LEFT;
			tab_group.add(btn);
		}

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Reload Chart', function()
		{
			var func:Void->Void = function()
			{
				if(Song.chartPath == null)
				{
					showOutput('You must save/load a Chart first to Reload it!', true);
					return;
				}
	
				if(FileSystem.exists(Song.chartPath))
				{
					try
					{
						MusicBeatState.switchState(new LoadingState(new ChartEditorState(), true));
						LoadingState.prepareToSong();
					}
					catch(e:Exception)
					{
						showOutput('Error: ${e.message}', true);
					}
				}
				else showOutput('You must save/load a Chart first to Reload it!', true);
			}

			if(!ignoreProgressCheckBox.checked){
				FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
				charter.openSubState(new Prompt('Warning: Any unsaved progress will be lost', func));
		    } else func();
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Import from V-Slice', function()
		{
			if(upperBox != null) {
				upperBox.isMinimized = true;
				if(upperBox.bg != null) upperBox.bg.visible = false;
			}

			var chartFile:openfl.net.FileReference = new openfl.net.FileReference();
			var jsonFilter:openfl.net.FileFilter = new openfl.net.FileFilter("JSON Files (*.json)", "*.json");

			chartFile.addEventListener(openfl.events.Event.SELECT, function(e:openfl.events.Event)
			{
				var pathToChart:String = @:privateAccess chartFile.__path;
				if (pathToChart == null || pathToChart.toLowerCase().contains('meta')) {
					showOutput('Error: Please select the chart file first.', true);
					return;
				}
				
				var metaFile:openfl.net.FileReference = new openfl.net.FileReference();
				
				metaFile.addEventListener(openfl.events.Event.SELECT, function(e2:openfl.events.Event)
				{
					var pathToMeta:String = @:privateAccess metaFile.__path;
					if (pathToMeta == null || !pathToMeta.toLowerCase().contains('meta')) {
						showOutput('Error: The file must be a valid metadata file.', true);
						return;
					}

					try {
						var vsliceChart = new FNFVSlice().fromFile(pathToChart, pathToMeta);
						var finalChart = new FNFNotepulse().fromFormat(vsliceChart);
						
						if (finalChart == null || finalChart.data == null || finalChart.data.song == null) {
							showOutput('Error: The chart data conversion failed.', true);
							return;
						}
						
						var loadedChart:SwagSong = cast finalChart.data.song;
						
						if(!Reflect.hasField(loadedChart, 'notes'))
						{
							showOutput('Error: The loaded chart does not contain valid notes.', true);
							return;
						}
						
						var func:Void->Void = function()
						{
							var formattedPath:String = pathToChart.replace('\\', '/');
							charter.loadChart(loadedChart);
							Song.chartPath = null;
							reloadNotesDropdowns();
							charter.prepareReload();
							showOutput('Imported V-Slice chart successfully!');
						}
						
						var ignoreProgress:Bool = false;
						if(ignoreProgressCheckBox != null) {
							ignoreProgress = ignoreProgressCheckBox.checked;
						}
						
						if(!ignoreProgress)
						{
							if(FlxG.sound != null) FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
							charter.openSubState(new Prompt('Warning: This will overwrite the current chart.\nAny unsaved progress\nwill be lost.', func));
						}
						else func();
					}
					catch(err:Dynamic)
					{
						showOutput('ERROR: ${err}', true);
					}
				});

				metaFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
					showOutput('Metadata file selection cancelled.', true);
				});

				metaFile.browse([jsonFilter]);
			});

			chartFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
				showOutput('Chart file selection cancelled.', true);
			});

			chartFile.browse([jsonFilter]);

		}, btnWid);

		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Import from CNE', function()
		{
			if(upperBox != null) {
				upperBox.isMinimized = true;
				if(upperBox.bg != null) upperBox.bg.visible = false;
			}

			var chartFile:openfl.net.FileReference = new openfl.net.FileReference();
			var jsonFilter:openfl.net.FileFilter = new openfl.net.FileFilter("JSON Files (*.json)", "*.json");

			chartFile.addEventListener(openfl.events.Event.SELECT, function(e:openfl.events.Event)
			{
				var pathToChart:String = @:privateAccess chartFile.__path;
				if (pathToChart == null || pathToChart.toLowerCase().contains('meta')) {
					showOutput('Error: Please select the chart file first.', true);
					return;
				}
				
				var metaFile:openfl.net.FileReference = new openfl.net.FileReference();
				
				metaFile.addEventListener(openfl.events.Event.SELECT, function(e2:openfl.events.Event)
				{
					var pathToMeta:String = @:privateAccess metaFile.__path;
					if (pathToMeta == null || !pathToMeta.toLowerCase().contains('meta')) {
						showOutput('Error: The file must be a valid metadata file.', true);
						return;
					}

					try
					{
						var cneChart = new FNFCodename().fromFile(pathToChart, pathToMeta);
						var finalChart = new FNFNotepulse().fromFormat(cneChart);
						
						if (finalChart == null || finalChart.data == null || finalChart.data.song == null) {
							showOutput('Error: The chart data conversion failed.', true);
							return;
						}
						
						var loadedChart:SwagSong = cast finalChart.data.song;
						
						if(!Reflect.hasField(loadedChart, 'notes'))
						{
							showOutput('Error: The loaded chart does not contain valid notes.', true);
							return;
						}
						
						var func:Void->Void = function()
						{
							var formattedPath:String = pathToChart.replace('\\', '/');
							charter.loadChart(loadedChart);
							Song.chartPath = null;
							reloadNotesDropdowns();
							charter.prepareReload();
							showOutput('Imported Codename Engine chart successfully!');
						}
						
						var ignoreProgress:Bool = false;
						if(ignoreProgressCheckBox != null) {
							ignoreProgress = ignoreProgressCheckBox.checked;
						}
						
						if(!ignoreProgress)
						{
							if(FlxG.sound != null) FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
							charter.openSubState(new Prompt('Warning: This will overwrite the current chart.\nAny unsaved progress\nwill be lost.', func));
						}
						else func();
					}
					catch(err:Dynamic)
					{
						showOutput('ERROR: ${err}', true);
					}
				});

				metaFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
					showOutput('Metadata file selection cancelled.', true);
				});

				metaFile.browse([jsonFilter]);
			});

			chartFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
				showOutput('Chart file selection cancelled.', true);
			});

			chartFile.browse([jsonFilter]);

		}, btnWid);

		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Import from Osu', function()
		{
			if(upperBox != null) {
				upperBox.isMinimized = true;
				if(upperBox.bg != null) upperBox.bg.visible = false;
			}

			var chartFile:openfl.net.FileReference = new openfl.net.FileReference();
			var oszFilter:openfl.net.FileFilter = new openfl.net.FileFilter("OSU Files (*.osu)", "*.osu");

			chartFile.addEventListener(openfl.events.Event.SELECT, function(e:openfl.events.Event)
			{
				var pathToChart:String = @:privateAccess chartFile.__path;
				if (pathToChart == null) {
					showOutput('Error: Please select a valid Osu Mania chart file.', true);
					return;
				}
				
				try {
					var osuChart = new OsuMania().fromFile(pathToChart);
					var finalChart = new FNFNotepulse().fromFormat(osuChart);
						
					if (finalChart == null || finalChart.data == null || finalChart.data.song == null) {
						showOutput('Error: The chart data conversion failed.', true);
						return;
					}
						
					var loadedChart:SwagSong = cast finalChart.data.song;
						
					if(!Reflect.hasField(loadedChart, 'notes'))
					{
						showOutput('Error: The loaded chart does not contain valid notes.', true);
						return;
					}
						
					var func:Void->Void = function()
					{
						var formattedPath:String = pathToChart.replace('\\', '/');
						charter.loadChart(loadedChart);
						Song.chartPath = null;
						reloadNotesDropdowns();
						charter.prepareReload();
						showOutput('Imported Osu Mania chart successfully!');
					}
						
					var ignoreProgress:Bool = false;
					if(ignoreProgressCheckBox != null) {
						ignoreProgress = ignoreProgressCheckBox.checked;
					}
						
					if(!ignoreProgress)
					{
						if(FlxG.sound != null) FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
						charter.openSubState(new Prompt('Warning: This will overwrite the current chart.\nAny unsaved progress\nwill be lost.', func));
					}
					else func();
				}
				catch(err:Dynamic){
					showOutput('ERROR: ${err}', true);
				}
			});

			chartFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
				showOutput('Chart file selection cancelled.', true);
			});

			chartFile.browse([oszFilter]);

		}, btnWid);

		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Import from Guitar', function()
		{
			if(upperBox != null) {
				upperBox.isMinimized = true;
				if(upperBox.bg != null) upperBox.bg.visible = false;
			}

			var chartFile:openfl.net.FileReference = new openfl.net.FileReference();
			var chartFilter:openfl.net.FileFilter = new openfl.net.FileFilter("Guitar Hero Files (*.chart)", "*.chart");

			chartFile.addEventListener(openfl.events.Event.SELECT, function(e:openfl.events.Event)
			{
				var pathToChart:String = @:privateAccess chartFile.__path;
				if (pathToChart == null) {
					showOutput('Error: Please select a valid Guitar Hero chart file.', true);
					return;
				}
				
				try {
					var guitarChart = new GuitarHero().fromFile(pathToChart);
					var finalChart = new FNFNotepulse().fromFormat(guitarChart);
						
					if (finalChart == null || finalChart.data == null || finalChart.data.song == null) {
						showOutput('Error: The chart data conversion failed.', true);
						return;
					}
						
					var loadedChart:SwagSong = cast finalChart.data.song;
						
					if(!Reflect.hasField(loadedChart, 'notes'))
					{
						showOutput('Error: The loaded chart does not contain valid notes.', true);
						return;
					}
						
					var func:Void->Void = function()
					{
						var formattedPath:String = pathToChart.replace('\\', '/');
						charter.loadChart(loadedChart);
						Song.chartPath = null;
						reloadNotesDropdowns();
						charter.prepareReload();
						showOutput('Imported Guitar Hero chart successfully!');
					}
						
					var ignoreProgress:Bool = false;
					if(ignoreProgressCheckBox != null) {
						ignoreProgress = ignoreProgressCheckBox.checked;
					}
						
					if(!ignoreProgress)
					{
						if(FlxG.sound != null) FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
						charter.openSubState(new Prompt('Warning: This will overwrite the current chart.\nAny unsaved progress\nwill be lost.', func));
					}
					else func();
				}
				catch(err:Dynamic){
					showOutput('ERROR: ${err}', true);
				}
			});

			chartFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
				showOutput('Chart file selection cancelled.', true);
			});

			chartFile.browse([chartFilter]);

		}, btnWid);

		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Import from SM', function()
		{
			if(upperBox != null) {
				upperBox.isMinimized = true;
				if(upperBox.bg != null) upperBox.bg.visible = false;
			}

			var chartFile:openfl.net.FileReference = new openfl.net.FileReference();
			var smFilter:openfl.net.FileFilter = new openfl.net.FileFilter("Step Mania Files (*.sm)", "*.sm");

			chartFile.addEventListener(openfl.events.Event.SELECT, function(e:openfl.events.Event)
			{
				var pathToChart:String = @:privateAccess chartFile.__path;
				if (pathToChart == null) {
					showOutput('Error: Please select a valid Step Mania chart file.', true);
					return;
				}
				
				try {
					var guitarChart = new StepMania().fromFile(pathToChart);
					var finalChart = new FNFNotepulse().fromFormat(guitarChart);
						
					if (finalChart == null || finalChart.data == null || finalChart.data.song == null) {
						showOutput('Error: The chart data conversion failed.', true);
						return;
					}
						
					var loadedChart:SwagSong = cast finalChart.data.song;
						
					if(!Reflect.hasField(loadedChart, 'notes'))
					{
						showOutput('Error: The loaded chart does not contain valid notes.', true);
						return;
					}
						
					var func:Void->Void = function()
					{
						var formattedPath:String = pathToChart.replace('\\', '/');
						charter.loadChart(loadedChart);
						Song.chartPath = null;
						reloadNotesDropdowns();
						charter.prepareReload();
						showOutput('Imported Step Mania chart successfully!');
					}
						
					var ignoreProgress:Bool = false;
					if(ignoreProgressCheckBox != null) {
						ignoreProgress = ignoreProgressCheckBox.checked;
					}
						
					if(!ignoreProgress)
					{
						if(FlxG.sound != null) FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
						charter.openSubState(new Prompt('Warning: This will overwrite the current chart.\nAny unsaved progress\nwill be lost.', func));
					}
					else func();
				}
				catch(err:Dynamic){
					showOutput('ERROR: ${err}', true);
				}
			});

			chartFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
				showOutput('Chart file selection cancelled.', true);
			});

			chartFile.browse([smFilter]);

		}, btnWid);

		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Import from Quaver', function()
		{
			if(upperBox != null) {
				upperBox.isMinimized = true;
				if(upperBox.bg != null) upperBox.bg.visible = false;
			}

			var chartFile:openfl.net.FileReference = new openfl.net.FileReference();
			var quaFilter:openfl.net.FileFilter = new openfl.net.FileFilter("Quaver Files (*.qua)", "*.qua");

			chartFile.addEventListener(openfl.events.Event.SELECT, function(e:openfl.events.Event)
			{
				var pathToChart:String = @:privateAccess chartFile.__path;
				if (pathToChart == null) {
					showOutput('Error: Please select a valid Quaver chart file.', true);
					return;
				}
				
				try {
					var guitarChart = new Quaver().fromFile(pathToChart);
					var finalChart = new FNFNotepulse().fromFormat(guitarChart);
						
					if (finalChart == null || finalChart.data == null || finalChart.data.song == null) {
						showOutput('Error: The chart data conversion failed.', true);
						return;
					}
						
					var loadedChart:SwagSong = cast finalChart.data.song;
						
					if(!Reflect.hasField(loadedChart, 'notes'))
					{
						showOutput('Error: The loaded chart does not contain valid notes.', true);
						return;
					}
						
					var func:Void->Void = function()
					{
						var formattedPath:String = pathToChart.replace('\\', '/');
						charter.loadChart(loadedChart);
						Song.chartPath = null;
						reloadNotesDropdowns();
						charter.prepareReload();
						showOutput('Imported Quaver chart successfully!');
					}
						
					var ignoreProgress:Bool = false;
					if(ignoreProgressCheckBox != null) {
						ignoreProgress = ignoreProgressCheckBox.checked;
					}
						
					if(!ignoreProgress)
					{
						if(FlxG.sound != null) FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
						charter.openSubState(new Prompt('Warning: This will overwrite the current chart.\nAny unsaved progress\nwill be lost.', func));
					}
					else func();
				}
				catch(err:Dynamic){
					showOutput('ERROR: ${err}', true);
				}
			});

			chartFile.addEventListener(openfl.events.Event.CANCEL, function(e:openfl.events.Event) {
				showOutput('Chart file selection cancelled.', true);
			});

			chartFile.browse([quaFilter]);

		}, btnWid);

		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Preview (F12)', charter.editorPlayStatePrompt, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);
		
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Playtest (Enter)', charter.goToPlayState, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Exit', function()
		{
			if(!ignoreProgressCheckBox.checked){
				FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
				charter.openSubState(new Prompt("Are you sure you want to exit the Chart Editor?\nAny unsaved progress will be lost.", function() {
					PlayState.chartingMode = false;
					MusicBeatState.switchState(new MainMenuState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}));
			} else {
				PlayState.chartingMode = false;
				MusicBeatState.switchState(new MainMenuState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);
	}

	function addEditTab()
	{
		var tab = upperBox.getTab('Edit');
		var tab_group = tab.menu;
		var btnX = tab.x - upperBox.x;
		var btnY = 1;
		var btnWid = Std.int(tab.width);

		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Undo', charter.undo, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Redo', charter.redo, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Select All', function()
		{
			var sel = charter.selectedNotes;
			charter.selectedNotes = charter.curRenderedNotes.members.copy();
			charter.addUndoAction(SELECT_NOTE, {old: sel, current: charter.selectedNotes.copy()});
			charter.onSelectNote();
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		if(ChartEditorState.SHOW_EVENT_COLUMN)
		{
			btnY++;
			btnY += 20;
			var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Lock Events', btnWid);
			btn.onClick = function()
			{
				charter.lockedEvents = !charter.lockedEvents;
				if(charter.lockedEvents) btn.text.text = '  Unlock Events';
				else btn.text.text = '  Lock Events';
				charter.eventLockOverlay.visible = charter.lockedEvents;
	
				if(charter.selectedNotes.length >= 1)
				{
					var sel = charter.selectedNotes;
					var onlyNotes = charter.selectedNotes.filter((note:MetaNote) -> !note.isEvent);
					charter.resetSelectedNotes();
					charter.selectedNotes = onlyNotes;
					charter.addUndoAction(SELECT_NOTE, {old: sel, current: charter.selectedNotes.copy()});
					if(charter.selectedNotes.length == 1) charter.onSelectNote();
				}
				charter.softReloadNotes();
			};
			btn.text.alignment = LEFT;
			tab_group.add(btn);
		}
		
		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Autosave Settings...', btnWid);
		btn.onClick = function()
		{
			upperBox.isMinimized = true;
			upperBox.bg.visible = false;
			FlxG.sound.play(Paths.sound('chartingSounds/openWindow'));
			charter.openSubState(new BasePrompt(400, 160, 'Autosave Settings',
				function(state:BasePrompt)
				{
					var btn:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'X', state.close, 40);
					btn.cameras = state.cameras;
					state.add(btn);

					var checkbox:PsychUICheckBox = null;
					var timeStepper:PsychUINumericStepper = null;

					timeStepper = new PsychUINumericStepper(state.bg.x + 50, state.bg.y + 90, 1, charter.autoSaveCap, 1, 30, 0);
					timeStepper.onValueChange = function() {
						charter.autoSaveTime = 0;
						checkbox.checked = true;
						charter.autoSaveCap = charter.chartEditorSave.data.autoSave = Std.int(timeStepper.value);
					};
					timeStepper.cameras = state.cameras;

					checkbox = new PsychUICheckBox(timeStepper.x + 80, timeStepper.y, 'Enabled', 60, function() {
						charter.autoSaveTime = 0;
						charter.autoSaveCap = charter.chartEditorSave.data.autoSave = checkbox.checked ? Std.int(timeStepper.value) : 0;
					});
					checkbox.checked = (charter.autoSaveCap > 0);
					checkbox.cameras = state.cameras;
					
					var maxFileStepper:PsychUINumericStepper = new PsychUINumericStepper(checkbox.x + 140, checkbox.y, 1, charter.backupLimit, 0, 50, 0);
					maxFileStepper.onValueChange = function() {
						charter.autoSaveTime = 0;
						checkbox.checked = true;
						charter.chartEditorSave.data.backupLimit = charter.backupLimit = Std.int(maxFileStepper.value);
					};
					maxFileStepper.cameras = state.cameras;

					var txt1:FlxText = new FlxText(timeStepper.x, timeStepper.y - 15, 100, 'Time (in minutes):');
					txt1.cameras = state.cameras;
					var txt2:FlxText = new FlxText(maxFileStepper.x, maxFileStepper.y - 15, 100, 'File Limit:');
					txt2.cameras = state.cameras;

					state.add(txt1);
					state.add(txt2);
					state.add(checkbox);
					state.add(timeStepper);
					state.add(maxFileStepper);
				}
			));

		};
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Clear All Notes', function()
		{
			var func:Void->Void = function()
			{
				charter.resetSelectedNotes();
				charter.addUndoAction(DELETE_NOTE, {notes: charter.notes.copy()});
				charter.notes = [];
				charter.loadSection();
			}

			if(!ignoreProgressCheckBox.checked){
				FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
				charter.openSubState(new Prompt('Delete all Notes in the song?', func));
			} else func();
		}, btnWid);
		btn.normalStyle.bgColor = FlxColor.RED;
		btn.normalStyle.textColor = FlxColor.WHITE;
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		if(ChartEditorState.SHOW_EVENT_COLUMN)
		{
			btnY += 20;
			var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Clear All Events', function()
			{
				var func:Void->Void = function()
				{
					charter.resetSelectedNotes();
					charter.addUndoAction(DELETE_NOTE, {events: charter.events.copy()});
					charter.events = [];
					charter.loadSection();
				}
	
				if(!ignoreProgressCheckBox.checked){
					FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
					charter.openSubState(new Prompt('Delete all Events in the song?', func));
				} else func();
			}, btnWid);
			btn.normalStyle.bgColor = FlxColor.RED;
			btn.normalStyle.textColor = FlxColor.WHITE;
			btn.text.alignment = LEFT;
			tab_group.add(btn);
		}
	}

	function addViewTab()
	{
		var tab = upperBox.getTab('View');
		var tab_group = tab.menu;
		var btnX = tab.x - upperBox.x;
		var btnY = 1;
		var btnWid = Std.int(tab.width);

		if(charter.chartEditorSave.data.waveformEnabled != null)
			charter.waveformEnabled = charter.chartEditorSave.data.waveformEnabled;
		if(charter.chartEditorSave.data.waveformTarget != null)
			waveformTarget = charter.chartEditorSave.data.waveformTarget;
		if(charter.chartEditorSave.data.waveformColor != null)
			charter.waveformSprite.color = CoolUtil.colorFromString(charter.chartEditorSave.data.waveformColor);

		showLastGridButton = new PsychUIButton(btnX, btnY, '', function()
		{
			charter.showPreviousSection = !charter.showPreviousSection;
			charter.updateGridVisibility();
		}, btnWid);
		showLastGridButton.text.alignment = LEFT;
		tab_group.add(showLastGridButton);

		btnY += 20;
		showNextGridButton = new PsychUIButton(btnX, btnY, '', function()
		{
			charter.showNextSection = !charter.showNextSection;
			charter.updateGridVisibility();
		}, btnWid);
		showNextGridButton.text.alignment = LEFT;
		tab_group.add(showNextGridButton);

		btnY++;
		btnY += 20;
		noteTypeLabelsButton = new PsychUIButton(btnX, btnY, '', function()
		{
			charter.showNoteTypeLabels = !charter.showNoteTypeLabels;
			charter.updateGridVisibility();
		}, btnWid);
		noteTypeLabelsButton.text.alignment = LEFT;
		tab_group.add(noteTypeLabelsButton);

		btnY++;
		btnY += 20;
		vortexEditorButton = new PsychUIButton(btnX, btnY, charter.vortexEnabled ? '  Vortex Editor ON' : '  Vortex Editor OFF', function()
		{
			charter.vortexEnabled = !charter.vortexEnabled;
			charter.chartEditorSave.data.vortex = charter.vortexEnabled;
			charter.vortexIndicator.visible = charter.strumLineNotes.visible = charter.strumLineNotes.active = charter.vortexEnabled;
			vortexEditorButton.text.text = charter.vortexEnabled ? '  Vortex Editor ON' : '  Vortex Editor OFF';

			for (note in charter.strumLineNotes)
			{
				note.playAnim('static');
				note.resetAnim = 0;
			}
			charter.prevGridBg.vortexLineEnabled = charter.gridBg.vortexLineEnabled = charter.nextGridBg.vortexLineEnabled = charter.vortexEnabled;
		}, btnWid);
		vortexEditorButton.text.alignment = LEFT;
		tab_group.add(vortexEditorButton);
		
		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Waveform...', function()
		{
			ClientPrefs.toggleVolumeKeys(false);
			FlxG.sound.play(Paths.sound('chartingSounds/openWindow'));
			charter.openSubState(new BasePrompt(320, 200, 'Waveform Settings',
				function(state:BasePrompt) {
					upperBox.isMinimized = true;
					upperBox.bg.visible = false;

					var btn:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'X', state.close, 40);
					btn.cameras = state.cameras;
					state.add(btn);

					var check:PsychUICheckBox = new PsychUICheckBox(state.bg.x + 40, state.bg.y + 80, 'Enabled', 60);
					check.onClick = function()
					{
						charter.chartEditorSave.data.waveformEnabled = charter.waveformEnabled = check.checked;
						charter.updateWaveform();
					};
					check.cameras = state.cameras;
					check.checked = charter.waveformEnabled;
					state.add(check);

					var waveformC:String = '0000FF';
					if(charter.chartEditorSave.data.waveformColor != null)
						waveformC = charter.chartEditorSave.data.waveformColor;

					var input:PsychUIInputText = new PsychUIInputText(check.x, check.y + 50, 60, waveformC, 10);
					input.onChange = function(old:String, cur:String)
					{
						charter.chartEditorSave.data.waveformColor = cur;
						charter.waveformSprite.color = CoolUtil.colorFromString(cur);
					}
					input.maxLength = 6;
					input.filterMode = ONLY_HEXADECIMAL;
					input.cameras = state.cameras;
					input.forceCase = UPPER_CASE;

					var options:Array<WaveformTarget> = [INST, PLAYER, OPPONENT];
					var radioGrp:PsychUIRadioGroup = new PsychUIRadioGroup(check.x + 120, check.y, ['Instrumental', 'Main Vocals', 'Opponent Vocals']);
					radioGrp.cameras = state.cameras;
					radioGrp.onClick = function()
					{
						waveformTarget = charter.chartEditorSave.data.waveformTarget = options[radioGrp.checked];
						charter.updateWaveform();
					};
					radioGrp.checked = options.indexOf(waveformTarget);
					state.add(radioGrp);

					var txt1:FlxText = new FlxText(input.x, input.y - 15, 80, 'Color (Hex):');
					txt1.cameras = state.cameras;
					state.add(txt1);
					state.add(input);
				}
			));
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Go to...', function()
		{
			upperBox.isMinimized = true;
			upperBox.bg.visible = false;
			FlxG.sound.play(Paths.sound('chartingSounds/openWindow'));
			charter.openSubState(new BasePrompt(420, 200, 'Go to Time/Section:',
				function(state:BasePrompt)
				{
					var curTime:Float = Conductor.songPosition;
					var currentSec:Int = charter.curSec;

					var timeStepper:PsychUINumericStepper = new PsychUINumericStepper(state.bg.x + 100, state.bg.y + 90, 1, Math.floor(curTime)/1000, 0, FlxG.sound.music.length/1000 - 0.01, 2, 80);
					timeStepper.cameras = state.cameras;
					var sectionStepper:PsychUINumericStepper = new PsychUINumericStepper(timeStepper.x + 160, timeStepper.y, 1, currentSec, 0, PlayState.SONG.notes.length - 1, 0);
					sectionStepper.cameras = state.cameras;

					var txt1:FlxText = new FlxText(timeStepper.x, timeStepper.y - 15, 100, 'Time (in seconds):');
					var txt2:FlxText = new FlxText(sectionStepper.x, sectionStepper.y - 15, 100, 'Section:');
					txt1.cameras = state.cameras;
					txt2.cameras = state.cameras;
					state.add(txt1);
					state.add(txt2);
					state.add(timeStepper);
					state.add(sectionStepper);

					var timeTxt:FlxText = new FlxText(15, state.bg.y + state.bg.height - 75, 230, '', 16);
					timeTxt.alignment = CENTER;
					timeTxt.screenCenter(X);
					timeTxt.cameras = state.cameras;
					state.add(timeTxt);
					function updateTime()
					{
						var tm:String = FlxStringUtil.formatTime(curTime / 1000, true);
						var ln:String = FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, true);
						timeTxt.text = '$tm / $ln';
					}
					updateTime();

					timeStepper.onValueChange = function()
					{
						curTime = timeStepper.value * 1000;
						for (i => time in charter.cachedSectionTimes)
						{
							if(time <= curTime)
								currentSec = i;
							else break;
						}
						updateTime();
					};
					sectionStepper.onValueChange = function()
					{
						currentSec = Std.int(sectionStepper.value);
						curTime = charter.cachedSectionTimes[currentSec] + 0.000001;
						updateTime();
					};

					var btn:PsychUIButton = new PsychUIButton(0, timeTxt.y + 30, 'Go To', function()
					{
						charter.curSec = currentSec;
						FlxG.sound.music.time = FlxMath.bound(curTime, 0, FlxG.sound.music.length - 1);
						charter.loadSection();
						state.close();
					});
					btn.cameras = state.cameras;
					btn.screenCenter(X);
					btn.x -= 60;
					state.add(btn);

					var btn:PsychUIButton = new PsychUIButton(0, btn.y, 'Cancel', state.close);
					btn.cameras = state.cameras;
					btn.screenCenter(X);
					btn.x += 60;
					state.add(btn);
				}
			));
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY++;
		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Theme...', function()
		{
			if(!charter.fileDialog.completed) return;
			upperBox.isMinimized = true;
			upperBox.bg.visible = false;

			FlxG.sound.play(Paths.sound('chartingSounds/openWindow'));
			charter.openSubState(new BasePrompt(500, 260, 'Chart Editor Theme',
				function(state:BasePrompt)
				{
					var btn:PsychUIButton = new PsychUIButton(state.bg.x + state.bg.width - 40, state.bg.y, 'X', state.close, 40);
					btn.cameras = state.cameras;
					state.add(btn);

					var btnY = 320;
					var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Light', charter.changeTheme.bind(LIGHT));
					btn.screenCenter(X);
					btn.x -= 180;
					btn.cameras = state.cameras;
					state.add(btn);
			
					var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Dark', charter.changeTheme.bind(DARK));
					btn.screenCenter(X);
					btn.x -= 60;
					btn.cameras = state.cameras;
					state.add(btn);
					
					var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Default', charter.changeTheme.bind(DEFAULT));
					btn.screenCenter(X);
					btn.cameras = state.cameras;
					btn.x += 60;
					state.add(btn);
			
					var btn:PsychUIButton = new PsychUIButton(0, btnY, 'V-Slice', charter.changeTheme.bind(VSLICE));
					btn.screenCenter(X);
					btn.x += 180;
					btn.cameras = state.cameras;
					state.add(btn);

					btnY += 60;
					var btn:PsychUIButton = new PsychUIButton(0, btnY, 'Custom', charter.changeTheme.bind(CUSTOM));
					btn.screenCenter(X);
					btn.x -= 180;
					btn.cameras = state.cameras;
					state.add(btn);

					var customBgC:String = '303030';
					if(charter.chartEditorSave.data.customBgColor != null)
						customBgC = charter.chartEditorSave.data.customBgColor;

					var input:PsychUIInputText = new PsychUIInputText(0, btnY, 80, customBgC, 10);
					input.maxLength = 6;
					input.filterMode = ONLY_HEXADECIMAL;
					input.forceCase = UPPER_CASE;
					input.screenCenter(X);
					input.x -= 60;
					input.cameras = state.cameras;
					input.onChange = function(old:String, cur:String)
					{
						charter.chartEditorSave.data.customBgColor = cur;
						charter.changeTheme(CUSTOM);
					}

					var txt:FlxText = new FlxText(input.x, input.y - 15, 120, 'BG Color:');
					txt.cameras = state.cameras;
					state.add(txt);
					state.add(input);

					var customGridC:Array<String> = ['DFDFDF', 'BFBFBF'];
					if(charter.chartEditorSave.data.customGridColors != null && charter.chartEditorSave.data.customGridColors.length > 1)
						customGridC = charter.chartEditorSave.data.customGridColors;

					var input:PsychUIInputText = new PsychUIInputText(0, btnY, 80, customGridC[0], 10);
					input.maxLength = 6;
					input.filterMode = ONLY_HEXADECIMAL;
					input.forceCase = UPPER_CASE;
					input.screenCenter(X);
					input.x += 60;
					input.cameras = state.cameras;
					input.onChange = function(old:String, cur:String)
					{
						charter.chartEditorSave.data.customGridColors[0] = cur;
						charter.changeTheme(CUSTOM);
					}

					var txt:FlxText = new FlxText(input.x, input.y - 15, 120, 'Grid Colors:');
					txt.cameras = state.cameras;
					state.add(txt);
					state.add(input);

					var input:PsychUIInputText = new PsychUIInputText(0, btnY + 30, 80, customGridC[1], 10);
					input.maxLength = 6;
					input.filterMode = ONLY_HEXADECIMAL;
					input.forceCase = UPPER_CASE;
					input.screenCenter(X);
					input.x += 60;
					input.cameras = state.cameras;
					input.onChange = function(old:String, cur:String)
					{
						charter.chartEditorSave.data.customGridColors[1] = cur;
						charter.changeTheme(CUSTOM);
					}
					state.add(input);

					var customGridOtherC:Array<String> = ['5F5F5F', '4A4A4A'];
					if(charter.chartEditorSave.data.customNextGridColors != null && charter.chartEditorSave.data.customNextGridColors.length > 1)
						customGridOtherC = charter.chartEditorSave.data.customNextGridColors;

					var input:PsychUIInputText = new PsychUIInputText(0, btnY, 80, customGridOtherC[0], 10);
					input.maxLength = 6;
					input.filterMode = ONLY_HEXADECIMAL;
					input.forceCase = UPPER_CASE;
					input.screenCenter(X);
					input.x += 180;
					input.cameras = state.cameras;
					input.onChange = function(old:String, cur:String)
					{
						charter.chartEditorSave.data.customNextGridColors[0] = cur;
						charter.changeTheme(CUSTOM);
					}

					var txt:FlxText = new FlxText(input.x, input.y - 15, 120, 'Next Grid Colors:');
					txt.cameras = state.cameras;
					state.add(txt);
					state.add(input);

					var input:PsychUIInputText = new PsychUIInputText(0, btnY + 30, 80, customGridOtherC[1], 10);
					input.maxLength = 6;
					input.filterMode = ONLY_HEXADECIMAL;
					input.forceCase = UPPER_CASE;
					input.screenCenter(X);
					input.x += 180;
					input.cameras = state.cameras;
					input.onChange = function(old:String, cur:String)
					{
						charter.chartEditorSave.data.customNextGridColors[1] = cur;
						charter.changeTheme(CUSTOM);
					}
					state.add(input);
				}
			));
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);

		btnY += 20;
		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, '  Reset UI Boxes', function()
		{
			mainBox.setPosition(mainBoxPosition.x, mainBoxPosition.y);
			infoBox.setPosition(infoBoxPosition.x, infoBoxPosition.y);
			UIEvent(PsychUIBox.DROP_EVENT, btn); //to force a save
		}, btnWid);
		btn.text.alignment = LEFT;
		tab_group.add(btn);
	}

    function createUIBoxes(){
		infoBox = new PsychUIBox(infoBoxPosition.x, infoBoxPosition.y, 220, 220, ['Information']);
		infoBox.scrollFactor.set();
		infoText = new FlxText(15, 15, 230, '', 16);
		infoText.scrollFactor.set();
		infoBox.getTab('Information').menu.add(infoText);
		add(infoBox);

		mainBox = new PsychUIBox(mainBoxPosition.x, mainBoxPosition.y, 300, 280, ['Charting', 'Data', 'Actions', 'Note', 'Section', 'Song']);
		mainBox.selectedName = 'Charting';
		mainBox.scrollFactor.set();
		add(mainBox);

		eventsBox = new PsychUIBox(0, 0, 300, 0, ['Events', 'Modchart']);
		eventsBox.selectedName = 'Events';
		eventsBox.scrollFactor.set();
		eventsBox.canMove = false;
		eventsBox.canMinimize = false;
		mainBox.getTab('Actions').menu.add(eventsBox);

		// save data positions for the UI boxes
		if(charter.chartEditorSave.data.mainBoxPosition != null && charter.chartEditorSave.data.mainBoxPosition.length > 1)
			mainBox.setPosition(charter.chartEditorSave.data.mainBoxPosition[0], charter.chartEditorSave.data.mainBoxPosition[1]);
		if(charter.chartEditorSave.data.infoBoxPosition != null && charter.chartEditorSave.data.infoBoxPosition.length > 1)
			infoBox.setPosition(charter.chartEditorSave.data.infoBoxPosition[0], charter.chartEditorSave.data.infoBoxPosition[1]);

		upperBox = new PsychUIBox(40, 40, 330, 300, ['File', 'Edit', 'View']);
		upperBox.scrollFactor.set();
		upperBox.isMinimized = true;
		upperBox.minimizeOnFocusLost = true;
		upperBox.canMove = false;
		upperBox.bg.visible = false;
		add(upperBox);

		////// for main box
		addChartingTab();
		addDataTab();
		addEventsTab();
		addModchartTab();
		addNoteTab();
		addSectionTab();
		addSongTab();
		
		////// for upper box
		addFileTab();
		addEditTab();
		addViewTab();
		//
    }

    function createSongSlider(){
		songPosSlider = new PsychUIVerticalSlider(0, 0, null, (FlxG.sound.music != null && FlxG.sound.music.length > 0) ? (Conductor.songPosition / FlxG.sound.music.length) * FlxG.height : 0, 0, FlxG.height, FlxG.height, 0xFF4D4D4D, FlxColor.WHITE);
		songPosSlider.valueText.visible = false;
		songPosSlider.minText.visible = false;
		songPosSlider.maxText.visible = false;
		songPosSlider.angle = 180;
		songPosSlider.x = FlxG.width - 20;
		songPosSlider.bar.alpha = 0.5;
		songPosSlider.value = (FlxG.sound.music != null && FlxG.sound.music.length > 0) ? (Conductor.songPosition / FlxG.sound.music.length) * FlxG.height : 0;
		songPosSlider.scrollFactor.set();
		add(songPosSlider);

		songPosSlider.onDragStart = (v:Float) -> {
			sliderIsDragging = true;
			if(FlxG.sound.music.playing) sliderWasPlaying = true;
			charter.setSongPlaying(false);
		}

		songPosSlider.onDrag = (v:Float) -> {
			var songLen:Float = (FlxG.sound.music != null ? FlxG.sound.music.length : 0.0001);
			var t:Float = (v / FlxG.height) * songLen;
			FlxG.sound.music.time = t;
			Conductor.songPosition = FlxG.sound.music.time;
		}

		songPosSlider.onDragEnd = (v:Float) -> {
			if(sliderWasPlaying) charter.setSongPlaying(true);
			sliderIsDragging = false;
			sliderWasPlaying = false;
		}
    }

	function addChartingTab()
	{
		var tab_group = mainBox.getTab('Charting').menu;
		var objX = 10;
		var objY = 10;

		var txt = new FlxText(objX, objY, 280, "Any options here won't actually affect gameplay!");
		txt.alignment = CENTER;
		tab_group.add(txt);

		objY += 25;
		playbackSlider = new PsychUISlider(50, objY, function(v:Float) charter.setPitch(charter.playbackRate = v), 1, 0.1, 5.0, 200);
		playbackSlider.label = 'Playback Rate';
		
		objY += 60;
		mouseSnapCheckBox = new PsychUICheckBox(objX, objY, 'Mouse Scroll Snap', 100, function() charter.chartEditorSave.data.mouseScrollSnap = mouseSnapCheckBox.checked);
		mouseSnapCheckBox.checked = charter.chartEditorSave.data.mouseScrollSnap;

		ignoreProgressCheckBox = new PsychUICheckBox(objX + 150, objY, 'Ignore Progress Warnings', 100, function() charter.chartEditorSave.data.ignoreProgressWarns = ignoreProgressCheckBox.checked);
		ignoreProgressCheckBox.checked = charter.chartEditorSave.data.ignoreProgressWarns;

		objY += 50;
		instVolumeStepper = new PsychUINumericStepper(objX, objY, 0.1, 0.6, 0, 1, 1);
		instVolumeStepper.onValueChange = charter.updateAudioVolume;
		playerVolumeStepper = new PsychUINumericStepper(objX + 100, objY, 0.1, 1, 0, 1, 1);
		playerVolumeStepper.onValueChange = charter.updateAudioVolume;
		opponentVolumeStepper = new PsychUINumericStepper(objX + 200, objY, 0.1, 1, 0, 1, 1);
		opponentVolumeStepper.onValueChange = charter.updateAudioVolume;

		objY += 25;
		instMuteCheckBox = new PsychUICheckBox(objX, objY, 'Mute', 60, charter.updateAudioVolume);
		playerMuteCheckBox = new PsychUICheckBox(objX + 100, objY, 'Mute', 60, charter.updateAudioVolume);
		opponentMuteCheckBox = new PsychUICheckBox(objX + 200, objY, 'Mute', 60, charter.updateAudioVolume);

		objY += 50;
		metronomeStepper = new PsychUINumericStepper(objX + 100, objY, 0.2, 0, 0, 1, 1);

		tab_group.add(playbackSlider);
		tab_group.add(mouseSnapCheckBox);
		tab_group.add(ignoreProgressCheckBox);

		tab_group.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 100, 'Metronome:'));
		tab_group.add(metronomeStepper);
		
		tab_group.add(new FlxText(instVolumeStepper.x, instVolumeStepper.y - 15, 100, 'Inst. Volume:'));
		tab_group.add(new FlxText(playerVolumeStepper.x, playerVolumeStepper.y - 15, 100, 'Main Vocals:'));
		tab_group.add(new FlxText(opponentVolumeStepper.x, opponentVolumeStepper.y - 15, 100, 'Opp. Vocals:'));
		tab_group.add(instVolumeStepper);
		tab_group.add(instMuteCheckBox);
		tab_group.add(playerVolumeStepper);
		tab_group.add(playerMuteCheckBox);
		tab_group.add(opponentVolumeStepper);
		tab_group.add(opponentMuteCheckBox);
	}

	function addDataTab()
	{
		var tab_group = mainBox.getTab('Data').menu;
		var objX = 10;
		var objY = 25;
		gameOverCharDropDown = new PsychUIDropDownMenu(objX, objY, [''], function(id:Int, character:String)
		{
			PlayState.SONG.gameOverChar = character;
			if(character.length < 1) Reflect.deleteField(PlayState.SONG, 'gameOverChar');
		});

		objY += 40;
		gameOverSndInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		gameOverSndInputText.onChange = function(old:String, cur:String)
		{
			PlayState.SONG.gameOverSound = cur;
			if(cur.trim().length < 1) Reflect.deleteField(PlayState.SONG, 'gameOverSound');
		}
		objY += 40;
		gameOverLoopInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		gameOverLoopInputText.onChange = function(old:String, cur:String)
		{
			PlayState.SONG.gameOverLoop = cur;
			if(cur.trim().length < 1) Reflect.deleteField(PlayState.SONG, 'gameOverLoop');
		}
		objY += 40;
		gameOverRetryInputText = new PsychUIInputText(objX, objY, 120, '', 8);
		gameOverRetryInputText.onChange = function(old:String, cur:String)
		{
			PlayState.SONG.gameOverEnd = cur;
			if(cur.trim().length < 1) Reflect.deleteField(PlayState.SONG, 'gameOverEnd');
		}

		objY += 35;
		noRGBCheckBox = new PsychUICheckBox(objX, objY, 'Disable Note RGB', 100, charter.updateNotesRGB);
		pixel4kTextureCheckBox = new PsychUICheckBox(objX + 140, objY, 'Pixel 4K Texture', 100, charter.updatePixelTexture);
		
		objY += 40;
		noteTextureInputText = new PsychUIInputText(objX, objY, 120, '');
		noteTextureInputText.unfocus = function()
		{
			var changed:Bool = false;
			if(PlayState.SONG.arrowSkin != noteTextureInputText.text) changed = true;
			PlayState.SONG.arrowSkin = noteTextureInputText.text.trim();
			if(PlayState.SONG.arrowSkin.trim().length < 1) PlayState.SONG.arrowSkin = null;

			if(changed)
			{
				var textureLoad:String = 'images/${noteTextureInputText.text}.png';
				if(Paths.fileExists(textureLoad, IMAGE) || noteTextureInputText.text.trim() == '')
				{
					for (note in charter.notes)
					{
						if(note == null) continue;
						note.reloadNote(note.texture);
		
						if(note.width > note.height)
							note.setGraphicSize(ChartEditorState.GRID_SIZE);
						else
							note.setGraphicSize(0, ChartEditorState.GRID_SIZE);
		
						note.updateHitbox();
					}
					if(noteTextureInputText.text.trim().length > 0) showOutput('Reloaded notes to: "$textureLoad"');
					else showOutput('Reloaded notes to default texture');
					
				}
				else showOutput('ERROR: "$textureLoad" not found.', true);
			}
		};

		noteSplashesInputText = new PsychUIInputText(objX + 140, objY, 120, '');
		noteSplashesInputText.onChange = function(old:String, cur:String)
		{
			PlayState.SONG.splashSkin = cur;
			if(cur.trim().length < 1) PlayState.SONG.splashSkin = null;
		}
	
		tab_group.add(new FlxText(gameOverCharDropDown.x, gameOverCharDropDown.y - 15, 120, 'Game Over Character:'));
		tab_group.add(new FlxText(gameOverSndInputText.x, gameOverSndInputText.y - 15, 180, 'Game Over Death Sound (sounds/):'));
		tab_group.add(new FlxText(gameOverLoopInputText.x, gameOverLoopInputText.y - 15, 180, 'Game Over Loop Music (music/):'));
		tab_group.add(new FlxText(gameOverRetryInputText.x, gameOverRetryInputText.y - 15, 180, 'Game Over Retry Music (music/):'));
		tab_group.add(gameOverSndInputText);
		tab_group.add(gameOverLoopInputText);
		tab_group.add(gameOverRetryInputText);
		tab_group.add(noRGBCheckBox);
		tab_group.add(pixel4kTextureCheckBox);

		tab_group.add(new FlxText(noteTextureInputText.x, noteTextureInputText.y - 15, 100, 'Note Texture:'));
		tab_group.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 15, 120, 'Note Splashes Texture:'));
		tab_group.add(noteTextureInputText);
		tab_group.add(noteSplashesInputText);

		tab_group.add(gameOverCharDropDown); //lowest priority to display properly
	}

    function addModchartTab():Void {
		var tabGroupModchart = eventsBox.getTab('Modchart').menu;
		var posX = 10;
		var posY = 30;

		modifierInput = new PsychUIInputText(posX+150, posY, 120, '', 8);
    	modifierInput.onChange = function(old:String, cur:String){
			charter.updateModEvV1();
		}

		var modifierLabelText = new FlxText(modifierInput.x, modifierInput.y - 15, 80, 'Modifier:');

		actionsDropdown = new PsychUIDropDownMenu(posX, posY, ["Set", "Ease"], function(index:Int, name:String){
			charter.updateModEvV1();
		});

		var actionsLabelText = new FlxText(actionsDropdown.x, actionsDropdown.y - 15, 80, 'Action:');

		posY += 60;

		timeStepper = new PsychUINumericStepper(posX, posY, 0.01, 0, 0, 9999, 2);
		timeStepper.onValueChange = function() {
			charter.updateModEvV1();
		};

		valueStepper = new PsychUINumericStepper(posX + 150, posY, 0.01, 0, -999999, 999999, 2);
		valueStepper.onValueChange = function() {
			charter.updateModEvV1();
		};

		posY += 60;

		easeInput = new PsychUIInputText(posX, posY, 120, '', 8);
		easeInput.onChange = function(old:String, cur:String){
			charter.updateModEvV1();
		}

		playerStepper = new PsychUINumericStepper(posX + 150, posY, 1, -1, -1, (PlayState.SONG.lanes - 1), 0);
		playerStepper.onValueChange = function() {
			charter.updateModEvV1();
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

    function addEventsTab()
	{
		var tab_group = eventsBox.getTab('Events').menu;
		var objX = 10;
		var objY = 25;

		eventDropDown = new PsychUIDropDownMenu(objX, objY, [], function(id:Int, character:String)
		{
			var eventSelected:Array<String> = charter.eventsList[id];
			var eventName:String = eventSelected[0];
			var description:String = eventSelected[1];
			eventDescriptionText.text = description;
			if(charter.selectedNotes.length > 1)
			{
				for (note in charter.selectedNotes)
				{
					if(note == null || !note.isEvent) continue;

					var event:EventMetaNote = cast (note, EventMetaNote);
					event.events[event.events.length - 1][0] = eventName;
					event.updateEventText();
				}
			}
			else if(charter.selectedNotes.length == 1 && charter.selectedNotes[0].isEvent)
			{
				var event:EventMetaNote = cast (charter.selectedNotes[0], EventMetaNote);
				event.events[Std.int(FlxMath.bound(charter.curEventSelected, 0, event.events.length - 1))][0] = eventName;
				event.updateEventText();
			}
		});

		function genericEventButton(func:EventMetaNote->Void)
		{
			if(charter.selectedNotes.length == 1)
			{
				if(charter.selectedNotes[0].isEvent)
				{
					var event:EventMetaNote = cast (charter.selectedNotes[0], EventMetaNote);
					func(event);
					charter.updateSelectedEventText();
				}
				else showOutput('Note selected must be an Event!', true);
			}
			else showOutput('You must select a single event to press this button.', true);
		}

		var objX2 = 140;
		var removeButton:PsychUIButton = new PsychUIButton(objX2, objY, '-', function()
		{
			genericEventButton(function(event:EventMetaNote)
			{
				if(event.events.length > 1)
				{
					var selectedEvent = event.events[charter.curEventSelected];
					if(selectedEvent != null)
					{
						event.events.remove(selectedEvent);
						event.updateEventText();
						charter.curEventSelected--;
					}
					else showOutput('No event is selected when you deleted it?? Weird.', true);
				}
				else
				{
					charter.selectedNotes.remove(event);
					charter.events.remove(event);
					charter.curRenderedNotes.remove(event, true);
					charter.addUndoAction(DELETE_NOTE, {events: [event]});
				}
			});
		}, 20);
		var addButton:PsychUIButton = new PsychUIButton(objX2 + 30, objY, '+', function()
		{
			genericEventButton(function(event:EventMetaNote)
			{
				event.events.push([charter.eventsList[Std.int(Math.max(eventDropDown.selectedIndex, 0))][0], value1InputText.text, value2InputText.text]);
				event.updateEventText();
				charter.curEventSelected++;
			});
		}, 20);
		var leftButton:PsychUIButton = new PsychUIButton(objX2 + 80, objY, '<', function()
		{
			genericEventButton(function(event:EventMetaNote) charter.curEventSelected = FlxMath.wrap(charter.curEventSelected - 1, 0, event.events.length - 1));
		}, 20);
		var rightButton:PsychUIButton = new PsychUIButton(objX2 + 110, objY, '>', function()
		{
			genericEventButton(function(event:EventMetaNote) charter.curEventSelected = FlxMath.wrap(charter.curEventSelected + 1, 0, event.events.length - 1));
		}, 20);
		removeButton.normalStyle.bgColor = FlxColor.RED;
		removeButton.normalStyle.textColor = FlxColor.WHITE;
		addButton.normalStyle.bgColor = FlxColor.GREEN;
		addButton.normalStyle.textColor = FlxColor.WHITE;

		selectedEventText = new FlxText(150, objY + 30, 150, '');
		selectedEventText.visible = false;

		function changeEventsValue(str:String, n:Int)
		{
			if(charter.selectedNotes.length > 1)
			{
				for (note in charter.selectedNotes)
				{
					if(note == null || !note.isEvent) continue;

					var event:EventMetaNote = cast (note, EventMetaNote);
					event.events[event.events.length - 1][n] = str;
					event.updateEventText();
				}
			}
			else if(charter.selectedNotes.length == 1 && charter.selectedNotes[0].isEvent)
			{
				var event:EventMetaNote = cast (charter.selectedNotes[0], EventMetaNote);
				event.events[Std.int(FlxMath.bound(charter.curEventSelected, 0, event.events.length - 1))][n] = str;
				event.updateEventText();
			}
		}

		objY += 70;
		value1InputText = new PsychUIInputText(objX, objY, 120, '', 8);
		value1InputText.onChange = function(old:String, cur:String) changeEventsValue(cur, 1);
		value2InputText = new PsychUIInputText(objX + 150, objY, 120, '', 8);
		value2InputText.onChange = function(old:String, cur:String) changeEventsValue(cur, 2);

		objY += 40;
		eventDescriptionText = new FlxText(objX, objY, 280, ChartEditorState.defaultEvents[0][1]);

		tab_group.add(new FlxText(eventDropDown.x, eventDropDown.y - 15, 80, 'Event:'));
		tab_group.add(new FlxText(value1InputText.x, value1InputText.y - 15, 80, 'Value 1:'));
		tab_group.add(new FlxText(value2InputText.x, value2InputText.y - 15, 80, 'Value 2:'));

		tab_group.add(removeButton);
		tab_group.add(addButton);
		tab_group.add(leftButton);
		tab_group.add(rightButton);
		tab_group.add(selectedEventText);

		tab_group.add(value1InputText);
		tab_group.add(value2InputText);
		tab_group.add(eventDescriptionText);
		
		tab_group.add(eventDropDown); //lowest priority to display properly
	}

	function addNoteTab()
	{
		var tab_group = mainBox.getTab('Note').menu;
		var objX = 10;
		var objY = 25;

		susLengthStepper = new PsychUINumericStepper(objX, objY, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 128, 1, 80);
		susLengthStepper.onValueChange = function()
		{
			var halfStep:Float = (Conductor.stepCrochet / 2);
			var val:Float = Math.round(susLengthStepper.value / halfStep) * halfStep;
			susLengthStepper.value = val;
			if(charter.susLengthLastVal != susLengthStepper.value)
			{
				if(charter.selectedNotes.length > 1)
				{
					for (note in charter.selectedNotes)
					{
						if(note == null && !note.isEvent) continue;
						note.setSustainLength(note.sustainLength + (susLengthStepper.value - charter.susLengthLastVal), Conductor.stepCrochet, charter.curZoom);
					}
				}
				else if(charter.selectedNotes.length == 1) charter.selectedNotes[0].setSustainLength(susLengthStepper.value, Conductor.stepCrochet, charter.curZoom);
				charter.susLengthLastVal = susLengthStepper.value;
			}
		};

		objY += 40;
		strumTimeStepper = new PsychUINumericStepper(objX, objY, Conductor.stepCrochet, 0, -5000, Math.POSITIVE_INFINITY, 3, 120);
		strumTimeStepper.onValueChange = function()
		{
			if(charter.selectedNotes.length < 1) return;

			var firstTime:Float = charter.selectedNotes[0].strumTime;
			for (note in charter.selectedNotes)
			{
				if(note == null) continue;

				note.setStrumTime(Math.max(-5000, strumTimeStepper.value + (note.strumTime - firstTime)));
				charter.positionNoteYOnTime(note, charter.curSec);

				if(note.isEvent)
				{
					cast (note, EventMetaNote).updateEventText();
				}
			}
			charter.softReloadNotes();
		};
		
		objY += 40;
		noteTypeDropDown = new PsychUIDropDownMenu(objX, objY, [], function(id:Int, changeToType:String)
		{
			var newSelected:Array<MetaNote> = [];
			var typeSelected:String = charter.noteTypes[id].trim();
			for (note in charter.selectedNotes)
			{
				if(note == null || note.isEvent) continue;

				if(typeSelected != null && typeSelected.length > 0)
					note.songData[3] = typeSelected;
				else
					note.songData.remove(note.songData[3]);

				var id:Int = charter.notes.indexOf(note);
				if(id > -1)
				{
					charter.notes[id] = charter.createNote(note.songData, charter.curSec);
					charter.actionReplaceNotes(note, charter.notes[id]);
					newSelected.push(charter.notes[id]);
					note.destroy();
				}
			}
			charter.selectedNotes = newSelected;
			charter.softReloadNotes();
		}, 150);
		
		tab_group.add(new FlxText(susLengthStepper.x, susLengthStepper.y - 15, 80, 'Sustain length:'));
		tab_group.add(new FlxText(strumTimeStepper.x, strumTimeStepper.y - 15, 100, 'Note Hit time (ms):'));
		tab_group.add(new FlxText(noteTypeDropDown.x, noteTypeDropDown.y - 15, 80, 'Note Type:'));
		tab_group.add(susLengthStepper);
		tab_group.add(strumTimeStepper);
		tab_group.add(noteTypeDropDown);
	}

	function swapDaSection(pAm:Int){
		var maxData:Int = ChartEditorState.GRID_COLUMNS_PER_PLAYER * pAm;
		for (note in charter.curRenderedNotes)
		{
			if(note != null && !note.isEvent)
			{
				var data:Int = note.songData[1] + ChartEditorState.GRID_COLUMNS_PER_PLAYER;
				if(data >= maxData) data -= maxData;
				note.changeNoteData(data);
				charter.positionNoteXByData(note);
			}
		}
		charter.softReloadNotes(true);
	}

	function addSectionTab()
	{
		var affectNotes:PsychUICheckBox = null;
		var affectEvents:PsychUICheckBox = null;
		var copyLastSecStepper:PsychUINumericStepper = null;
		var tab_group = mainBox.getTab('Section').menu;
		var objX = 10;
		var objY = 10;
		function copyNotesOnSection(?secOff:Int = 0, ?showMessage:Bool = true) //Used on "Copy Section" and "Copy Last Section" buttons
		{
			var curSectionTime:Null<Float> = charter.cachedSectionTimes[charter.curSec - secOff];
			if(curSectionTime == null)
			{
				//showOutput('ERROR: Unknown section??', true);
				return;
			}

			var nextSectionTime:Null<Float> = charter.cachedSectionTimes[charter.curSec - secOff + 1];
			if(nextSectionTime == null) Math.POSITIVE_INFINITY;

			var notesCopyNum:Int = 0;
			if(affectNotes.checked)
			{
				charter.copiedNotes = [];
				for (note in charter.notes)
				{
					if(note.strumTime >= curSectionTime && note.strumTime < nextSectionTime)
					{
						var dataCopy:Array<Dynamic> = charter.makeNoteDataCopy(note.songData, false);
						dataCopy[0] = note.strumTime - curSectionTime;
						charter.copiedNotes.push(dataCopy);
						notesCopyNum++;
					}
				}
			}

			var eventsCopyNum:Int = 0;
			if(affectEvents.checked)
			{
				charter.copiedEvents = [];
				for (event in charter.events)
				{
					if(event.strumTime >= curSectionTime && event.strumTime < nextSectionTime)
					{
						var dataCopy:Array<Dynamic> = charter.makeNoteDataCopy(event.songData, true);
						dataCopy[0] = event.strumTime - curSectionTime;
						charter.copiedEvents.push(dataCopy);
						eventsCopyNum++;
					}
				}
			}

			if(showMessage)
			{
				if(notesCopyNum == 0 && eventsCopyNum == 0)
				{
					showOutput('Nothing to copy!', true);
					return;
				}

				var str:String = '';
				if(notesCopyNum > 0) str += 'Notes Copied: $notesCopyNum';
				if(eventsCopyNum > 0)
				{
					if(str.length > 0) str += '\n';
					str += 'Events Copied: $eventsCopyNum';
				}
	
				if(str.length > 0) showOutput(str);
			}
		}

		mustHitCheckBox = new PsychUICheckBox(objX, objY, 'Must Hit Sec.', 70, function()
		{
			var sec = charter.getCurChartSection();
			if(sec != null) sec.mustHitSection = mustHitCheckBox.checked;
			charter.updateHeads(true);
		});
		gfSectionCheckBox = new PsychUICheckBox(objX + 100, objY, 'GF Section', 70, function()
		{
			var sec = charter.getCurChartSection();
			if(sec != null) sec.gfSection = gfSectionCheckBox.checked;
			charter.updateHeads(true);
		});
		altAnimSectionCheckBox = new PsychUICheckBox(objX + 200, objY, 'Alt Anim', 70, function()
		{
			var sec = charter.getCurChartSection();
			if(sec != null) sec.altAnim = altAnimSectionCheckBox.checked;
		});

		objY += 40;
		changeBpmCheckBox = new PsychUICheckBox(objX, objY, 'Change BPM', 80, function()
		{
			var sec = charter.getCurChartSection();
			if(sec != null)
			{
				var oldTimes:Array<Float> = charter.cachedSectionTimes.copy();
				sec.changeBPM = changeBpmCheckBox.checked;
				if(!Reflect.hasField(sec, 'bpm')) sec.bpm = changeBpmStepper.value;
				charter.adaptNotesToNewTimes(oldTimes);
			}
		});

		focusGFCheckBox = new PsychUICheckBox(objX+100, objY, 'Focus GF', 80, function()
		{
			var sec = charter.getCurChartSection();
			if(sec != null)
			{
				sec.focusGF = focusGFCheckBox.checked;
				charter.updateHeads(true);
			}
		});

		objY += 25;
		changeBpmStepper = new PsychUINumericStepper(objX, objY, 1, 0, 1, 400, 3);
		changeBpmStepper.onValueChange = function()
		{
			var sec = charter.getCurChartSection();
			if(sec != null)
			{
				var oldTimes:Array<Float> = charter.cachedSectionTimes.copy();
				sec.bpm = changeBpmStepper.value;
				sec.changeBPM = true;
				changeBpmCheckBox.checked = true;
				charter.adaptNotesToNewTimes(oldTimes);
			}
		};

		beatsPerSecStepper = new PsychUINumericStepper(objX + 200, objY, 1, 4, 1, 16, 2);
		beatsPerSecStepper.onValueChange = function()
		{
			beatsPerSecStepper.value = Math.round(beatsPerSecStepper.value * 4) / 4;
			var sec = charter.getCurChartSection();
			if(sec != null)
			{
				var oldTimes:Array<Float> = charter.cachedSectionTimes.copy();
				sec.sectionBeats = beatsPerSecStepper.value;
				charter.adaptNotesToNewTimes(oldTimes);
			}
		};

		objY += 40;
		var copyButton:PsychUIButton = new PsychUIButton(objX, objY, 'Copy Section', copyNotesOnSection.bind());
		var pasteButton:PsychUIButton = new PsychUIButton(objX + 100, objY, 'Paste Section', function()
		{
			charter.pasteCopiedNotesToSection(affectNotes.checked, affectEvents.checked);
		});
		var clearButton:PsychUIButton = new PsychUIButton(objX + 200, objY, 'Clear', function()
		{
			for (note in charter.curRenderedNotes)
			{
				if(note == null) continue;

				if(!note.isEvent && affectNotes.checked)
					charter.notes.remove(note);
				if(note.isEvent && affectEvents.checked)
					charter.events.remove(cast (note, EventMetaNote));

				charter.selectedNotes.remove(note);
			}
			charter.softReloadNotes(true);
		});
		clearButton.normalStyle.bgColor = FlxColor.RED;
		clearButton.normalStyle.textColor = FlxColor.WHITE;

		objY += 25;
		affectNotes = new PsychUICheckBox(objX, objY, 'Notes', 60);
		affectNotes.checked = true;
		affectEvents = new PsychUICheckBox(objX + 100, objY, 'Events', 60);

		objY += 32;
		var copyLastSecButton:PsychUIButton = new PsychUIButton(objX, objY, 'Copy Last Section', function()
		{
			var lastCopiedNotes = charter.copiedNotes;
			var lastCopiedEvents = charter.copiedEvents;
			copyNotesOnSection(Std.int(copyLastSecStepper.value), false);
			charter.pasteCopiedNotesToSection(affectNotes.checked, affectEvents.checked);
			charter.copiedNotes = lastCopiedNotes;
			charter.copiedEvents = lastCopiedEvents;
		});
		copyLastSecButton.resize(80, 26);
		copyLastSecStepper = new PsychUINumericStepper(objX + 110, objY + 2, 1, 1, -999, 999, 0);
		
		objY += 40;
		var swapSectionButton:PsychUIButton = new PsychUIButton(objX, objY, 'Swap Section', function()
		{
			swapDaSection(PlayState.SONG.lanes); // CHANGE LATER
		});
		var duetSectionButton:PsychUIButton = new PsychUIButton(objX + 100, objY, 'Duet Section', function()
		{
			var side:Int = -1;
			for (note in charter.curRenderedNotes.members)
			{
				if(note == null || note.isEvent) continue;

				//First figure out if there are notes on more than one player's sides to cancel operation early
				if(side > -1)
				{
					if(Math.floor(note.songData[1] / ChartEditorState.GRID_COLUMNS_PER_PLAYER) != side)
					{
						showOutput('You cannot press this button with notes on more than one side.');
						return;
					}
				}
				else side = Math.floor(note.songData[1] / ChartEditorState.GRID_COLUMNS_PER_PLAYER);
			}

			var pushedNotes:Array<MetaNote> = [];
			for (note in charter.curRenderedNotes.members)
			{
				if(note == null || note.isEvent) continue;

				for (i in 0...ChartEditorState.GRID_PLAYERS)
				{
					if(i == side) continue;

					var songDataCopy:Array<Dynamic> = note.songData.copy();
					songDataCopy[1] = note.noteData + note.fieldID * ChartEditorState.GRID_COLUMNS_PER_PLAYER;
					var newNote = charter.createNote(songDataCopy);
					charter.notes.push(newNote);
					pushedNotes.push(newNote);
				}
			}
			charter.notes.sort(CoolUtil.sortByTime);
			charter.softReloadNotes(true);
			
			charter.addUndoAction(ADD_NOTE, {notes: pushedNotes});
		});
		var mirrorNotesButton:PsychUIButton = new PsychUIButton(objX + 200, objY, 'Mirror Notes', function()
		{
			var maxData:Int = ChartEditorState.GRID_COLUMNS_PER_PLAYER * ChartEditorState.GRID_PLAYERS;
			for (note in charter.curRenderedNotes)
			{
				if(note == null || note.isEvent) continue;

				var data:Int = Std.int(note.songData[1]);
				note.changeNoteData((Math.floor(data / ChartEditorState.GRID_COLUMNS_PER_PLAYER) * ChartEditorState.GRID_COLUMNS_PER_PLAYER) + ChartEditorState.GRID_COLUMNS_PER_PLAYER - note.noteData - 1);
				charter.positionNoteXByData(note);
			}
			charter.softReloadNotes(true);
		});

		tab_group.add(mustHitCheckBox);
		tab_group.add(gfSectionCheckBox);
		tab_group.add(altAnimSectionCheckBox);
		tab_group.add(focusGFCheckBox);

		tab_group.add(new FlxText(beatsPerSecStepper.x, beatsPerSecStepper.y - 15, 100, 'Beats per Section:'));
		tab_group.add(changeBpmCheckBox);
		tab_group.add(changeBpmStepper);
		tab_group.add(beatsPerSecStepper);
		
		tab_group.add(copyButton);
		tab_group.add(pasteButton);
		tab_group.add(clearButton);
		tab_group.add(affectNotes);
		tab_group.add(affectEvents);

		tab_group.add(copyLastSecButton);
		tab_group.add(copyLastSecStepper);

		tab_group.add(swapSectionButton);
		tab_group.add(duetSectionButton);
		tab_group.add(mirrorNotesButton);
	}

	public function reloadNotesDropdowns()
	{
		if(eventDropDown != null)
		{
			charter.eventsList = [];
			var eventFiles:Array<String> = charter.loadFileList('custom_events/', ['.txt']);
			for (file in eventFiles)
			{
				var desc:String = Paths.getTextFromFile('custom_events/$file.txt');
				charter.eventsList.push([file, desc]);
			}

			for (id => event in ChartEditorState.defaultEvents)
				if(!charter.eventsList.contains(event))
					charter.eventsList.insert(id, event);
			
			var displayEventsList:Array<String> = [];
			for (id => data in charter.eventsList)
			{
				if(id > 0)
					displayEventsList[id] = '$id. ${data[0]}';
				else
					displayEventsList.push('');
			}

			var lastSelected:String = eventDropDown.selectedLabel;
			eventDropDown.list = displayEventsList;
			eventDropDown.selectedLabel = lastSelected;
		}

		// Note type drop down
		if(noteTypeDropDown != null)
		{
			var exts:Array<String> = ['.txt'];
			#if LUA_ALLOWED exts.push('.lua'); #end
			#if HSCRIPT_ALLOWED exts.push('.hx'); #end
			charter.noteTypes = charter.loadFileList('custom_notetypes/', exts);
			for (id in 0...ChartEditorState.noteTypeList.length)
			{
				var noteType = ChartEditorState.noteTypeList[id];
				if(!charter.noteTypes.contains(noteType))
					charter.noteTypes.insert(id, noteType);
			}

			if(Song.chartPath != null && Song.chartPath.length > 0)
			{
				var parentFolder:String = Song.chartPath.replace('\\', '/');
				parentFolder = parentFolder.substr(0, Song.chartPath.lastIndexOf('/')+1);
				var notetypeFile:Array<String> = CoolUtil.coolTextFile(parentFolder + 'notetypes.txt');
				if(notetypeFile.length > 0)
				{
					for (ntTyp in notetypeFile)
					{
						var name:String = ntTyp.trim();
						if(!charter.noteTypes.contains(name))
							charter.noteTypes.push(name);
					}
				}
			}
			
			var displayNoteTypes:Array<String> = charter.noteTypes.copy();
			for (id => key in displayNoteTypes){
				if(id == 0) continue;
				displayNoteTypes[id] = '$id. $key';
			}
			
			var lastSelected:String = noteTypeDropDown.selectedLabel;
			noteTypeDropDown.list = displayNoteTypes;
			noteTypeDropDown.selectedLabel = lastSelected;
		}
	}

	public function createCharacterBoxes(){
		for(char in characters){
			char.destroy();
			characters.remove(char);
		}
		for(charBox in characterBoxes){
			charBox.destroy();
			characterBoxes.remove(charBox);
		}
		characters = [];
		characterBoxes = [];

		for(fieldIndex in 0...ChartEditorState.GRID_PLAYERS){
			var char:String = fieldIndex == 0 ? PlayState.SONG.player2 : fieldIndex == 1 ? PlayState.SONG.player1 : fieldIndex == 2 ? PlayState.SONG.gfVersion : PlayState.SONG.extraPlayers[fieldIndex - 3];
			var character = new Character(0, 0, char, fieldIndex == 1);
			character.limitSize(250, 250);
			character.updateHitbox();

			var scaleX:Float = character.scale.x;
			var scaleY:Float = character.scale.y;

			var minOffX:Float = 0;
			var minOffY:Float = 0;
			var first:Bool = true;
			for(offset in character.animOffsets){
				if(first){
					minOffX = offset[0];
					minOffY = offset[1];
					first = false;
				} else {
					if(offset[0] < minOffX) minOffX = offset[0];
					if(offset[1] < minOffY) minOffY = offset[1];
				}
			}
			for(key in character.animOffsets.keys()){
				var offset = character.animOffsets.get(key);
				character.animOffsets.set(key, [
					(offset[0] - minOffX) * scaleX,
					(offset[1] - minOffY) * scaleY
				]);
			}
			character.dance();
			characters.push(character);

			var charBox = new PsychUIBox(0, 0, Std.int((character.frameWidth*character.scale.x)*1.5), Std.int((character.frameHeight*character.scale.y)*1.75), [char]);
			charBox.scrollFactor.set(1, 0);
			charBox.canMove = true;
			charBox.canMinimize = true;
			charBox.isMinimized = false;
			charBox.minimizeOnFocusLost = false;
			charBox.visible = false;
			add(charBox);
			characterBoxes.push(charBox);

			charBox.getTab(char).menu.add(character);
		}
	}

	public function createPlayerBoxes(){
		var boxWidth:Int = Std.int(ChartEditorState.GRID_SIZE * ChartEditorState.GRID_COLUMNS_PER_PLAYER);

		if(charter.lastplayerBoxesColumns != ChartEditorState.GRID_COLUMNS_PER_PLAYER){
			for(playerBox in playerBoxes)
				if(playerBox != null) playerBox.destroy();
			playerBoxes = [];
			characterDropdowns = [];
			hitsoundSliders = [];
			charter.lastplayerBoxesColumns = ChartEditorState.GRID_COLUMNS_PER_PLAYER;
		}

		while(playerBoxes.length > ChartEditorState.GRID_PLAYERS){
			var extraBox = playerBoxes.pop();
			if(extraBox != null) extraBox.destroy();
			characterDropdowns.pop();
			hitsoundSliders.pop();
		}

		for(i in 0...ChartEditorState.GRID_PLAYERS){
			var fieldIndex:Int = i;
			var thisBoxWidth:Int = boxWidth;
			var includeHitsound:Bool = true;
			var thisBoxHeight:Int = 270;
			var boxX:Float = charter.gridBg.x + (ChartEditorState.GRID_SIZE * ChartEditorState.GRID_COLUMNS_PER_PLAYER * i) + ChartEditorState.GRID_SIZE;

			if(i < playerBoxes.length){
				var playerBox = playerBoxes[i];
				playerBox.x = boxX;
				playerBox.y = 0;
				playerBox.resize(thisBoxWidth, thisBoxHeight);
				playerBox.isMinimized = true;
				playerBox.minimizeOnFocusLost = true;
				continue;
			}

			var boxName:String = ((i == 0) ? PlayState.SONG.player2 : ((i == 1) ? PlayState.SONG.player1 : ((i == 2) ? PlayState.SONG.gfVersion : ((PlayState.SONG.extraPlayers[i-3] != null && PlayState.SONG.extraPlayers[i-3] != "") ? PlayState.SONG.extraPlayers[i-3] : 'Player ${i+1}'))));
			var playerBox = new PsychUIBox(boxX, 0, thisBoxWidth, thisBoxHeight, [boxName]);
			playerBox.scrollFactor.set(1, 0);
			playerBox.canMove = false;
			playerBox.canMinimize = true;
			playerBox.isMinimized = true;
			playerBox.minimizeOnFocusLost = true;
			add(playerBox);
			playerBoxes.push(playerBox);

			var tab_group = playerBox.getTab(boxName).menu;

			var hitsoundSlider:PsychUISlider = null;
			if(includeHitsound){
				hitsoundSlider = new PsychUISlider(10, 100, function(v:Float) {}, 0, 0, 1, thisBoxWidth - 20);
				hitsoundSlider.label = 'Hitsound Volume';
				tab_group.add(hitsoundSlider);
			}
			hitsoundSliders.push(hitsoundSlider);

			var leftBound:Float = fieldIndex >= 3 ? 35 : 10;
			var rightBound:Float = thisBoxWidth - 10;
			var dropDownY:Float = includeHitsound ? 175 : 100;

			var charDropDown:PsychUIDropDownMenu = new PsychUIDropDownMenu(leftBound, dropDownY, charter.cachedCharacterList, function(id:Int, character:String){
				if(characterBoxes[fieldIndex] != null && characters[fieldIndex] != null && characters[fieldIndex].curCharacter != character){
					var newChar = new Character(0, 0, character, fieldIndex == 1);
					newChar.limitSize(300, 300);
					newChar.updateHitbox();

					var scaleX:Float = newChar.scale.x;
					var scaleY:Float = newChar.scale.y;

					var minOffX:Float = 0;
					var minOffY:Float = 0;
					var first:Bool = true;
					for(offset in newChar.animOffsets){
						if(first){
							minOffX = offset[0];
							minOffY = offset[1];
							first = false;
						} else {
							if(offset[0] < minOffX) minOffX = offset[0];
							if(offset[1] < minOffY) minOffY = offset[1];
						}
					}
					for(key in newChar.animOffsets.keys()){
						var offset = newChar.animOffsets.get(key);
						newChar.animOffsets.set(key, [
							(offset[0] - minOffX) * scaleX,
							(offset[1] - minOffY) * scaleY
						]);
					}
					newChar.dance();
					characterBoxes[fieldIndex].resize(newChar.width * 1.5, newChar.height * 1.75);
					characterBoxes[fieldIndex].tabs[0].name = character;
					var oldChar = characters[fieldIndex];
					characters[fieldIndex] = newChar;
					characterBoxes[fieldIndex].getTab(character).menu.remove(oldChar);
					characterBoxes[fieldIndex].getTab(character).menu.add(newChar);
					oldChar.destroy();
				}

				switch(fieldIndex){
					case 0:
						PlayState.SONG.player2 = character;
						charter.updateJsonData();
						charter.updateHeads(true);
						charter.loadMusic();
					case 1:
						PlayState.SONG.player1 = character;
						charter.updateJsonData();
						charter.updateHeads(true);
						charter.loadMusic();
					case 2:
						PlayState.SONG.gfVersion = character;
						charter.updateJsonData();
						charter.updateHeads(true);
					default:
						var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
						if(extraChars == null) extraChars = [];
						while(extraChars.length <= fieldIndex - 3)
							extraChars.push('');
						extraChars[fieldIndex - 3] = character;
						Reflect.setField(PlayState.SONG, 'extraPlayers', extraChars);
						charter.updateJsonData();
						charter.updateHeads(true);
				}
				playerBoxes[fieldIndex].tabs[0].name = character;
			});
			charDropDown.x = leftBound + ((rightBound - leftBound) - charDropDown.width) / 2;

			switch(fieldIndex){
				case 0: charDropDown.selectedLabel = PlayState.SONG.player2;
				case 1: charDropDown.selectedLabel = PlayState.SONG.player1;
				case 2: charDropDown.selectedLabel = PlayState.SONG.gfVersion;
				default:
					var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
					charDropDown.selectedLabel = (extraChars != null && extraChars.length > fieldIndex - 3) ? extraChars[fieldIndex - 3] : '';
			}

			if(fieldIndex >= 3){
				var deleteCharBtn:PsychUIButton = new PsychUIButton(10, dropDownY, 'X', function(){
					charDropDown.selectedLabel = '';
					switch(fieldIndex){
						case 0: PlayState.SONG.player2 = '';
						case 1: PlayState.SONG.player1 = '';
						case 2: PlayState.SONG.gfVersion = '';
						default:
							var extraChars:Array<String> = Reflect.hasField(PlayState.SONG, 'extraPlayers') ? Reflect.field(PlayState.SONG, 'extraPlayers') : null;
							if(extraChars != null && extraChars.length > fieldIndex - 3)
								extraChars[fieldIndex - 3] = '';
					}
					charter.updateJsonData();
					charter.updateHeads(true);
					playerBoxes[fieldIndex].tabs[0].name = ((fieldIndex == 0) ? PlayState.SONG.player2 : ((fieldIndex == 1) ? PlayState.SONG.player1 : ((fieldIndex == 2) ? PlayState.SONG.gfVersion : ((PlayState.SONG.extraPlayers[fieldIndex-3] != null && PlayState.SONG.extraPlayers[fieldIndex-3] != "") ? PlayState.SONG.extraPlayers[fieldIndex-3] : 'Player ${fieldIndex+1}'))));
				}, 20);
				deleteCharBtn.normalStyle.bgColor = FlxColor.RED;
				deleteCharBtn.normalStyle.textColor = FlxColor.WHITE;
				tab_group.add(deleteCharBtn);
			}

			var showCharBoxBtn:PsychUIButton = new PsychUIButton(0, 230, characterBoxes[fieldIndex].visible ? '  Hide Character Box' : '  Show Character Box', function(){
				characterBoxes[fieldIndex].visible = !characterBoxes[fieldIndex].visible;
			}, Std.int(playerBoxes[fieldIndex].bg.width));
			showCharBoxBtn.text.alignment = CENTER;
			tab_group.add(showCharBoxBtn);

			if(fieldIndex >= 2){
				showCharBoxBtn.y -= 20;
				var btn:PsychUIButton = new PsychUIButton(0, 230, '  Remove Lane', function(){
					if(ChartEditorState.GRID_PLAYERS - 1 < 2) return;

					var confirmFunc:Void->Void = function(){
						pendingLaneRemoveIndex = fieldIndex;
					}

					if(!ignoreProgressCheckBox.checked){
						FlxG.sound.play(Paths.sound('chartingSounds/exitWindow'));
						charter.openSubState(new Prompt('Warning: Removing this lane\nwill delete all notes in it.', confirmFunc));
					} else confirmFunc();
				}, Std.int(playerBoxes[fieldIndex].bg.width));
				btn.normalStyle.bgColor = FlxColor.RED;
				btn.normalStyle.textColor = FlxColor.WHITE;
				btn.text.alignment = CENTER;
				tab_group.add(btn);
			}

			tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 15, rightBound - leftBound, 'Character:'));
			tab_group.add(charDropDown);
			characterDropdowns.push(charDropDown);
		}

		createLanesTab();

		opponentDropDown = characterDropdowns.length > 0 ? characterDropdowns[0] : null;
		playerDropDown = characterDropdowns.length > 1 ? characterDropdowns[1] : null;
		girlfriendDropDown = characterDropdowns.length > 2 ? characterDropdowns[2] : null;
	}

	function createLanesTab(){
		if(lanesBox == null){
			lanesBox = new PsychUIBox(0, 0, 120, 300, ['Lanes']);
			lanesBox.scrollFactor.set(1, 0);
			lanesBox.isMinimized = true;
			lanesBox.minimizeOnFocusLost = true;
			lanesBox.canMove = false;
			add(lanesBox);
		}
		var tab_group = lanesBox.getTab("Lanes").menu;

		for(item in tab_group.members){
			if(item == null) continue;
			tab_group.remove(item);
			item.destroy();
		}
		lanesGfDropDown = null;

		var tab = lanesBox.getTab('Lanes');
		var tab_group = tab.menu;
		var btnX = tab.x - lanesBox.x;
		var btnY = 1;
		var btnWid = Std.int(tab.width);

		if(ChartEditorState.GRID_PLAYERS <= 2)
			lanesBox.resize(btnWid, 80);
		else
			lanesBox.resize(btnWid, 20);

		lanesBox.isMinimized = true;
		lanesBox.bg.visible = true;

		var btn:PsychUIButton = new PsychUIButton(btnX, btnY, 'Add new lane', function(){
			if(ChartEditorState.GRID_PLAYERS + 1 > 999) return;
			pendingLaneAdd = true;
		}, btnWid);
		btn.normalStyle.bgColor = FlxColor.GREEN;
		btn.normalStyle.textColor = FlxColor.WHITE;
		btn.text.alignment = CENTER;
		tab_group.add(btn);

		btnY += 40;
		var charDropDown:PsychUIDropDownMenu = new PsychUIDropDownMenu(btnX, btnY, charter.cachedCharacterList, function(id:Int, character:String){
			PlayState.SONG.gfVersion = character;
			charter.updateJsonData();
			charter.updateHeads(true);
		});
		charDropDown.selectedLabel = PlayState.SONG.gfVersion;
		if(ChartEditorState.GRID_PLAYERS >= 3) charDropDown.visible = false;
		if(ChartEditorState.GRID_PLAYERS < 3) tab_group.add(new FlxText(charDropDown.x, charDropDown.y - 15, btnWid, 'Girlfriend:'));
		tab_group.add(charDropDown);
		lanesGfDropDown = charDropDown;

		lanesBox.x = playerBoxes[playerBoxes.length - 1].x + playerBoxes[playerBoxes.length - 1].width;
	}

	public function UIEvent(id:String, sender:Dynamic){
		switch(id)
		{
			case PsychUIButton.CLICK_EVENT, PsychUIDropDownMenu.CLICK_EVENT:
				charter.ignoreClickForThisFrame = true;

			case PsychUIBox.CLICK_EVENT:
				charter.ignoreClickForThisFrame = true;
				if(sender == upperBox) updateUpperBoxBg();

			case PsychUIBox.MINIMIZE_EVENT:
				if(sender == upperBox)
				{
					upperBox.bg.visible = !upperBox.isMinimized;
					updateUpperBoxBg();
				}

			case PsychUIBox.DROP_EVENT:
				charter.chartEditorSave.data.mainBoxPosition = [mainBox.x, mainBox.y];
				charter.chartEditorSave.data.infoBoxPosition = [infoBox.x, infoBox.y];
		}
	}

	function updateUpperBoxBg(){
		if(upperBox.selectedTab != null){
			var menu = upperBox.selectedTab.menu;
			upperBox.bg.x = upperBox.x + upperBox.selectedIndex * (upperBox.width/upperBox.tabs.length);
			upperBox.bg.setGraphicSize(menu.width, menu.height + 21);
			upperBox.bg.updateHitbox();
		}
	}
}