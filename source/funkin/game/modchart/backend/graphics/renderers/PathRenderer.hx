package funkin.game.modchart.backend.graphics.renderers;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxDestroyUtil;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

// Module-level base-position scratch vector — reset before each getPath call.
var pathVector = new Vector3();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class PathRenderer extends BaseRenderer<FlxSprite> {
	var __lineGraphic:FlxGraphic;
	var __lastDivisions:Int = -1;

	// Shared UVT and index buffers (rebuilt only when divisions change).
	var uvt:NativeVector<Float>;
	var indices:NativeVector<Int>;

	// Per-lane vertex and color-transform buffers (up to 16 lanes × 2 players = 32 slots).
	// Each lane's DrawCommand holds a reference to its own slot so no cross-frame aliasing.
	static final MAX_SLOTS = 32;
	var _laneVertexBufs:Array<NativeVector<Float>> = [for (_ in 0...MAX_SLOTS) null];
	var _laneTransformBufs:Array<NativeVector<ColorTransform>> = [for (_ in 0...MAX_SLOTS) null];

	// Pre-sampled modifier outputs for two-pass normal computation.
	var _outputs:NativeVector<ModifierOutput>;

	// Pre-allocated base-position vectors (one per division) — avoids clone() per sample.
	var _inputPool:Array<Vector3> = [];

	// Pre-allocated ArrowData scratch buffer.
	final _paramBuf:ArrowData = {hitTime: 0, distance: 0, lane: 0, player: 0, isTapArrow: true};

	public function updateTris(divisions:Int) {
		if (divisions != __lastDivisions) {
			uvt = new NativeVector<Float>(divisions * 12);
			indices = new NativeVector<Int>(divisions * 6);
			var ui = 0, ii = 0, vertCount = 0;
			for (div in 0...divisions) {
				for (_ in 0...4) {
					uvt.set(ui++, 0);
					uvt.set(ui++, 0);
					uvt.set(ui++, 1);
				}

				indices.set(ii++, vertCount);
				indices.set(ii++, vertCount + 1);
				indices.set(ii++, vertCount + 2);
				indices.set(ii++, vertCount + 1);
				indices.set(ii++, vertCount + 3);
				indices.set(ii++, vertCount + 2);

				vertCount += 4;
			}
		}
		__lastDivisions = divisions;
	}

	public function new(parent:ModPlayField) {
		super(parent);

		__lineGraphic = FlxG.bitmap.create(1, 1, 0xFFFFFFFF, true);
		__lineGraphic.destroyOnNoUse = false;
		__lineGraphic.persist = true;
	}

	var __lastPlayer:Int = -1;
	var __lastAlpha:Float = 0;
	var __lastThickness:Float = 0;

	// The entry sprite should be A RECEPTOR / STRUM.
	override public function prepare(item:FlxSprite):Null<DrawCommand> {
		final lane = Adapter.getLaneFromArrow(item);
		final fn = Adapter.getPlayerFromArrow(item);

		final canUseLast = fn == __lastPlayer;

		final pathAlpha = canUseLast ? __lastAlpha : parent.getPercent('arrowPathAlpha', fn);
		final pathThickness = canUseLast ? __lastThickness : parent.getPercent('arrowPathThickness', fn);

		if (pathAlpha <= 0 || pathThickness <= 0)
			return null;

		__lastAlpha = pathAlpha;
		__lastThickness = pathThickness;
		__lastPlayer = fn;

		final divisions = Std.int(Config.ARROW_PATHS_CONFIG.BASE_DIVISIONS * Config.ARROW_PATHS_CONFIG.RESOLUTION);
		final limit = 1800 + Config.ARROW_PATHS_CONFIG.LENGTH;
		final segs = divisions - 1;
		// Uniform sample spacing so distance=0 is at the receptor.
		final interval = limit / segs;
		final songPos = Conductor.songPosition;

		// Grow per-lane buffers as needed.
		final slot = lane + fn * 16;
		var vertices = _laneVertexBufs[slot];
		if (vertices == null || vertices.length < segs * 8)
			vertices = _laneVertexBufs[slot] = new NativeVector<Float>(segs * 8);

		var transforms = _laneTransformBufs[slot];
		if (transforms == null || transforms.length < segs)
			transforms = _laneTransformBufs[slot] = new NativeVector<ColorTransform>(segs);

		// Grow sampled-output buffer as needed.
		if (_outputs == null || _outputs.length < divisions)
			_outputs = new NativeVector<ModifierOutput>(divisions);

		// Grow input-vector pool as needed.
		while (_inputPool.length < divisions)
			_inputPool.push(new Vector3());

		final bx = Adapter.getDefaultReceptorX(lane, fn) + ModchartUtil.getHalfPos().x;
		final by = Adapter.getDefaultReceptorY(lane, fn) + ModchartUtil.getHalfPos().y;

		final colored = Config.ARROW_PATHS_CONFIG.APPLY_COLOR;
		final applyAlpha = Config.ARROW_PATHS_CONFIG.APPLY_ALPHA;

		// Phase 1: sample all modifier positions.
		for (index in 0...divisions) {
			final hitTime = interval * index;
			_paramBuf.hitTime = songPos + hitTime;
			_paramBuf.distance = hitTime;
			_paramBuf.lane = lane;
			_paramBuf.player = fn;
			_paramBuf.isTapArrow = true;
			final iv = _inputPool[index];
			iv.setTo(bx, by, 0);
			_outputs.set(index, parent.modifiers.getPath(iv, _paramBuf));
		}

		// Phase 2: build quad vertices with smooth (central-difference) normals.
		var vi = 0;
		var tID = 0;
		var hasC = false;
		var hasCOff = false;

		for (s in 0...segs) {
			final p0 = _outputs.get(s);
			final p1 = _outputs.get(s + 1);

			final pos0 = p0.pos;
			final pos1 = p1.pos;

			// Central-difference tangents for smooth normals.
			final prevPos = s > 0 ? _outputs.get(s - 1).pos : pos0;
			final nextPos = s + 2 < divisions ? _outputs.get(s + 2).pos : pos1;

			final tx0 = pos1.x - prevPos.x;
			final ty0 = pos1.y - prevPos.y;
			final len0 = Math.sqrt(tx0 * tx0 + ty0 * ty0);

			final tx1 = nextPos.x - pos0.x;
			final ty1 = nextPos.y - pos0.y;
			final len1 = Math.sqrt(tx1 * tx1 + ty1 * ty1);

			// Degenerate segment guard.
			if (len0 < 1e-9 || len1 < 1e-9) {
				vi += 8;
				continue;
			}

			final nx0 = -ty0 / len0;
			final ny0 = tx0 / len0;
			final nx1 = -ty1 / len1;
			final ny1 = tx1 / len1;

			final t0 = (pathThickness * (Config.ARROW_PATHS_CONFIG.APPLY_SCALE ? p0.visuals.scaleX : 1) * (Config.ARROW_PATHS_CONFIG.APPLY_DEPTH ? 1 / pos0.z : 1)) * 0.5;
			final t1 = (pathThickness * (Config.ARROW_PATHS_CONFIG.APPLY_SCALE ? p1.visuals.scaleX : 1) * (Config.ARROW_PATHS_CONFIG.APPLY_DEPTH ? 1 / pos1.z : 1)) * 0.5;

			vertices.set(vi++, pos0.x + nx0 * t0);
			vertices.set(vi++, pos0.y + ny0 * t0);
			vertices.set(vi++, pos0.x - nx0 * t0);
			vertices.set(vi++, pos0.y - ny0 * t0);
			vertices.set(vi++, pos1.x + nx1 * t1);
			vertices.set(vi++, pos1.y + ny1 * t1);
			vertices.set(vi++, pos1.x - nx1 * t1);
			vertices.set(vi++, pos1.y - ny1 * t1);

			final glow = colored ? p0.visuals.glow : 0.;
			final fAlpha = applyAlpha ? p0.visuals.alpha : 1.;
			final negGlow = 1 - glow;
			final absGlow = glow * 255;

			var ctr:ColorTransform;
			transforms.set(tID++, ctr = new ColorTransform(negGlow, negGlow, negGlow, fAlpha * pathAlpha, Math.round(p0.visuals.glowR * absGlow),
				Math.round(p0.visuals.glowG * absGlow), Math.round(p0.visuals.glowB * absGlow)));

			if (ctr.hasRGBMultipliers() || ctr.alphaMultiplier != 1)
				hasC = true;
			if (ctr.hasRGBAOffsets())
				hasCOff = true;
		}

		updateTris(divisions);

		return {
			parent: item,
			graphic: __lineGraphic,
			antialiasing: false,
			blend: NORMAL,
			cameras: ModchartUtil.resolveCameras(parent, item),
			shader: null,
			vertices: vertices,
			uvs: uvt,
			indices: indices,
			colors: transforms,
			isColored: hasC,
			hasColorOffsets: hasCOff
		};
	}

	override function dispose() {
		__lineGraphic.destroy();
		__lineGraphic = null;
	}
}