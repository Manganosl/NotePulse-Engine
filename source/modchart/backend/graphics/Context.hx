package modchart.backend.graphics;

import modchart.backend.graphics.renderers.*;
import modchart.backend.math.View3D;
import modchart.engine.ModPlayField;

class Context {
	public var parent:ModPlayField;
	public var view:View3D;

	public var arrowRenderer:ArrowRenderer;
	public var holdRenderer:BaseRenderer<FlxSprite>;
	public var pathRenderer:PathRenderer;

	public function new(parent:ModPlayField) {
		this.parent = parent;

		arrowRenderer = new ArrowRenderer(parent);
		holdRenderer = new NVHoldRenderer(parent);
		if(!Adapter.instance.getNVHoldsPref())
			holdRenderer = new HoldRenderer(parent);
		pathRenderer = new PathRenderer(parent);

		view = new View3D();
	}
}
