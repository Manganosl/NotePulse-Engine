# Extra HScript utils
Here's a list of all utilities added this this engine.

### CustomShader
This util will help to create shaders and add them to cameras directly
```
var shader:CustomShader = new CustomShader("shaderName");
shader.addToCamera(camera);
shader.addToCameras(cameras);
shader.removeFromCamera(camera);
shader.removeFromCameras(cameras);
shader.setFloat("val", num);
shader.setArrayFloat("val", [nums]);
shader.setInt("val", num);
shader.setArrayInt("val", [nums]);
shader.setBool("val", bool);
shader.setArrayBool("val", [bools]);
shader.setSampler2D("val", texture);
shader.setArraySampler2D("val", [textures]);
```

### WindowUtils
(Still more functions to be added!) This util helps with manipulating the game window
```
setTitle("name", add? = false)
setGameDimensions(width:Int, height:Int, cameras:Array<FlxCamera>)
centerWindowOnPoint(point)
getCenterWindowPoint()
```
### NdllUtil
(Thanks to CNE for this one!) This util loads custom ndlls located in the ndlls directory from your mod
```
var ndll = NdllUtil.getFunction("ndll", "funcName", args:Int)
```
From there you can just
```
ndll(val)
```

### Others
More things added are:
- [FunkinModchart functions](https://github.com/theoo-h/FunkinModchart/blob/main/DOC.md)
- [FlxEmitter](https://api.haxeflixel.com/flixel/effects/particles/FlxTypedEmitter.html)
- Away3D (I've got no idea how to use it right now)

# Extra LUA functions
Here you'll find multiple LUA functions added to make coding easier and do some things without the need of runHaxeCode() or a separate HScript file

### Return Functions
- Lerp that has the same speed independently from fps
```
fpsLerp(from, to, lerpSpeed)
```
- Get Discord username, will return null if not connected
```
getDiscordUser()
```
- Get device username
```
getSystemUser()
```

### Video Functions
- Make and play a video sprite
```
makeVideoSprite(tag, video, ?x = 0, ?y = 0, ?camera = "camHUD", ?looped = false)
```
- Precache a video
```
precacheVideo(video)
```

### Window Functions
- Center the game window
```
windowScreenCenter(?axis = 'xy')
```
- Change window position
```
setWindowPosition(x, y)
```
- Set a window property
```
setWindowProperty(name, value)
```
- Make a window alert pop up
```
windowAlert(msg, title)
```
- Tween window resolution
```
windowTweenResize(tag, width, height, duration, easing)
```
- Tween the window to the center
```
windowTweenCenter(tag, ?axis = 'xy', duration, easing)
```
- Tween window x value
```
windowTweenX(tag, x, duration, easing)
```
- Tween window y value
```
windowTweenY(tag, y, duration, easing)
```
- Change window title
```
setWindowTitle(title)
```

### "Why isn't this in Psych?" Functions
- Tween a number value
```
doTweenNumber(tag, from, to, duration, easing)
```
This function also makes a call:
```
function onNumberTweenUpdate(tag, num)
```

### Ndll functions
- Initialize a Ndll under a tag
```
initNdll(tag, path, name, args)
```
- Change a Ndll's bool value
```
setNdllBool(tag, bool)
```

### Modcharting functions
- **You can use a special call specific for modcharting as alternative to onCreatePost()**
```
function initModchart()
```
- Create a modchart instance under a tag
```
modchart.newInstance(tag)
```
- Add a modifier to a modchart instance
```
modchart.addModifier(tag, modifier, field)
```
- Set a modifier's value
```
modchart.setPercent(tag, modifier, value, player, field)
```
- Get a modifier's value
```
modchart.getPercent(tag, modifier, player, field)
```
- Set a modifier's value at a specific beat
```
modchart.set(tag, modifier, beat, value, player, field)
```
- Tween a modifier's value at a specific beat
```
modchart.ease(tag, modifier, beat, value, ease, player, field)
```
- Add a playfield
```
modchart.addPlayfield(tag)
```