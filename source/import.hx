#if !macro
//Discord API
#if DISCORD_ALLOWED
import backend.Discord;
#end

//FunkinModchart
import modchart.Config;
import modchart.Manager;
import modchart.backend.core.*;
import modchart.backend.graphics.*;
import modchart.backend.math.*;
import modchart.backend.standalone.Adapter;
import modchart.backend.util.ModchartUtil;
import modchart.engine.*;
import modchart.engine.events.*;
import modchart.engine.modifiers.*;
import openfl.geom.Vector3D;
import flixel.graphics.tile.FlxDrawTrianglesItem;

//Psych
#if LUA_ALLOWED
import llua.*;
import llua.Lua;
#end

#if ACHIEVEMENTS_ALLOWED
import backend.Achievements;
#end

#if sys
import sys.*;
import sys.io.*;
#elseif js
import js.html.*;
#end

import backend.Paths;
import backend.Controls;
import backend.utils.CoolUtil;
import states.base.MusicBeatState;
import states.base.MusicBeatSubstate;
import backend.CustomFadeTransition;
import backend.ClientPrefs;
import backend.Conductor;
import backend.BaseStage;
import backend.Difficulty;
import backend.Mods;
import backend.PsychCamera;

import objects.Alphabet;
import objects.BGSprite;

import states.PlayState;
import states.handlers.LoadingState;

#if flxanimate
import flxanimate.*;
import flxanimate.PsychFlxAnimate as FlxAnimate;
#end

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

using StringTools;

#if PRETTY_TRACE
import backend.Log;
import backend.Log.error;
import backend.Log.warn;
import backend.Log.info;
#else
import haxe.Log;
#end
#end
