package funkin.game.modchart.modifiers;

class RotateModifier extends NoteModifier { // this'll be rotateX in ModManager
	var _name:String;
	override function getName() return _name;
	override function getOrder() return Modifier.ModifierOrder.LAST + 2;
	
	public var daOrigin:Vector3;
	
	var prefix:String;

	var sRotY:Modifier;
	var sRotZ:Modifier;
	var cRotX:Array<Modifier>;
	var cRotY:Array<Modifier>;
	var cRotZ:Array<Modifier>;
	
	public function new(modMgr:ModManager, ?prefix:String = '', ?origin:Vector3, ?parent:Modifier)
	{
		this.prefix = prefix;
		this._name = '${prefix}rotateX';
		this.daOrigin = origin;
		super(modMgr, parent);
	}

	override function bind()
	{
		sRotY = submods.get('${prefix}rotateY');
		sRotZ = submods.get('${prefix}rotateZ');
		cRotX = bindColumn('${prefix}rotate', 'X');
		cRotY = bindColumn('${prefix}rotate', 'Y');
		cRotZ = bindColumn('${prefix}rotate', 'Z');
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		var ox:Float;
		var oy:Float;
		var oz:Float = 0;
		if (daOrigin != null) {
			ox = daOrigin.x;
			oy = daOrigin.y;
			oz = daOrigin.z;
		} else {
			ox = modMgr.getBaseX(data, player);
			oy = (FlxG.height / 2) - (Note.swagWidth / 2);
		}

		MathUtil.rotatePos3D(pos, ox, oy, oz,
			getValue(player) + colVal(cRotX, data, player),
			subVal(sRotY, player) + colVal(cRotY, data, player),
			subVal(sRotZ, player) + colVal(cRotZ, data, player),
			FlxG.height);
		
		return pos;
	}
	
	override function getSubmods()
	{
		var list = ['${prefix}rotateY', '${prefix}rotateZ'];
		for (i in 0...PlayState.SONG.mania+1)
		{
			list.push('${prefix}rotate${i}X');
			list.push('${prefix}rotate${i}Y');
			list.push('${prefix}rotate${i}Z');
		}
		
		return list;
	}
}
