package backend;

import backend.ClientPrefs;

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var score:Int = 350;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String)
	{
		this.name = name;
		this.image = name;
		this.hitWindow = 0;

		var window:String = name + 'Window';
		try
		{
			this.hitWindow = Reflect.field(ClientPrefs.data, window);
		}
		catch(e) FlxG.log.error(e);
	}

	public static function loadDefault():Array<Rating>{
	    var ratingsData:Array<Rating> = [];

	    var marvelous:Rating = new Rating('marvelous');
	    marvelous.ratingMod = 1.0;
	    marvelous.score = 500;
	    marvelous.noteSplash = true;
	    marvelous.hitWindow = 20;
	    ratingsData.push(marvelous);

	    var sick:Rating = new Rating('sick');
	    sick.ratingMod = 1.0;
	    sick.score = 350;
	    sick.noteSplash = true;
	    sick.hitWindow = 55;
	    ratingsData.push(sick);

	    var good:Rating = new Rating('good');
	    good.ratingMod = 0.67;
	    good.score = 200;
	    good.noteSplash = false;
	    good.hitWindow = 100;
	    ratingsData.push(good);

	    var bad:Rating = new Rating('bad');
	    bad.ratingMod = 0.34;
	    bad.score = 100;
	    bad.noteSplash = false;
	    bad.hitWindow = 140;
	    ratingsData.push(bad);

	    var shit:Rating = new Rating('shit');
	    shit.ratingMod = 0;
	    shit.score = 50;
	    shit.noteSplash = false;
	    shit.hitWindow = 200;
	    ratingsData.push(shit);

	    return ratingsData;
	}
}
