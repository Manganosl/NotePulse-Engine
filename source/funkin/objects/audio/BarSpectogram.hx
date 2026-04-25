package funkin.objects.audio;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import funkin.objects.audio.PolygonSpectogram.VISTYPE;
import funkin.objects.audio.SpectogramSprite.SPECDIRECTION;
import funkin.objects.audio.VisShit.CurAudioInfo;
import lime.utils.Int16Array;

class BarSpectogram extends FlxTypedSpriteGroup<FlxSprite>
{
    public var visType:VISTYPE = FREQUENCIES;
    public var col:FlxColor = FlxColor.WHITE;
    public var direction:SPECDIRECTION = HORIZONTAL;
    
    public var vis:VisShit;
    public var audioData:Int16Array;
    public var sampleRate:Int;
    
    var numBars:Int = 0;
    var barWidth:Float = 5;
    var maxHeight:Float = 200;
    var spacing:Float = 2;
    var setBuffer:Bool = false;
    var numSamples:Int = 0;

    public function new(daSound:FlxSound, numBars:Int = 32, width:Float = 500, height:Float = 200, ?col:FlxColor = FlxColor.WHITE)
    {
        super();
        
        this.vis = new VisShit(daSound);
        this.numBars = numBars;
        this.maxHeight = height;
        this.col = col;
        
        this.barWidth = (width - (numBars * spacing)) / numBars;
        
        regenBars();
    }

    public function regenBars():Void
    {
        clear();

        for (i in 0...numBars)
        {
            var bar:FlxSprite = new FlxSprite().makeGraphic(Std.int(barWidth), 1, col);
            bar.origin.set(barWidth / 2, 1); 
            
            if (direction == HORIZONTAL) {
                bar.x = i * (barWidth + spacing);
                bar.y = maxHeight; 
            } else {
                bar.x = 0;
                bar.y = i * (barWidth + spacing);
                bar.angle = 90;
            }
            
            bar.active = false;
            bar.ID = i;
            add(bar);
        }
    }

    override function update(elapsed:Float)
    {
        checkAndSetBuffer();

        if (setBuffer)
        {
            switch (visType)
            {
                case FREQUENCIES:
                    updateFFTBars(elapsed);
                case UPDATED:
                    updateWaveformBars(elapsed);
                default:
            }
        }

        super.update(elapsed);
    }

    function updateFFTBars(elapsed:Float)
    {
        if (vis.snd == null) return;

        var songPos:Float = (vis.snd.playing) ? vis.snd.time : Conductor.songPosition;
        var remappedPos = Std.int(FlxMath.remapToRange(songPos, 0, vis.snd.length, 0, numSamples));

        var fftSamples:Array<Float> = [];
        for (i in 0...256) {
            var curAud = VisShit.getCurAud(audioData, remappedPos + (i * 2));
            fftSamples.push(curAud.balanced);
        }

        var freqData = vis.funnyFFT(fftSamples);

        for (i in 0...group.members.length)
        {
            var p:Float = i / group.members.length;
            var powed:Float = FlxMath.remapToRange(p, 0, 1, 1.2, 4.1);
            var hzPicker:Float = Math.pow(10, powed);
            var remappedFreq:Int = Std.int(FlxMath.remapToRange(hzPicker, 15, 12000, 0, freqData[0].length - 1));

            var freqPower:Float = 0;
            for (chan in 0...freqData.length)
                freqPower += freqData[chan][remappedFreq];
            
            freqPower /= freqData.length;

            var boost:Float = 1 + (p * 4);
            var targetHeight:Float = FlxMath.remapToRange(freqPower * boost, 0, 0.00004, 1, maxHeight);
            
            var lerpVal:Float = FlxMath.bound(elapsed * 12, 0, 1);
            group.members[i].scale.y = FlxMath.lerp(group.members[i].scale.y, targetHeight, lerpVal); 
        }
    }

    function updateWaveformBars(elapsed:Float)
    {
        var songPos:Float = (vis.snd.playing) ? vis.snd.time : Conductor.songPosition;
        var startingSample = Std.int(FlxMath.remapToRange(songPos, 0, vis.snd.length, 0, numSamples));

        for (i in 0...group.members.length)
        {
            var sampleIdx = startingSample + (i * 10); 
            var curAud = VisShit.getCurAud(audioData, sampleIdx);
            
            var val = Math.abs(curAud.balanced) * maxHeight * 2;
            var lerpVal:Float = FlxMath.bound(elapsed * 15, 0, 1);
            group.members[i].scale.y = FlxMath.lerp(group.members[i].scale.y, Math.max(1, val), lerpVal);
        }
    }

    public function checkAndSetBuffer()
    {
        vis.checkAndSetBuffer();
        if (vis.setBuffer && !setBuffer)
        {
            audioData = vis.audioData;
            sampleRate = vis.sampleRate;
            setBuffer = true;
            numSamples = Std.int(audioData.length / 2);
        }
    }
}