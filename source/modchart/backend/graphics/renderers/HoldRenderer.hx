package modchart.backend.graphics.renderers;

import funkin.objects.Note;

using flixel.util.FlxColorTransformUtil;

final matrix:Matrix = new Matrix();
final fMatrix:FlxMatrix = new FlxMatrix();
final rotationVector = new Vector3();
final helperVector = new Vector3();

#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
final class HoldRenderer extends BaseRenderer<FlxSprite> {
    private var __rotateX:Float = 0;
    private var __rotateY:Float = 0;
    private var __rotateZ:Float = 0;
    private var __parentOutput:ModifierOutput;

    private var __instanceID:Int;

    public function new(instance:ModPlayField) {
        super(instance);
        __instanceID = instance.ID;
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

        var castedArrow = cast(arrow, Note);
        @:privateAccess
        if(castedArrow.prevNote.modchartNotOnScreen[__instanceID]){
            castedArrow.modchartNotOnScreen[__instanceID] = false;
            return null;
        }

        final arrowFrame = arrow.frame.frame;
        
        final player = Adapter.getPlayerFromArrow(arrow);
        final lane = Adapter.getLaneFromArrow(arrow);
        
        var arrowData = getArrowParams(castedArrow);
        final realDistance = arrowData.distance;
        final isHitten = arrowData.hitten;

        final fullHeight = (arrowFrame.height * arrow.scale.y);
        final clipRatio = (isHitten && realDistance < 0) 
            ? FlxMath.bound(1 + (realDistance / fullHeight), 0, 1) 
            : 1;

        if (clipRatio <= 0.001) return null;

        var basePos = ModchartUtil.getHalfPos();
        basePos.x += Adapter.getDefaultReceptorX(lane, player);
        basePos.y += Adapter.getDefaultReceptorY(lane, player);

        final output = parent.modifiers.getPath(basePos.clone(), arrowData);
        if (output == null || (output.visuals.alpha * arrow.alpha <= 0)) return null;
        
        var diff:Vector3;
        var isCached:Bool = false;

        @:privateAccess
        if (castedArrow.nextNote != null && castedArrow.nextNote.modchartCachedModPos[__instanceID] != null) {
            var nextPos:Vector3 = castedArrow.nextNote.modchartCachedModPos[__instanceID];
            diff = output.pos.subtract(nextPos);
            isCached = true;
        } else {
            final stepDuration = (Adapter.startCrochet / 3.85); 
            var nextData = getArrowParams(castedArrow, stepDuration);
            var nextOutput = parent.modifiers.getPath(basePos.clone(), nextData);
            diff = nextOutput.pos.subtract(output.pos);
        }

        @:privateAccess castedArrow.modchartCachedModPos[__instanceID] = output.pos;
        
        var velocity = Math.sqrt(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z); 
        
        var pathAngle = (diff.x == 0 && diff.y == 0) ? 0 : Math.atan2(diff.y, diff.x) * FlxAngle.TO_DEG - 90 + (ClientPrefs.data.downScroll ? 180 : 0) + (isCached ? 180 : 0);

        var planeWidth = arrowFrame.width * arrow.scale.x * 0.5;
        var frameHeight = (castedArrow.isSustainEnd ? fullHeight : velocity);

        var clipOffset = frameHeight * (1 - clipRatio);

        var y1:Float = ClientPrefs.data.downScroll ? -clipOffset : clipOffset; 
        var y2:Float = ClientPrefs.data.downScroll ? -frameHeight : frameHeight;

        if (arrow.flipY) {
            var temp = y1;
            y1 = y2;
            y2 = temp;
        }

        var x1 = arrow.flipX ? planeWidth : -planeWidth;
        var x2 = arrow.flipX ? -planeWidth : planeWidth;

        final zScale:Float = output.pos.z != 0 ? (1 / output.pos.z) : 1;
        final scaleXMult = zScale * output.visuals.scaleX;

        var projectionZ = new NativeVector<Float>(4);
        var vertices = new NativeVector<Float>(8);

        rotationVector.setTo(x1, y1, 0);
        var rot = ModchartUtil.rotate3DVector(rotationVector, 0, 0, pathAngle);
        var view = new Vector3(rot.x * scaleXMult + output.pos.x, rot.y * zScale + output.pos.y, output.pos.z);
        view.z *= 0.001;
        var proj = (view.z != 0) ? this.view.transformVector(view) : view;
        vertices[0] = proj.x; vertices[1] = proj.y;
        projectionZ[0] = proj.z > 0.0001 ? proj.z : 0.0001;

        rotationVector.setTo(x2, y1, 0);
        rot = ModchartUtil.rotate3DVector(rotationVector, 0, 0, pathAngle);
        view = new Vector3(rot.x * scaleXMult + output.pos.x, rot.y * zScale + output.pos.y, output.pos.z);
        view.z *= 0.001;
        proj = (view.z != 0) ? this.view.transformVector(view) : view;
        vertices[2] = proj.x; vertices[3] = proj.y;
        projectionZ[1] = proj.z > 0.0001 ? proj.z : 0.0001;

        rotationVector.setTo(x1, y2, 0);
        rot = ModchartUtil.rotate3DVector(rotationVector, 0, 0, pathAngle);
        view = new Vector3(rot.x * scaleXMult + output.pos.x, rot.y * zScale + output.pos.y, output.pos.z);
        view.z *= 0.001;
        proj = (view.z != 0) ? this.view.transformVector(view) : view;
        vertices[4] = proj.x; vertices[5] = proj.y;
        projectionZ[2] = proj.z > 0.0001 ? proj.z : 0.0001;

        rotationVector.setTo(x2, y2, 0);
        rot = ModchartUtil.rotate3DVector(rotationVector, 0, 0, pathAngle);
        view = new Vector3(rot.x * scaleXMult + output.pos.x, rot.y * zScale + output.pos.y, output.pos.z);
        view.z *= 0.001;
        proj = (view.z != 0) ? this.view.transformVector(view) : view;
        vertices[6] = proj.x; vertices[7] = proj.y;
        projectionZ[3] = proj.z > 0.0001 ? proj.z : 0.0001;

        final uvRectangle = arrow.frame.uv;
        var uvData = new NativeVector<Float>(12);
        var k = 0;

        #if (flixel == "6.1.0")
        uvData[k++] = uvRectangle.left; uvData[k++] = uvRectangle.right; uvData[k++] = 1 / projectionZ[0];
        uvData[k++] = uvRectangle.top; uvData[k++] = uvRectangle.right; uvData[k++] = 1 / projectionZ[1];
        uvData[k++] = uvRectangle.top; uvData[k++] = uvRectangle.bottom; uvData[k++] = 1 / projectionZ[2];
        uvData[k++] = uvRectangle.left; uvData[k++] = uvRectangle.bottom; uvData[k++] = 1 / projectionZ[3];
        #elseif (flixel >= "6.1.1")
        uvData[k++] = uvRectangle.left; uvData[k++] = uvRectangle.top; uvData[k++] = 1 / projectionZ[0];
        uvData[k++] = uvRectangle.right; uvData[k++] = uvRectangle.top; uvData[k++] = 1 / projectionZ[1];
        uvData[k++] = uvRectangle.left; uvData[k++] = uvRectangle.bottom; uvData[k++] = 1 / projectionZ[2];
        uvData[k++] = uvRectangle.right; uvData[k++] = uvRectangle.bottom; uvData[k++] = 1 / projectionZ[3];
        #else
        uvData[k++] = uvRectangle.x; uvData[k++] = uvRectangle.y; uvData[k++] = 1 / projectionZ[0];
        uvData[k++] = uvRectangle.width; uvData[k++] = uvRectangle.y; uvData[k++] = 1 / projectionZ[1];
        uvData[k++] = uvRectangle.x; uvData[k++] = uvRectangle.height; uvData[k++] = 1 / projectionZ[2];
        uvData[k++] = uvRectangle.width; uvData[k++] = uvRectangle.height; uvData[k++] = 1 / projectionZ[3];
        #end

        var indices = new NativeVector<Int>(6);
        indices[0] = 0; indices[1] = 1; indices[2] = 2;
        indices[3] = 1; indices[4] = 3; indices[5] = 2;

        var resolvedCameras = ModchartUtil.resolveCameras(parent, arrow);

        var minX = Math.min(Math.min(vertices[0], vertices[2]), Math.min(vertices[4], vertices[6]));
        var maxX = Math.max(Math.max(vertices[0], vertices[2]), Math.max(vertices[4], vertices[6]));
        var minY = Math.min(Math.min(vertices[1], vertices[3]), Math.min(vertices[5], vertices[7]));
        var maxY = Math.max(Math.max(vertices[1], vertices[3]), Math.max(vertices[5], vertices[7]));

        for (cam in resolvedCameras) {
            var viewWidth = cam.width / cam.zoom;
            var viewHeight = cam.height / cam.zoom;
            var marginX = (cam.width - viewWidth) / 2;
            var marginY = (cam.height - viewHeight) / 2;

            @:privateAccess
            if (maxX >= marginX && minX <= cam.width - marginX && maxY >= marginY && minY <= cam.height - marginY) {
                castedArrow.modchartNotOnScreen[__instanceID] = false;
                break;
            } else {
                castedArrow.modchartNotOnScreen[__instanceID] = true;
            }
        }

        @:privateAccess
        if (castedArrow.modchartNotOnScreen[__instanceID]) return null;

        final absGlow = output.visuals.glow * 255;
        final negGlow = 1 - output.visuals.glow;

        if ((arrow.alpha * output.visuals.alpha) <= 0)
            return null;

        var color = new ColorTransform(
            negGlow, negGlow, negGlow, arrow.alpha * output.visuals.alpha, 
            Math.round(output.visuals.glowR * absGlow), Math.round(output.visuals.glowG * absGlow), Math.round(output.visuals.glowB * absGlow)
        );

        return {
            parent: arrow,
            graphic: arrow.graphic,
            antialiasing: arrow.antialiasing,
            blend: arrow.blend,
            cameras: resolvedCameras,
            shader: arrow.shader,
            vertices: vertices,
            uvs: uvData,
            indices: indices,
            color: color,
            isColored: color.hasRGBMultipliers() || color.alphaMultiplier != 1,
            hasColorOffsets: color.hasRGBAOffsets()
        };
    }

    inline private function getArrowParams(arrow:Note, posOff:Float = 0):ArrowData {
        final player = Adapter.getPlayerFromArrow(arrow);
        final lane = Adapter.getLaneFromArrow(arrow);

        final centered2 = (player == __lastPlayer) ? __lastC2 : (__lastC2 = parent.getPercent('centered2', player));
        final timeC2 = FlxG.height * 0.25 * centered2;
        final hitTime = Adapter.getTimeFromArrow(arrow);

        var pos = (hitTime - Conductor.songPosition) + posOff + timeC2;

        return {
            hitTime: hitTime + posOff + timeC2,
            distance: pos,
            lane: lane,
            player: player,
            hitten: arrow.wasGoodHit,
            isTapArrow: true
        };
    }
}