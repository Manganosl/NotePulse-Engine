package states.editors;

import backend.Section;
import backend.Rating;

import objects.Note;
import objects.StrumNote;

import flixel.util.FlxSort;
import flixel.input.keyboard.FlxKey;
import openfl.events.KeyboardEvent;

import haxe.Json;
import objects.Character;

import modchart.Manager;
import modchart.Config;

import states.editors.ChartingState;

import psychlua.LuaUtils;
class ModchartEditor extends MusicBeatState
{
	// Borrowed from original PlayState
	public var camHUD:FlxCamera = new FlxCamera();

	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var vocals:FlxSound;
	var opponentVocals:FlxSound;
	var inst:FlxSound;
	
	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var allNotes:Array<Note> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();
	
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var gfStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	
	var combo:Int = 0;
	var lastRating:FlxSprite;
	var lastCombo:FlxSprite;
	var lastScore:Array<FlxSprite> = [];
	var keysArray:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];
	
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	public var songSpeed:Float = 1;
	
	var totalPlayed:Int = 0;
	var totalNotesHit:Float = 0.0;
	var ratingPercent:Float;
	var ratingFC:String;
	
	var showCombo:Bool = false;
	var showComboNum:Bool = true;
	var showRating:Bool = true;

	// Originals
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var guitarHeroSustains:Bool = false;

	public static var instance:ModchartEditor;

	public var manager:Manager;

	private var player:Int;

	var paused:Bool = false;
	static inline var SEEK_STEP:Float = 1000;

	public function new(playbackRate:Float, player:Int)
	{
		super();

		keysArray = [];
		for (i in 0...PlayState.SONG.mania + 1){
			keysArray.push(PlayState.SONG.mania + '_key_$i');
		}

		instance = this;
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		camHUD.zoom = 0.4;
		camHUD.y -= 100;

		this.player = player;
		
		Conductor.songPosition = 0;
		/* setting up some important data */
		this.playbackRate = playbackRate;
		this.startPos = Conductor.songPosition;

		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		Conductor.songPosition -= startOffset;
		startOffset = Conductor.crochet;
		timerToStart = startOffset;
		
		/* borrowed from PlayState */
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		cachePopUpScore();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');

		/* setting up Editor PlayState stuff */
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = 0xFF101010;
		bg.alpha = 0.9;
		add(bg);
		
		/**** NOTES ****/
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();
		gfStrums = new FlxTypedGroup<StrumNote>();
		
		generateStaticArrows(0);
		generateStaticArrows(1);
		if (PlayState.SONG.gfStrums) {
			generateStaticArrows(2);
			for (i in 0...gfStrums.length) {
				gfStrums.members[i].x = (opponentStrums.members[i].x + playerStrums.members[i].x) / 2;
			}
			adaptStrumline(gfStrums);
		}

		/***************/
		
		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		add(scoreTxt);

		FlxG.mouse.visible = false;
		
		generateSong(PlayState.SONG.song);

		if(PlayState.SONG.nativeModchart){ 
			var fields = 1;
			manager = new Manager();
			add(manager);

			while(fields != PlayState.SONG.playfields){
				fields += 1;
				manager.addPlayfield();
			}

			for (songEvent in PlayState.SONG.events){
				for (i in 0...songEvent[1].length){
					var evName:String = songEvent[1][i][0];
					if(evName == "Modchart Event"){
						var value1:String = songEvent[1][i][1];
						if(value1 == null) continue;
						var info = value1.split(',');
						if(info[0] == "Add Modifier")
							manager.addModifier(info[1], Std.parseInt(info[6]));
						if(info[0] == "Ease"){
							var ease = FlxEase.linear;
							if(info[4] != null) ease = LuaUtils.getTweenEaseByString(info[4]);
							var strumTime:Float = songEvent[0] + ClientPrefs.data.noteOffset;
							manager.ease(info[1], strumTime/(60000 / Conductor.bpm), Std.parseFloat(info[2]), Std.parseFloat(info[3]), ease, Std.parseInt(info[5]), Std.parseInt(info[6]));
						}
						if(info[0] == "Set")
							manager.set(info[1], (songEvent[0] + ClientPrefs.data.noteOffset)/(60000 / Conductor.bpm), Std.parseFloat(info[3]), Std.parseInt(info[5]), Std.parseInt(info[6]));
						if(info[0] == "EaseAdd"){
							var ease = FlxEase.linear;
							if(info[4] != null) ease = LuaUtils.getTweenEaseByString(info[4]);
							var strumTime:Float = songEvent[0] + ClientPrefs.data.noteOffset;
							manager.add(info[1], strumTime/(60000 / Conductor.bpm), Std.parseFloat(info[2]), Std.parseFloat(info[3]), ease, Std.parseInt(info[5]), Std.parseInt(info[6]));
						}
						if(info[0] == "SetAdd")
							manager.setAdd(info[1], (songEvent[0] + ClientPrefs.data.noteOffset)/(60000 / Conductor.bpm), Std.parseFloat(info[3]), Std.parseInt(info[5]), Std.parseInt(info[6]));
					}
				}
			}
		}

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence('Playtesting on Chart Editor', PlayState.SONG.song, null, true, songLength);
		#end
		RecalculateRating();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.SPACE)
			togglePause();

		if (FlxG.keys.justPressed.RIGHT)
			seek(SEEK_STEP);

		if (FlxG.keys.justPressed.LEFT)
			seek(-SEEK_STEP);

		if(controls.BACK || FlxG.keys.justPressed.ESCAPE)
		{
			//endSong();
			super.update(elapsed);
			return;
		}
		
		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;
			if(timerToStart < 0) startSong();
		}
		else if(!paused) Conductor.songPosition += elapsed * 1000 * playbackRate;

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		keysCheck();
		notesFollow();
		
		super.update(elapsed);
	}

	function notesFollow(){
		if(notes.length > 0)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;
				if(daNote.gfStrum) strumGroup = gfStrums;

				var strum:StrumNote = strumGroup.members[daNote.noteData];
				daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

				if(daNote.strum.cpuControlled && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					opponentNoteHit(daNote);

				if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
				{
					if (!daNote.strum.cpuControlled && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}
	}
	
	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if (PlayState.SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			var timeSub:Float = Conductor.songPosition - Conductor.offset;
			var syncTime:Float = 20 * playbackRate;
			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime ||
			(vocals.length > 0 && Math.abs(vocals.time - timeSub) > syncTime) ||
			(opponentVocals.length > 0 && Math.abs(opponentVocals.time - timeSub) > syncTime))
			{
				resyncVocals();
			}
		}
		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}
		lastStepHit = curStep;
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}
		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		super.beatHit();
		lastBeatHit = curBeat;
	}
	
	override function sectionHit()
	{
		if (PlayState.SONG.notes[curSection] != null)
		{
			if (PlayState.SONG.notes[curSection].changeBPM)
				Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		}
		super.sectionHit();
	}

	override function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.mouse.visible = true;
		Config.RENDER_ARROW_PATHS = false;
		if(PlayState.SONG.nativeModchart){ 
			remove(manager);
			manager = null;
		}
		FlxG.cameras.remove(camHUD);
		camHUD.destroy();
		FlxG.sound.list.remove(inst);
		flixel.util.FlxDestroyUtil.destroy(inst);
		camHUD = null;
		super.destroy();
	}
	
	function startSong():Void
	{
		startingSong = false;
		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		FlxG.sound.music.time = startPos;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong;
		//vocals.volume = 1;
		vocals.time = startPos;
		vocals.play();
		//opponentVocals.volume = 1;
		opponentVocals.time = startPos;
		opponentVocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
	}

	// Borrowed from PlayState
	function generateSong(dataPath:String)
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);

		var songData = PlayState.SONG;
		Conductor.bpm = songData.bpm;

		var boyfriendVocals:String = loadCharacterFile(PlayState.SONG.player1).vocals_file;
		var dadVocals:String = loadCharacterFile(PlayState.SONG.player2).vocals_file;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();

		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, boyfriendVocals);
				if (playerVocals != null)
				{
					vocals.loadEmbedded(playerVocals);
					FlxG.sound.list.add(vocals);
					vocals.persist = true;
					vocals.looped = true;
					vocals.volume = 0;
					vocals.play();
					vocals.pause();
				}

				var oppVocals = Paths.voices(songData.song, dadVocals);
				if (oppVocals != null)
				{
					opponentVocals.loadEmbedded(oppVocals);
					FlxG.sound.list.add(opponentVocals);
					opponentVocals.persist = true;
					opponentVocals.looped = true;
					opponentVocals.volume = 0;
					opponentVocals.play();
					opponentVocals.pause();
				}
			}
		}
		catch (e:Dynamic) {}

		vocals.volume = 1;
		opponentVocals.volume = 1;

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound().loadEmbedded(Paths.inst(songData.song));
		FlxG.sound.list.add(inst);
		FlxG.sound.music.volume = 0;

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				if(daStrumTime < startPos) continue;

				var daNoteData:Int = Std.int(songNotes[1] % (PlayState.SONG.mania + 1));
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > PlayState.SONG.mania)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, this);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				//swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				swagNote.gfStrum = (songNotes[4] == true);
				if(swagNote.gfStrum) swagNote.mustPress = false;

				swagNote.scrollFactor.set();

				allNotes.push(swagNote);
				unspawnNotes.push(swagNote);

				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength);

				if(floorSus > 0) {
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true, this);
						sustainNote.mustPress = gottaHitNote;
						//sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						sustainNote.gfStrum = swagNote.gfStrum;
						if(sustainNote.gfStrum) sustainNote.mustPress = false;
						allNotes.push(sustainNote);
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
			}
		}

		unspawnNotes.sort(CoolUtil.sortByTime);
	}
	
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...PlayState.SONG.mania + 1)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1){
				playerStrums.add(babyArrow);
			} else if (player == 2){
				gfStrums.add(babyArrow);
			} else {
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}

		adaptStrumline(opponentStrums);
		adaptStrumline(playerStrums);
		if (PlayState.SONG.gfStrums) adaptStrumline(gfStrums);
	}

	public function adaptStrumline(strumline:FlxTypedGroup<StrumNote>) {
		var strumLineWidth:Float = 0;
		var strumLineIsBig:Bool = false;

		for (note in strumline.members) strumLineWidth += note.width;
		strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;

		while (strumLineIsBig) {
			strumLineWidth = 0;
			for (note in strumline.members) {
				note.retryBound();
				strumLineWidth += note.width;
			}
			Log.warn('Strumline is too big! Shrinking and retrying.');
			strumLineIsBig = strumLineWidth > StrumBoundaries.getBoundaryWidth().x;
		}
	}

	public function finishSong():Void
	{
		if(ClientPrefs.data.noteOffset <= 0) {
			endSong();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endSong();
			});
		}
	}

	public function endSong()
	{
		vocals.pause();
		vocals.destroy();
		opponentVocals.pause();
		opponentVocals.destroy();
		if(finishTimer != null)
		{
			finishTimer.cancel();
			finishTimer.destroy();
		}
		//close();
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
	}

	private function cachePopUpScore(){}
	private function popUpScore(note:Note = null):Void{}
	private function onKeyPress(event:KeyboardEvent):Void{}
	private function keyPressed(key:Int){}
	private function onKeyRelease(event:KeyboardEvent):Void{}
	private function keysCheck():Void{}
	function goodNoteHit(note:Note):Void{}
	function noteMiss(daNote:Note):Void {}
	function RecalculateRating(badHit:Bool = false){}
	function updateScore(miss:Bool = false){}
	function fullComboUpdate(){}
	
	function opponentNoteHit(note:Note):Void
	{
		var strum:StrumNote = note.strum;
		if(strum != null) {
			strum.playAnim('confirm', true);
			strum.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
		}
		note.hitByOpponent = true;

		if (!note.isSustainNote)
			invalidateNote(note);
	}
	
	function resyncVocals():Void
	{
		if(paused) return;
		if(finishTimer != null) return;

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = Conductor.songPosition;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
		}
		vocals.play();
		opponentVocals.play();
	}
	
	function loadCharacterFile(char:String):CharacterFile {
		var characterPath:String = 'characters/' + char + '.json';
		var isJSON:Bool = true;
		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path)) {
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!OpenFlAssets.exists(path))
		#end
		{
			isJSON = true;
			path = Paths.getSharedPath('characters/' + Character.DEFAULT_CHARACTER + '.json'); //If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = OpenFlAssets.getText(path);
		#end
		return cast Json.parse(rawJson);
	}

	function togglePause()
	{
		paused = !paused;

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		else
		{
			FlxG.sound.music.play();
			vocals.play();
			opponentVocals.play();
		}
	}

	function seek(delta:Float)
	{
		var newTime = Math.max(0, FlxG.sound.music.time + delta);

		// Audio
		FlxG.sound.music.time = newTime;
		vocals.time = newTime;
		opponentVocals.time = newTime;
		Conductor.songPosition = newTime;

		for (note in notes)
		{
			note.kill();
		}
		notes.clear();

		unspawnNotes = [];

		for (note in allNotes)
		{
			note.revive();
			note.spawned = false;
			note.wasGoodHit = false;
			note.hitByOpponent = false;
			note.tooLate = false;
			note.visible = true;
			note.active = true;

			if(note.isSustainNote)
				if(note.clipRect != null)
					note.clipRect = null;

			if (note.strumTime >= newTime)
			{
				unspawnNotes.push(note);
			}
			else if (note.isSustainNote)
			{
				if (note.parent != null && note.parent.strumTime + note.parent.sustainLength >= newTime)
				{
					notes.add(note);
					note.spawned = true;
				}
				else
				{
					note.kill();
				}
			}
			else
			{
				note.kill();
			}
		}

		unspawnNotes.sort(CoolUtil.sortByTime);
	}
}