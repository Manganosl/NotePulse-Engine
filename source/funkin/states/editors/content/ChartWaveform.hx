package funkin.states.editors.content;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.io.Bytes;
import lime.media.AudioBuffer;

class ChartWaveform extends FlxSprite
{
	public var enabled:Bool = false;
	public var yToTime:Null<Float->Float> = null;
	public var timeOffset:Float = 0;
	public var waveWidth:Int = 320;
	public var maxY:Float = 0;

	public var chunkHeight(default, null):Int = 512;
	public var maxChunks:Int = 12;

	var chunks:Map<Int, FlxSprite> = [];
	var lastUse:Map<Int, Int> = [];
	var tick:Int = 0;

	var buffer:AudioBuffer = null;
	var bytes:Bytes = null;

	public function new(x:Float = 0){
		super(x, 0);
		makeGraphic(1, 1, 0x00FFFFFF);
		active = false;
	}

	public function setSound(sound:FlxSound):Void {
		var newBuffer:AudioBuffer = null;
		#if (lime_cffi && !macro)
		@:privateAccess
		if(sound != null && sound._sound != null)
			newBuffer = sound._sound.__buffer;
		#end

		if(newBuffer != buffer){
			buffer = newBuffer;
			bytes = null;
			#if (lime_cffi && !macro)
			if(buffer != null && buffer.data != null)
				bytes = buffer.data.toBytes();
			#end
		}
		invalidate();
	}

	public function invalidate():Void {
		for(chunk in chunks)
			chunk.destroy();
		chunks.clear();
		lastUse.clear();
	}

	override function draw(){
		if(!enabled || !visible || alpha <= 0 || yToTime == null || bytes == null || buffer == null) return;

		var cam = camera;
		var viewH:Float = cam.height / cam.zoom;
		var viewTop:Float = cam.scroll.y + (cam.height - viewH) * 0.5;
		var viewBottom:Float = viewTop + viewH;

		tick++;

		var firstChunk:Int = Std.int(Math.max(0, Math.floor(viewTop / chunkHeight)));
		var lastChunk:Int = Std.int(Math.floor(Math.min(viewBottom, maxY) / chunkHeight));

		var c:Int = Lambda.count(chunks);
		while(c > maxChunks){
			var oldest:Int = -1;
			var oldestUse:Int = tick + 1;
			for(i => used in lastUse){
				if(i >= firstChunk && i <= lastChunk) continue;
				if(used < oldestUse){
					oldest = i;
					oldestUse = used;
				}
			}
			if(oldest < 0) break;

			var old:FlxSprite = chunks.get(oldest);
			if(old != null) old.destroy();
			chunks.remove(oldest);
			lastUse.remove(oldest);
			c--;
		}

		for(i in firstChunk...(lastChunk + 1)){
			var chunk:FlxSprite = chunks.get(i);
			if(chunk == null){
				chunk = renderChunk(i);
				chunks.set(i, chunk);
			}
			lastUse.set(i, tick);

			chunk.x = x;
			chunk.y = i * chunkHeight;
			chunk.color = color;
			chunk.alpha = alpha;
			chunk.scrollFactor.copyFrom(scrollFactor);
			chunk.cameras = cameras;
			chunk.draw();
		}
	}

	function renderChunk(i:Int):FlxSprite {
		var chunk:FlxSprite = new FlxSprite(0, i * chunkHeight);
		chunk.makeGraphic(waveWidth, chunkHeight, 0x00FFFFFF, true);
		chunk.active = false;

		var bytesPerSample:Int = Std.int(buffer.bitsPerSample / 8);
		if(bytes == null || (bytesPerSample != 1 && bytesPerSample != 2) || buffer.channels < 1) return chunk;

		var channels:Int = buffer.channels;
		var frameSize:Int = channels * bytesPerSample;
		var totalFrames:Int = Std.int(bytes.length / frameSize);
		var perMs:Float = buffer.sampleRate / 1000;
		var center:Float = waveWidth * 0.5;
		var amp:Float = waveWidth * 0.5 * 0.9;

		var bitmap:BitmapData = chunk.pixels;
		var rect:Rectangle = new Rectangle(0, 0, 0, 1);
		bitmap.lock();

		var y0:Float = i * chunkHeight;
		var t0:Float = yToTime(y0) - timeOffset;
		for (row in 0...chunkHeight){
			var t1:Float = yToTime(y0 + row + 1) - timeOffset;
			var from:Int = Std.int(Math.floor(Math.min(t0, t1) * perMs));
			var to:Int = Std.int(Math.ceil(Math.max(t0, t1) * perMs));
			t0 = t1;

			if(to <= from) to = from + 1;
			if(to <= 0 || from >= totalFrames) continue;
			if(from < 0) from = 0;
			if(to > totalFrames) to = totalFrames;

			var stride:Int = Std.int(Math.max(1, (to - from) / 64));

			var minL:Float = 0;
			var maxL:Float = 0;
			var minR:Float = 0;
			var maxR:Float = 0;

			var i:Int = from;
			while(i < to)
			{
				var pos:Int = i * frameSize;
				var l:Float = readSample(pos, bytesPerSample);
				var r:Float = (channels >= 2) ? readSample(pos + bytesPerSample, bytesPerSample) : l;

				if(l < minL) minL = l;
				if(l > maxL) maxL = l;
				if(r < minR) minR = r;
				if(r > maxR) maxR = r;
				i += stride;
			}

			var negative:Float = FlxMath.bound((-minL - minR) * 0.5 * amp, 0, center);
			var positive:Float = FlxMath.bound((maxL + maxR) * 0.5 * amp, 0, center);
			if(negative + positive <= 0) continue;

			rect.x = center - negative;
			rect.y = row;
			rect.width = negative + positive;
			bitmap.fillRect(rect, FlxColor.WHITE);
		}

		bitmap.unlock();
		chunk.dirty = true;
		
		return chunk;
	}

	inline function readSample(pos:Int, bytesPerSample:Int):Float {
		if(bytesPerSample == 2){
			var value:Int = bytes.getUInt16(pos);
			if(value >= 32768) value -= 65536;
			return value / 32768;
		}
		return (bytes.get(pos) - 128) / 128;
	}

	override function destroy(){
		invalidate();
		chunks = null;
		lastUse = null;
		buffer = null;
		bytes = null;
		yToTime = null;
		super.destroy();
	}
}
