package backend.ui;

class PsychUIVerticalSlider extends FlxSpriteGroup
{
	public static final CHANGE_EVENT = "slider_change";
	public var bar:FlxSprite;
	public var minText:FlxText;
	public var maxText:FlxText;
	public var valueText:FlxText;
	public var handle:FlxSprite;
	public var label(get, set):String;
	public var labelText:FlxText;

	public var value(default, set):Float = 0;
	public var onChange:Float->Void;
	public var min(default, set):Float = -999;
	public var max(default, set):Float = 999;
	public var decimals(default, set):Int = 2;

	public function new(x:Float = 0, y:Float = 0, callback:Float->Void, def:Float = 0, min:Float = -999, max:Float = 999, height:Float = 200, mainColor:FlxColor = FlxColor.WHITE, handleColor:FlxColor = 0xFFAAAAAA)
	{
		super(x, y);
		this.onChange = callback;

		// Vertical bar
		bar = new FlxSprite().makeGraphic(20, 1, FlxColor.WHITE);
		bar.scale.set(1, height);
		bar.updateHitbox();
		bar.color = mainColor;
		add(bar);

		// Labels
		minText = new FlxText(0, 0, 80, '', 8);
		minText.alignment = CENTER;
		minText.color = mainColor;
		add(minText);

		maxText = new FlxText(0, 0, 80, '', 8);
		maxText.alignment = CENTER;
		maxText.color = mainColor;
		add(maxText);

		valueText = new FlxText(0, 0, 80, '', 8);
		valueText.alignment = CENTER;
		valueText.color = handleColor;
		add(valueText);

		labelText = new FlxText(0, 0, 100, '', 8);
		labelText.alignment = CENTER;
		add(labelText);

		// Handle
		handle = new FlxSprite().makeGraphic(20, 5, FlxColor.WHITE);
		handle.color = handleColor;
		add(handle);

		this.min = min;
		this.max = max;
		this.value = def;
		_updatePositions();
		forceNextUpdate = true;
	}

	public var movingHandle:Bool = false;
	public var forceNextUpdate:Bool = false;
	public var broadcastSliderEvent:Bool = true;
	private var isPointer:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if(FlxG.mouse.overlaps(handle, camera)){
			isPointer = true;
			Mouse.cursor = MouseCursor.RESIZE_NS;
		} else if(FlxG.mouse.overlaps(bar, camera)){
			isPointer = true;
			Mouse.cursor = MouseCursor.POINTER;
		} else if(isPointer){
			isPointer = false;
			Mouse.cursor = MouseCursor.DEFAULT;
		}

		if(FlxG.mouse.justMoved || FlxG.mouse.justPressed || forceNextUpdate)
		{
			forceNextUpdate = false;
			if(FlxG.mouse.justPressed && (FlxG.mouse.overlaps(bar, camera) || FlxG.mouse.overlaps(handle, camera)))
				movingHandle = true;

			if(movingHandle)
			{
				var lastValue:Float = FlxMath.roundDecimal(value, decimals);
				value = Math.max(min, Math.min(max, FlxMath.remapToRange(
					FlxG.mouse.getPositionInCameraView(camera).y,
					bar.y,
					bar.y + bar.height,
					min,
					max
				)));
				if(this.onChange != null && lastValue != value)
				{
					this.onChange(FlxMath.roundDecimal(value, decimals));
					if(broadcastSliderEvent) PsychUIEventHandler.event(CHANGE_EVENT, this);
				}
			}
		}

		if(FlxG.mouse.released)
			movingHandle = false;
	}

	function _updatePositions()
	{
		// Labels
		minText.x = bar.x + bar.width/2 - minText.width/2;
		maxText.x = bar.x + bar.width/2 - maxText.width/2;
		valueText.x = bar.x + bar.width + 4; // value label to the right

		labelText.x = bar.x + bar.width/2 - labelText.width/2;
		if(label.length > 0) bar.y = labelText.y + 24;

		minText.y = bar.y + bar.height - minText.height/2;
		maxText.y = bar.y - maxText.height/2;
		valueText.y = handle.y + handle.height/2 - valueText.height/2;

		_updateHandleY();
	}

	function _updateHandleY()
	{
		handle.y = bar.y - handle.height/2 + FlxMath.remapToRange(FlxMath.roundDecimal(value, decimals), min, max, 0, bar.height);
		handle.x = bar.x + bar.width/2 - handle.width/2;
	}

	function set_decimals(v:Int)
	{
		decimals = v;
		minText.text = Std.string(FlxMath.roundDecimal(min, decimals));
		maxText.text = Std.string(FlxMath.roundDecimal(max, decimals));
		valueText.text = Std.string(FlxMath.roundDecimal(value, decimals));
		if(this.onChange != null) this.onChange(FlxMath.roundDecimal(value, decimals));
		_updatePositions();
		return decimals;
	}

	function set_min(v:Float)
	{
		if(v > max) max = v;
		min = v;
		minText.text = Std.string(FlxMath.roundDecimal(min, decimals));
		_updateHandleY();
		return min;
	}

	function set_max(v:Float)
	{
		if(v < min) min = v;
		max = v;
		maxText.text = Std.string(FlxMath.roundDecimal(max, decimals));
		_updateHandleY();
		return max;
	}

	function set_value(v:Float)
	{
		value = Math.max(min, Math.min(max, v));
		valueText.text = Std.string(FlxMath.roundDecimal(value, decimals));
		_updateHandleY();
		return value;
	}

	function set_label(v:String)
	{
		labelText.text = v;
		_updatePositions();
		return labelText.text;
	}

	function get_label()
		return labelText.text;
}
