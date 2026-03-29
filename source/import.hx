#if !macro
//Discord API
#if DISCORD_ALLOWED
import funkin.backend.Discord;
#end

import funkin.Main;

//Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

import funkin.backend.Paths;
import funkin.data.Controls;
import funkin.backend.utils.CoolUtil;
import funkin.states.base.MusicBeatState;
import funkin.states.base.MusicBeatSubstate;
import funkin.backend.CustomFadeTransition;
import funkin.data.ClientPrefs;
import funkin.backend.Conductor;
import funkin.backend.BaseStage;
import funkin.backend.Difficulty;
import funkin.backend.Mods;
import funkin.backend.PsychCamera;

import funkin.objects.Alphabet;
import funkin.objects.BGSprite;

import funkin.states.PlayState;
import funkin.states.handlers.LoadingState;

import funkin.objects.ui.*;

import animate.*;


//Flixel
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.util.FlxSimplex;
import openfl.ui.Mouse;
import lime.ui.MouseCursor;
import openfl.ui.MouseCursor as OpenflCursor;

using StringTools;

#if PRETTY_TRACE
import funkin.backend.Log;
import funkin.backend.Log.error;
import funkin.backend.Log.warn;
import funkin.backend.Log.info;
#else
import haxe.Log;
#end
#end
