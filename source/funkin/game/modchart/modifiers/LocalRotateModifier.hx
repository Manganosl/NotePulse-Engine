package funkin.game.modchart.modifiers;

class LocalRotateModifier extends NoteModifier
{ // this'll be rotateX in ModManager
	override function getName() return '${prefix}rotateX';
	override function getOrder() return Modifier.ModifierOrder.POST_REVERSE;
	var prefix:String;
	
	public function new(modMgr:ModManager, ?prefix:String = '', ?parent:Modifier){
		this.prefix = prefix;
		super(modMgr, parent);
	}
	
	// thanks schmoovin'
	function rotateV3(vec:Vector3, xA:Float, yA:Float, zA:Float):Vector3
	{
		var rotateZ = MathUtil.rotate(vec.x, vec.y, zA);
		var offZ = Vector3.get(rotateZ.x, rotateZ.y, vec.z);
		
		var rotateX = MathUtil.rotate(offZ.z, offZ.y, xA);
		var offX = Vector3.get(offZ.x, rotateX.y, rotateX.x);
		
		var rotateY = MathUtil.rotate(offX.x, offX.z, yA);
		var offY = Vector3.get(rotateY.x, offX.y, rotateY.y);
		
		offZ.put();
		offX.put();
		
		rotateZ.putWeak();
		rotateX.putWeak();
		rotateY.putWeak();
		
		return offY;
	}

	private var origin = Vector3.get(0.0, FlxG.height * 0.5, 0.0);
	private function getFieldOrigin(field:PlayField):Vector3 {
		final FKC = field.keyCount;

		if (FKC % 2 == 0) {
			final RKN = Math.floor(FKC / 2);
			final LKN = RKN - 1;
			origin.x = (field.members[LKN].x + field.members[RKN].x) * 0.5;
		} else {
			origin.x = field.members[Math.floor(FKC / 2)].x;
		}

		return origin;
	}
	
	override function getPos(time:Float, visualDiff:Float, timeDiff:Float, beat:Float, pos:Vector3, data:Int, player:Int, obj:FlxSprite)
	{
		var origin = getFieldOrigin(PlayField.fields[player]);
		
		var diff = pos.subtract(origin);
		var scale = FlxG.height;
		diff.z *= scale;
		
		final vals = Vector3.get(getValue(player), getSubmodValue('${prefix}rotateY', player), getSubmodValue('${prefix}rotateZ', player));
		
		vals.x += getSubmodValue('${prefix}rotate${data}X', player);
		vals.y += getSubmodValue('${prefix}rotate${data}Y', player);
		vals.z += getSubmodValue('${prefix}rotate${data}Z', player);
		
		var out = rotateV3(diff, vals.x, vals.y, vals.z);
		out.z /= scale;
		
		origin.add(out, pos);
		out.put();
		vals.put();
		
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