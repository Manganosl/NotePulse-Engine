## Libraries

### HScript

- Replaced SScript, now using HScript Improved.
  - Public variables
  - Static variables
  - Custom classes.
  - Enums.
  - Many more things.
- Many more classes imported by default.
- Scripted States

### Flixel

###### Using Flixel 5.6.2 and Flixel-Addons 3.2.3

- FlxCamera:
  - Camera rotation from cne-flixel.
  - Functions for adding and removing FlxGraphicShader as ShaderFilter.
- FlxSprite zoomFactor property.
- FlxBasic extraData map.
- Added wait() function from newer versions to FlxTimer.
- Using inputs from newer versions to avoid problems with specific keyboards (Such as my own)
- Using FlxDrawQuadsItem and FlxDrawTrianglesItem from newer versions as it improves performance significantly.

### [Modcharting Framework](https://github.com/nebulazorua)

- RGBShader now has a perspective shader.
- Functions that add compatibility for FunkinModchart.
- StrumNotes render using modPos.x and modPos.y, (x and y still work)
- Sustains can use more subdivisions, the count can be changed on the charting editor (2 is the default value)

### Others

- Added Nape
- Added Away3D
- Using cne-hxcpp
- Replaced hxCodec, now using hxvlc.
- Using cne-hxdiscord as it adds many features.

## Game

- Reorganized source code.
- Compatible with Psych 1.0 charts
- Fifth rating
- Play as opponent
- Support for more PlayFields
- CustomShader utility
- NDLL support.
- Camera movement on note hit.
- Changing Key Count.
- Sustain splashes.
- Psych 1.0 Stage editor.
- Psych 1.0 Charting Editor

###### Probably more things but I forgot