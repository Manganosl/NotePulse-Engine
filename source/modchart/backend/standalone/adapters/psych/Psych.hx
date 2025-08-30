package modchart.backend.standalone.adapters.psych;

#if (FM_ENGINE_VERSION == "1.0" || FM_ENGINE_VERSION == "0.7")
import backend.ClientPrefs;
import backend.Conductor;
import objects.Note;
import objects.StrumNote.SustainSplash;
import objects.NoteSplash;
import objects.StrumNote as Strum;
import states.PlayState;
#else
import ClientPrefs;
import Conductor;
import Note;
import PlayState;
import StrumNote as Strum;
#end
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import modchart.Manager;
import modchart.backend.standalone.IAdapter;

class Psych implements IAdapter {
	private var __fCrochet:Float = 0;
	
	public function onModchartingInitialization() {
		__fCrochet = (Conductor.crochet + 8) / 4;
		PlayState.fModchart = true;
	}

	public function isTapNote(sprite:FlxSprite) {
		return sprite is Note;
	}

	// Song related
	public function getSongPosition():Float {
		return Conductor.songPosition;
	}

	public function getCurrentBeat():Float {
		@:privateAccess
		return PlayState.instance.curDecBeat;
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
			return cast(arrow, NoteSplash).extraData["strumNote"].noteData;
		if (arrow is SustainSplash) @:privateAccess
			return cast(arrow, SustainSplash).strum.noteData;

		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).gfStrum ? 2 : cast(arrow, Note).mustPress ? !PlayState.isPlayerOpponent ? 1 : 0 : !PlayState.isPlayerOpponent ? 0 : 1;
		if (arrow is FlxSprite && arrow.extraData["linkStrum"] != null)
			return cast(arrow, FlxSprite).extraData["linkStrum"].player;
		if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).player;
		if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).extraData["strumNote"].player;
		if (arrow is SustainSplash) @:privateAccess
			return cast(arrow, SustainSplash).strum.player;
		return 0;
	}

	public function getKeyCount(?player:Int = 0):Int {
		return PlayState.SONG.mania+1;
	}

	public function getPlayerCount():Int {
		return if(PlayState.SONG.gfStrums) 3 else 2;
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
		#if (FM_ENGINE_VERSION >= "0.7")
		return ClientPrefs.data.downScroll;
		#else
		return ClientPrefs.downScroll;
		#end
	}

	inline function getStrumFromInfo(lane:Int, player:Int) {
		var group = player == 0 ? PlayState.instance.opponentStrums : PlayState.instance.playerStrums;
		var strum = null;
		group.forEach(str -> {
			@:privateAccess
			if (str.noteData == lane)
				strum = str;
		});
		return strum;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float {
		return getStrumFromInfo(lane, player).x;
	}

	public function getDefaultReceptorY(lane:Int, player:Int):Float {
		return getDownscroll() ? FlxG.height - getStrumFromInfo(lane, player).y - Note.swagWidth : getStrumFromInfo(lane, player).y;
	}

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float {
		return PlayState.instance.songSpeed * .45;
	}

	public function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []], [[], [], [], []]];

		@:privateAccess
		PlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
			if (pspr[strumNote.player] == null)
				pspr[strumNote.player] = [];

			pspr[strumNote.player][0].push(strumNote);
		});

		if(ClientPrefs.data.ratingCam == "Bellow Note"){
			PlayState.instance.comboGroup.forEachAlive(comboSprite -> {
			@:privateAccess
				if (comboSprite != null) {
					if (comboSprite.extraData["linkStrum"] != null) {
						final player = comboSprite.extraData["linkStrum"].player;
						if (pspr[player] == null)
							pspr[player] = [];

						pspr[player][0].push(comboSprite);
					}
				}
			});
		};

		PlayState.instance.notes.forEachAlive(strumNote -> {
			final player = Adapter.instance.getPlayerFromArrow(strumNote);
			if (pspr[player] == null)
				pspr[player] = [];

			pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
		});

		PlayState.instance.grpNoteSplashes.forEachAlive(splash -> {
			@:privateAccess
			if (splash != null) {
				if (splash.extraData["strumNote"] != null) {
					final player = splash.extraData["strumNote"].player;
					if (pspr[player] == null)
						pspr[player] = [];

					pspr[player][3].push(splash);
				}
			}
		});

		PlayState.instance.grpSustainSplashes.forEachAlive(splash -> {
			@:privateAccess
			if (splash != null) {
				if (splash.strum != null && splash.shouldVisible) {
					final player = splash.strum.player;
					if (pspr[player] == null)
						pspr[player] = [];

					pspr[player][3].push(splash);
				}
				if (splash.strum != null && !splash.shouldVisible) {
					final player = splash.strum.player;
					if (pspr[player] == null)
						pspr[player] = [];

					pspr[player][3].remove(splash);
				}
			}
		});

		return pspr;
	}
}
