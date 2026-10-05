package funkin.game.modchart.modifiers;

class LocalRotateModifier extends NoteModifier
{ // this'll be rotateX in ModManager
	var _name:String;
	override function getName() return _name;
	override function getOrder() return Modifier.ModifierOrder.POST_REVERSE;
	var prefix:String;

	var sRotY:Modifier;
	var sRotZ:Modifier;
	var cRotX:Array<Modifier>;
	var cRotY:Array<Modifier>;
	var cRotZ:Array<Modifier>;
	
	public function new(modMgr:ModManager, ?prefix:String = '', ?parent:Modifier){
		this.prefix = prefix;
		this._name = '${prefix}rotateX';
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

	private var originX:Float = 0;
	private function getFieldOriginX(field:PlayField):Float {
		final FKC = field.keyCount;

		if (FKC % 2 == 0) {
			final RKN = Math.floor(FKC / 2);
			final LKN = RKN - 1;
			originX = (field.members[LKN].x + field.members[RKN].x) * 0.5;
		} else {
			originX = field.members[Math.floor(FKC / 2)].x;
		}

		return originX;
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		var ox = getFieldOriginX(PlayField.fields[player]);

		MathUtil.rotatePos3D(pos, ox, FlxG.height * 0.5, 0.0,
			getValue(player) + colVal(cRotX, data, player),
			subVal(sRotY, player) + colVal(cRotY, data, player),
			subVal(sRotZ, player) + colVal(cRotZ, data, player),
			FlxG.height);
		
		return pos;
	}
	
	override function getSubmods()
	{
		var returns = ['${prefix}rotateY', '${prefix}rotateZ'];
		
		for (i in 0...PlayState.SONG.mania+1)
		{
			returns.push('${prefix}rotate${i}X');
			returns.push('${prefix}rotate${i}Y');
			returns.push('${prefix}rotate${i}Z');
		}
		
		return returns;
	}
}
