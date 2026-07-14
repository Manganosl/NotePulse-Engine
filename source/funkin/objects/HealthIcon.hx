package funkin.objects;

class HealthIcon extends FlxSkewedSprite
{
	public var frameAmount(default, set):Int = 2;
	public var sprTracker:FlxSprite;
	private var isOldIcon:Bool = false;
	private var isPlayer:Bool = false;
	private var char:String = '';

	private function set_frameAmount(value:Int){
        var newValue = (value > 3) ? 3 : ((value < 1) ? 1 : value);
        
        if(frameAmount != newValue) {
            frameAmount = newValue;
            changeIcon(char, true, true);
        }
        return frameAmount;
    }

	public function new(char:String = 'bf', isPlayer:Bool = false, ?allowGPU:Bool = true)
	{
		super();
		isOldIcon = (char == 'bf-old');
		this.isPlayer = isPlayer;
		changeIcon(char, allowGPU);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
	}

	private var iconOffsets:Array<Float> = [0, 0];
	public function changeIcon(char:String, ?allowGPU:Bool = true, ?forceRefresh:Bool = false) {
		if(this.char != char || forceRefresh){
			var name:String = 'icons/' + char;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char; //Older versions of psych engine's support
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face'; //Prevents crash from missing icon
			
			var graphic = Paths.image(name, allowGPU);
			loadGraphic(graphic, true, Math.floor(graphic.width / frameAmount), Math.floor(graphic.height));
			iconOffsets[0] = (width - 150) / 2;
			iconOffsets[1] = (height - 150) / 2;
			updateHitbox();

			var animAm:Array<Int> = [];
			for(i in 0...frameAmount) animAm.push(i);
			animation.add(char, animAm, 0, false, isPlayer);
			animation.play(char);
			this.char = char;

			if(char.endsWith('-pixel'))
				antialiasing = false;
			else
				antialiasing = ClientPrefs.data.antialiasing;
		}
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		offset.x = iconOffsets[0];
		offset.y = iconOffsets[1];
	}

	public function getCharacter():String {
		return char;
	}
}
