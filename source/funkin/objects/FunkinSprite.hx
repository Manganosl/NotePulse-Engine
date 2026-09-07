package funkin.objects;

import flixel.graphics.frames.FlxFrame.FlxFrameType;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

// Original 3D code from https://github.com/dotaxel/Flixel-3DSprites/blob/main/source/flixel/FlxSprite3D.hx
class FunkinSprite extends FlxSkewedSprite {
	public var angle3D:Vector3D = new Vector3D();

	@:noCompletion private var __position3D:Vector3D = new Vector3D();
	@:noCompletion private var __angle3D:Vector3D = new Vector3D();

	@:noCompletion private static var __rotationMatrix:Matrix3D = new Matrix3D();

	@:noCompletion private var _clippedFrame:FlxFrame;

	override public function destroy():Void {
		skew = FlxDestroyUtil.put(skew);
		skewOffset = FlxDestroyUtil.put(skewOffset);
		_clippedFrame = FlxDestroyUtil.destroy(_clippedFrame);

		super.destroy();
	}

	override function draw(){
		checkEmptyFrame();

		if(alpha == 0 || _frame.type == FlxFrameType.EMPTY)
			return;

		if(dirty)
			calcFrame(useFramePixels);

		if(colorTransform == null)
			updateColorTransform();

		for(camera in cameras){
			if(!camera.visible || !camera.exists || !isOnScreen(camera))
				continue;

			__drawSprite3D(camera);
		}
	}

	private function getGraphicVertices(planeWidth:Float, planeHeight:Float){
		var x1 = flipX ? planeWidth : -planeWidth;
		var x2 = flipX ? -planeWidth : planeWidth;
		var y1 = flipY ? planeHeight : -planeHeight;
		var y2 = flipY ? -planeHeight : planeHeight;

		return [
			x1, y1,
			x2, y1,
			x1, y2,
			x2, y2
		];
	}

	inline private function applySkew(point:FlxPoint):Void {
		if(skew.x == 0 && skew.y == 0 && skewOffset.x == 0 && skewOffset.y == 0)
			return;

		final originalX = point.x;
		final originalY = point.y;

		final skewX = Math.tan((skew.x + skewOffset.x) * FlxAngle.TO_RAD);
		final skewY = Math.tan((skew.y + skewOffset.y) * FlxAngle.TO_RAD);

		point.x = originalX + skewX * originalY;
		point.y = originalY + skewY * originalX;
	}

	private static inline function rotation3D(input:Vector3D, angle:Vector3D):Vector3D {
		if(angle.x == 0 && angle.y == 0 && angle.z == 0)
			return input;

		__rotationMatrix.identity();
		__rotationMatrix.appendRotation(angle.z, Vector3D.Z_AXIS);
		__rotationMatrix.appendRotation(angle.y, Vector3D.Y_AXIS);
		__rotationMatrix.appendRotation(angle.x, Vector3D.X_AXIS);

		return __rotationMatrix.transformVector(input);
	}

	private function __drawSprite3D(camera:FlxCamera):Void {
		var renderFrame = frame;
		if (clipRect != null) {
			_clippedFrame = frame.clipTo(clipRect, _clippedFrame);
			renderFrame = _clippedFrame;
		}

		var halfFrameW = frameWidth * 0.5;
		var halfFrameH = frameHeight * 0.5;

		var trimCenterX = renderFrame.offset.x + renderFrame.frame.width * 0.5;
		var trimCenterY = renderFrame.offset.y + renderFrame.frame.height * 0.5;

		var planeWidth = renderFrame.frame.width * scale.x * .5;
		var planeHeight = renderFrame.frame.height * scale.y * .5;

		var planeVertices = getGraphicVertices(planeWidth, planeHeight);
		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;

		var centerOffsetX = (trimCenterX - origin.x) * scale.x;
		var centerOffsetY = (trimCenterY - origin.y) * scale.y;

		var zoomDiff = 1.0;
		if(__shouldDoZoomFactor()){
			var requestedZoom = (camera.zoom >= 0 ? Math.max : Math.min)(FlxMath.lerp(1, camera.zoom, zoomFactor), 0);
			zoomDiff = requestedZoom / camera.zoom;
		}

		var vertPointer:Int = 0;
		do {
			__position3D.setTo(
				planeVertices[vertPointer] + centerOffsetX,
				planeVertices[vertPointer + 1] + centerOffsetY,
				0
			);
			__angle3D.setTo(angle3D.x, angle3D.y, angle + angle3D.z);

			var rotation = rotation3D(__position3D, __angle3D);

			var skewPoint = FlxPoint.get(rotation.x, rotation.y);
			applySkew(skewPoint);

			var vx = _point.x + skewPoint.x;
			var vy = _point.y + skewPoint.y;

			if(__shouldDoZoomFactor()){
				vx = (vx - camera.width * 0.5) * zoomDiff + camera.width * 0.5;
				vy = (vy - camera.height * 0.5) * zoomDiff + camera.height * 0.5;
			}

			planeVertices[vertPointer] = vx;
			planeVertices[vertPointer + 1] = vy;

			skewPoint.put();

			vertPointer += 2;
		} while (vertPointer < planeVertices.length);

		var vertices = new DrawData<Float>(12, true, [
			planeVertices[0], planeVertices[1],
			planeVertices[2], planeVertices[3],
			planeVertices[6], planeVertices[7],
			planeVertices[0], planeVertices[1],
			planeVertices[4], planeVertices[5],
			planeVertices[6], planeVertices[7]
		]);

		final uvRectangle = renderFrame.uv;
		var uvData = new DrawData<Float>(12, true, [
			uvRectangle.x, uvRectangle.y,
			uvRectangle.width, uvRectangle.y,
			uvRectangle.width, uvRectangle.height,
			uvRectangle.x, uvRectangle.y,
			uvRectangle.x, uvRectangle.height,
			uvRectangle.width, uvRectangle.height
		]);

		@:privateAccess
		camera.drawTriangles(graphic, vertices, new DrawData<Int>(vertices.length, true, [for (i in 0...vertices.length) i]),
			uvData, new DrawData<Int>(), camera._point, blend, false, antialiasing, colorTransform, shader
		);
	}
}