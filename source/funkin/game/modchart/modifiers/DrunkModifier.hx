package funkin.game.modchart.modifiers;

// Drunk calculations were too expensive so I had to optimize it.
class DrunkModifier extends NoteModifier {
	override function getName() return 'drunk';

	var _time:Float = 0;

	var _dV:Float; var _dSpd:Float; var _dPer:Float; var _dOff:Float;
	var _dYV:Float; var _dYSpd:Float; var _dYPer:Float; var _dYOff:Float;
	var _dZV:Float; var _dZSpd:Float; var _dZPer:Float; var _dZOff:Float;

	var _tV:Float; var _tSpd:Float; var _tOff:Float;
	var _tXV:Float; var _tXSpd:Float; var _tXOff:Float;
	var _tZV:Float; var _tZSpd:Float; var _tZOff:Float;

	var _bV:Float; var _bPer:Float; var _bOff:Float;
	var _bXV:Float; var _bXPer:Float; var _bXOff:Float;
	var _bYV:Float; var _bYPer:Float; var _bYOff:Float;

	function getDrunkCos(perc:Float, spd:Float, per:Float, off:Float, time:Float, vd:Float, data:Float):Float {
		if (perc == 0) return 0;
		var angle = time * (1 + spd) + data * (off * 0.2 + 0.2) + vd * (per * 10 + 10) / FlxG.height;
		return perc * Math.cos(angle) * (Note.swagWidth * 0.5);
	}

	function getDrunkTan(perc:Float, spd:Float, per:Float, off:Float, time:Float, vd:Float, data:Float):Float {
		if (perc == 0) return 0;
		var angle = time * (1 + spd) + data * (off * 0.2 + 0.2) + vd * (per * 10 + 10) / FlxG.height;
		return perc * Math.tan(angle) * (Note.swagWidth * 0.5);
	}

	function getTipsyCos(perc:Float, spd:Float, off:Float, time:Float, data:Float):Float {
		if (perc == 0) return 0;
		return perc * Math.cos(time * (spd * 1.2 + 1.2) + data * (off * 1.8 + 1.8)) * Note.swagWidth * 0.4;
	}

	function getTipsyTan(perc:Float, spd:Float, off:Float, time:Float, data:Float):Float {
		if (perc == 0) return 0;
		return perc * Math.tan(time * (spd * 1.2 + 1.2) + data * (off * 1.8 + 1.8)) * Note.swagWidth * 0.4;
	}

	function getBumpySin(perc:Float, per:Float, off:Float, vd:Float):Float {
		if (perc == 0 || per == -1) return 0;
		return perc * 40 * Math.sin((vd + 100 * off) / (per * 24 + 24));
	}

	function getBumpyTan(perc:Float, per:Float, off:Float, vd:Float):Float {
		if (perc == 0 || per == -1) return 0;
		return perc * 40 * Math.tan((vd + 100 * off) / (per * 24 + 24));
	}

	function getSubmodValues(player:Int):Void {
		_dV = getValue(player);
		_dSpd = getSubmodValue('drunkSpeed', player);
		_dPer = getSubmodValue('drunkPeriod', player);
		_dOff = getSubmodValue('drunkOffset', player);

		_dYV = getSubmodValue('drunkY', player);
		_dYSpd = getSubmodValue('drunkYSpeed', player);
		_dYPer = getSubmodValue('drunkYPeriod', player);
		_dYOff = getSubmodValue('drunkYOffset', player);

		_dZV = getSubmodValue('drunkZ', player);
		_dZSpd = getSubmodValue('drunkZSpeed', player);
		_dZPer = getSubmodValue('drunkZPeriod', player);
		_dZOff = getSubmodValue('drunkZOffset', player);

		_tV = getSubmodValue('tipsy', player) + getSubmodValue('tip', player);
		_tSpd = getSubmodValue('tipsySpeed', player) + getSubmodValue('tipSpeed', player);
		_tOff = getSubmodValue('tipsyOffset', player) + getSubmodValue('tipOffset', player);

		_tXV = getSubmodValue('tipsyX', player) + getSubmodValue('tipX', player);
		_tXSpd = getSubmodValue('tipsyXSpeed', player) + getSubmodValue('tipXSpeed', player);
		_tXOff = getSubmodValue('tipsyXOffset', player) + getSubmodValue('tipXOffset', player);

		_tZV = getSubmodValue('tipsyZ', player) + getSubmodValue('tipZ', player);
		_tZSpd = getSubmodValue('tipsyZSpeed', player) + getSubmodValue('tipZSpeed', player);
		_tZOff = getSubmodValue('tipsyZOffset', player) + getSubmodValue('tipZOffset', player);

		_bV = getSubmodValue('bumpy', player);
		_bPer = getSubmodValue('bumpyPeriod', player);
		_bOff = getSubmodValue('bumpyOffset', player);

		_bXV = getSubmodValue('bumpyX', player);
		_bXPer = getSubmodValue('bumpyXPeriod', player);
		_bXOff = getSubmodValue('bumpyXOffset', player);

		_bYV = getSubmodValue('bumpyY', player);
		_bYPer = getSubmodValue('bumpyYPeriod', player);
		_bYOff = getSubmodValue('bumpyYOffset', player);
	}

	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite){
		_time = Conductor.songPosition * 0.001;
		final t = _time;
		final vd = visualDiff;
		final d = data;

		getSubmodValues(player);

		pos.x += getDrunkCos(_dV, _dSpd, _dPer, _dOff, t, vd, d)
		        + getTipsyCos(_tXV, _tXSpd, _tXOff, t, d)
		        + getBumpySin(_bXV, _bXPer, _bXOff, vd);

		pos.y += getDrunkCos(_dYV, _dYSpd, _dYPer, _dYOff, t, vd, d)
		        + getTipsyCos(_tV, _tSpd, _tOff, t, d)
		        + getBumpySin(_bYV, _bYPer, _bYOff, vd);

		pos.z += (getDrunkCos(_dZV, _dZSpd, _dZPer, _dZOff, t, vd, d) 
				+ getTipsyCos(_tZV, _tZSpd, _tZOff, t, d)
		        + getBumpySin(_bV, _bPer, _bOff, vd)) / 1280;

		final ds = Std.string(d);

		final dDV = getSubmodValue('drunk$ds', player);
		final dDSpd = getSubmodValue('drunk${ds}Speed', player);
		final dDPer = getSubmodValue('drunk${ds}Period', player);
		final dDOff = getSubmodValue('drunk${ds}Offset', player);

		final dDYV = getSubmodValue('drunkY$ds', player);
		final dDYSpd = getSubmodValue('drunkY${ds}Speed', player);
		final dDYPer = getSubmodValue('drunkY${ds}Period', player);
		final dDYOff = getSubmodValue('drunkY${ds}Offset', player);

		final dDZV = getSubmodValue('drunkZ$ds', player);
		final dDZSpd = getSubmodValue('drunkZ${ds}Speed', player);
		final dDZPer = getSubmodValue('drunkZ${ds}Period', player);
		final dDZOff = getSubmodValue('drunkZ${ds}Offset', player);

		final tDV = getSubmodValue('tipsy$ds', player) + getSubmodValue('tip$ds', player);
		final tDSpd = getSubmodValue('tipsy${ds}Speed', player) + getSubmodValue('tip${ds}Speed', player);
		final tDOff = getSubmodValue('tipsy${ds}Offset', player) + getSubmodValue('tip${ds}Offset', player);

		final tXDV = getSubmodValue('tipsyX$ds', player) + getSubmodValue('tipX$ds', player);
		final tXDSpd = getSubmodValue('tipsyX${ds}Speed', player) + getSubmodValue('tipX${ds}Speed', player);
		final tXDOff = getSubmodValue('tipsyX${ds}Offset', player) + getSubmodValue('tipX${ds}Offset', player);

		final tZDV = getSubmodValue('tipsyZ$ds', player) + getSubmodValue('tipZ$ds', player);
		final tZDSpd = getSubmodValue('tipsyZ${ds}Speed', player) + getSubmodValue('tipZ${ds}Speed', player);
		final tZDOff = getSubmodValue('tipsyZ${ds}Offset', player) + getSubmodValue('tipZ${ds}Offset', player);

		final bDV = getSubmodValue('bumpy$ds', player);
		final bDPer = getSubmodValue('bumpy${ds}Period', player);
		final bDOff = getSubmodValue('bumpy${ds}Offset', player);

		final bXDV = getSubmodValue('bumpyX$ds', player);
		final bXDPer = getSubmodValue('bumpyX${ds}Period', player);
		final bXDOff = getSubmodValue('bumpyX${ds}Offset', player);

		final bYDV = getSubmodValue('bumpyY$ds', player);
		final bYDPer = getSubmodValue('bumpyY${ds}Period', player);
		final bYDOff = getSubmodValue('bumpyY${ds}Offset', player);

		pos.x += getDrunkCos(dDV, dDSpd, dDPer, dDOff, t, vd, d)
		        + getTipsyCos(tXDV, tXDSpd, tXDOff, t, d)
		        + getBumpySin(bXDV, bXDPer, bXDOff, vd);

		pos.y += getDrunkCos(dDYV, dDYSpd, dDYPer, dDYOff, t, vd, d)
		        + getTipsyCos(tDV, tDSpd, tDOff, t, d)
		        + getBumpySin(bYDV, bYDPer, bYDOff, vd);

		pos.z += (getDrunkCos(dDZV, dDZSpd, dDZPer, dDZOff, t, vd, d)
		        + getTipsyCos(tZDV, tZDSpd, tZDOff, t, d)
		        + getBumpySin(bDV, bDPer, bDOff, vd)) / 1280;

		final dTanV = getSubmodValue('drunkTan', player);
		final dTanSpd = getSubmodValue('drunkTanSpeed', player);
		final dTanPer = getSubmodValue('drunkTanPeriod', player);
		final dTanOff = getSubmodValue('drunkTanOffset', player);

		final dTanYV = getSubmodValue('drunkTanY', player);
		final dTanYSpd = getSubmodValue('drunkTanYSpeed', player);
		final dTanYPer = getSubmodValue('drunkTanYPeriod', player);
		final dTanYOff = getSubmodValue('drunkTanYOffset', player);

		final dTanZV = getSubmodValue('drunkTanZ', player);
		final dTanZSpd = getSubmodValue('drunkTanZSpeed', player);
		final dTanZPer = getSubmodValue('drunkTanZPeriod', player);
		final dTanZOff = getSubmodValue('drunkTanZOffset', player);

		final tTanV = getSubmodValue('tipsyTan', player) + getSubmodValue('tipTan', player);
		final tTanSpd = getSubmodValue('tipsyTanSpeed',   player) + getSubmodValue('tipTanSpeed', player);
		final tTanOff = getSubmodValue('tipsyTanOffset',  player) + getSubmodValue('tipTanOffset', player);

		final tTanXV = getSubmodValue('tipsyTanX',        player) + getSubmodValue('tipTanX', player);
		final tTanXSpd = getSubmodValue('tipsyTanXSpeed',   player) + getSubmodValue('tipTanXSpeed', player);
		final tTanXOff = getSubmodValue('tipsyTanXOffset',  player) + getSubmodValue('tipTanXOffset', player);

		final tTanZV = getSubmodValue('tipsyTanZ', player) + getSubmodValue('tipTanZ', player);
		final tTanZSpd = getSubmodValue('tipsyTanZSpeed', player) + getSubmodValue('tipTanZSpeed', player);
		final tTanZOff = getSubmodValue('tipsyTanZOffset', player) + getSubmodValue('tipTanZOffset', player);

		final bTanV = getSubmodValue('bumpyTan', player);
		final bTanPer = getSubmodValue('bumpyTanPeriod', player);
		final bTanOff = getSubmodValue('bumpyTanOffset', player);

		final bTanXV = getSubmodValue('bumpyTanX', player);
		final bTanXPer = getSubmodValue('bumpyTanXPeriod', player);
		final bTanXOff = getSubmodValue('bumpyTanXOffset', player);

		final bTanYV = getSubmodValue('bumpyTanY', player);
		final bTanYPer = getSubmodValue('bumpyTanYPeriod', player);
		final bTanYOff = getSubmodValue('bumpyTanYOffset', player);

		pos.x += getDrunkTan(dTanV, dTanSpd, dTanPer, dTanOff, t, vd, d)
		        + getTipsyTan(tTanXV, tTanXSpd, tTanXOff, t, d)
		        + getBumpyTan(bTanXV, bTanXPer, bTanXOff, vd);

		pos.y +=  getDrunkTan(dTanYV, dTanYSpd, dTanYPer, dTanYOff, t, vd, d)
		        + getTipsyTan(tTanV, tTanSpd, tTanOff, t, d)
		        + getBumpyTan(bTanYV, bTanYPer, bTanYOff, vd);

		pos.z += (getDrunkTan(dTanZV, dTanZSpd, dTanZPer, dTanZOff, t, vd, d)
		        + getTipsyTan(tTanZV, tTanZSpd, tTanZOff, t, d)
		        + getBumpyTan(bTanV, bTanPer, bTanOff, vd)) / 1280;

		final dTDV = getSubmodValue('drunkTan$ds', player);
		final dTDSpd = getSubmodValue('drunkTan${ds}Speed', player);
		final dTDPer = getSubmodValue('drunkTan${ds}Period', player);
		final dTDOff = getSubmodValue('drunkTan${ds}Offset', player);

		final dTDYV = getSubmodValue('drunkTanY$ds', player);
		final dTDYSpd = getSubmodValue('drunkTanY${ds}Speed', player);
		final dTDYPer = getSubmodValue('drunkTanY${ds}Period', player);
		final dTDYOff = getSubmodValue('drunkTanY${ds}Offset', player);

		final dTDZV = getSubmodValue('drunkTanZ$ds', player);
		final dTDZSpd = getSubmodValue('drunkTanZ${ds}Speed', player);
		final dTDZPer = getSubmodValue('drunkTanZ${ds}Period', player);
		final dTDZOff = getSubmodValue('drunkTanZ${ds}Offset', player);

		final tTDV = getSubmodValue('tipsyTan$ds', player) + getSubmodValue('tipTan$ds', player);
		final tTDSpd = getSubmodValue('tipsyTan${ds}Speed', player) + getSubmodValue('tipTan${ds}Speed', player);
		final tTDOff = getSubmodValue('tipsyTan${ds}Offset', player) + getSubmodValue('tipTan${ds}Offset', player);

		final tTXDV = getSubmodValue('tipsyTanX$ds', player) + getSubmodValue('tipTanX$ds', player);
		final tTXDSpd = getSubmodValue('tipsyTanX${ds}Speed', player) + getSubmodValue('tipTanX${ds}Speed', player);
		final tTXDOff = getSubmodValue('tipsyTanX${ds}Offset', player) + getSubmodValue('tipTanX${ds}Offset', player);

		final tTZDV = getSubmodValue('tipsyTanZ$ds', player) + getSubmodValue('tipTanZ$ds', player);
		final tTZDSpd = getSubmodValue('tipsyTanZ${ds}Speed', player) + getSubmodValue('tipTanZ${ds}Speed', player);
		final tTZDOff = getSubmodValue('tipsyTanZ${ds}Offset', player) + getSubmodValue('tipTanZ${ds}Offset', player);

		final bTDV = getSubmodValue('bumpyTan$ds', player);
		final bTDPer = getSubmodValue('bumpyTan${ds}Period', player);
		final bTDOff = getSubmodValue('bumpyTan${ds}Offset', player);

		final bTXDV = getSubmodValue('bumpyTanX$ds', player);
		final bTXDPer = getSubmodValue('bumpyTanX${ds}Period', player);
		final bTXDOff = getSubmodValue('bumpyTanX${ds}Offset', player);

		final bTYDV = getSubmodValue('bumpyTanY$ds', player);
		final bTYDPer = getSubmodValue('bumpyTanY${ds}Period', player);
		final bTYDOff = getSubmodValue('bumpyTanY${ds}Offset', player);

		pos.x += getDrunkTan(dTDV, dTDSpd, dTDPer, dTDOff, t, vd, d)
		        + getTipsyTan(tTXDV, tTXDSpd, tTXDOff, t, d)
		        + getBumpyTan(bTXDV, bTXDPer, bTXDOff, vd);

		pos.y +=  getDrunkTan(dTDYV, dTDYSpd, dTDYPer, dTDYOff, t, vd, d)
		        + getTipsyTan(tTDV, tTDSpd, tTDOff, t, d)
		        + getBumpyTan(bTYDV, bTYDPer, bTYDOff, vd);

		pos.z += (getDrunkTan(dTDZV, dTDZSpd, dTDZPer, dTDZOff, t, vd, d)
		        + getTipsyTan(tTZDV, tTZDSpd, tTZDOff, t, d)
		        + getBumpyTan(bTDV, bTDPer, bTDOff, vd)) / 1280;

		return pos;
	}

	override function getSubmods() {
		final axes  = ["X", "Y", "Z"];
		final props = [
			["Speed", "Offset", "Period"],
			["Speed", "Offset"],
			["Speed", "Offset"],
			["Offset", "Period"],
			["Speed", "Offset", "Period"],
			["Speed", "Offset"],
			["Offset", "Period"]
		];
		final shids = ["drunk", "tipsy", "tip", "bumpy", "drunkTan", "tipsyTan", "bumpyTan"];
		final mania = PlayState.SONG.mania;
		final submods:Array<String> = [];

		for (i in 0...shids.length) {
			final mod = shids[i];
			final p   = props[i];
			for (a in 0...axes.length) {
				var axe = axes[a];
				if (a == (i % axes.length)) axe = '';
				submods.push('$mod$axe');
				for (prop in p) submods.push('$mod$axe$prop');
				for (col in 0...mania + 1) {
					submods.push('$mod$axe$col');
					for (prop in p) submods.push('$mod$axe$col$prop');
				}
			}
		}
		submods.remove("drunk");
		return submods;
	}
}