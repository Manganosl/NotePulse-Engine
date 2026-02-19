package funkin.backend;

import funkin.backend.ClientPrefs;

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
	}

	public static function loadDefault():Array<Rating>{
	    var ratingsData:Array<Rating> = [];

	    var epic:Rating = new Rating('epic');
	    epic.ratingMod = 1.0;
	    epic.score = 500;
	    epic.noteSplash = true;
	    epic.hitWindow = ClientPrefs.data.epicWindow;
	    ratingsData.push(epic);

	    var sick:Rating = new Rating('sick');
	    sick.ratingMod = 1.0;
	    sick.score = 350;
	    sick.noteSplash = true;
	    sick.hitWindow = ClientPrefs.data.sickWindow;
	    ratingsData.push(sick);

	    var good:Rating = new Rating('good');
	    good.ratingMod = 0.67;
	    good.score = 200;
	    good.noteSplash = false;
	    good.hitWindow = ClientPrefs.data.goodWindow;
	    ratingsData.push(good);

	    var bad:Rating = new Rating('bad');
	    bad.ratingMod = 0.34;
	    bad.score = 100;
	    bad.noteSplash = false;
	    bad.hitWindow = ClientPrefs.data.badWindow;
	    ratingsData.push(bad);

	    var shit:Rating = new Rating('shit');
	    shit.ratingMod = 0;
	    shit.score = 50;
	    shit.noteSplash = false;
	    shit.hitWindow = 190;
	    ratingsData.push(shit);

	    return ratingsData;
	}
}
