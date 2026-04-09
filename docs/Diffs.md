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
  - Functions for adding and removing FlxRuntimeShaders.
- FlxSprite zoomFactor property.
- FlxBasic extraData map.
- Added wait() function from newer versions to FlxTimer.
- Using inputs from newer versions to avoid problems with specific keyboards (Such as my own)
- Using FlxDrawQuadsItem and FlxDrawTrianglesItem from newer versions as it improves performance significantly.

### Modcharting Framework - FunkinModchart

- Integrated to make as less calls to the Adapter as possible.
- Added a simple hold renderer (Can be toggled in Graphics Settings)
- More modifiers added by default (How is transform not by default?)
- Renamed PlayField to ModPlayField to avoid problems with PlayField class.
- Added Troll Engine functions.
- Optimized multiple modifiers and fixed others.
- Added more modifiers (Such as stretch or squish)

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
- Support for "CopyFields" (Which just visually copies a PlayField)
- CustomShader utility
- NDLL support.
- Camera movement on note hit.
- Changing Key Count.
- Judgement counter.
- Sustain splashes.
- Stage editor.
- Psych 1.0 Charting Editor

###### Probably more things but I forgot