package moonchart.formats.fnf.legacy;

import moonchart.backend.FormatData;
import moonchart.backend.Util;
import moonchart.formats.BasicFormat;
import moonchart.formats.fnf.legacy.FNFLegacy;
import moonchart.formats.fnf.legacy.FNFPsych;

typedef NotepulseJsonFormat = PsychJsonFormat &
{
	?format:String,
	?mania:Int,
	?lanes:Int
}

private final KEYS_PER_PLAYER:Int = 4;

@:private
@:noCompletion
class FNFNotepulseBasic<T:NotepulseJsonFormat> extends FNFPsychBasic<T>
{
	public static function __getFormat():FormatData
	{
		return {
			ID: FNF_LEGACY_NOTEPULSE,
			name: "FNF (Notepulse)",
			description: "FNF Legacy branching format that stores per-note lane data.",
			extension: "json",
			formatFile: FNFLegacy.formatFile,
			hasMetaFile: POSSIBLE,
			metaFileExtension: "json",
			specialValues: ['"format":"notepulse"', '?"mania":', '?"lanes":'],
			handler: FNFNotepulseBasic
		}
	}

	public function new(?data:T)
	{
		super(data);
	}

	override function resolvePsychEvent(event:BasicEvent):PsychEvent
	{
		var values:Array<Dynamic> = Util.resolveEventValues(event);

		var value1:String = Std.string(values[0] ?? "");

		var extra:Array<String> = [];
		for (i in 1...values.length)
		{
			extra.push(Std.string(values[i] ?? ""));
		}
		var value2:String = extra.join(",");

		return [event.time, [[event.name, value1, value2]]];
	}

	override function fromBasicFormat(chart:BasicChart, ?diff:FormatDifficulty):FNFNotepulseBasic<T>
	{
		offsetMustHits = false;
		chart.meta.extraData.set(LANES_LENGTH, 4);

		var maxLane:Int = -1;
		var playerQueue:Map<String, Array<Int>> = [];

		for (notes in chart.data.diffs)
		{
			for (note in notes)
			{
				if (note.lane > maxLane)
					maxLane = note.lane;

				var player:Int = Std.int(note.lane / KEYS_PER_PLAYER);
				var localLane:Int = note.lane % KEYS_PER_PLAYER;

				var key:String = Std.string(note.time);
				if (!playerQueue.exists(key))
					playerQueue.set(key, []);
				playerQueue.get(key).push(player);

				note.lane = localLane;
			}
		}

		var totalLanes:Int = maxLane + 1;
		if (totalLanes <= 0)
			totalLanes = KEYS_PER_PLAYER;
		var lanes:Int = Std.int(Math.max(1, Math.ceil(totalLanes / KEYS_PER_PLAYER)));
		var mania:Int = KEYS_PER_PLAYER - 1;

		var basic = super.fromBasicFormat(chart, diff);
		var song = basic.data.song;

		song.format = "notepulse";
		song.mania = mania;
		song.lanes = lanes;

		var offset:Float = chart.meta.offset;

		for (section in song.notes)
		{
			var sectionNotes:Array<FNFLegacyNote> = section.sectionNotes;

			for (note in sectionNotes)
			{
				if (note == null || note.lane <= -1)
					continue;

				var originalTime:Float = note.time + (bakedOffset ? offset : 0);
				var key:String = Std.string(originalTime);
				var queue = playerQueue.get(key);
				var player:Int = (queue != null && queue.length > 0) ? queue.shift() : 0;

				var rawNote:Array<Dynamic> = cast note;
				rawNote[4] = player;
			}
		}

		return cast basic;
	}

	override function getChartMeta():BasicMetaData
	{
		var meta = super.getChartMeta();
		meta.extraData.set("mania", data.song.mania ?? (KEYS_PER_PLAYER - 1));
		meta.extraData.set("lanes", data.song.lanes ?? 1);
		return meta;
	}
}

typedef FNFNotepulse = FNFNotepulseBasic<NotepulseJsonFormat>;