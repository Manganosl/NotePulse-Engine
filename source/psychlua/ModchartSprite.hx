package psychlua;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxAxes;
import flixel.system.FlxAssets;

class ModchartSprite extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);
		antialiasing = ClientPrefs.data.antialiasing;
	}

	public function playAnim(name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0)
	{
		animation.play(name, forced, reverse, startFrame);
		
		var daOffset = animOffsets.get(name);
		if (animOffsets.exists(name)) offset.set(daOffset[0], daOffset[1]);
	}

	public function addOffset(name:String, x:Float, y:Float)
	{
		animOffsets.set(name, [x, y]);
	}
}

class ModchartBackdrop extends FlxBackdrop
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function new(?graphic:FlxGraphicAsset, axes:FlxAxes = XY, ?xSpacing:Int = 0, ?ySpacing:Int = 0)
	{
		super(graphic, axes, xSpacing, ySpacing);
		antialiasing = ClientPrefs.data.antialiasing;
	}
}