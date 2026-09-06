package funkin.states.editors.ui;

import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.ListView;
import haxe.ui.core.Screen;

import flixel.util.typeLimit.OneOfThree;
import flixel.FlxG;

import haxe.ui.core.*;
import haxe.ui.components.DropDown;
import haxe.ui.components.OptionStepper;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.notifications.NotificationData;
import haxe.ui.containers.dialogs.MessageBox.MessageBoxType;
import haxe.ui.data.ArrayDataSource;

class ToolKitUtils {
	public static var currentFocus(default, null):Null<InteractiveComponent> = null;
	static var iterated:Array<Component> = [];

	static var _hitTest:Null<flixel.math.FlxPoint> = null;
	
	/**
	 * Checks if haxe ui element is currently being covered by the mouse
	 */
	public static function isHaxeUIHovered(camera:FlxCamera)
	{
		// ok just dont fucking work sure
		// trace(FocusManager.instance.focus);
		_hitTest = FlxG.mouse.getPositionInCameraView(camera, _hitTest);
		return Screen.instance.hasSolidComponentUnderPoint(_hitTest.x, _hitTest.y);
	}

	public static function forceUnfocus(){
		iterated.resize(0);
		currentFocus = null;
		
		for (component in Screen.instance.rootComponents)
			unfocusIter(component, true);
	}

	static function unfocusIter(component:Component, ignoreHitTest:Bool = false):Void
	{
		if (iterated.contains(component)) return;
		
		if (component is InteractiveComponent && (cast component : InteractiveComponent).focus)
		{
			_hitTest = FlxG.mouse.getPositionInCameraView(FlxG.cameras.list[FlxG.cameras.list.length - 1], _hitTest);
			
			if (ignoreHitTest || !component.hasComponentUnderPoint(_hitTest.x, _hitTest.y))
			{
				var component:InteractiveComponent = cast component;
				@:privateAccess component._focus = true;
				component.focus = false;
				return;
			}
		}
		@:privateAccess if (component._children != null) for (child in component._children)
			unfocusIter(child, ignoreHitTest);
	}

	static function focusIter(component:Component):Void {
		if (iterated.contains(component) || currentFocus != null) return;
		
		var focusable:Bool = (
			component is InteractiveComponent &&
			(!(component is haxe.ui.components.CheckBox)) &&
			(!(component is haxe.ui.components.Button) || component is haxe.ui.components.DropDown) // fuck you TabButton
		);
		
		if (focusable && (cast component : InteractiveComponent).focus)
		{
			currentFocus = cast component;
			return;
		}
		@:privateAccess if (component._children != null) for (child in component._children)
			focusIter(child);
	}

	public static function update():Void {
		// some duct tape
		// to make using haxe ui more stable
		@:privateAccess
		if (FlxG.game._nextState == null && (FlxG.mouse.justMoved || FlxG.mouse.justPressed || FlxG.mouse.justReleased))
		{
			iterated.resize(0);
			currentFocus = null;
			
			if (FlxG.mouse.justPressed) for (component in Screen.instance.rootComponents)
				unfocusIter(component);
				
			iterated.resize(0);
			
			for (component in Screen.instance.rootComponents)
				focusIter(component);
		}
	}
}
