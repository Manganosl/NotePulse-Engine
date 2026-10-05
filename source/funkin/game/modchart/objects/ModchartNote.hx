package funkin.game.modchart.objects;

import flixel.math.FlxPoint;

import funkin.objects.FunkinSprite;
import funkin.game.modchart.math.Vector3;
import funkin.game.modchart.math.MathUtil;

import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import openfl.geom.ColorTransform;

typedef CurveData = {
	var vertices:DrawData<Float>;
	var indices:DrawData<Int>;
	var UVT:DrawData<Float>;
	var samplesX:Array<Float>;
	var samplesY:Array<Float>;
	var topX:Array<Float>;
	var topY:Array<Float>;
	var botX:Array<Float>;
	var botY:Array<Float>;
	var point:FlxPoint;
	var transform:ColorTransform;
}

class ModchartNote extends FunkinSprite {
	public var vec3Cache:Vector3 = new Vector3();
	public var defScale:FlxPoint = FlxPoint.get();

	public var z:Float = 0;

	public var mAngle:Float = 0;
	public var bAngle:Float = 0;
	public var visualLength:Float = 0;

	public var extraSusLength:Int = 0;
	public var modSpeed:Float = 1;

	var _curveData:CurveData = {
		vertices: new DrawData<Float>(),
		indices: DrawData.ofArray([0, 1, 2, 1, 3, 2]),
		UVT: new DrawData<Float>(),
		samplesX: [],
		samplesY: [],
		topX: [],
		topY: [],
		botX: [],
		botY: [],
		point: FlxPoint.get(),
		transform: new ColorTransform()
	}

	override function destroy() {
		defScale.put();
		_curveData.point.put();
		super.destroy();
	}

	function drawSustain() {
		final n:Note = cast this;
		if (frames == null || frame == null) {
			super.draw();
			return;
		}

		final pf:Dynamic = n.createdFrom;
		final modManager:Dynamic = pf.modManager;
		final pN:Int = n.playField != null ? n.playField.player : 0;
		final songSpeed:Float = pf.songSpeed;

		@:privateAccess
		var segLength:Float = Math.max(((pf.initialCrochet + 8) / 4), 10);
		if (!n.isSustainEnd && n.nextNote != null && n.nextNote.isSustainNote)
			segLength = Math.max(n.nextNote.strumTime - n.strumTime + 2 + extraSusLength, 1);

		final halfW:Float = frameWidth * 0.5 * Math.abs(scale.x);

		var tStart:Float = 0;
		if (clipRect != null && frameHeight > 0)
			tStart = Math.max(0, Math.min(1, clipRect.y / frameHeight));

		if (tStart >= 1) return;

		_curveData.samplesX.resize(0);
		_curveData.samplesY.resize(0);

		var sampleAlphas:Array<Float> = [];
		var sampleGlows:Array<Float> = [];
		var sampleVDiffs:Array<Float> = [];

		final segs:Int = n.playField.sustainSegments;

		var ptX:Float = 0, ptY:Float = 0, ptA:Float = 1, ptG:Float = 0;
		inline function evalPoint(sampleStrumTime:Float, vDiff:Float):Void {
			final diff:Float = sampleStrumTime - Conductor.songPosition;
			final sampBeat:Float = Conductor.getStep(sampleStrumTime) / 4;

			var samplePos = modManager.getPos(n.strumTime, vDiff, diff, sampBeat, n.noteData, pN, this, [], vec3Cache);
			var sx:Float = samplePos.x + n.offsetX;
			var sy:Float = samplePos.y + n.offsetY;
			if (n.parent != null) {
				sx += n.parent.width / 2 - width / 2;
				sy += n.parent.height / 2;
			}
			sy += n.strum.y - 50;

			sx += origin.x - offset.x;
			sy += origin.y - offset.y;

			ptX = sx;
			ptY = sy;
			ptA = samplePos.alpha;
			ptG = samplePos.glow;
		}

		final totalLen:Float = frameHeight * Math.abs(scale.y);
		var fixedEnd:Bool = false;
		var baseVDiff:Float = 0;
		var pxPerMs:Float = 0;
		var dirSign:Float = 1;
		if(n.isSustainEnd){
			baseVDiff = modManager.getVisPos(Conductor.songPosition, n.strumTime, songSpeed);
			final rawPx:Float = modManager.getVisPos(Conductor.songPosition, n.strumTime + 1, songSpeed) - baseVDiff;
			pxPerMs = Math.abs(rawPx);
			dirSign = rawPx >= 0 ? 1 : -1;
			fixedEnd = pxPerMs > 0.0001 && totalLen > 0.0001;
		}

		if(fixedEnd){
			final dS:Array<Float> = [0];
			final dX:Array<Float> = [];
			final dY:Array<Float> = [];
			final dA:Array<Float> = [];
			final dG:Array<Float> = [];
			final dL:Array<Float> = [0];

			evalPoint(n.strumTime, baseVDiff);
			dX.push(ptX); dY.push(ptY); dA.push(ptA); dG.push(ptG);

			final ds:Float = totalLen / (segs * 4);
			final maxSteps:Int = segs * 4 * 8;
			var cum:Float = 0;
			var k:Int = 0;
			while (cum < totalLen && k < maxSteps) {
				k++;
				final sOff:Float = ds * k;
				evalPoint(n.strumTime + sOff / pxPerMs, baseVDiff + dirSign * sOff);
				final last:Int = dX.length - 1;
				final ddx:Float = ptX - dX[last];
				final ddy:Float = ptY - dY[last];
				cum += Math.sqrt(ddx * ddx + ddy * ddy);
				dS.push(sOff); dX.push(ptX); dY.push(ptY); dA.push(ptA); dG.push(ptG); dL.push(cum);
			}

			if(cum < totalLen){
				final n:Int = dX.length;
				var dirX:Float = 0, dirY:Float = 1;
				if(n >= 2){
					final ex:Float = dX[n - 1] - dX[n - 2];
					final ey:Float = dY[n - 1] - dY[n - 2];
					final el:Float = Math.sqrt(ex * ex + ey * ey);
					if (el > 0.0001) { dirX = ex / el; dirY = ey / el; }
				}
				final rest:Float = totalLen - cum;
				dS.push(dS[n - 1]);
				dX.push(dX[n - 1] + dirX * rest);
				dY.push(dY[n - 1] + dirY * rest);
				dA.push(dA[n - 1]);
				dG.push(dG[n - 1]);
				dL.push(totalLen);
			}

			var j:Int = 1;
			for(i in 0...segs + 1){
				final target:Float = totalLen * (tStart + (1 - tStart) * (i / segs));
				while (j < dL.length - 1 && dL[j] < target) j++;
				final l0:Float = dL[j - 1];
				final l1:Float = dL[j];
				final f:Float = (l1 - l0) > 0.00001 ? Math.max(0, Math.min(1, (target - l0) / (l1 - l0))) : 0;

				_curveData.samplesX.push(dX[j - 1] + (dX[j] - dX[j - 1]) * f);
				_curveData.samplesY.push(dY[j - 1] + (dY[j] - dY[j - 1]) * f);
				sampleAlphas.push(dA[j - 1] + (dA[j] - dA[j - 1]) * f);
				sampleGlows.push(dG[j - 1] + (dG[j] - dG[j - 1]) * f);
				sampleVDiffs.push(baseVDiff + dirSign * (dS[j - 1] + (dS[j] - dS[j - 1]) * f));
			}
		} else {
			for(i in 0...segs + 1){
				final t:Float = tStart + (1 - tStart) * (i / segs);
				final sampleStrumTime:Float = n.strumTime + segLength * t;
				final vDiff:Float = modManager.getVisPos(Conductor.songPosition, sampleStrumTime, songSpeed);

				sampleVDiffs.push(vDiff);
				evalPoint(sampleStrumTime, vDiff);

				_curveData.samplesX.push(ptX);
				_curveData.samplesY.push(ptY);
				sampleAlphas.push(ptA);
				sampleGlows.push(ptG);
			}
		}
		
		final texW:Float = frames.parent.width;
		final texH:Float = frames.parent.height;
		final uStart:Float = frame.frame.x / texW, uEnd:Float = (frame.frame.x + frame.frame.width) / texW;
		final vStart:Float = frame.frame.y / texH, vEnd:Float = (frame.frame.y + frame.frame.height) / texH;
		final sampleCount:Int = _curveData.samplesX.length;

		_curveData.topX.resize(0);
		_curveData.topY.resize(0);
		_curveData.botX.resize(0);
		_curveData.botY.resize(0);

		for (i in 0...sampleCount){
			final px:Float = _curveData.samplesX[i];
			final py:Float = _curveData.samplesY[i];
			final prevI:Int = (i > 0) ? i - 1 : i;
			final nextI:Int = (i < sampleCount - 1) ? i + 1 : i;

			var dx:Float = _curveData.samplesX[nextI] - _curveData.samplesX[prevI];
			var dy:Float = _curveData.samplesY[nextI] - _curveData.samplesY[prevI];
			final len:Float = Math.sqrt(dx * dx + dy * dy);
			if(len > 0.0001){
				dx /= len;
				dy /= len;
			} else { 
				dx = 0;
				dy = 1;
			}

			final nx:Float = -dy * halfW;
			final ny:Float = dx * halfW;

			_curveData.topX.push(px + nx);
			_curveData.topY.push(py + ny);
			_curveData.botX.push(px - nx);
			_curveData.botY.push(py - ny);
		}

		final tPrevs:Array<Float> = [];
		final tCurs:Array<Float> = [];
		for (i in 1...sampleCount) {
			tPrevs.push(tStart + (1 - tStart) * ((i - 1) / n.playField.sustainSegments));
			tCurs.push(tStart + (1 - tStart) * (i / n.playField.sustainSegments));
		}

		for (camera in cameras){
			if (camera == null || !camera.visible || !camera.exists) continue;

			final scrollX:Float = camera.scroll.x * scrollFactor.x;
			final scrollY:Float = camera.scroll.y * scrollFactor.y;

			final angleRad:Float = camera.angle * (Math.PI / 180);
			final cosA:Float = Math.cos(angleRad);
			final sinA:Float = Math.sin(angleRad);
			final camCenterX:Float = camera.width * 0.5;
			final camCenterY:Float = camera.height * 0.5;

			inline function transform(x:Float, y:Float):{x:Float, y:Float} {
				final sx:Float = x - scrollX;
				final sy:Float = y - scrollY;
				final relX:Float = sx - camCenterX;
				final relY:Float = sy - camCenterY;
				final rx:Float = relX * cosA - relY * sinA;
				final ry:Float = relX * sinA + relY * cosA;
				return {x: rx + camCenterX, y: ry + camCenterY};
			}

			final topT:Array<{x:Float, y:Float}> = [for (i in 0...sampleCount) transform(_curveData.topX[i], _curveData.topY[i])];
			final botT:Array<{x:Float, y:Float}> = [for (i in 0...sampleCount) transform(_curveData.botX[i], _curveData.botY[i])];

			final camAlphaMult:Float = MathUtil.clamp(alpha * camera.alpha, 0, 1);

			_curveData.point.set(0, 0);

			for (i in 1...sampleCount){
				if(n.strum.sustainReduce && n.wasGoodHit && sampleVDiffs[i - 1] <= 0 && sampleVDiffs[i] <= 0) continue;

				_curveData.vertices.length = 0;
				_curveData.UVT.length = 0;

				_curveData.vertices.push(topT[i - 1].x);
				_curveData.vertices.push(topT[i - 1].y);
				_curveData.vertices.push(botT[i - 1].x);
				_curveData.vertices.push(botT[i - 1].y);
				_curveData.vertices.push(topT[i].x);
				_curveData.vertices.push(topT[i].y);
				_curveData.vertices.push(botT[i].x);
				_curveData.vertices.push(botT[i].y);

				final vPrev:Float = vStart + (vEnd - vStart) * tPrevs[i - 1];
				final vCur:Float  = vStart + (vEnd - vStart) * tCurs[i - 1];

				_curveData.UVT.push(uStart);
				_curveData.UVT.push(vPrev);
				_curveData.UVT.push(uEnd);
				_curveData.UVT.push(vPrev);
				_curveData.UVT.push(uStart);
				_curveData.UVT.push(vCur);
				_curveData.UVT.push(uEnd);
				_curveData.UVT.push(vCur);

				final segAlpha:Float = (sampleAlphas[i - 1] + sampleAlphas[i]) * 0.5;
				final segGlow:Float = (sampleGlows[i - 1] + sampleGlows[i]) * 0.5;

				_curveData.transform.redMultiplier = 1 - segGlow;
				_curveData.transform.greenMultiplier = 1 - segGlow;
				_curveData.transform.blueMultiplier = 1 - segGlow;
				_curveData.transform.redOffset = 255 * segGlow;
				_curveData.transform.greenOffset = 255 * segGlow;
				_curveData.transform.blueOffset = 255 * segGlow;
				_curveData.transform.alphaMultiplier = segAlpha * camAlphaMult * (n.copyAlpha ? n.strum.alpha : 1);
				_curveData.transform.alphaOffset = 0;

				camera.drawTriangles(frames.parent, _curveData.vertices, _curveData.indices, _curveData.UVT, null,
					_curveData.point, blend, true, antialiasing, _curveData.transform, shader);
			}
		}
	}
}
