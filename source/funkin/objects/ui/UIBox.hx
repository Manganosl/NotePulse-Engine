package funkin.objects.ui;

typedef UIStyleData = {
	var bgColor:FlxColor;
	var textColor:FlxColor;
	var bgAlpha:Float;
}

class UIBox extends FlxSpriteGroup
{
	public static final CLICK_EVENT = "uibox_click";
	public static final MINIMIZE_EVENT = "uibox_minimize"; //called on both minimizing and maximizing
	public static final DRAG_EVENT = "uibox_drag";
	public static final DROP_EVENT = "uibox_drop";
	public var tabs(default, null):Array<UITab> = [];
	
	public var selectedTab(default, set):UITab = null;
	public var selectedIndex(default, set):Int = -1;
	public var selectedName(default, set):String = null;

	public var bg:FlxSprite;

	public var selectedStyle:UIStyleData = {
		bgColor: 0xFF8000FF,
		textColor: 0xFFF1F1F5,
		bgAlpha: 1
	};
	public var hoverStyle:UIStyleData = {
		bgColor: 0xFFA855F7,
		textColor: 0xFF14161C,
		bgAlpha: 0.9
	};
	public var unselectedStyle:UIStyleData = {
		bgColor: 0xFF262A34,
		textColor: 0xFFF1F1F5,
		bgAlpha: 0.88
	};

	public var canMove:Bool = true;
	public var canMinimize(default, set):Bool = true;
	public var isMinimized(default, set):Bool = false;
	public var minimizeOnFocusLost:Bool = false;

	public var border:FlxSprite;
	public var borderThickness:Int = 1;

	public var tabIndicator:FlxSprite;
	var _indicatorLeft:Float = 0;
	var _indicatorRight:Float = 0;
	var _indicatorOffsetY:Float = 0;
	public var indicatorHeight:Int = 4;
	public var indicatorLerpSpeed:Float = 0.2;

	public var openCloseAnimDuration:Float = 0.12;
	public var tabSwitchPunchAmount:Float = 5;
	public var tabSwitchPunchDecay:Float = 14;
	var _indicatorPunch:Float = 0;

	public function new(x:Float, y:Float, width:Int, height:Int, tabs:Array<String> = null)
	{
		super(x, y);

		border = new FlxSprite(-borderThickness, -borderThickness).makeGraphic(1, 1, FlxColor.WHITE);
		border.color = 0xFF3A3F52;
		border.alpha = 0.55;
		add(border);

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		bg.color = 0xFF1C1F27;
		bg.alpha = 0.78;
		add(bg);

		if(tabs != null)
		{
			for (tab in tabs)
			{
				var createdTab:UITab = new UITab(tab);
				this.tabs.push(createdTab);
				add(createdTab);
			}
		}

		tabIndicator = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE);
		tabIndicator.color = selectedStyle.bgColor;
		tabIndicator.alpha = 1;
		tabIndicator.visible = true;

		resize(width, height);
		selectedIndex = 0;
		forceCheckNext = true;
		snapIndicatorToSelected();
	}

	var _draggingPos:FlxPoint;
	var _draggingPoint:FlxPoint;
	var _pressedBox:Bool = false;
	var _draggingBox:Bool = false;
	var _lastTab:UITab;
	var _lastClick:Float = 0;
	private var isPointer:Bool = false;
	private var isMove:Bool = false;
	public var forceCheckNext:Bool = false;
	public var broadcastBoxEvents:Bool = true;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		_lastClick += elapsed;
		if(!FlxG.mouse.released && _draggingBox && canMove)
		{
			var newPoint:FlxPoint = FlxG.mouse.getPositionInCameraView(camera);
			setPosition(_draggingPos.x - (_draggingPoint.x - newPoint.x), _draggingPos.y - (_draggingPoint.y - newPoint.y));
		}
		else
		{
			var wasDragging:Bool = _draggingBox;
			_draggingPos = null;
			_draggingPoint = null;
			_draggingBox = false;
			if(FlxG.mouse.released)
			{
				if(_pressedBox) forceCheckNext = true;
				_pressedBox = false;
			}
			//if(wasDragging && broadcastBoxEvents) UIEventHandler.event(DROP_EVENT, this);
		}

		for (tab in tabs)
		{
			tab.scrollFactor.set(scrollFactor.x, scrollFactor.y);
			tab.text.scrollFactor.set(scrollFactor.x, scrollFactor.y);
		}
		tabIndicator.scrollFactor.set(scrollFactor.x, scrollFactor.y);

		var _ignoreTabUpdate:Bool = false;
		if(forceCheckNext || FlxG.mouse.justMoved || FlxG.mouse.justPressed || FlxG.mouse.justReleased)
		{
			forceCheckNext = false;
			for (tab in tabs)
			{
				if(FlxG.mouse.overlaps(tab, camera))
				{
					if(!isMove) Mouse.cursor = MouseCursor.POINTER;
					isPointer = true;
					tab.color = hoverStyle.bgColor;
					tab.alpha = hoverStyle.bgAlpha;
					tab.text.color = hoverStyle.textColor;
	
					if(FlxG.mouse.justPressed)
						_pressedBox = true;

					if(visible && !_draggingBox && canMove && _pressedBox && FlxG.mouse.pressed && (Math.abs(FlxG.mouse.deltaScreenX) > 1 || Math.abs(FlxG.mouse.deltaScreenY) > 1))
					{
						_draggingPos = FlxPoint.weak(x, y);
						_draggingPoint = FlxG.mouse.getPositionInCameraView(camera);
						_draggingBox = true;
						if(broadcastBoxEvents) UIEventHandler.event(DRAG_EVENT, this);
					} 
					if(_draggingBox){
						isMove = true;
						Mouse.cursor = MouseCursor.MOVE;
					} else if(isMove){
						isMove = false;
					}
					
					if(FlxG.mouse.justReleased && canMinimize && _lastClick < 0.15 && selectedTab == tab && _lastTab == selectedTab)
					{
						_ignoreTabUpdate = true;
						isMinimized = !isMinimized;
						_lastClick = 0;
						//trace('do minimize: $isMinimized');
					}
					
					if(FlxG.mouse.justPressed)
					{
						if(selectedTab != tab)
						{
							isMinimized = false;
							_ignoreTabUpdate = true;
						}
						_lastTab = selectedTab;
						selectedTab = tab;
						_lastClick = 0;
						if(broadcastBoxEvents) UIEventHandler.event(CLICK_EVENT, this);
					}
					continue;
				} else if(isPointer){
            		Mouse.cursor = MouseCursor.DEFAULT;
           			isPointer = false;
        		}
				
				var isSelected:Bool = (selectedTab == tab);
				tab.color = unselectedStyle.bgColor;
				tab.alpha = unselectedStyle.bgAlpha;
				tab.text.color = isSelected ? selectedStyle.textColor : unselectedStyle.textColor;
			}
		}

		updateTabIndicator(elapsed);

		if(_ignoreTabUpdate)
		{
			if(broadcastBoxEvents)
				UIEventHandler.event(MINIMIZE_EVENT, this);
		}
		else if(selectedTab != null && !isMinimized)
			selectedTab.updateMenu(this, elapsed);

		if(minimizeOnFocusLost && FlxG.mouse.justPressed && !isMinimized && !FlxG.mouse.overlaps(bg, camera))
		{
			isMinimized = true;
			if(broadcastBoxEvents)
				UIEventHandler.event(MINIMIZE_EVENT, this);
		}
	}

	function updateTabIndicator(elapsed:Float){
        tabIndicator.visible = true;

        var targetLeft:Float;
        var targetRight:Float;
        var targetY:Float;

        if(selectedTab == null){
            targetLeft = 0;
            targetRight = bg.width;
            targetY = tabHeight - indicatorHeight;
        } else {
            targetLeft = selectedTab.x - x;
            targetRight = targetLeft + selectedTab.width;
            targetY = (selectedTab.y - y) + selectedTab.height - indicatorHeight;
        }

        _indicatorLeft = CoolUtil.fpsLerp(_indicatorLeft, targetLeft, indicatorLerpSpeed);
        _indicatorRight = CoolUtil.fpsLerp(_indicatorRight, targetRight, indicatorLerpSpeed);
        _indicatorOffsetY = CoolUtil.fpsLerp(_indicatorOffsetY, targetY, indicatorLerpSpeed);

        if(_indicatorPunch > 0.01)
            _indicatorPunch -= _indicatorPunch * tabSwitchPunchDecay * elapsed;
        else
            _indicatorPunch = 0;

        var newWidth:Float = _indicatorRight - _indicatorLeft;
        if(newWidth < 1) newWidth = 1;

        var punchedHeight:Float = indicatorHeight + _indicatorPunch;

        tabIndicator.setGraphicSize(Std.int(newWidth), Std.int(punchedHeight));
        tabIndicator.updateHitbox();
        tabIndicator.x = x + _indicatorLeft;
        tabIndicator.y = y + _indicatorOffsetY - _indicatorPunch;
    }

    function snapIndicatorToSelected(){
        if(selectedTab == null){
            _indicatorLeft = 0;
            _indicatorRight = bg.width;
            _indicatorOffsetY = tabHeight - indicatorHeight;
            
            tabIndicator.setGraphicSize(Std.int(Math.max(1, bg.width)), indicatorHeight);
        } else {
            _indicatorLeft = selectedTab.x - x;
            _indicatorRight = _indicatorLeft + selectedTab.width;
            _indicatorOffsetY = (selectedTab.y - y) + selectedTab.height - indicatorHeight;
            
            tabIndicator.setGraphicSize(Std.int(Math.max(1, selectedTab.width)), indicatorHeight);
        }

        tabIndicator.updateHitbox();
        tabIndicator.x = x + _indicatorLeft;
        tabIndicator.y = y + _indicatorOffsetY;
    }

	override function set_cameras(v:Array<FlxCamera>)
	{
		for (tab in tabs) tab.cameras = v;
		if(tabIndicator != null) tabIndicator.cameras = v;
		return super.set_cameras(v);
	}

	override function set_camera(v:FlxCamera)
	{
		for (tab in tabs) tab.camera = v;
		if(tabIndicator != null) tabIndicator.camera = v;
		return super.set_camera(v);
	}
			
	override function draw()
	{
		super.draw();

		if(tabIndicator != null && tabIndicator.visible)
			tabIndicator.draw();

		if(selectedTab != null && !isMinimized)
			selectedTab.drawMenu(this);
	}

	override function destroy()
	{
		tabs = null;
		selectedTab = null;
		if(tabIndicator != null)
		{
			tabIndicator.destroy();
			tabIndicator = null;
		}
		super.destroy();
	}

	public function addTab(name:String)
	{
		var createdTab:UITab = new UITab(name);
		tabs.push(createdTab);
		add(createdTab);
		updateTabs();

		if(selectedTab == null)
			selectedTab = createdTab;
	}

	public var tabHeight:Int = 20;
	public function updateTabs()
	{
		var wid:Int = Std.int(bg.width / tabs.length);
		for (num => tab in tabs)
		{
			tab.x = x + wid * num;
			tab.resize(wid, tabHeight);
			tab.cameras = cameras;
		}
	}

	var _originalHeight:Int = 0;
	public function resize(width:Dynamic, height:Dynamic)
	{
		_originalHeight = height;
		bg.setGraphicSize(width, height);
		bg.updateHitbox();
		border.setGraphicSize(width + borderThickness * 2, height + borderThickness * 2);
		border.updateHitbox();
		updateTabs();
	}

	private function set_selectedTab(v:UITab)
	{
		if(v != null && v != selectedTab)
			_indicatorPunch = tabSwitchPunchAmount;

		if(v != null)
		{
			@:bypassAccessor selectedName = v.name;
			@:bypassAccessor selectedIndex = tabs.indexOf(v);
		}
		else
		{
			@:bypassAccessor selectedName = null;
			@:bypassAccessor selectedIndex = -1;
		}
		return (selectedTab = v);
	}

	private function set_selectedName(v:String)
	{
		if(v == null || v.trim().length < 1) selectedTab = null;

		for (tab in tabs)
		{
			if(tab.name == v)
			{
				selectedTab = tab;
				return v;
			}
		}
		return null;
	}

	private function set_selectedIndex(v:Int)
	{
		v = Std.int(Math.max(Math.min(v, tabs.length-1), -1));
		if(v > -1) selectedTab = tabs[v];
		else selectedTab = null;
		return v;
	}

	public function getTab(name:String)
	{
		for (tab in tabs)
			if(tab.name == name)
				return tab;

		return null;
	}

	function set_canMinimize(v:Bool)
	{
		isMinimized = false;
		return (canMinimize = v);
	}

	function set_isMinimized(v:Bool){
		if(!v){
			bg.scale.y = _originalHeight;
			bg.updateHitbox();
			if(bg.visible && bg.alpha > 0){
				border.scale.y = _originalHeight + borderThickness * 2;
				border.updateHitbox();
			}
		} else {
			bg.scale.y = tabHeight + 20;
			bg.updateHitbox();
			border.scale.y = tabHeight + 20 + borderThickness * 2;
			border.updateHitbox();
			selectedTab = null;
		}
		return (isMinimized = v);
	}
}
