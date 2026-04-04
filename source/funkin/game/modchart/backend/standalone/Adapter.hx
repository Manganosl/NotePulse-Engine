package funkin.game.modchart.backend.standalone;

import funkin.data.ClientPrefs;
import funkin.backend.Conductor;
import funkin.objects.Note;
import funkin.objects.SustainSplash;
import funkin.objects.AttachedSprite;
import funkin.game.modchart.backend.util.ModchartableSprite;
import funkin.objects.NoteSplash;
import funkin.objects.StrumNote as Strum;
import funkin.states.PlayState;
import funkin.states.editors.content.EditorPlayState;
import funkin.states.editors.ModchartEditor;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import funkin.game.modchart.Config;

class Adapter {
	public static var startCrochet:Float = 0;
	private static var isPlayState:Bool = false;
	private static var isModchartEditor:Bool = false;
	private static var __holdSubdivisions:Int = 4;
	
	public static function onModchartingInitialization() {
		isPlayState = Std.is(FlxG.state, PlayState);
		isModchartEditor = Std.is(FlxG.state, ModchartEditor);
		startCrochet = Conductor.crochet;
		PlayState.fModchart = true;
	}

	public static function getHoldParentTime(arrow:FlxSprite) {
		final note:Note = cast arrow;
		return note.parent.strumTime;
	}

	public static function getLaneFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).noteData;
		else if (arrow is AttachedSprite) @:privateAccess
			return cast(arrow, AttachedSprite).parentArrow.noteData;
		else if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).noteData;
		else if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.noteData;
		else if (arrow is SustainSplash) @:privateAccess
			return cast(arrow, SustainSplash).strum.noteData;
		else if (arrow is ModchartableSprite) @:privateAccess
			return cast(arrow, ModchartableSprite).parentArrow.noteData;
		return 0;
	}

	public static function getHoldSubdivisions():Int {
		return __holdSubdivisions;
	}

	public static function setHoldSubdivisions(value:Int):Void {
		__holdSubdivisions = value;
	}

	public static function getCastedSprite(arrow:FlxSprite):Dynamic {
		if (arrow is Note)
			return cast(arrow, Note);
		else if (arrow is AttachedSprite)
			return cast(arrow, AttachedSprite);
		else if (arrow is Strum)
			return cast(arrow, Strum);
		else if (arrow is NoteSplash)
			return cast(arrow, NoteSplash);
		else if (arrow is SustainSplash)
			return cast(arrow, SustainSplash);
		else if (arrow is ModchartableSprite)
			return cast(arrow, ModchartableSprite);
		return null;
	}

	public static function getPlayerFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).playField.player;
		else if (arrow is AttachedSprite) @:privateAccess
			return cast(arrow, AttachedSprite).parentArrow.player;
		else if (arrow is Strum) @:privateAccess
			return cast(arrow, Strum).player;
		else if (arrow is NoteSplash) @:privateAccess
			return cast(arrow, NoteSplash).babyArrow.player;
		else if (arrow is SustainSplash) @:privateAccess
			return cast(arrow, SustainSplash).strum.player;
		else if (arrow is ModchartableSprite) @:privateAccess
			return cast(arrow, ModchartableSprite).parentArrow.player;
		return 0;
	}

	public static function getTimeFromArrow(arrow:FlxSprite) {
		if (arrow is Note)
			return cast(arrow, Note).strumTime;
		return 0;
	}

	inline static function getStrumFromInfo(lane:Int, player:Int) {
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

	public static function getDefaultReceptorX(lane:Int, player:Int):Float {
		return getStrumFromInfo(lane, player).x;
	}

	public static function getDefaultReceptorY(lane:Int, player:Int):Float {
		return ClientPrefs.data.downScroll
			? FlxG.height - getStrumFromInfo(lane, player).y - Note.swagWidth
			: getStrumFromInfo(lane, player).y;
	}

	public static function getArrowCamera():Array<FlxCamera> {
		if (isPlayState)
			return [PlayState.instance.camHUD];
		else if (isModchartEditor)
			return [ModchartEditor.instance.camHUD];
		else
			return [EditorPlayState.instance.camHUD];
	}

	public static function getCurrentScrollSpeed():Float {
		if (isPlayState)
			return PlayState.instance.songSpeed * .45;
		else if (isModchartEditor)
			return ModchartEditor.instance.songSpeed * .45;
		else
			return EditorPlayState.instance.songSpeed * .45;
	}

	public static function getArrowItems() {
		var pspr:Array<Array<Array<FlxSprite>>> = [];
		var interpspr:Array<Array<FlxSprite>> = [];
		while(interpspr.length != PlayState.SONG.mania+1)
			interpspr.push([]);
		while(pspr.length != PlayState.SONG.lanes)
			pspr.push(interpspr);

		if (isPlayState) {
			@:privateAccess
			PlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
				pspr[strumNote.player][0].push(strumNote);
			});

			if (ClientPrefs.data.ratingCam == "Bellow Note") {
				PlayState.instance.comboGroup.forEachAlive(comboSprite -> {
					var castedCombo = null;
					if (comboSprite is ModchartableSprite)
				 		castedCombo = cast(comboSprite, ModchartableSprite);
					@:privateAccess
					if (castedCombo != null && castedCombo.modchartIsRating) {
						final player = castedCombo.parentArrow.player;
						pspr[player][0].push(castedCombo);
						if(castedCombo.babySprite != null)
							pspr[player][0].push(castedCombo.babySprite);
					}
				});
			}

			PlayState.instance.notes.forEachAlive(strumNote -> {
				if(strumNote.modchartVisible){
					final player = getPlayerFromArrow(strumNote);
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
				if (splash != null && splash.strum != null) {
					pspr[splash.strum.player][3].push(splash);
				}
			});
		} else if (isModchartEditor) {
			@:privateAccess
			ModchartEditor.instance.strumLineNotes.forEachAlive(strumNote -> {
				pspr[strumNote.player][0].push(strumNote);
			});

			ModchartEditor.instance.notes.forEachAlive(strumNote -> {
				final player = getPlayerFromArrow(strumNote);
				pspr[player][strumNote.isSustainNote ? 2 : 1].push(strumNote);
			});
		} else {
			@:privateAccess
			EditorPlayState.instance.strumLineNotes.forEachAlive(strumNote -> {
				pspr[strumNote.player][0].push(strumNote);
			});

			EditorPlayState.instance.notes.forEachAlive(strumNote -> {
				final player = getPlayerFromArrow(strumNote);
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