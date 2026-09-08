## Libraries
- Replaced SScript, now using HScript Improved.
- Added Nape
- Added Away3D
- Using cne-hxcpp
- Replaced hxCodec, using hxvlc to avoid crashes.
- Using cne-hxdiscord.

## Flixel
- Camera rotation from cne-flixel.
- Functions for adding and removing FlxGraphicShader as ShaderFilter.
- FlxSprite zoomFactor property.
- FlxBasic extraData map.
- Added wait() function from newer versions to FlxTimer.
- Using inputs from newer versions to avoid problems with specific keyboards (Such as my own)
- Using FlxDrawQuadsItem and FlxDrawTrianglesItem from newer versions as it improves performance significantly.
- Using Flixel 5.6.2 and Flixel-Addons 3.2.3

## [Modcharting Framework](https://github.com/nebulazorua)
- RGBShader handles the glow and alpha from modchart (Only on Strum Notes). Notes handle it via ColorTransform.
- Functions that add compatibility for FunkinModchart.
- StrumNotes render using modPos.x and modPos.y, (x and y still work)
- Sustains can be segmented, the number of segments can be changed through it's PlayField.
- New modifiers and fixes for others
- FunkinSprite with 3D angles
- Sustain splashes

## Game
- Changed FPS counter to V-Slice's, adding debug info.
- DebugPrints now render on top of the game
- Added V-Slice's soundtray.
- Changed the editor selector.
- Many more classes imported by default.
- Reorganized source code.
- Changing Key Count.
- Compatible with Psych 1.0 charts
- Fifth rating
- Play as opponent
- Camera movement on note hit.
- Custom frame amounts on Health Icons

## Modding
- Scripted States / Scripted Substates
- Scripted Transitions
- Mod loading
  - Forcing mod loading when opening the game
  - State redirection
  - config.json in a mod's data folder adds custom options on OptionsState, which are stored in Mods.save.data

## PlayField system
- Custom keyCount per field.
- Set if the player/cpu is in control of the field (Can also be per strum).
- Set if the playfield is controlled by the player or cpu (Can also be per strum). Multiple fields can be played by the player, even with different keyCount each.
- Change both note hit and note miss callbacks (Can also be per strum).

## Editors and Utilities

- Psych 1.0 Stage editor.
- Psych 1.0 Charting Editor
  - Multiple players
  - Character per lane
  - Fixed bugs from Psych 1.0
  - Modchart Events
  - Import charts from:  (Moonchart)
    - V-Slice
    - Codename Engine
    - Osu mania
    - Clone Hero
    - StepMania
    - Quaver
- Modchart Editor
- New Utilities
  - CustomShader
  - NdllUtil
  - WindowUtil
  - CameraUtil