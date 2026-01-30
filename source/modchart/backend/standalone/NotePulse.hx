package modchart.backend.standalone;

import backend.ClientPrefs;
import backend.Conductor;
import objects.Note;
import objects.SustainSplash;
import objects.NoteSplash;
import objects.StrumNote as Strum;
import states.PlayState;
import states.editors.content.EditorPlayState;
import states.editors.ModchartEditor;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import modchart.backend.standalone.IAdapter;
import modchart.Config;

class NotePulse implements IAdapter {
	private var __fCrochet:Float = 0;
	
	public function onModchartingInitialization() {
		__fCrochet = (Conductor.crochet + 8) / 4;
		PlayState.fModchart = true;
	}

	public function onModchartingDispose(){}

	public function isTapNote(sprite:FlxSprite) {
		return sprite is Note;
	}

	public function getSongPosition():Float {
		return Conductor.songPosition;
	}

	public function getPixelStage():Bool {
		return PlayState.isPixelStage;
	}

	public function getCurrentBeat():Float {
		@:privateAccess
		if (Type.getClassName(Type.getClass(FlxG.state)) == 'states.PlayState')
			return PlayState.instance.curDecBeat;
		else if (Type.getClassName(Type.getClass(FlxG.state)) == 'states.editors.ModchartEditor')
			return ModchartEditor.instance.curDecBeat;
		else
			return EditorPlayState.instance.curDecBeat;
	}

	public function getCurrentCrochet():Float {
		return Conductor.crochet;
	}

	public function getBeatFromStep(step:Float)
		return step * .25;

	public function arrowHit(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).wasGoodHit;
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite) {
		if (arrow is Note) {
			final castedNote = cast(arrow, Note);
			if (castedNote.nextNote != null)
				return !castedNote.nextNote.isSustainNote;
		}
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).noteData;
		if (arrow is FlxSprite && arrow.extraData["linkStrum"] != null)
			return cast(arrow, FlxSprite).extraData["linkStrum"].noteData;
		else if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).noteData;
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.noteData;
		if (arrow is SustainSplash) @:privateAccess
			return cast(arrow, SustainSplash).strum.noteData;
		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).gfStrum ? 2 : cast(arrow, Note).mustPress ? 1 : 0;
		if (arrow is FlxSprite && arrow.extraData["linkStrum"] != null)
			return cast(arrow, FlxSprite).extraData["linkStrum"].player;
		if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).player;
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.player;
		if (arrow is SustainSplash) @:privateAccess
			return cast(arrow, SustainSplash).strum.player;
		return 0;
	}

	public function getKeyCount(?player:Int = 0):Int {
		return PlayState.SONG.mania + 1;
	}

	public function getPlayerCount():Int {
		return if (PlayState.SONG.gfStrums) 3 else 2;
	}

	public function getTimeFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).strumTime;
		return 0;
	}

	public function getHoldSubdivisions(hold:FlxSprite):Int {
		return 4;
	}

	public function getHoldLength(item:FlxSprite):Float
		return __fCrochet;

	public function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		return note.parent.strumTime;
	}

	public function getDownscroll():Bool {
		return ClientPrefs.data.downScroll;
	}

	inline function getStrumFromInfo(lane:Int, player:Int) {
		var isPlayState:Bool = Std.is(FlxG.state, PlayState);
		var isModchartEditor:Bool = Std.is(FlxG.state, ModchartEditor);

		var group = if (isPlayState) {
			if (player == 0) PlayState.instance.opponentStrums else PlayState.instance.playerStrums;
		} else if (isModchartEditor) {
			if (player == 0) ModchartEditor.instance.opponentStrums else ModchartEditor.instance.playerStrums;
		} else {
			if (player == 0) EditorPlayState.instance.opponentStrums else EditorPlayState.instance.playerStrums;
		}

		var found:Strum = null;
		for (i in 0...group.members.length) {
			var s = cast(group.members[i], Strum);
			if (s != null && s.noteData == lane) {
				found = s;
				break;
			}
		}
		return found;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		return getStrumFromInfo(lane, player).x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		return getDownscroll()
			? FlxG.height - getStrumFromInfo(lane, player).y - Note.swagWidth
			: getStrumFromInfo(lane, player).y;
	}

	public function getArrowCamera():Array<FlxCamera> {
		if (Type.getClassName(Type.getClass(FlxG.state)) == 'states.PlayState')
			return [PlayState.instance.camHUD];
		else if (Type.getClassName(Type.getClass(FlxG.state)) == 'states.editors.ModchartEditor')
			return [ModchartEditor.instance.camHUD];
		else
			return [EditorPlayState.instance.camHUD];
	}

	public function getCurrentScrollSpeed():Float {
		if (Type.getClassName(Type.getClass(FlxG.state)) == 'states.PlayState')
			return PlayState.instance.songSpeed * .45;
		else if (Type.getClassName(Type.getClass(FlxG.state)) == 'states.editors.ModchartEditor')
			return ModchartEditor.instance.songSpeed * .45;
		else
			return EditorPlayState.instance.songSpeed * .45;
	}

	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []], [[], [], [], []]];

		if (Std.is(FlxG.state, PlayState)) {
			@:privateAccess
			PlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
				pspr[strumNote.player][0].push(strumNote);
			});

			if (ClientPrefs.data.ratingCam == "Bellow Note") {
				PlayState.instance.comboGroup.forEachAlive(comboSprite -> {
					@:privateAccess
					if (comboSprite != null && comboSprite.extraData["linkStrum"] != null) {
						final player = comboSprite.extraData["linkStrum"].player;
						pspr[player][0].push(comboSprite);
					}
				});
			}

			PlayState.instance.notes.forEachAlive(strumNote -> {
				if(strumNote.modchartVisible){
					final player = Adapter.instance.getPlayerFromArrow(strumNote);
					pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
				} else strumNote.visible = false;
			});

			PlayState.instance.grpNoteSplashes.forEachAlive(splash -> {
				@:privateAccess
				if (splash != null && splash.babyArrow != null) {
					pspr[splash.babyArrow.player][3].push(splash);
				}
			});

			PlayState.instance.grpSustainSplashes.forEachAlive(splash -> {
				@:privateAccess
				if (splash != null && splash.strum != null && splash.shouldVisible) {
					pspr[splash.strum.player][3].push(splash);
				}
			});
		} else if (Std.is(FlxG.state, ModchartEditor)) {
			@:privateAccess
			ModchartEditor.instance.strumLineNotes.forEachAlive(strumNote -> {
				pspr[strumNote.player][0].push(strumNote);
			});

			ModchartEditor.instance.notes.forEachAlive(strumNote -> {
				final player = Adapter.instance.getPlayerFromArrow(strumNote);
				pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
			});
		} else {
			@:privateAccess
			EditorPlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
				pspr[strumNote.player][0].push(strumNote);
			});

			EditorPlayState.instance.notes.forEachAlive(strumNote -> {
				final player = Adapter.instance.getPlayerFromArrow(strumNote);
				pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
			});

			EditorPlayState.instance.grpNoteSplashes.forEachAlive(splash -> {
				@:privateAccess
				if (splash != null && splash.babyArrow != null) {
					pspr[splash.babyArrow.player][3].push(splash);
				}
			});
		}

		return pspr;
	}
}