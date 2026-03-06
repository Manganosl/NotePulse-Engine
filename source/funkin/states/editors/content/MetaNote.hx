package funkin.states.editors.content;

import funkin.objects.Note;
import funkin.shaders.RGBPalette;
import flixel.util.FlxDestroyUtil;
import flixel.math.FlxRect;

class MetaSustain extends Note {
    public var sustainTile:FlxSprite;
    public var basicSustainTile:FlxSprite;
    public var downScroll:Bool = false;
    public var sustainHeight:Float = 0;
    public var useBlandSustains:Bool = false;

    public function new(data:Int) {
        basicSustainTile = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
        sustainTile = new FlxSprite();
        sustainTile.scrollFactor.x = 0;

        clipRect = new FlxRect(0, 0, 0, 0);
        sustainTile.clipRect = new FlxRect();

        super(0, data, null, true, true);

        animation.play(Note.colArray[noteData] + "holdend");
        scale.set(scale.x, scale.x);
        updateHitbox();
        flipY = false;
    }

    override function update(elapsed:Float) {
        sustainTile.update(elapsed);
        super.update(elapsed);
    }

    override function draw() {
        if (!visible) return;

        if (useBlandSustains) {
            basicSustainTile.scale.set(8, sustainHeight);
            basicSustainTile.updateHitbox();
            basicSustainTile.alpha = alpha;
            basicSustainTile.setPosition(x + (width - basicSustainTile.width) * .5, y);
            basicSustainTile.draw();
            return;
        }

        var tileY:Float = (downScroll ? 0 : sustainHeight - height);
        flipY = sustainTile.flipY = downScroll;

        if (sustainTile.shader != shader) sustainTile.shader = shader;
        if (colorTransform != null) {
            sustainTile.setColorTransform(colorTransform.redMultiplier, colorTransform.blueMultiplier, colorTransform.redMultiplier);
        }
        sustainTile.scale.copyFrom(scale);
        sustainTile.updateHitbox();
        sustainTile.alpha = alpha;

        if (scale.y <= 0) return;

        sustainTile.clipRect.set(0, 1, sustainTile.frameWidth, sustainTile.frameHeight - 2);
        sustainTile.clipRect = sustainTile.clipRect;
        clipRect.set(0, 0, frameWidth, frameHeight);
        clipRect = clipRect;
        var stop:Bool = false;

        var tileXOffset:Float = (this.width - sustainTile.width) * .5;

        if (downScroll) {
            function clipTile(tile:FlxSprite, y:Float) {
                if (tileY + tile.height >= sustainHeight) {
                    var clip:Float = (tileY + tile.height - sustainHeight) / tile.scale.y + 1;
                    tile.clipRect.set(0, clip, tile.frameWidth, tile.frameHeight - clip);
                    tile.clipRect = tile.clipRect;
                    stop = true;
                }
            }

            clipTile(this, 0);
            super.draw();
            tileY += height - scale.y;

            while (tileY < sustainHeight) {
                clipTile(sustainTile, tileY);

                sustainTile.setPosition(this.x + tileXOffset, y + tileY);
                sustainTile.draw();

                if (stop) break;

                tileY += sustainTile.clipRect.height * sustainTile.scale.y;
            }
        } else {
            function clipTile(tile:FlxSprite, y:Float) {
                if (tileY <= 0) {
                    var clip:Float = -tileY / tile.scale.y + 1;
                    tile.clipRect.set(0, clip, tile.frameWidth, tile.frameHeight - clip);
                    tile.clipRect = tile.clipRect;
                    stop = true;
                }
            }

            y += tileY;
            clipTile(this, sustainHeight);
            super.draw();
            y -= tileY;
            tileY -= scale.y;

            while (tileY > 0) {
                tileY -= sustainTile.clipRect.height * sustainTile.scale.y;
                clipTile(sustainTile, tileY);

                sustainTile.setPosition(this.x + tileXOffset, y + tileY);
                sustainTile.draw();

                if (stop) break;
            }
        }
    }

    public function reloadSustainTile() {
        sustainTile.frames = frames;
        sustainTile.antialiasing = antialiasing;
        sustainTile.animation.copyFrom(animation);
        sustainTile.animation.play(Note.colArray[this.noteData % Note.colArray.length] + "hold");
        sustainTile.clipRect = new FlxRect(0, 1, sustainTile.frameWidth, 1);
    }

    public function changeNoteData(v:Int) {
        this.noteData = v;

        if (!PlayState.isPixelStage)
            loadNoteAnims();
        else
            loadPixelNoteAnims();

        reloadSustainTile();
        animation.play(Note.colArray[this.noteData % Note.colArray.length] + "holdend");
    }

    public override function reloadNote(tex:String = "", postfix:String = "") {
        super.reloadNote(tex, postfix);
        reloadSustainTile();
    }
}

class MetaNote extends Note {
    public static var noteTypeTexts:Map<Int, FlxText> = [];
    public var isEvent:Bool = false;
    public var songData:Array<Dynamic>;
    public var sustain:MetaSustain;
    public var chartY:Float = 0;
    public var chartNoteData:Int = 0;
    public var fieldID:Int;

    public function new(time:Float, data:Int, songData:Array<Dynamic>) {
        super(time, data, null, false, true);
        this.fieldID = Std.int(songData[1]);
        this.songData = songData;
        this.strumTime = time;
        this.chartNoteData = data;
    }

    public function changeNoteData(v:Int) {
        this.chartNoteData = v;
        this.songData[1] = v;
        this.noteData = v % ChartingState.GRID_COLUMNS_PER_PLAYER;
        this.mustPress = (v < ChartingState.GRID_COLUMNS_PER_PLAYER);

        if (!PlayState.isPixelStage)
            loadNoteAnims();
        else
            loadPixelNoteAnims();

        if (Note.globalRgbShaders.contains(rgbShader.parent))
            rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(noteData));

        animation.play(Note.colArray[this.noteData % Note.colArray.length] + "Scroll");
        updateHitbox();

        if (width > height)
            setGraphicSize(ChartingState.GRID_SIZE);
        else
            setGraphicSize(0, ChartingState.GRID_SIZE);

        updateHitbox();

        if (sustain != null) {
            sustain.changeNoteData(this.noteData);
            sustain.animation.play(Note.colArray[this.noteData % Note.colArray.length] + "holdend");
            sustain.reloadSustainTile();
        }
    }

    override public function reloadNote(tex:String = "", postfix:String = "") {
        super.reloadNote(tex, postfix);

        if (width > height)
            setGraphicSize(ChartingState.GRID_SIZE);
        else
            setGraphicSize(0, ChartingState.GRID_SIZE);

        updateHitbox();
    }

    public function setStrumTime(v:Float) {
        this.songData[0] = v;
        this.strumTime = v;
    }

    var _lastZoom:Float = -1;

    public function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {
        _lastZoom = zoom;
        v = Math.round(v / (stepCrochet / 2)) * (stepCrochet / 2);
        songData[2] = sustainLength = Math.max(Math.min(v, stepCrochet * 128), 0);

        if (sustainLength > 0) {
            if (sustain == null) {
                sustain = new MetaSustain(this.chartNoteData);
                sustain.useBlandSustains = false;
                sustain.downScroll = false;
            }

            var pixelBlocks:Int = Math.round((v * ChartingState.GRID_SIZE + ChartingState.GRID_SIZE) / stepCrochet);
            var pixelHeight:Float = Math.max(ChartingState.GRID_SIZE / 4, pixelBlocks * zoom - ChartingState.GRID_SIZE / 2);

            pixelHeight = Math.max(pixelHeight, 1);

            sustain.sustainHeight = pixelHeight;

            sustain.setGraphicSize(16, ChartingState.GRID_SIZE);
            sustain.updateHitbox();

            sustain.changeNoteData(this.noteData);
            sustain.reloadSustainTile();
        } else {
            sustain = FlxDestroyUtil.destroy(sustain);
        }
    }

    public var hasSustain(get, never):Bool;
    function get_hasSustain() return (!isEvent && sustainLength > 0);

    public function updateSustainToZoom(stepCrochet:Float, zoom:Float = 1) {
        if (_lastZoom == zoom) return;
        setSustainLength(sustainLength, stepCrochet, zoom);
    }

    public function updateSustainToStepCrochet(stepCrochet:Float) {
        if (_lastZoom < 0) return;
        setSustainLength(sustainLength, stepCrochet, _lastZoom);
    }

    var _noteTypeText:FlxText;
    public function findNoteTypeText(num:Int) {
        var txt:FlxText = null;
        if (num != 0) {
            if (!noteTypeTexts.exists(num)) {
                txt = new FlxText(0, 0, ChartingState.GRID_SIZE, (num > 0) ? Std.string(num) : "?", 16);
                txt.autoSize = false;
                txt.alignment = CENTER;
                txt.borderStyle = SHADOW;
                txt.shadowOffset.set(2, 2);
                txt.borderColor = FlxColor.BLACK;
                txt.scrollFactor.x = 0;
                noteTypeTexts.set(num, txt);
            } else txt = noteTypeTexts.get(num);
        }
        return (_noteTypeText = txt);
    }

    override function draw() {
        if (sustain != null && sustain.exists && sustain.visible && sustainLength > 0) {
            sustain.x = this.x + this.width / 2 - sustain.width / 2;
            sustain.y = this.y + this.height / 2;
            sustain.alpha = this.alpha;

            sustain.updateHitbox();

            sustain.draw();
        }

        super.draw();

        if (_noteTypeText != null && _noteTypeText.exists && _noteTypeText.visible) {
            _noteTypeText.x = this.x + this.width / 2 - _noteTypeText.width / 2;
            _noteTypeText.y = this.y + this.height / 2 - _noteTypeText.height / 2;
            _noteTypeText.alpha = this.alpha;
            _noteTypeText.draw();
        }
    }

    override function destroy() {
        sustain = FlxDestroyUtil.destroy(sustain);
        super.destroy();
    }
}

class EventMetaNote extends MetaNote
{
	public var eventText:FlxText;
	public function new(time:Float, eventData:Dynamic)
	{
		super(time, -1, eventData);
		this.isEvent = true;
		events = eventData[1];
		//trace('events: $events');

		eventText = new FlxText(0, 0, 400, '', 12);
		eventText.setFormat(Paths.font('vcr.ttf'), 12, FlxColor.WHITE, RIGHT);
		eventText.scrollFactor.x = 0;
		updateEventText();
	}

	public function loadIcon(){
		if(events.length>1){
			loadGraphic(Paths.image('editors/eventIcon-many'));
		} else if(Paths.fileExists('images/editors/events/${events[0][0]}.png',IMAGE)) {
            loadGraphic(Paths.image('editors/events/${events[0][0]}'));
        } else loadGraphic(Paths.image('editors/eventArrow'));
        if(events[0][0] == "Modchart Event"){
            var name = events[0][1].split(",")[0].toLowerCase();
            if(name == "set"){
                loadGraphic(Paths.image('editors/events/Modcharting/set'));
            } else if(name == "ease"){
                loadGraphic(Paths.image('editors/events/Modcharting/ease'));
            } else if(name == "add modifier"){
                loadGraphic(Paths.image('editors/events/Modcharting/addMod'));
            } else if(name == "easeadd"){
                loadGraphic(Paths.image('editors/events/Modcharting/easeAdd'));
            } else if(name == "setadd"){
                loadGraphic(Paths.image('editors/events/Modcharting/setAdd'));
            } else { // Failsafe
                loadGraphic(Paths.image('editors/eventArrow'));
            }
        }
		setGraphicSize(ChartingState.GRID_SIZE);
		updateHitbox();
	}
	
	override function draw()
	{
		if(eventText != null && eventText.exists && eventText.visible)
		{
			eventText.y = this.y + this.height/2 - eventText.height/2;
			eventText.alpha = this.alpha;
			eventText.draw();
		}
		super.draw();
	}

	override function setSustainLength(v:Float, stepCrochet:Float, zoom:Float = 1) {}

	public var events:Array<Array<String>>;
	public function updateEventText()
	{
		loadIcon();
		var myTime:Float = Math.floor(this.strumTime);
		if(events.length == 1)
		{
			var event = events[0];
			if(event[0] == "Modchart Event"){
				var vals = event[1].split(",");
				eventText.text = 'Modchart Event ($myTime ms)\n${vals[0]}\nModifier: ${vals[1]}';
			} else 
				eventText.text = 'Event: ${event[0]} ($myTime ms)\nValue 1: ${event[1]}\nValue 2: ${event[2]}';
		}
		else if(events.length > 1)
		{
			var eventNames:Array<String> = [for (event in events) event[0]];
			eventText.text = '${events.length} Events ($myTime ms):\n${eventNames.join(', ')}';
		}
		else eventText.text = 'ERROR FAILSAFE';
	}

	override function destroy()
	{
		eventText = FlxDestroyUtil.destroy(eventText);
		super.destroy();
	}
}