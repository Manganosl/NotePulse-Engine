package modchart.backend.graphics.renderers;

final matrix:Matrix = new Matrix();
final fMatrix:FlxMatrix = new FlxMatrix();
final rotationVector = new Vector3();
final helperVector = new Vector3();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class ModchartNVHoldRenderer extends ModchartRenderer<FlxSprite> {
	private var __rotateX:Float = 0;
    private var __rotateY:Float = 0;
    private var __rotateZ:Float = 0;
    private var __parentOutput:ModifierOutput;

	public function new(instance:PlayField) {
		super(instance);

		instance.setPercent('dizzyHolds', 1, -1);
	}

	inline private function __rotateTail(pos:Vector3) {
        if (__parentOutput == null || (__rotateX == 0 && __rotateY == 0 && __rotateZ == 0))
            return pos;

        var tailFactor = pos.subtract(__parentOutput.pos);
        tailFactor = ModchartUtil.rotate3DVector(tailFactor, __rotateX, __rotateY, __rotateZ);
        var output = __parentOutput.pos.add(tailFactor);
        
        output.z *= 0.001 * Config.Z_SCALE;
        return projection.transformVector(output, __parentOutput.pos);
    }

	inline private function getGraphicVertices(planeWidth:Float, planeHeight:Float, flipX:Bool, flipY:Bool) {
		var x1 = flipX ? planeWidth : -planeWidth;
		var x2 = flipX ? -planeWidth : planeWidth;
		var y1 = flipY ? planeHeight : -planeHeight;
		var y2 = flipY ? -planeHeight : planeHeight;

		return [
			// top left
			x1,
			y1,
			// top right
			x2,
			y1,
			// bottom left
			x1,
			y2,
			// bottom right
			x2,
			y2
		];
	}

	var __lastOrient:Float = 0;
	var __lastC2:Float = 0;
	var __lastPlayer:Int = -1;
	override public function prepare(arrow:FlxSprite) {
		if (arrow.alpha <= 0) return;

		final player = Adapter.instance.getPlayerFromArrow(arrow);
		final lane = Adapter.instance.getLaneFromArrow(arrow);
		
		var arrowData = getArrowParams(arrow);
		final isEnd = Adapter.instance.isHoldEnd(arrow);
		if (isEnd) {
			arrowData.distance -= 1.0;
		}

		final realDistance = arrowData.distance;
		final isHitten = arrowData.hitten;
		if (isHitten && realDistance < 0) {
			arrowData.distance = 0;
		}

		final fullHeight = arrow.frame.frame.height * arrow.scale.y * (Adapter.instance.getPixelStage() ? 8 : 1);
		final clipRatio = (isHitten && realDistance < 0) 
			? FlxMath.bound(1 + (realDistance / fullHeight), 0, 1) 
			: 1;

		if (clipRatio <= 0.001) return;

		var basePos = ModchartUtil.getHalfPos();
		basePos.x += Adapter.instance.getDefaultReceptorX(lane, player);
		basePos.y += Adapter.instance.getDefaultReceptorY(lane, player);

		final output = instance.modifiers.getPath(basePos.clone(), arrowData);
		if (output == null || (output.visuals.alpha * arrow.alpha <= 0)) return;

		var nextOutput = instance.modifiers.getPath(basePos.clone(), arrowData, 1, false, true);
		var unit = nextOutput.pos.subtract(output.pos);
		unit.normalize();

		var pathAngle = (unit.x == 0 && unit.y == 0) ? 0 : Math.atan2(unit.y, unit.x) * FlxAngle.TO_DEG - 90;
		
		var planeWidth = arrow.frame.frame.width * arrow.scale.x * .5;
		var isDownscroll = Adapter.instance.getDownscroll(); 

		var y1:Float = 0;
		var y2:Float = fullHeight * clipRatio;
		if (isDownscroll)
			y2 = -y2;

		if (arrow.flipY) {
			var temp = y1;
			y1 = y2;
			y2 = temp;
		}

		var x1 = arrow.flipX ? planeWidth : -planeWidth;
		var x2 = arrow.flipX ? -planeWidth : planeWidth;

		var planeVertices = [
			x1, y1, // top left
			x2, y1, // top right
			x1, y2, // bottom left
			x2, y2  // bottom right
		];

		var projectionZ:haxe.ds.Vector<Float> = new haxe.ds.Vector(4);
		final zScale:Float = output.pos.z != 0 ? (1 / output.pos.z) : 1;
		var vertPointer = 0;
		while (vertPointer < planeVertices.length) {
			rotationVector.setTo(planeVertices[vertPointer], planeVertices[vertPointer + 1], 0);
			var rotation = ModchartUtil.rotate3DVector(rotationVector, 0, 0, pathAngle);
			rotation.x *= zScale * output.visuals.scaleX;
			rotation.y *= zScale * output.visuals.scaleY;

			var view = new Vector3(rotation.x + output.pos.x, rotation.y + output.pos.y, output.pos.z);
			
			@:privateAccess
			if (Config.CAMERA3D_ENABLED)
				view = instance.camera3D.applyViewTo(view);
			
			view.z *= 0.001;
			final projection = (view.z != 0) ? this.projection.transformVector(view) : view;

			final cam = arrow._cameras != null ? arrow._cameras[0] : Adapter.instance.getArrowCamera()[0];
			if(cam != null){
				planeVertices[vertPointer] = projection.x - cam.scroll.x * (arrow.scrollFactor.x);
				planeVertices[vertPointer + 1] = projection.y - cam.scroll.y * (arrow.scrollFactor.y);
			} else {
				planeVertices[vertPointer] = projection.x;
				planeVertices[vertPointer + 1] = projection.y;
			}

			projectionZ[Math.floor(vertPointer / 2)] = Math.max(0.0001, projection.z);
			vertPointer += 2;
		}

		var vertices = new DrawData<Float>(12, true, [
			planeVertices[0], planeVertices[1], planeVertices[2], planeVertices[3], planeVertices[6], planeVertices[7],
			planeVertices[0], planeVertices[1], planeVertices[4], planeVertices[5], planeVertices[6], planeVertices[7]
		]);

		final uv = arrow.frame.uv;
		var uvData = new DrawData<Float>(18, true, [
			#if (flixel >= "6.1.0")
			uv.left,  FlxMath.lerp(uv.bottom, uv.top, clipRatio), 1 / projectionZ[0],
			uv.right, FlxMath.lerp(uv.bottom, uv.top, clipRatio), 1 / projectionZ[1],
			uv.right, uv.bottom, 1 / projectionZ[3],
			
			uv.left,  FlxMath.lerp(uv.bottom, uv.top, clipRatio), 1 / projectionZ[0],
			uv.left,  uv.bottom, 1 / projectionZ[2],
			uv.right, uv.bottom, 1 / projectionZ[3]
			#else
			uv.x,          FlxMath.lerp(uv.height, uv.y, clipRatio), 1 / projectionZ[0],
			uv.width,      FlxMath.lerp(uv.height, uv.y, clipRatio), 1 / projectionZ[1],
			uv.width,      uv.height, 1 / projectionZ[3],
			
			uv.x,          FlxMath.lerp(uv.height, uv.y, clipRatio), 1 / projectionZ[0],
			uv.x,          uv.height, 1 / projectionZ[2],
			uv.width,      uv.height, 1 / projectionZ[3]
			#end
		]);

		final absGlow = output.visuals.glow * 255;
		final negGlow = 1 - output.visuals.glow;
		var color = new ColorTransform(negGlow, negGlow, negGlow, arrow.alpha * output.visuals.alpha, Math.round(output.visuals.glowR * absGlow),
			Math.round(output.visuals.glowG * absGlow), Math.round(output.visuals.glowB * absGlow));

		var newInstruction:FMDrawInstruction = {};
		newInstruction.item = arrow;
		newInstruction.vertices = vertices;
		newInstruction.uvt = uvData;
		newInstruction.indices = new Vector<Int>(vertices.length, true, [for (i in 0...vertices.length) i]);
		newInstruction.colorData = [color];
		queue[count++] = newInstruction;
	}

	override public function shift() {
		__drawInstruction(queue[postCount++]);
	}

	private function __drawInstruction(instruction:FMDrawInstruction) {
		if (instruction == null)
			return;

		final item = instruction.item;
		final cameras = ModchartUtil.resolveCameras(item);

		@:privateAccess
		for (camera in cameras) {
			final cTransform = instruction.colorData[0];
			cTransform.alphaMultiplier *= camera.alpha;

			var batch = camera.startTrianglesBatch( item.graphic, item.antialiasing, true, item.blend, true, item.shader);
			batch.addGradientTriangles( instruction.vertices, instruction.indices, instruction.uvt, null, getZoomAwareBounds(camera), [cTransform]);
		}
	}

	inline private function getArrowParams(arrow:FlxSprite, posOff:Float = 0):ArrowData {
		final player = Adapter.instance.getPlayerFromArrow(arrow);
		final lane = Adapter.instance.getLaneFromArrow(arrow);

		final centered2 = (player == __lastPlayer) ? __lastC2 : (__lastC2 = instance.getPercent('centered2', player));
		final timeC2 = flixel.FlxG.height * 0.25 * centered2;
		final hitTime = Adapter.instance.getTimeFromArrow(arrow);

		var pos = (hitTime - Adapter.instance.getSongPosition()) + posOff;

		pos += timeC2;

		return {
			__holdSubdivisionOffset: posOff,
			hitTime: hitTime + posOff + timeC2,
			distance: pos,
			lane: lane,
			player: player,
			hitten: Adapter.instance.arrowHit(arrow),
			isTapArrow: true
		};
	}
}