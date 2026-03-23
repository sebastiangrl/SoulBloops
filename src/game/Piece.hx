package game;

import hxd.Event;
import hxd.Event.EventKind;
import h2d.Graphics;
import h2d.Object;
import h2d.Tile;
import h2d.TileGroup;
import h2d.col.Point;

/**
	Forma arrastrable: un `TileGroup` (misma textura que el tablero) + `Interactive` con área táctil ampliada.
**/
class Piece extends Object {

	static inline var TOUCH_PADDING = 36;
	/** Escala del dibujo en el carril (no inline: asegura que el JS refleje el valor). */
	public static var TRAY_SCALE:Float = 0.52;

	public var shape(default, null):Array<{x:Int, y:Int}>;
	public var grid(default, null):Grid;
	public var fillId:Int = 7;

	/** Índice de ranura (0…2) para re-layout; -1 si no aplica. */
	public var traySlot:Int = -1;

	/**
		Tras colocar con éxito (modelo ya escrito + `rebuildVisual`); la pieza ya se ha quitado de la escena.
		`lineCount` = filas+columnas detectadas; si > 0, Main aplicará clear tras VFX.
	**/
	public var onPlacementResolved : Null<(lineCount:Int, rowDone:Array<Bool>, colDone:Array<Bool>)->Void>;

	/** Verdadero si, con el ancla actual (esquina sup. izq. del bbox), la pieza encajaría en el grid. */
	public var fitsOnGrid(default, null):Bool = false;

	var cellTile:Tile;
	/** Hijo con escala: solo encoge el dibujo, no el Interactive (mejor toque + escala fiable). */
	var visuals:Object;
	var under:Graphics;
	var blocks:TileGroup;
	var hit:h2d.Interactive;

	var grabDx:Float = 0.;
	var grabDy:Float = 0.;
	var homeX:Float = 0.;
	var homeY:Float = 0.;
	var cr:Float;
	var cg:Float;
	var cb:Float;
	var inputEnabled:Bool = true;
	/** Último ancla válida mientras encaja (misma que la sombra en el grid). */
	var dragSnapAnchor:Null<{x:Int, y:Int}> = null;

	/** Mismo color en toda la pieza; un número de personaje distinto por celda (alineado con `shape`). */
	var bloopColorIdx:Int = 0;
	var bloopNums:Null<Array<Int>> = null;

	public function new(sharedCellTile:Tile, targetGrid:Grid, offsets:Array<{x:Int, y:Int}>, r:Float, g:Float, b:Float, pieceFillId:Int, ?parent:Object, ?bloopColor:Null<Int>,
			?cellBloopNums:Array<Int>) {
		super(parent);
		cellTile = sharedCellTile;
		grid = targetGrid;
		shape = normalizeShape(offsets);
		cr = r;
		cg = g;
		cb = b;
		fillId = pieceFillId;

		if (bloopColor != null && bloopColor > 0 && cellBloopNums != null && cellBloopNums.length == shape.length) {
			bloopColorIdx = bloopColor;
			bloopNums = [for (n in cellBloopNums) n];
		} else {
			bloopColorIdx = 0;
			bloopNums = null;
		}

		visuals = new Object(this);
		under = new Graphics(visuals);
		drawUnderlay();
		blocks = new TileGroup(cellTile, visuals);
		drawBlocks();

		var bw = bboxCellsW();
		var bh = bboxCellsH();
		var w = bw * Grid.CELL_SIZE + TOUCH_PADDING * 2;
		var h = bh * Grid.CELL_SIZE + TOUCH_PADDING * 2;
		hit = new h2d.Interactive(w, h, this);
		hit.x = -TOUCH_PADDING;
		hit.y = -TOUCH_PADDING;
		hit.cursor = hxd.Cursor.Button;

		hit.onPush = onPush;

		applyTrayVisualScale();
	}

	inline function usesPerCellBloops():Bool {
		return bloopColorIdx > 0 && bloopNums != null && bloopNums.length == shape.length;
	}

	function applyTrayVisualScale():Void {
		visuals.scaleX = visuals.scaleY = TRAY_SCALE;
	}

	function applyDragVisualScale():Void {
		visuals.scaleX = visuals.scaleY = 1.;
	}

	public function setInputEnabled(on:Bool):Void {
		inputEnabled = on;
		hit.cursor = on ? hxd.Cursor.Button : hxd.Cursor.Default;
		alpha = on ? 1. : 0.4;
	}

	function normalizeShape(src:Array<{x:Int, y:Int}>):Array<{x:Int, y:Int}> {
		if (src.length == 0)
			return [];
		var minX = src[0].x, minY = src[0].y;
		for (o in src) {
			if (o.x < minX) minX = o.x;
			if (o.y < minY) minY = o.y;
		}
		return [for (o in src) {x: o.x - minX, y: o.y - minY}];
	}

	public function bboxCellsW():Int {
		var m = 0;
		for (o in shape)
			if (o.x + 1 > m) m = o.x + 1;
		return m;
	}

	public function bboxCellsH():Int {
		var m = 0;
		for (o in shape)
			if (o.y + 1 > m) m = o.y + 1;
		return m;
	}

	public function pixelBbox():{w:Float, h:Float} {
		return {w: bboxCellsW() * Grid.CELL_SIZE, h: bboxCellsH() * Grid.CELL_SIZE};
	}

	public function setRestPosition(px:Float, py:Float):Void {
		x = px;
		y = py;
		homeX = px;
		homeY = py;
		applyTrayVisualScale();
	}

	/** Fondo del bbox de la pieza (carril); más suave si ya hay sprite bloop. */
	function drawUnderlay():Void {
		var cs = Grid.CELL_SIZE;
		under.clear();
		var bloopUi = usesPerCellBloops() || BloopSprites.tileForCellId(fillId) != null;
		if (bloopUi) {
			under.beginFill(0x22232e, 0.65);
			for (o in shape)
				under.drawRect(o.x * cs, o.y * cs, cs, cs);
			under.endFill();
			under.lineStyle(1.2, 0x4a5060, 0.55);
		} else {
			under.beginFill(0x3a3e4c, 1.);
			for (o in shape)
				under.drawRect(o.x * cs, o.y * cs, cs, cs);
			under.endFill();
			under.lineStyle(1.5, 0x5a6278, 0.88);
		}
		for (o in shape) {
			var px = o.x * cs;
			var py = o.y * cs;
			under.moveTo(px, py);
			under.lineTo(px + cs, py);
			under.moveTo(px, py);
			under.lineTo(px, py + cs);
			under.moveTo(px + cs, py);
			under.lineTo(px + cs, py + cs);
			under.moveTo(px, py + cs);
			under.lineTo(px + cs, py + cs);
		}
	}

	function drawBlocks():Void {
		blocks.clear();
		blocks.invalidate();
		var cs = Grid.CELL_SIZE;
		var inset = Grid.CELL_INSET;
		var inner = cs - 2 * inset;
		var sc = inner / cs;
		if (usesPerCellBloops()) {
			blocks.smooth = true;
			blocks.setDefaultColor(0xffffff);
			for (i in 0...shape.length) {
				var o = shape[i];
				var t = BloopSprites.getTile(bloopNums[i], bloopColorIdx);
				if (t != null) {
					var L = BloopSprites.layoutInCell(cs, inset, t);
					blocks.addTransform(o.x * cs + L.ox, o.y * cs + L.oy, L.sc, L.sc, 0., t);
				} else {
					blocks.setDefaultColor(rgbFromFloats(cr, cg, cb));
					blocks.addTransform(o.x * cs + inset, o.y * cs + inset, sc, sc, 0., cellTile);
				}
			}
		} else {
			var t = BloopSprites.tileForCellId(fillId);
			if (t != null) {
				blocks.smooth = true;
				blocks.setDefaultColor(0xffffff);
				var L = BloopSprites.layoutInCell(cs, inset, t);
				for (o in shape)
					blocks.addTransform(o.x * cs + L.ox, o.y * cs + L.oy, L.sc, L.sc, 0., t);
			} else {
				blocks.setDefaultColor(rgbFromFloats(cr, cg, cb));
				for (o in shape)
					blocks.addTransform(o.x * cs + inset, o.y * cs + inset, sc, sc, 0., cellTile);
			}
		}
	}

	static inline function rgbFromFloats(r:Float, g:Float, b:Float):Int {
		var ri = Std.int(Math.max(0, Math.min(1, r)) * 255) & 0xFF;
		var gi = Std.int(Math.max(0, Math.min(1, g)) * 255) & 0xFF;
		var bi = Std.int(Math.max(0, Math.min(1, b)) * 255) & 0xFF;
		return (ri << 16) | (gi << 8) | bi;
	}

	function updateFitHint():Void {
		var a = grid.anchorFromScene(x, y);
		fitsOnGrid = grid.canPlaceShape(shape, a.x, a.y);
		if (fitsOnGrid) {
			dragSnapAnchor = {x: a.x, y: a.y};
			var pulse = 0.88 + 0.12 * Math.sin(haxe.Timer.stamp() * 6.2);
			grid.setGhostPulseAlpha(pulse);
			grid.updatePlacementGhost(shape, fillId, cr, cg, cb, a.x, a.y, bloopColorIdx, bloopNums);
			grid.updateLineClearPreview(shape, a.x, a.y);
		} else {
			dragSnapAnchor = null;
			grid.hidePlacementGhost();
			grid.clearLineClearPreview();
		}
	}

	function onPush(e:Event):Void {
		if (!inputEnabled)
			return;
		if (parent != null)
			parent.addChild(this);
		dragSnapAnchor = null;
		homeX = x;
		homeY = y;
		if (visuals.scaleX < 0.999) {
			var bw = bboxCellsW() * Grid.CELL_SIZE;
			var bh = bboxCellsH() * Grid.CELL_SIZE;
			var s0 = visuals.scaleX;
			var cx = x + bw * s0 * 0.5;
			var cy = y + bh * s0 * 0.5;
			applyDragVisualScale();
			x = cx - bw * 0.5;
			y = cy - bh * 0.5;
		}
		var scene = getScene();
		if (scene == null)
			return;
		var finger = new Point(e.relX, e.relY);
		hit.localToGlobal(finger);
		grabDx = finger.x - x;
		grabDy = finger.y - y;

		scene.startCapture(function(ev:Event) {
			switch (ev.kind) {
				case EMove:
					x = ev.relX - grabDx;
					y = ev.relY - grabDy;
					updateFitHint();
				case ERelease, EReleaseOutside:
					scene.stopCapture();
					tryCommit();
				default:
			}
		}, null, e.touchId);
		updateFitHint();
	}

	function tryCommit():Void {
		grid.clearLineClearPreview();
		grid.hidePlacementGhost();
		var a = grid.anchorFromScene(x, y);
		if (dragSnapAnchor != null && grid.canPlaceShape(shape, dragSnapAnchor.x, dragSnapAnchor.y))
			a = dragSnapAnchor;
		if (!grid.canPlaceShape(shape, a.x, a.y)) {
			dragSnapAnchor = null;
			x = homeX;
			y = homeY;
			applyTrayVisualScale();
			alpha = 1.;
			updateFitHint();
			AudioHub.playDeny();
			return;
		}
		x = grid.x + a.x * Grid.CELL_SIZE;
		y = grid.y + a.y * Grid.CELL_SIZE;
		var ok = usesPerCellBloops() ? grid.writeShapeBloops(shape, a.x, a.y, bloopColorIdx, bloopNums) : grid.writeShapeOnly(shape, a.x, a.y, fillId);
		if (!ok) {
			dragSnapAnchor = null;
			x = homeX;
			y = homeY;
			applyTrayVisualScale();
			alpha = 1.;
			updateFitHint();
			AudioHub.playDeny();
			return;
		}
		var mask = grid.computeLineClearMask();
		grid.rebuildVisual();
		remove();
		if (onPlacementResolved != null)
			onPlacementResolved(mask.lineCount, mask.rowDone, mask.colDone);
	}

	override function onRemove():Void {
		grid.clearLineClearPreview();
		grid.hidePlacementGhost();
		if (getScene() != null)
			getScene().stopCapture();
		super.onRemove();
	}
}
