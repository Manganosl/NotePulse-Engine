package objects;

import haxe.ds.IntMap;
import objects.Note;

class OurLittleFriend extends FlxSprite
{
	var _colors:Array<FlxColor> = [FlxColor.MAGENTA, FlxColor.CYAN, FlxColor.LIME, FlxColor.RED, FlxColor.WHITE];
    var _dances:Array<String> = ['left', 'down', 'up', 'right', 'idle'];

	var _offsetPath:String = '';

	public var offsets:IntMap<Array<Float>> = new IntMap();

	public function new(char:String)
	{
		super();
		final basePath = 'images/editors/friends/$char';
		if (FileSystem.exists(Paths.getSharedPath('$basePath.png')))
		{
			frames = Paths.getSparrowAtlas(basePath.substr(basePath.indexOf('/') + 1));
			animation.addByPrefix('idle', 'i', 24);
			animation.addByPrefix('left', 'l', 24, false);
			animation.addByPrefix('down', 'd', 24, false);
			animation.addByPrefix('up', 'u', 24, false);
			animation.addByPrefix('right', 'r', 24, false);

			setGraphicSize(100);
			updateHitbox();

			buildOffsets(basePath);

			sing("idle");
		}
	}

	function buildOffsets(?path:String)
	{
		path ??= _offsetPath;
		if (FileSystem.exists(Paths.getSharedPath('$path.txt'))) for (k => i in File.getContent(Paths.getSharedPath('$path.txt')).trim().split('\n'))
		{
			var value = i.trim().split(',');
			offsets.set(k, [Std.parseFloat(value[0]), Std.parseFloat(value[1])]);
		}

		_offsetPath = path;
	}

	public function sing(shit:String, ?note:Note)
	{
        var anim = shit.toLowerCase();
        var dir = 0;
        switch(anim){
            case "left":
                dir = 0;
            case "down":
                dir = 1;
            case "up":
                dir = 2;
            case "right":
                dir = 3;
            case "idle":
                dir = 4;
        }
		animation.play(anim);

		color = note == null ? FlxColor.WHITE : note.rgbShader.r;

		centerOffsets();

		if (offsets.exists(dir))
		{
			offset.x += offsets.get(dir)[0] * scale.x;
			offset.y += offsets.get(dir)[1] * scale.y;
		}
		// else offset.set();
	}
}