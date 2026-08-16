package moonchart.formats.fnf;

import moonchart.backend.FormatData;
import moonchart.backend.Optimizer;
import moonchart.backend.Timing;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.FNFGlobal.BasicFNFNoteType;
import moonchart.formats.fnf.FNFGlobal.FNFNoteTypeResolver;
import moonchart.formats.fnf.legacy.FNFLegacy;

enum abstract FNFCodenameNoteType(String) from String to String
{
	var CODENAME_ALT_ANIM = "Alt Anim Note";
	var CODENAME_NO_ANIM = "No Anim Note";
}

class FNFCodename extends BasicJsonFormat<FNFCodenameFormat, FNFCodenameMeta>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_CODENAME,
			name: "FNF (Codename)",
			description: "Divided per strumline FNF format with lots of metadata.",
			extension: "json",
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
			specialValues: ['_"codenameChart":', '_"codenameChart":', '_"codenameChart":', '_"codenameChart":', '"strumLines":'],
			handler: FNFCodename
		}
	}

	public static inline var CODENAME_BPM_CHANGE:String = "BPM Change";
	public static inline var CODENAME_CAM_MOVEMENT:String = "Camera Movement";

	public var noteTypeResolver(default, null):FNFNoteTypeResolver;

	public function new(?data:FNFCodenameFormat, ?meta:FNFCodenameMeta)
	{
		super({timeFormat: MILLISECONDS, supportsDiffs: true, supportsEvents: true});
		this.data = data;
		this.meta = meta;
		beautify = true;

		noteTypeResolver = FNFGlobal.createNoteTypeResolver();
		noteTypeResolver.register(FNFCodenameNoteType.CODENAME_ALT_ANIM, BasicFNFNoteType.ALT_ANIM);
		noteTypeResolver.register(FNFCodenameNoteType.CODENAME_NO_ANIM, BasicFNFNoteType.NO_ANIM);
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFCodename
	{
		var chartResolve = resolveDiffsNotes(chart, diff);
		var diff:String = chartResolve.diffs[0];
		var basicNotes:Array<BasicNote> = chartResolve.notes.get(diff);
		var meta = chart.meta;

		var extraPlayers:Array<String> = meta.extraData.get(EXTRA_PLAYERS) ?? ([] : Array<String>);

		var savedKeyCounts:Array<Int> = meta.extraData.get(LANE_KEY_COUNTS) ?? ([] : Array<Int>);

		var maxLane:Int = -1;
		for (note in basicNotes)
		{
			if (note.lane > maxLane)
				maxLane = note.lane;
		}

		var totalStrumlines:Int;
		var keyCounts:Array<Int>;

		if (savedKeyCounts.length > 0)
		{
			totalStrumlines = Std.int(Math.max(3, savedKeyCounts.length));
			keyCounts = [for (i in 0...totalStrumlines) savedKeyCounts[i] ?? 4];
		}
		else
		{
			totalStrumlines = Std.int(Math.max(3, Math.ceil((maxLane + 1) / 4)));
			keyCounts = [for (i in 0...totalStrumlines) 4];
		}

		var offsets:Array<Int> = [];
		var acc:Int = 0;
		for (keyCount in keyCounts)
		{
			offsets.push(acc);
			acc += keyCount;
		}

		var strumlines:Array<FNFCodenameStrumline> = Util.makeArray(totalStrumlines);
		for (i in 0...totalStrumlines)
		{
			strumlines[i] = {
				position: switch (i)
				{
					case 0: "dad";
					case 1: "boyfriend";
					case 2: "girlfriend";
					default: "extra" + (i - 3);
				},
				strumScale: 1,
				visible: (i < 2),
				type: i,
				characters: [
					switch (i)
					{
						case 0:
							meta.extraData.get(PLAYER_2) ?? "dad";
						case 1:
							meta.extraData.get(PLAYER_1) ?? "bf";
						case 2:
							meta.extraData.get(PLAYER_3) ?? "gf";
						default:
							extraPlayers[i - 3] ?? "bf";
					}
				],
				strumPos: [0, 50],
				strumLinePos: switch (i)
				{
					case 1: 0.75;
					default: 0.25;
				},
				vocalsSuffix: "",
				notes: [],
				keyCount: keyCounts[i]
			}
		}

		var noteTypes:Array<String> = [];

		for (note in basicNotes)
		{
			var lane:Int = note.lane;

			var strumlineIndex:Int = -1;
			for (i in 0...totalStrumlines)
			{
				var start:Int = offsets[i];
				var end:Int = start + keyCounts[i];
				if (lane >= start && lane < end)
				{
					strumlineIndex = i;
					break;
				}
			}

			if (strumlineIndex == -1)
				continue;

			var strumline:FNFCodenameStrumline = strumlines[strumlineIndex];
			var type:Int = resolveCodenameType(note.type, noteTypes);
			var id:Int = lane - offsets[strumlineIndex];

			strumline.notes.push({
				time: note.time,
				id: id,
				sLen: note.length,
				type: type
			});
		}

		var basicEvents = chart.data.events;
		var events:Array<FNFCodenameEvent> = Util.makeArray(basicEvents.length);

		for (i in 0...basicEvents.length)
		{
			final event = basicEvents[i];
			final isFocus:Bool = event.name != CODENAME_CAM_MOVEMENT && FNFGlobal.isCamFocus(event);

			Util.setArray(events, i, isFocus ? {
				time: event.time,
				name: CODENAME_CAM_MOVEMENT,
				params: [resolveCamFocus(event)]
			} : {
				time: event.time,
				name: event.name,
				params: Util.resolveEventValues(event.data)
				});
		}

		final firstChange = chart.meta.bpmChanges[0];

		for (i in 1...chart.meta.bpmChanges.length)
		{
			final bpmChange = chart.meta.bpmChanges[i];
			events.push({
				time: bpmChange.time,
				name: CODENAME_BPM_CHANGE,
				params: [bpmChange.bpm]
			});
		}

		events.sort((a, b) -> return Util.sortValues(a.time, b.time));

		this.data = {
			codenameChart: true,
			scrollSpeed: meta.scrollSpeeds.get(diff) ?? 1.0,
			stage: meta.extraData.get(STAGE) ?? "stage",
			noteTypes: noteTypes,
			strumLines: strumlines,
			events: events,
			meta: null
		}

		this.meta = {
			opponentModeAllowed: true,
			coopAllowed: true,
			stepsPerBeat: firstChange.stepsPerBeat,
			beatsPerMeasure: firstChange.beatsPerMeasure,
			bpm: firstChange.bpm,
			difficulties: this.diffs,
			needsVoices: meta.extraData.get(NEEDS_VOICES) ?? false,
			displayName: meta.title,
			customValues: {
				composers: meta.extraData.get(SONG_ARTIST) ?? Moonchart.DEFAULT_ARTIST,
				charters: meta.extraData.get(SONG_CHARTER) ?? Moonchart.DEFAULT_CHARTER
			},
			icon: "bf",
			name: formatSongName(meta.title),
			color: ""
		}

		return this;
	}

	function resolveCamFocus(event:BasicEvent):Int
	{
		return switch (FNFGlobal.resolveCamFocus(event))
		{
			case DAD: 0;
			case BF: 1;
			case GF: 2;
		}
	}

	inline function formatSongName(name:String):String
	{
		return name.toLowerCase();
	}

	function resolveCodenameType(type:String, list:Array<String>):Int
	{
		if (type.length <= 0)
			return 0;

		if (list.contains(type))
			return list.indexOf(type);

		list.push(type);
		return list.length - 1;
	}

	override function getNotes(?diff:String):Array<BasicNote>
	{
		var notes:Array<BasicNote> = [];
		var offsets:Array<Int> = laneOffsets();

		for (i => strumline in data.strumLines)
		{
			for (note in strumline.notes)
			{
				var lane:Int = note.id + offsets[i];
				notes.push({
					time: note.time,
					lane: lane,
					length: note.sLen,
					type: resolveNoteType(note.type)
				});
			}
		}

		Timing.sortNotes(notes);
		return notes;
	}

	function laneKeyCounts():Array<Int>
	{
		return [for (strumline in data.strumLines) strumline.keyCount ?? 4];
	}

	function laneOffsets():Array<Int>
	{
		var offsets:Array<Int> = [];
		var acc:Int = 0;

		for (keyCount in laneKeyCounts())
		{
			offsets.push(acc);
			acc += keyCount;
		}

		return offsets;
	}

	public function resolveNoteType(type:Int){
		if (data.noteTypes[0] != "")
			data.noteTypes.insert(0, "");
		var noteType = data.noteTypes[type] ?? "";
		return noteTypeResolver.toBasic(noteType);
	}

	override function getEvents():Array<BasicEvent>
	{
		var events:Array<BasicEvent> = [];

		for (event in data.events)
		{
			if (event.name != CODENAME_BPM_CHANGE)
				events.push(Util.makeArrayEvent(event.time, event.name, event.params));
		}

		events.unshift({
			time: -1,
			name: CODENAME_CAM_MOVEMENT,
			data: {
				array: [0]
			}
		});

		return events;
	}

	function getStrumline(position:String):FNFCodenameStrumline
	{
		for (strumline in data.strumLines)
		{
			if (strumline.position == position)
				return strumline;
		}

		return null;
	}

	override function getChartMeta():BasicMetaData
	{
		var bpmChanges:Array<BasicBPMChange> = [
			{
				time: -1,
				bpm: meta.bpm,
				stepsPerBeat: meta.stepsPerBeat,
				beatsPerMeasure: meta.beatsPerMeasure
			}
		];

		for (event in data.events)
		{
			if (event.name == CODENAME_BPM_CHANGE)
			{
				bpmChanges.push({
					time: event.time,
					bpm: event.params[0],
					stepsPerBeat: meta.stepsPerBeat,
					beatsPerMeasure: meta.beatsPerMeasure
				});
			}
		}

		Timing.sortBPMChanges(bpmChanges);

		var extraPlayers:Array<String> = [];
		for (i in 3...data.strumLines.length)
		{
			var characters = data.strumLines[i]?.characters;
			extraPlayers.push((characters != null ? characters[0] : null) ?? "bf");
		}

		return {
			title: meta.displayName,
			bpmChanges: bpmChanges,
			offset: 0.0,
			scrollSpeeds: [diffs[0] => data.scrollSpeed],
			extraData: [
				PLAYER_1 => getStrumline("boyfriend")?.characters[0] ?? "bf",
				PLAYER_2 => getStrumline("dad")?.characters[0] ?? "bf",
				PLAYER_3 => getStrumline("girlfriend")?.characters[0] ?? "bf",
				EXTRA_PLAYERS => extraPlayers,
				LANE_KEY_COUNTS => laneKeyCounts(),
				SONG_ARTIST => meta?.customValues?.composers ?? Moonchart.DEFAULT_ARTIST,
				SONG_CHARTER => meta?.customValues?.charters ?? Moonchart.DEFAULT_CHARTER,
				STAGE => data.stage
			]
		}
	}

	public override function fromFile(path:String, ?meta:String, ?diff:FormatDifficulty):FNFCodename
	{
		return fromJson(Util.getText(path), Util.getText(meta), diff);
	}

	public override function fromJson(data:String, ?meta:String, ?diff:FormatDifficulty):FNFCodename
	{
		super.fromJson(data, meta, diff);

		Optimizer.addDefaultValues(this.data, {
			events: []
		});

		this.diffs = diff ?? this.meta.difficulties;
		return this;
	}
}

typedef FNFCodenameFormat =
{
	strumLines:Array<FNFCodenameStrumline>,
	events:Array<FNFCodenameEvent>,
	meta:FNFCodenameMeta,
	codenameChart:Bool,
	stage:String,
	scrollSpeed:Float,
	noteTypes:Array<String>
}

typedef FNFCodenameStrumline =
{
	position:String,
	strumScale:Float,
	visible:Bool,
	type:Int,
	characters:Array<String>,
	strumPos:Array<Float>,
	strumLinePos:Float,
	vocalsSuffix:String,
	notes:Array<FNFCodenameNote>,
	?keyCount:Int
}

typedef FNFCodenameNote =
{
	time:Float,
	id:Int,
	sLen:Float,
	type:Int
}

typedef FNFCodenameEvent =
{
	time:Float,
	name:String,
	params:Array<Dynamic>
}

typedef FNFCodenameMeta =
{
	name:String,
	?bpm:Float,
	?displayName:String,
	?beatsPerMeasure:Float,
	?stepsPerBeat:Float,
	?needsVoices:Bool,
	?icon:String,
	?color:Dynamic,
	?difficulties:Array<String>,
	?coopAllowed:Bool,
	?opponentModeAllowed:Bool,
	?customValues:Dynamic
}
