package en.vfx;

import haxe.ds.Vector;
import hxease.Linear;
import hxease.Cubic;
import hxease.IEasing;
import h2d.col.Point;
import h2d.Graphics;
import h2d.Object;

using GM;

typedef TrailPoint = {
	point:h2d.col.Point,
	lifetime:Float
}

class Trail extends Entity {
	var graphics:Graphics;

	var addingDelay = 3;

	var points:Array<TrailPoint> = [];

	var trailLifetimeFrames = 30;

	var sizeEase:IEasing;
	var trailColor:Col;

	public static function create(parent:Object, color: Col, lifetimeFrames:Int, addingDelay:Int) {
		var trail = new Trail(parent);

		trail.noSprite();
		trail.trailColor = color.withAlphaIfMissing();
		trail.graphics = new Graphics(parent);
		trail.trailLifetimeFrames = lifetimeFrames;
		trail.addingDelay = addingDelay;
		trail.sizeEase = hxease.Sine.easeIn;

		trail.addPointPos(parent.x, parent.y);
        return trail;
	}

	function new(parent:Object) {
		super(0, 0);

		noSprite();
		graphics = new Graphics(parent);

		sizeEase = Linear.easeNone;
	}

	function addPoint() {
		addPointPos(graphics.parent.x, graphics.parent.y);
	}

	function addPointPos(x, y) {
		points.insert(0, {
			point: new Point(x, y),
			lifetime: trailLifetimeFrames
		});
	}

	var addCounter = 0.0;

	override function preUpdate() {
		super.preUpdate();
		addCounter += tmod;
		if (addCounter > addingDelay) {
			addCounter = 0;

			addPoint();
		}

		var queuedRemoval:Array<TrailPoint> = [];
		for (point in points) {
			point.lifetime -= tmod;

			if (point.lifetime < 0)
				queuedRemoval.push(point);
		}
		for (point in queuedRemoval)
			points.remove(point);
	}

	override function frameUpdate() {
		graphics.clear();

		graphics.beginFill();
		var lastX = 0.0;
		var lastY = 0.0;

		var postPoints:Array<Point> = new Array();
		var i = 0;

		var addV = (x, y) -> {
			graphics.addVertex(x, y, trailColor.rf, trailColor.gf, trailColor.bf, 255);
		}

		for (point in points) {
			var curX = point.point.x - graphics.parent.x;
			var curY = point.point.y - graphics.parent.y;

			var perp = new Point(curX - lastX, curY - lastY).normalized().perp();

			var lineSize = sizeEase.calculate(point.lifetime / trailLifetimeFrames) * 8 / 2;

			addV(curX + perp.x * lineSize, curY + perp.y * lineSize);
			postPoints.push(new Point(curX - perp.x * lineSize, curY - perp.y * lineSize));

			lastX = curX;
			lastY = curY;
			i++;
		}
		
		postPoints.reverse();
		for (point in postPoints) {
			addV(point.x, point.y);
		}

		graphics.endFill();
	}
}
