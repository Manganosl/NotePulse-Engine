package modchart.backend.graphics.renderers;

using flixel.util.FlxColorTransformUtil;

final matrix:Matrix = new Matrix();
final fMatrix:FlxMatrix = new FlxMatrix();
final rotationVector = new Vector3();
final helperVector = new Vector3();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class NVHoldRenderer extends BaseRenderer<FlxSprite> {
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
        return this.view.transformVector(output, __parentOutput.pos);
    }

	inline private function getGraphicVertices(planeWidth:Float, planeHeight:Float, flipX:Bool, flipY:Bool) {
		var x1 = flipX ? planeWidth : -planeWidth;
		var x2 = flipX ? -planeWidth : planeWidth;
		var y1 = flipY ? planeHeight : -planeHeight;
		var y2 = flipY ? -planeHeight : planeHeight;

		return [
			x1, y1, // top left
			x2, y1, // top right
			x1, y2, // bottom left
			x2, y2  // bottom right
		];
	}

	var __lastOrient:Float = 0;
	var __lastC2:Float = 0;
	var __lastPlayer:Int = -1;
	override public function prepare(arrow:FlxSprite):Null<DrawCommand> {
		if (arrow.alpha <= 0) return null;

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

		final fullHeight = (arrow.frame.frame.height * arrow.scale.y);
		final clipRatio = (isHitten && realDistance < 0) 
			? FlxMath.bound(1 + (realDistance / fullHeight), 0, 1) 
			: 1;

		if (clipRatio <= 0.001) return null;

		var basePos = ModchartUtil.getHalfPos();
		basePos.x += Adapter.instance.getDefaultReceptorX(lane, player);
		basePos.y += Adapter.instance.getDefaultReceptorY(lane, player);

		final output = parent.modifiers.getPath(basePos.clone(), arrowData);
		if (output == null || (output.visuals.alpha * arrow.alpha <= 0)) return null;

		var nextOutput = parent.modifiers.getPath(basePos.clone(), arrowData, 1, false, true);
		var diff = nextOutput.pos.subtract(output.pos);

		var velocity = diff.length; 

		var unit = diff.clone();
		unit.normalize();

		var isDownscroll = Adapter.instance.getDownscroll(); 
		var pathAngle = (unit.x == 0 && unit.y == 0) ? 0 : Math.atan2(unit.y, unit.x) * FlxAngle.TO_DEG - 90 + (isDownscroll ? 180 : 0);

		var speedConstant = 0.5;
		var scrollSpeed = Math.abs(Adapter.instance.getCurrentScrollSpeed());
		var baseVelocity = scrollSpeed * speedConstant; 
		var stretch = (velocity / baseVelocity) * speedConstant;

		var planeWidth = arrow.frame.frame.width * arrow.scale.x * .5;

		var y1:Float = 0;
		var y2:Float = (fullHeight * clipRatio) * stretch; 

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

		var projectionZ:NativeVector<Float> = new NativeVector(4);
		final zScale:Float = output.pos.z != 0 ? (1 / output.pos.z) : 1;
		var vertPointer = 0;
		while (vertPointer < planeVertices.length) {
			rotationVector.setTo(planeVertices[vertPointer], planeVertices[vertPointer + 1], 0);
			var rotation = ModchartUtil.rotate3DVector(rotationVector, 0, 0, pathAngle);
			rotation.x *= zScale * output.visuals.scaleX;
			rotation.y *= zScale;

			var view = new Vector3(rotation.x + output.pos.x, rotation.y + output.pos.y, output.pos.z);
			
			view.z *= 0.001;
			final projection = (view.z != 0) ? this.view.transformVector(view) : view;
			
			planeVertices[vertPointer] = projection.x;
			planeVertices[vertPointer + 1] = projection.y;

			projectionZ[Math.floor(vertPointer / 2)] = Math.max(0.0001, projection.z);
			vertPointer += 2;
		}

		var vertices = new NativeVector<Float>(8);
		// top left
		vertices[0] = planeVertices[0];
		vertices[1] = planeVertices[1];
		// top right
		vertices[2] = planeVertices[2];
		vertices[3] = planeVertices[3];

		// botton left
		vertices[4] = planeVertices[4];
		vertices[5] = planeVertices[5];
		// bottom right
		vertices[6] = planeVertices[6];
		vertices[7] = planeVertices[7];

		final uvRectangle = arrow.frame.uv;
		var uvData = new NativeVector<Float>(12);
		var k = 0;

		#if (flixel == "6.1.0")
		// top left
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.right;
		uvData[k++] = 1 / projectionZ[0];
		// top right
		uvData[k++] = uvRectangle.top;
		uvData[k++] = uvRectangle.right;
		uvData[k++] = 1 / projectionZ[1];
		// bottom left
		uvData[k++] = uvRectangle.top;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[2];
		// bottom right
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[3];
		#elseif (flixel >= "6.1.1")
		// top left
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.top;
		uvData[k++] = 1 / projectionZ[0];
		// top right
		uvData[k++] = uvRectangle.right;
		uvData[k++] = uvRectangle.top;
		uvData[k++] = 1 / projectionZ[1];
		// bottom left
		uvData[k++] = uvRectangle.left;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[2];
		// bottom right
		uvData[k++] = uvRectangle.right;
		uvData[k++] = uvRectangle.bottom;
		uvData[k++] = 1 / projectionZ[3];
		#else
		// top left
		uvData[k++] = uvRectangle.x;
		uvData[k++] = uvRectangle.y;
		uvData[k++] = 1 / projectionZ[0];
		// top right
		uvData[k++] = uvRectangle.width;
		uvData[k++] = uvRectangle.y;
		uvData[k++] = 1 / projectionZ[1];
		// bottom left
		uvData[k++] = uvRectangle.x;
		uvData[k++] = uvRectangle.height;
		uvData[k++] = 1 / projectionZ[2];
		// bottom right
		uvData[k++] = uvRectangle.width;
		uvData[k++] = uvRectangle.height;
		uvData[k++] = 1 / projectionZ[3];
		#end

		var indices = new NativeVector<Int>(6);

		// triangle 1
		indices[0] = 0;
		indices[1] = 1;
		indices[2] = 2;

		// triangle 2
		indices[3] = 1;
		indices[4] = 3;
		indices[5] = 2;

		final absGlow = output.visuals.glow * 255;
		final negGlow = 1 - output.visuals.glow;

		if ((arrow.alpha * output.visuals.alpha) <= 0)
			return null;

		var color = new ColorTransform(negGlow, negGlow, negGlow, arrow.alpha * output.visuals.alpha, Math.round(output.visuals.glowR * absGlow),
			Math.round(output.visuals.glowG * absGlow), Math.round(output.visuals.glowB * absGlow));

		// make the instruction
		var dc:DrawCommand = {
			parent: arrow,
			graphic: arrow.graphic,
			antialiasing: arrow.antialiasing,
			blend: arrow.blend,
			cameras: ModchartUtil.resolveCameras(parent, arrow),
			shader: arrow.shader,

			vertices: vertices,
			uvs: uvData,
			indices: indices,
			color: color,
			isColored: color.hasRGBMultipliers() || color.alphaMultiplier != 1,
			hasColorOffsets: color.hasRGBAOffsets()
		};
		return dc;
	}

	inline private function getArrowParams(arrow:FlxSprite, posOff:Float = 0):ArrowData {
		final player = Adapter.instance.getPlayerFromArrow(arrow);
		final lane = Adapter.instance.getLaneFromArrow(arrow);

		final centered2 = (player == __lastPlayer) ? __lastC2 : (__lastC2 = parent.getPercent('centered2', player));
		final timeC2 = FlxG.height * 0.25 * centered2;
		final hitTime = Adapter.instance.getTimeFromArrow(arrow);

		var pos = (hitTime - Adapter.instance.getSongPosition()) + posOff;

		pos += timeC2;

		return {
			hitTime: hitTime + posOff + timeC2,
			distance: pos,
			lane: lane,
			player: player,
			hitten: Adapter.instance.arrowHit(arrow),
			isTapArrow: true
		};
	}
}