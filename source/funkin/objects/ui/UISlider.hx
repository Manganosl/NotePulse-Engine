package funkin.objects.ui;

class UISlider extends FlxSpriteGroup
{
	public static final CHANGE_EVENT = "slider_change";
	public var bar:FlxSprite;
	public var fill:FlxSprite;
	public var handleBorder:FlxSprite;
	public var minText:FlxText;
	public var maxText:FlxText;
	public var valueText:FlxText;
	public var handle:FlxSprite;
	public var label(get, set):String;
	public var labelText:FlxText;

	public var value(default, set):Float = 0;
	public var onDragStart:Float->Void;
	public var onDrag:Float->Void;
	public var onDragEnd:Float->Void;
	public var min(default, set):Float = -999;
	public var max(default, set):Float = 999;
	public var decimals(default, set):Int = 2;

	public function new(x:Float = 0, y:Float = 0, callback:Float->Void, def:Float = 0, min:Float = -999, max:Float = 999, wid:Float = 200, mainColor:FlxColor = 0xFF262A34, handleColor:FlxColor = 0xFFA855F7)
	{
		super(x, y);
		this.onDrag = callback;

		bar = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bar.scale.set(wid, 5);
		bar.updateHitbox();
		bar.color = mainColor;
		bar.alpha = 0.7;
		add(bar);

		fill = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		fill.scale.set(1, 5);
		fill.updateHitbox();
		fill.color = handleColor;
		add(fill);

		minText = new FlxText(0, 0, 80, '', 8);
		minText.alignment = CENTER;
		minText.color = 0xFFF1F1F5;
		add(minText);
		maxText = new FlxText(0, 0, 80, '', 8);
		maxText.alignment = CENTER;
		maxText.color = 0xFFF1F1F5;
		add(maxText);
		valueText = new FlxText(0, 0, 80, '', 8);
		valueText.alignment = CENTER;
		valueText.color = handleColor;
		add(valueText);
		labelText = new FlxText(0, 0, wid, '', 8);
		labelText.alignment = CENTER;
		labelText.color = 0xFFF1F1F5;
		add(labelText);

		handleBorder = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		handleBorder.scale.set(5 + 2, 15 + 2);
		handleBorder.updateHitbox();
		handleBorder.color = 0xFF14161C;
		handleBorder.alpha = 0.5;
		add(handleBorder);

		handle = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		handle.scale.set(5, 15);
		handle.updateHitbox();
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
			Mouse.cursor = MouseCursor.RESIZE_WE;
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
			if(FlxG.mouse.justPressed && (FlxG.mouse.overlaps(bar, camera) || FlxG.mouse.overlaps(handle, camera))){
				if(this.onDragStart != null) this.onDragStart(value);
				movingHandle = true;
			}
			
			if(movingHandle)
			{
				var lastValue:Float = FlxMath.roundDecimal(value, decimals);
				var mouseWorldX:Float = FlxG.mouse.getWorldPosition(camera).x;
				var barScreenX:Float = bar.x - (camera.scroll.x * (1 - bar.scrollFactor.x));
				value = Math.max(min, Math.min(max, FlxMath.remapToRange(mouseWorldX, barScreenX, barScreenX + bar.width, min, max)));

				if(this.onDrag != null && lastValue != value)
				{
					this.onDrag(FlxMath.roundDecimal(value, decimals));
					if(broadcastSliderEvent) UIEventHandler.event(CHANGE_EVENT, this);
				}
			}
		}

		if(FlxG.mouse.justReleased && movingHandle && this.onDragEnd != null){
			movingHandle = false;
			this.onDragEnd(value);
		}
		if(movingHandle && FlxG.mouse.released) movingHandle = false;
	}

	function _updatePositions()
	{
		minText.x = bar.x - minText.width/2;
		maxText.x = bar.x + bar.width - maxText.width/2;
		valueText.x = bar.x + bar.width/2 - valueText.width/2;

		labelText.x = bar.x + bar.width/2 - labelText.width/2;
		if(label.length > 0) bar.y = labelText.y + 24;
		
		minText.y = maxText.y = valueText.y = bar.y + 12;

		fill.y = bar.y;
		_updateHandleX();
		handle.y = bar.y + bar.height/2 - handle.height/2;
		_syncHandleVisuals();
	}

	function _updateHandleX()
	{
		handle.x = bar.x - handle.width/2 + FlxMath.remapToRange(FlxMath.roundDecimal(value, decimals), min, max, 0, bar.width);
		_syncHandleVisuals();
	}

	function _syncHandleVisuals()
	{
		handleBorder.x = handle.x - 1;
		handleBorder.y = handle.y - 1;

		fill.x = bar.x;
		fill.y = bar.y;
		var fillWidth:Float = Math.max(1, (handle.x + handle.width/2) - bar.x);
		fill.setGraphicSize(Std.int(fillWidth), Std.int(bar.height));
		fill.updateHitbox();
	}

	function set_decimals(v:Int)
	{
		decimals = v;
		minText.text = Std.string(FlxMath.roundDecimal(min, decimals));
		maxText.text = Std.string(FlxMath.roundDecimal(max, decimals));
		valueText.text = Std.string(FlxMath.roundDecimal(value, decimals));
		if(this.onDrag != null) this.onDrag(FlxMath.roundDecimal(value, decimals));
		_updatePositions();
		return decimals;
	}

	function set_min(v:Float)
	{
		if(v > max) max = v;
		min = v;
		minText.text = Std.string(FlxMath.roundDecimal(min, decimals));
		_updateHandleX();
		return min;
	}

	function set_max(v:Float)
	{
		if(v < min) min = v;
		max = v;
		maxText.text = Std.string(FlxMath.roundDecimal(max, decimals));
		_updateHandleX();
		return max;
	}

	function set_value(v:Float)
	{
		value = Math.max(min, Math.min(max, v));
		valueText.text = Std.string(FlxMath.roundDecimal(value, decimals));
		_updateHandleX();
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