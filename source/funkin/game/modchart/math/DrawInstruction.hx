package funkin.game.modchart.math;

import flixel.util.FlxPool;

// modified from lime.math.Vector4
/**
	`DrawInstruction` is a vector suitable for three-dimensional
	math, containing (x, y, z) components
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class DrawInstruction implements IFlxPooled
{
	static final _pool = new FlxPool<DrawInstruction>(() -> new DrawInstruction());
	
	public static function get(x:Float = 0, y:Float = 0, z:Float = 0):DrawInstruction
	{
		return _pool.get().setTo(x, y, z, 1, 0).resetDraw();
	}
	
	public static inline function recycle(x:Float = 0, y:Float = 0, z:Float = 0):DrawInstruction
	{
		return _pool.get().setTo(x, y, z, 1, 0).resetDraw();
	}
	
	public inline function put():Void
	{
		setTo(0, 0, 0, 1, 0);
		resetDraw();
		_pool.put(this);
	}
	
	// should set this up weak vecs later
	var _weak:Bool = false;
	
	public inline function putWeak() {}
	
	public function destroy():Void {}
	
	/**
		A constant representing the x axis (1, 0, 0)
	**/
	public static var X_AXIS(get, never):DrawInstruction;
	
	/**
		A constant representing the y axis (0, 1, 0)
	**/
	public static var Y_AXIS(get, never):DrawInstruction;
	
	/**
		A constant representing the z axis (0, 0, 1)
	**/
	public static var Z_AXIS(get, never):DrawInstruction;
	
	/**
		Get the length of this vector
	**/
	public var length(get, never):Float;
	
	/**
		Get the squared length of this vector
		(avoiding the use of `Math.sqrt` for faster
		performance)
	**/
	public var lengthSquared(get, never):Float;
	
	/**
		The x component value
	**/
	public var x:Float;
	
	/**
		The y component value
	**/
	public var y:Float;
	
	/**
		The z component value
	**/
	public var z:Float;

	/**
	 * Alpha value
	**/
	public var alpha:Float;

	/**
	 * Glow value
	**/
	public var glow:Float;

	public var scaleX:Float;

	public var scaleY:Float;

	public var skewX:Float;

	public var skewY:Float;

	public var angleX:Float;

	public var angleY:Float;

	public var angleZ:Float;
	
	/**
		Creates a new `DrawInstruction` instance
		@param	x	(Optional) An initial x value (default is 0)
		@param	y	(Optional) An initial y value (default is 0)
		@param	z	(Optional) An initial z value (default is 0)
	**/
	public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, ?alpha:Float = 1.0, ?glow:Float = 0.0)
	{
		resetDraw();
		setTo(x, y, z, alpha, glow);
	}

	public inline function resetDraw():DrawInstruction
	{
		alpha = 1;
		glow = 0;
		scaleX = scaleY = 1;
		skewX = skewY = 0;
		angleX = angleY = angleZ = 0;
		return this;
	}

	public inline function copyDrawFrom(o:DrawInstruction):DrawInstruction
	{
		alpha = o.alpha;
		glow = o.glow;
		scaleX = o.scaleX;
		scaleY = o.scaleY;
		skewX = o.skewX;
		skewY = o.skewY;
		angleX = o.angleX;
		angleY = o.angleY;
		angleZ = o.angleZ;
		return this;
	}

	public inline function multiplyScale(sx:Float, sy:Float):DrawInstruction
	{
		scaleX *= sx;
		scaleY *= sy;
		return this;
	}

	public inline function addSkew(kx:Float, ky:Float):DrawInstruction
	{
		skewX += kx;
		skewY += ky;
		return this;
	}

	public inline function addAngle(ax:Float, ay:Float, az:Float):DrawInstruction
	{
		angleX += ax;
		angleY += ay;
		angleZ += az;
		return this;
	}
	
	/**
		Adds two `DrawInstruction` instances together and returns the result
		@param	a	A `DrawInstruction` instance to add to the current one
		@param	result	(Optional) A `DrawInstruction` instance to store the result
		@return	A `DrawInstruction` instance with the added value
	**/
	public inline function add(a:DrawInstruction, result:DrawInstruction = null):DrawInstruction
	{
		var isNew = (result == null);
		result ??= DrawInstruction.get();
		if (isNew)
			result.setTo(this.x + a.x, this.y + a.y, this.z + a.z).copyDrawFrom(this);
		else
			result.setTo(this.x + a.x, this.y + a.y, this.z + a.z);
		return result;
	}
	
	/**
		Calculates the angle between two `DrawInstruction` coordinates
		@param	a	A `DrawInstruction` instance
		@param	b	A second `DrawInstruction` instance
		@return	The calculated angle
	**/
	public static inline function angleBetween(a:DrawInstruction, b:DrawInstruction):Float
	{
		var a0 = a.clone();
		a0.normalize();
		var b0 = b.clone();
		b0.normalize();
		
		return Math.acos(a0.dotProduct(b0));
	}
	
	/**
		Creates a new `DrawInstruction` instance with the same values as the current one
		@return	A new `DrawInstruction` instance with the same values
	**/
	public inline function clone():DrawInstruction
	{
		return DrawInstruction.get(x, y, z).copyDrawFrom(this);
	}
	
	/**
		Creates a new `DrawInstruction` instance linearly interpolated between this DrawInstruction and the given goal by the given lerpAlpha
		@param goal A `DrawInstruction` instance to interpolate towards
		@param lerpAlpha How far the interpolation is
		@return A `DrawInstruction instance linearly interpolated`
	**/
	// https://gamedev.stackexchange.com/questions/18615/how-do-i-linearly-interpolate-between-two-vectors
	public function lerp(goal:DrawInstruction, lerpAlpha:Float):DrawInstruction
	{
		inline function l(a:Float, b:Float):Float return lerpAlpha * b + a * (1 - lerpAlpha);
		var r = DrawInstruction.get(l(x, goal.x), l(y, goal.y), l(z, goal.z));
		r.alpha = l(alpha, goal.alpha);
		r.glow = l(glow, goal.glow);
		r.scaleX = l(scaleX, goal.scaleX);
		r.scaleY = l(scaleY, goal.scaleY);
		r.skewX = l(skewX, goal.skewX);
		r.skewY = l(skewY, goal.skewY);
		r.angleX = l(angleX, goal.angleX);
		r.angleY = l(angleY, goal.angleY);
		r.angleZ = l(angleZ, goal.angleZ);
		return r;
	}
	
	/**
		Copies the x, y and z component values of another `DrawInstruction` instance
		@param	sourceInstruction	A `DrawInstruction` instance to copy from
	**/
	public inline function copyFrom(sourceInstruction:DrawInstruction):Void
	{
		x = sourceInstruction.x;
		y = sourceInstruction.y;
		z = sourceInstruction.z;
		copyDrawFrom(sourceInstruction);
	}
	
	/**
		Performs vector multiplication between this vector and another `DrawInstruction` instance
		@param	A `DrawInstruction` instance to multiply by
		@param	result(Optional) A `DrawInstruction` to use for the result
		@return	A `DrawInstruction` instance with the result
		@see https://en.wikipedia.org/wiki/Cross_product
	**/
	public inline function crossProduct(a:DrawInstruction, result:DrawInstruction = null):DrawInstruction
	{
	    var isNew = (result == null);
	    result ??= DrawInstruction.get();
		if (isNew)
			result.setTo(y * a.z - z * a.y, z * a.x - x * a.z, x * a.y - y * a.x).copyDrawFrom(this);
		else
			result.setTo(y * a.z - z * a.y, z * a.x - x * a.z, x * a.y - y * a.x);
		return result;
	}
	
	/**
		Decrements the x, y and z component values by those in another `DrawInstruction` instance
		@param	a	A `DrawInstruction` instance to decrement the current vector by
	**/
	public inline function decrementBy(a:DrawInstruction):Void
	{
		x -= a.x;
		y -= a.y;
		z -= a.z;
	}
	
	/**
		Calculates the distance between two vectors
		@param	pt1	A `DrawInstruction` instance
		@param	pt2	A second `DrawInstruction` instance
		@return	The distance between each vector
	**/
	public inline static function distance(pt1:DrawInstruction, pt2:DrawInstruction):Float
	{
		var x = pt2.x - pt1.x;
		var y = pt2.y - pt1.y;
		var z = pt2.z - pt1.z;
		
		return Math.sqrt(x * x + y * y + z * z);
	}
	
	/**
		Calculates the squared distance between two vectors,
		(avoids the use of `Math.sqrt` for faster performance)
		@param	pt1	A `DrawInstruction` instance
		@param	pt2	A second `DrawInstruction` instance
		@return	The square of the distance between each vector
	**/
	public inline static function distanceSquared(pt1:DrawInstruction, pt2:DrawInstruction):Float
	{
		var x = pt2.x - pt1.x;
		var y = pt2.y - pt1.y;
		var z = pt2.z - pt1.z;
		
		return x * x + y * y + z * z;
	}
	
	/**
		Calculates the dot product of the current vector with another `DrawInstruction` instance
		@param	a	A `DrawInstruction` instance to use in the dot product
		@return	The calculated dot product value
		@see https://en.wikipedia.org/wiki/Dot_product
	**/
	public inline function dotProduct(a:DrawInstruction):Float
	{
		return x * a.x + y * a.y + z * a.z;
	}
	
	/**
		Whether two `DrawInstruction` instances have equal component values.

		Comparing the w component value is optional.
		@param	toCompare	A `DrawInstruction` instance to compare against
		@return	Whether both instances have equal values
	**/
	public inline function equals(toCompare:DrawInstruction):Bool
	{
		return x == toCompare.x && y == toCompare.y && z == toCompare.z;
	}
	
	/**
		Increments the x, y and z component values by those in a second `DrawInstruction` instance
		@param	a	A `DrawInstruction` instance to increment the current vector by
	**/
	public inline function incrementBy(a:DrawInstruction):Void
	{
		x += a.x;
		y += a.y;
		z += a.z;
	}
	
	/**
		Whether two `DrawInstruction` instances have nearly equal component values.
		Comparison is performed within a given tolerance value.
		@param	toCompare	A `DrawInstruction` instance to compare against
		@param	tolerance	A floating point value determining how near the values must be to be considered near equal
		@return	Whether both instances have equal values, within the given tolerance
	**/
	public inline function nearEquals(toCompare:DrawInstruction, tolerance:Float):Bool
	{
		return Math.abs(x - toCompare.x) < tolerance && Math.abs(y - toCompare.y) < tolerance && Math.abs(z - toCompare.z) < tolerance;
	}
	
	/**
		Negates the x, y and z values of the current vector
		(multiplying each value by -1)
	**/
	public inline function negate():Void
	{
		x *= -1;
		y *= -1;
		z *= -1;
	}
	
	/**
		Divides the x, y and z component values by the
		length of the vector
	**/
	public inline function normalize():Float
	{
		var l = length;
		
		if (l != 0)
		{
			x /= l;
			y /= l;
			z /= l;
		}
		
		return l;
	}

	/**
	    Projects this vector onto another `DrawInstruction` instance
	    @param onto A `DrawInstruction` instance to project onto
	    @param result (Optional) A `DrawInstruction` instance to store the result
	    @return A `DrawInstruction` instance containing the projected vector
		@see https://en.wikipedia.org/wiki/Vector_projection
	**/
	public inline function project(onto:DrawInstruction, result:DrawInstruction = null):DrawInstruction
	{
	    var isNew = (result == null);
	    result ??= DrawInstruction.get();
	    var scalar = dotProduct(onto) / onto.lengthSquared;
	    if (isNew)
	    	result.setTo(onto.x * scalar, onto.y * scalar, onto.z * scalar).copyDrawFrom(this);
	    else
	    	result.setTo(onto.x * scalar, onto.y * scalar, onto.z * scalar);
	    return result;
	}	

	/**
		Projects this vector onto a plane defined by a normal `DrawInstruction`
		@param normal A `DrawInstruction` instance representing the plane's normal (should be normalized)
		@param result (Optional) A `DrawInstruction` instance to store the result
		@return A `DrawInstruction` instance containing the projected vector
		@see https://en.wikipedia.org/wiki/Vector_projection
	**/
	public inline function projectOntoPlane(normal:DrawInstruction, result:DrawInstruction = null):DrawInstruction
	{
	    var isNew = (result == null);
	    result ??= DrawInstruction.get();
	    var projected = project(normal, DrawInstruction.get());
	    if (isNew)
	    	result.setTo(x - projected.x, y - projected.y, z - projected.z).copyDrawFrom(this);
	    else
	    	result.setTo(x - projected.x, y - projected.y, z - projected.z);
	    projected.put();
	    return result;
	}
	/**
		Puts this vector's values on an Absolute Value.
		@param result (Optional) A `DrawInstruction` instance to store the result
		@return A `Vector` instance containing the value in absolute.
	**/
	public inline function abs(result:DrawInstruction = null):DrawInstruction
	{
		var isNew = (result == null);
		result ??= DrawInstruction.get();
		if (isNew)
			result.setTo(Math.abs(x), Math.abs(y), Math.abs(z)).copyDrawFrom(this);
		else
			result.setTo(Math.abs(x), Math.abs(y), Math.abs(z));
		return result;
	}
	/**
		Scales the x, y and z component values by a scale value
		@param	s	The amount of scale to apply
	**/
	public inline function scaleBy(s:Float):Void
	{
		x *= s;
		y *= s;
		z *= s;
	}
	
	/**
		Sets the x, y and z component values
		@param	xa	An x value
		@param	ya	A y value
		@param	za	A z value

		@return returns `this` vector3
	**/
	public inline function setTo(xa:Float, ya:Float, za:Float, ?alphaa:Null<Float>, ?glowa:Null<Float>):DrawInstruction
	{
		x = xa;
		y = ya;
		z = za;
		if (alphaa != null) alpha = alphaa;
		if (glowa != null) glow = glowa;
		
		return this;
	}
	/**
		Subtracts the values of a second `DrawInstruction` instance
		from the current one
		@param	a	A second `DrawInstruction` instance to substract
		@param	result	(Optional) A `DrawInstruction` instance to store the result
		@return	A `DrawInstruction` instance containing the subtracted value
	**/
	public inline function subtract(a:DrawInstruction, result:DrawInstruction = null):DrawInstruction
	{
	    var isNew = (result == null);
	    result ??= DrawInstruction.get();
		if (isNew)
			result.setTo(x - a.x, y - a.y, z - a.z).copyDrawFrom(this);
		else
			result.setTo(x - a.x, y - a.y, z - a.z);
		return result;
	}
	
	/**
	    Creates a `DrawInstruction` from spherical coordinates
	    @param theta The polar angle in radians (from the z axis)
	    @param phi The azimuthal angle in radians (from the x axis)
	    @return A normalized `DrawInstruction` instance
		@see https://en.wikipedia.org/wiki/Spherical_coordinate_system
	**/
	public static inline function fromAngle(theta:Float, phi:Float):DrawInstruction
	{
	    var sinTheta = Math.sin(theta);
	    return DrawInstruction.get(sinTheta * Math.cos(phi), sinTheta * Math.sin(phi), Math.cos(theta));
	}
	
	/**
	    Returns a component-wise minimum of two `DrawInstruction` instances
	    @param a A `DrawInstruction` instance
	    @param b A second `DrawInstruction` instance
	    @param result (Optional) A `DrawInstruction` instance to store the result
	    @return A `DrawInstruction` instance with the minimum values
	**/
	public static inline function min(a:DrawInstruction, b:DrawInstruction, result:DrawInstruction = null):DrawInstruction
	{
	    var isNew = (result == null);
	    result ??= DrawInstruction.get();
	    if (isNew)
	    	result.setTo(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.min(a.z, b.z)).copyDrawFrom(a);
	    else
	    	result.setTo(Math.min(a.x, b.x), Math.min(a.y, b.y), Math.min(a.z, b.z));
	    return result;
	}
	
	/**
	    Returns a component-wise maximum of two `DrawInstruction` instances
	    @param a A `DrawInstruction` instance
	    @param b A second `DrawInstruction` instance
	    @param result (Optional) A `DrawInstruction` instance to store the result
	    @return A `DrawInstruction` instance with the maximum values
	**/
	public static inline function max(a:DrawInstruction, b:DrawInstruction, result:DrawInstruction = null):DrawInstruction
	{
	    var isNew = (result == null);
	    result ??= DrawInstruction.get();
	    if (isNew)
	    	result.setTo(Math.max(a.x, b.x), Math.max(a.y, b.y), Math.max(a.z, b.z)).copyDrawFrom(a);
	    else
	    	result.setTo(Math.max(a.x, b.x), Math.max(a.y, b.y), Math.max(a.z, b.z));
	    return result;
	}

	public static function weak(x:Float = 0., y:Float = 0., z:Float = 0.) {
		var vec = get(x, y, z);
		vec._weak = true;
		return vec;
	}
	
	@:dox(hide) public inline function toString():String
	{
		return 'DrawInstruction(x: $x, y: $y, z: $z, alpha: $alpha, glow: $glow, scale: ($scaleX, $scaleY), skew: ($skewX, $skewY), angle: ($angleX, $angleY, $angleZ))';
	}
	
	// Getters & Setters
	@:noCompletion private inline function get_length():Float
	{
		return Math.sqrt(x * x + y * y + z * z);
	}
	
	@:noCompletion private inline function get_lengthSquared():Float
	{
		return x * x + y * y + z * z;
	}
	
	private inline static function get_X_AXIS():DrawInstruction
	{
		return DrawInstruction.get(1, 0, 0);
	}
	
	private inline static function get_Y_AXIS():DrawInstruction
	{
		return DrawInstruction.get(0, 1, 0);
	}
	
	private inline static function get_Z_AXIS():DrawInstruction
	{
		return DrawInstruction.get(0, 0, 1);
	}
}

typedef Vector3 = DrawInstruction; // For compatibility with old Scripted Modifiers