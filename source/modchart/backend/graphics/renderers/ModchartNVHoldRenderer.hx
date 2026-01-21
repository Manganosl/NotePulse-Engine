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
		final canUseLast = player == __lastPlayer;

		final centered2 = canUseLast ? __lastC2 : (__lastC2 = instance.getPercent('centered2', player));
		final dizzy = instance.getPercent('dizzyHolds', player);
		__rotateX = instance.getPercent('holdRotateX', player);
		__rotateY = instance.getPercent('holdRotateY', player);
		__rotateZ = instance.getPercent('holdRotateZ', player);

		var arrowData = getArrowParams(arrow);
		if (arrowData.hitten && arrowData.distance < 0) arrowData.distance = 0;

		final shouldClip = arrowData.hitten && arrowData.distance < 0;
		final clipRatio = shouldClip ? FlxMath.bound(1 + (arrowData.distance / (arrow.frame.frame.height * arrow.scale.y)), 0, 1) : 1;

		var basePos = ModchartUtil.getHalfPos();
		basePos.x += Adapter.instance.getDefaultReceptorX(lane, player);
		basePos.y += Adapter.instance.getDefaultReceptorY(lane, player);

		final output = instance.modifiers.getPath(basePos.clone(), arrowData);
		if (output == null || (output.visuals.alpha * arrow.alpha <= 0)) return;

		var parentTime = Adapter.instance.getHoldParentTime(arrow);
		var parentData:ArrowData = {
			hitTime: parentTime,
			distance: Math.max(0, parentTime - Adapter.instance.getSongPosition()),
			lane: lane, player: player,
			hitten: Adapter.instance.arrowHit(arrow),
			isTapArrow: true
		};
		__parentOutput = instance.modifiers.getPath(basePos.clone(), parentData);
		__parentOutput.pos.z = (__parentOutput.pos.z - 1) * 1000;

		var nextOutput = instance.modifiers.getPath(basePos.clone(), arrowData, 1, false, true);
		var unit = nextOutput.pos.subtract(output.pos);
		unit.normalize();
		
		var pathAngle = (unit.x == 0 && unit.y == 0) ? 0 : Math.atan2(unit.y, unit.x) * FlxAngle.TO_DEG - 90;

		var planeWidth = arrow.frame.frame.width * arrow.scale.x * .5;
		var planeHeight = arrow.frame.frame.height * arrow.scale.y * .5;
		var planeVertices = getGraphicVertices(planeWidth, planeHeight, arrow.flipX, arrow.flipY);
		var projectionZ:haxe.ds.Vector<Float> = new haxe.ds.Vector(4);

		final zScale:Float = output.pos.z != 0 ? (1 / output.pos.z) : 1;
		var curPoint = output.pos.clone();
		curPoint.z = 0;

		var vertPointer = 0;
		while (vertPointer < planeVertices.length) {
			rotationVector.setTo(planeVertices[vertPointer], planeVertices[vertPointer + 1], 0);
			var rotation = ModchartUtil.rotate3DVector(rotationVector, 0, output.visuals.angleY * dizzy, 0);
			rotation = ModchartUtil.rotate3DVector(rotation, output.visuals.angleX, output.visuals.angleY, pathAngle + output.visuals.angleZ);

			@:privateAccess
			if (output.visuals.skewX != 0 || output.visuals.skewY != 0) {
				matrix.identity();
				matrix.b = ModchartUtil.tan(output.visuals.skewY * FlxAngle.TO_RAD);
				matrix.c = ModchartUtil.tan(output.visuals.skewX * FlxAngle.TO_RAD);
				var tx = matrix.__transformX(rotation.x, rotation.y);
				var ty = matrix.__transformY(rotation.x, rotation.y);
				rotation.x = tx; rotation.y = ty;
			}

			rotation.x *= zScale * output.visuals.scaleX;
			rotation.y *= zScale * output.visuals.scaleY;

			var view = new Vector3(rotation.x + curPoint.x, rotation.y + curPoint.y, rotation.z);
			view = __rotateTail(view);

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

        // @formatter:off
		// this is confusing af
		var vertices = new DrawData<Float>(12, true, [
			// triangle 1
			planeVertices[0], planeVertices[1], // top left
			planeVertices[2], planeVertices[3], // top right
			planeVertices[6], planeVertices[7], // bottom left
			// triangle 2
			planeVertices[0], planeVertices[1], // top right
			planeVertices[4], planeVertices[5], // top left
			planeVertices[6], planeVertices[7] // bottom right
		]);
		final uvRectangle = arrow.frame.uv;
		final uvClip = clipRatio;
		var uvData = new DrawData<Float>(18, true, [
			#if (flixel >= "6.1.0")
			// uv for triangle 1
			uvRectangle.left, uvRectangle.right,  1 / projectionZ[0], // top left
			uvRectangle.top,  uvRectangle.right,  1 / projectionZ[1], // top right
			uvRectangle.top,  FlxMath.lerp(uvRectangle.top, uvRectangle.bottom, uvClip), 1 / projectionZ[3], // bottom left
			// uv for triangle 2
			uvRectangle.left, uvRectangle.right,  1 / projectionZ[0], // top right
			uvRectangle.left, FlxMath.lerp(uvRectangle.top, uvRectangle.bottom, uvClip), 1 / projectionZ[2], // top left
			uvRectangle.top,  FlxMath.lerp(uvRectangle.top, uvRectangle.bottom, uvClip), 1 / projectionZ[3]  // bottom right
			#else
			// uv for triangle 1
			uvRectangle.x,     uvRectangle.y,      1 / projectionZ[0], // top left
			uvRectangle.width, uvRectangle.y,      1 / projectionZ[1], // top right
			uvRectangle.width, FlxMath.lerp(uvRectangle.width, uvRectangle.height, uvClip), 1 / projectionZ[3], // bottom left
			// uv for triangle 2
			uvRectangle.x,      uvRectangle.y,      1 / projectionZ[0], // top right
			uvRectangle.x,      FlxMath.lerp(uvRectangle.width, uvRectangle.height, uvClip), 1 / projectionZ[2], // top left
			uvRectangle.width,  FlxMath.lerp(uvRectangle.width, uvRectangle.height, uvClip), 1 / projectionZ[3]  // bottom right
			#end
		]);
        // @formatter:on
		final absGlow = output.visuals.glow * 255;
		final negGlow = 1 - output.visuals.glow;
		var color = new ColorTransform(negGlow, negGlow, negGlow, arrow.alpha * output.visuals.alpha, Math.round(output.visuals.glowR * absGlow),
			Math.round(output.visuals.glowG * absGlow), Math.round(output.visuals.glowB * absGlow));

		if (shouldClip && clipRatio <= 0.001) {
			return;
		}

		// make the instruction
		var newInstruction:FMDrawInstruction = {};
		newInstruction.item = arrow;
		newInstruction.vertices = vertices;
		newInstruction.uvt = uvData;
		newInstruction.indices = new Vector<Int>(vertices.length, true, [for (i in 0...vertices.length) i]);
		newInstruction.colorData = [color];
		queue[count] = newInstruction;

		count++;
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
		pos += 53.2/(!Adapter.instance.isHoldEnd(arrow)?1:2); // adjustment for hold positioning

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
