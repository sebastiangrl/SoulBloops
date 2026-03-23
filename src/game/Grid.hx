package game;

import h2d.BlendMode;
import h2d.Graphics;
import h2d.Layers;
import h2d.Object;
import h2d.Tile;
import h2d.TileGroup;

/**
	Tablero 8×8: `Layers` separa rejilla neón (capa 0) de celdas/bloques (capa 1) para que el batch de Heaps no pinte líneas encima de los sprites.
**/
class Grid extends Layers {

	public static inline var SIZE = 8;
	public static inline var CELL_SIZE = 72;
	/** Hueco entre celdas: deja ver líneas del fondo y ayuda a contar (también piezas del carril). */
	public static inline var CELL_INSET = 2.5;
	static inline var EMPTY_CELL_COLOR = 0x151822;
	static inline var BOARD_FILL_COLOR = 0x14131d;
	static inline var NEON_LINE_THICK = 2.35;
	static inline var NEON_LINE_ALPHA = 0.78;
	public static inline var GHOST_ALPHA = 0.5;
	/** Tope de seguridad por ronda (el presupuesto real lo elige `randomSeedIterationBudget`). */
	static inline var SEED_ATTEMPT_HARD_CAP = 520;
	static inline var PREVIEW_BORDER_OUTER = 0x7b3dff;
	static inline var PREVIEW_BORDER_MID = 0xc94cff;
	static inline var PREVIEW_BORDER_INNER = 0xff9adf;
	static inline var PREVIEW_PARTICLE_SPAWN_PER_SEC = 58.;
	static inline var PREVIEW_PARTICLE_MAX = 52;

	/** 0 = vacío; >0 = ocupado (id de color / tipo). */
	var cells:Array<Array<Int>>;

	var cellTile:Tile;
	/** Relleno del tablero (sin líneas): va debajo de todo. */
	var boardFill:Graphics;
	/** Líneas de rejilla: debajo de `tiles` para que los sprites tapen la cuadrícula. */
	var gridLines:Graphics;
	var tiles:TileGroup;
	var ghostLayer:Object;
	var ghostBlocks:TileGroup;
	var ghostCachedShape:Array<{x:Int, y:Int}>;
	var ghostCachedSig:String = "";
	var linePreview:Graphics;
	var previewRows:Array<Int> = [];
	var previewCols:Array<Int> = [];
	var previewFxTime:Float = 0.;
	var previewParticleSpawnCarry:Float = 0.;
	var previewParticles:Array<{x:Float, y:Float, vx:Float, vy:Float, life:Float, maxLife:Float, size:Float}> = [];

	/** Bloquea arrastre de piezas (p. ej. durante VFX de clear). */
	public var interactionLocked:Bool = false;

	/** Alpha actual del ghost (pulso al arrastrar). */
	var ghostAlphaMul:Float = 1.;

	/** Fase para pulsar el degradado blanco ↔ neón. */
	var neonWave:Float = 0.;
	/** Tono base (°) que deriva lentamente para cambiar la paleta. */
	var neonHue:Float = 0.;

	public function new(sharedCellTile:Tile, ?parent:Object) {
		super(parent);
		cellTile = sharedCellTile;
		cells = [];
		for (y in 0...SIZE) {
			var row = [];
			for (x in 0...SIZE)
				row.push(0);
			cells.push(row);
		}

		boardFill = new Graphics(null);
		gridLines = new Graphics(null);
		gridLines.blendMode = Add;
		tiles = new TileGroup(cellTile, null);
		ghostLayer = new Object(null);
		ghostLayer.visible = false;
		ghostBlocks = new TileGroup(cellTile, ghostLayer);
		linePreview = new Graphics(null);

		add(boardFill, 0);
		add(gridLines, 0);
		add(tiles, 1);
		add(ghostLayer, 2);
		add(linePreview, 2);

		rebuildBoardBackground();
		rebuildVisual();
		redrawNeonGridLines();
	}

	function rebuildBoardBackground():Void {
		var gw = SIZE * CELL_SIZE;
		var gh = gw;
		boardFill.clear();
		boardFill.beginFill(BOARD_FILL_COLOR, 1.);
		boardFill.drawRect(0, 0, gw, gh);
		boardFill.endFill();
	}

	/** Llamar cada frame: anima la rejilla neón (degradado blanco + color). */
	public function updateNeon(dt:Float):Void {
		neonWave += dt * 1.15;
		neonHue += dt * 22.;
		if (neonHue >= 360.)
			neonHue -= 360.;
		redrawNeonGridLines();
		updateLinePreviewFx(dt);
	}

	function redrawNeonGridLines():Void {
		var gw = SIZE * CELL_SIZE;
		var gh = gw;
		var cs = CELL_SIZE;
		gridLines.clear();
		for (i in 0...SIZE + 1) {
			var x = i * cs;
			for (seg in 0...SIZE) {
				var y0 = seg * cs;
				var y1 = (seg + 1) * cs;
				var c = neonSegmentColor(i, seg, true);
				gridLines.lineStyle(NEON_LINE_THICK, c, NEON_LINE_ALPHA);
				gridLines.moveTo(x, y0);
				gridLines.lineTo(x, y1);
			}
		}
		for (j in 0...SIZE + 1) {
			var y = j * cs;
			for (seg in 0...SIZE) {
				var x0 = seg * cs;
				var x1 = (seg + 1) * cs;
				var c = neonSegmentColor(seg, j, false);
				gridLines.lineStyle(NEON_LINE_THICK, c, NEON_LINE_ALPHA);
				gridLines.moveTo(x0, y);
				gridLines.lineTo(x1, y);
			}
		}
	}

	/**
		Degradado sutil: mezcla blanco con un neón derivado de `neonHue`, modulado por posición y `neonWave`.
	**/
	function neonSegmentColor(a:Int, b:Int, vertical:Bool):Int {
		var t = vertical ? (a * 0.31 + b * 0.52) : (a * 0.47 + b * 0.29);
		var pulse = 0.5 + 0.5 * Math.sin(neonWave * 0.95 + t * 1.85);
		var hue = neonHue + t * 38. + (vertical ? 0. : 14.);
		// Valores moderados: `blendMode = Add` sobre fondo oscuro ya da aspecto neón.
		var accent = hsvToRgb(hue, 0.82, 0.48);
		var mix = 0.18 + 0.62 * pulse;
		return lerpRgb(0xffffff, accent, mix);
	}

	static function lerpRgb(a:Int, b:Int, t:Float):Int {
		if (t <= 0)
			return a;
		if (t >= 1)
			return b;
		var ar = (a >> 16) & 0xFF, ag = (a >> 8) & 0xFF, ab = a & 0xFF;
		var br = (b >> 16) & 0xFF, bg = (b >> 8) & 0xFF, bb = b & 0xFF;
		var r = Std.int(ar + (br - ar) * t) & 0xFF;
		var g = Std.int(ag + (bg - ag) * t) & 0xFF;
		var bl = Std.int(ab + (bb - ab) * t) & 0xFF;
		return (r << 16) | (g << 8) | bl;
	}

	static function hsvToRgb(h:Float, s:Float, v:Float):Int {
		h = (h % 360. + 360.) % 360.;
		var c = v * s;
		var hp = h / 60.;
		var x = c * (1. - Math.abs(hp % 2. - 1.));
		var m = v - c;
		var rp:Float, gp:Float, bp:Float;
		if (hp < 1) {
			rp = c; gp = x; bp = 0.;
		} else if (hp < 2) {
			rp = x; gp = c; bp = 0.;
		} else if (hp < 3) {
			rp = 0.; gp = c; bp = x;
		} else if (hp < 4) {
			rp = 0.; gp = x; bp = c;
		} else if (hp < 5) {
			rp = x; gp = 0.; bp = c;
		} else {
			rp = c; gp = 0.; bp = x;
		}
		var ri = Std.int((rp + m) * 255.) & 0xFF;
		var gi = Std.int((gp + m) * 255.) & 0xFF;
		var bi = Std.int((bp + m) * 255.) & 0xFF;
		return (ri << 16) | (gi << 8) | bi;
	}

	public inline function getCell(gx:Int, gy:Int):Int {
		return cells[gy][gx];
	}

	public inline function setCell(gx:Int, gy:Int, v:Int):Void {
		cells[gy][gx] = v;
	}

	/** Toda la fila `row` (0…7) tiene celdas no vacías. */
	public function isRowComplete(row:Int):Bool {
		if (row < 0 || row >= SIZE)
			return false;
		var r = cells[row];
		for (x in 0...SIZE)
			if (r[x] == 0)
				return false;
		return true;
	}

	/** Toda la columna `col` (0…7) tiene celdas no vacías. */
	public function isColComplete(col:Int):Bool {
		if (col < 0 || col >= SIZE)
			return false;
		for (y in 0...SIZE)
			if (cells[y][col] == 0)
				return false;
		return true;
	}

	/**
		Comprueba si la forma (offsets desde el ancla) cabe en (anchorX, anchorY).
	**/
	public function canPlaceShape(offsets:Array<{x:Int, y:Int}>, anchorX:Int, anchorY:Int):Bool {
		for (o in offsets) {
			var gx = anchorX + o.x;
			var gy = anchorY + o.y;
			if (gx < 0 || gy < 0 || gx >= SIZE || gy >= SIZE)
				return false;
			if (cells[gy][gx] != 0)
				return false;
		}
		return true;
	}

	/**
		Mientras se arrastra: si la forma encaja y al colocarla se completarían filas/columnas,
		dibuja resaltado sobre esas líneas (vacío si no encaja o no completaría ninguna).
	**/
	public function updateLineClearPreview(offsets:Array<{x:Int, y:Int}>, anchorX:Int, anchorY:Int):Void {
		clearLineClearPreview();
		if (!canPlaceShape(offsets, anchorX, anchorY))
			return;
		var tmp = [for (y in 0...SIZE) [for (x in 0...SIZE) cells[y][x]]];
		for (o in offsets) {
			var gy = anchorY + o.y;
			var gx = anchorX + o.x;
			tmp[gy][gx] = 1;
		}
		var rows:Array<Int> = [];
		var cols:Array<Int> = [];
		for (y in 0...SIZE) {
			var full = true;
			for (x in 0...SIZE)
				if (tmp[y][x] == 0) {
					full = false;
					break;
				}
			if (full)
				rows.push(y);
		}
		for (x in 0...SIZE) {
			var full = true;
			for (y in 0...SIZE)
				if (tmp[y][x] == 0) {
					full = false;
					break;
				}
			if (full)
				cols.push(x);
		}
		if (rows.length == 0 && cols.length == 0)
			return;
		previewRows = rows;
		previewCols = cols;
		redrawLineClearPreview();
	}

	public function clearLineClearPreview():Void {
		linePreview.clear();
		previewRows = [];
		previewCols = [];
		previewFxTime = 0.;
		previewParticleSpawnCarry = 0.;
		previewParticles = [];
	}

	inline function hasLinePreviewActive():Bool {
		return previewRows.length > 0 || previewCols.length > 0;
	}

	function updateLinePreviewFx(dt:Float):Void {
		if (!hasLinePreviewActive()) {
			if (previewParticles.length > 0) {
				previewParticles = [];
				linePreview.clear();
			}
			return;
		}
		previewFxTime += dt;
		previewParticleSpawnCarry += dt * PREVIEW_PARTICLE_SPAWN_PER_SEC;
		while (previewParticleSpawnCarry >= 1.) {
			previewParticleSpawnCarry -= 1.;
			if (previewParticles.length < PREVIEW_PARTICLE_MAX)
				spawnLinePreviewParticle();
		}
		for (p in previewParticles) {
			p.life -= dt;
			p.x += p.vx * dt;
			p.y += p.vy * dt;
		}
		var keep:Array<{x:Float, y:Float, vx:Float, vy:Float, life:Float, maxLife:Float, size:Float}> = [];
		for (p in previewParticles)
			if (p.life > 0.)
				keep.push(p);
		previewParticles = keep;
		redrawLineClearPreview();
	}

	function redrawLineClearPreview():Void {
		linePreview.clear();
		if (!hasLinePreviewActive())
			return;
		var cs = CELL_SIZE;
		var gw = SIZE * cs;
		var pulse = 0.5 + 0.5 * Math.sin(previewFxTime * 6.2);
		var outerA = 0.22 + 0.20 * pulse;
		var midA = 0.34 + 0.24 * pulse;
		var innerA = 0.60 + 0.30 * pulse;
		var whiteA = 0.15 + 0.20 * pulse;

		for (y in previewRows)
			drawPreviewRectBorder(0, y * cs, gw, cs, outerA, midA, innerA, whiteA);
		for (x in previewCols)
			drawPreviewRectBorder(x * cs, 0, cs, gw, outerA, midA, innerA, whiteA);

		for (p in previewParticles) {
			var t = p.life / p.maxLife;
			var a = Math.max(0., Math.min(1., t)) * 0.95;
			linePreview.beginFill(0xffffff, a);
			linePreview.drawCircle(p.x, p.y, p.size);
			linePreview.endFill();
		}
	}

	function drawPreviewRectBorder(x:Float, y:Float, w:Float, h:Float, outerA:Float, midA:Float, innerA:Float, whiteA:Float):Void {
		drawBorderPass(x, y, w, h, PREVIEW_BORDER_OUTER, 8.0, outerA);
		drawBorderPass(x, y, w, h, PREVIEW_BORDER_MID, 4.8, midA);
		drawBorderPass(x, y, w, h, PREVIEW_BORDER_INNER, 2.4, innerA);
		drawBorderPass(x, y, w, h, 0xffffff, 1.3, whiteA);
	}

	function drawBorderPass(x:Float, y:Float, w:Float, h:Float, c:Int, thick:Float, a:Float):Void {
		linePreview.lineStyle(thick, c, a);
		linePreview.moveTo(x, y);
		linePreview.lineTo(x + w, y);
		linePreview.lineTo(x + w, y + h);
		linePreview.lineTo(x, y + h);
		linePreview.lineTo(x, y);
	}

	function spawnLinePreviewParticle():Void {
		var cs = CELL_SIZE;
		var gw = SIZE * cs;
		var pickRow = previewRows.length > 0 && (previewCols.length == 0 || Std.random(2) == 0);
		var x = 0.;
		var y = 0.;
		var vx = 0.;
		var vy = 0.;
		if (pickRow) {
			var ry = previewRows[Std.random(previewRows.length)] * cs;
			var top = Std.random(2) == 0;
			x = Math.random() * gw;
			y = top ? ry : (ry + cs);
			vx = (Math.random() * 2. - 1.) * 16.;
			vy = top ? (-14. - Math.random() * 30.) : (14. + Math.random() * 30.);
		} else {
			var rx = previewCols[Std.random(previewCols.length)] * cs;
			var left = Std.random(2) == 0;
			x = left ? rx : (rx + cs);
			y = Math.random() * gw;
			vx = left ? (-14. - Math.random() * 30.) : (14. + Math.random() * 30.);
			vy = (Math.random() * 2. - 1.) * 16.;
		}
		var life = 0.22 + Math.random() * 0.38;
		previewParticles.push({
			x: x,
			y: y,
			vx: vx,
			vy: vy,
			life: life,
			maxLife: life,
			size: 0.8 + Math.random() * 1.4,
		});
	}

	/**
		Sombra de la pieza en coordenadas de tablero (ancla celda). Misma forma que al colocar.
	**/
	public function updatePlacementGhost(offsets:Array<{x:Int, y:Int}>, fillId:Int, r:Float, g:Float, b:Float, anchorX:Int, anchorY:Int, bloopColorIdx:Int = 0,
			?bloopPerCell:Array<Int>):Void {
		if (!canPlaceShape(offsets, anchorX, anchorY)) {
			hidePlacementGhost();
			return;
		}
		var sig = ghostVisualSig(offsets, fillId, bloopColorIdx, bloopPerCell);
		if (ghostCachedShape != offsets || ghostCachedSig != sig) {
			ghostCachedShape = offsets;
			ghostCachedSig = sig;
			ghostBlocks.clear();
			ghostBlocks.invalidate();
			var cs = CELL_SIZE;
			var inset = CELL_INSET;
			var inner = cs - 2 * inset;
			var sc = inner / cs;
			var multi = bloopColorIdx > 0 && bloopPerCell != null && bloopPerCell.length == offsets.length;
			if (multi) {
				ghostBlocks.smooth = true;
				ghostBlocks.setDefaultColor(0xffffff);
				for (i in 0...offsets.length) {
					var o = offsets[i];
					var t = BloopSprites.getTile(bloopPerCell[i], bloopColorIdx);
					if (t != null) {
						var L = BloopSprites.layoutInCell(cs, inset, t);
						ghostBlocks.addTransform(o.x * cs + L.ox, o.y * cs + L.oy, L.sc, L.sc, 0., t);
					} else {
						ghostBlocks.setDefaultColor(rgbFromFloats(r, g, b));
						ghostBlocks.addTransform(o.x * cs + inset, o.y * cs + inset, sc, sc, 0., cellTile);
					}
				}
			} else {
				var t = BloopSprites.tileForCellId(fillId);
				if (t != null) {
					ghostBlocks.smooth = true;
					ghostBlocks.setDefaultColor(0xffffff);
					var L = BloopSprites.layoutInCell(cs, inset, t);
					for (o in offsets)
						ghostBlocks.addTransform(o.x * cs + L.ox, o.y * cs + L.oy, L.sc, L.sc, 0., t);
				} else {
					ghostBlocks.setDefaultColor(rgbFromFloats(r, g, b));
					for (o in offsets)
						ghostBlocks.addTransform(o.x * cs + inset, o.y * cs + inset, sc, sc, 0., cellTile);
				}
			}
		}
		ghostLayer.x = anchorX * CELL_SIZE;
		ghostLayer.y = anchorY * CELL_SIZE;
		ghostLayer.alpha = GHOST_ALPHA * ghostAlphaMul;
		ghostLayer.visible = true;
	}

	public function setGhostPulseAlpha(mul:Float):Void {
		ghostAlphaMul = mul;
		if (ghostLayer.visible)
			ghostLayer.alpha = GHOST_ALPHA * ghostAlphaMul;
	}

	public function hidePlacementGhost():Void {
		ghostLayer.visible = false;
		ghostCachedShape = null;
		ghostCachedSig = "";
		ghostAlphaMul = 1.;
	}

	static function ghostVisualSig(offsets:Array<{x:Int, y:Int}>, fillId:Int, bloopColorIdx:Int, bloopPerCell:Null<Array<Int>>):String {
		if (bloopColorIdx > 0 && bloopPerCell != null && bloopPerCell.length == offsets.length) {
			var s = "m" + bloopColorIdx + ":";
			for (k in 0...bloopPerCell.length)
				s += (k > 0 ? "," : "") + bloopPerCell[k];
			return s;
		}
		return "f" + fillId;
	}

	/** RGB 0xRRGGBB para partículas / FX (misma lógica que bloques del tablero). */
	public static function tintRgbFromBlockId(id:Int):Int {
		if (BloopSprites.isPackedBloopId(id))
			return BloopSprites.accentRgbForColor(BloopSprites.unpackColorIdx(id));
		var hue = (id * 47) % 360;
		var r = 0.45 + 0.45 * Math.cos(hue * Math.PI / 180);
		var g = 0.55 + 0.35 * Math.cos((hue + 120) * Math.PI / 180);
		var b = 0.65 + 0.25 * Math.cos((hue + 240) * Math.PI / 180);
		return rgbFromFloats(r, g, b);
	}

	static inline function rgbFromFloats(r:Float, g:Float, b:Float):Int {
		var ri = Std.int(Math.max(0, Math.min(1, r)) * 255) & 0xFF;
		var gi = Std.int(Math.max(0, Math.min(1, g)) * 255) & 0xFF;
		var bi = Std.int(Math.max(0, Math.min(1, b)) * 255) & 0xFF;
		return (ri << 16) | (gi << 8) | bi;
	}

	/** ¿Existe algún ancla (0…SIZE) donde la forma quepa en celdas vacías? */
	public function canPlaceShapeAnywhere(offsets:Array<{x:Int, y:Int}>):Bool {
		if (offsets.length == 0)
			return false;
		for (ay in 0...SIZE)
			for (ax in 0...SIZE)
				if (canPlaceShape(offsets, ax, ay))
					return true;
		return false;
	}

	public static inline var POINTS_PER_LINE = 100;

	/**
		Detecta filas y columnas completas sin mutar el tablero.
		`lineCount` = filas completas + columnas completas (como antes: se borra la unión al aplicar).
	**/
	public function computeLineClearMask():{rowDone:Array<Bool>, colDone:Array<Bool>, lineCount:Int} {
		var rowDone = [for (_ in 0...SIZE) false];
		var colDone = [for (_ in 0...SIZE) false];
		var nr = 0;
		var nc = 0;
		for (y in 0...SIZE) {
			if (isRowComplete(y)) {
				rowDone[y] = true;
				nr++;
			}
		}
		for (x in 0...SIZE) {
			if (isColComplete(x)) {
				colDone[x] = true;
				nc++;
			}
		}
		return {rowDone: rowDone, colDone: colDone, lineCount: nr + nc};
	}

	public function applyLineClearMask(rowDone:Array<Bool>, colDone:Array<Bool>):Void {
		for (y in 0...SIZE) {
			for (x in 0...SIZE) {
				if (rowDone[y] || colDone[x])
					cells[y][x] = 0;
			}
		}
	}

	/**
		Una pasada: si hay filas/columnas completas, borra su unión.
		@return Número de líneas eliminadas (filas + columnas) en esta pasada; 0 si no hubo nada.
	**/
	public function stripCompleteLinesOnce():Int {
		var m = computeLineClearMask();
		if (m.lineCount == 0)
			return 0;
		applyLineClearMask(m.rowDone, m.colDone);
		return m.lineCount;
	}

	/** Escribe la forma en celdas vacías; no limpia líneas. */
	public function writeShapeOnly(offsets:Array<{x:Int, y:Int}>, anchorX:Int, anchorY:Int, fillId:Int):Bool {
		if (!canPlaceShape(offsets, anchorX, anchorY))
			return false;
		for (o in offsets) {
			var gx = anchorX + o.x;
			var gy = anchorY + o.y;
			cells[gy][gx] = fillId;
		}
		return true;
	}

	/** Una celda = un `packCell(bloopNum, color)`; mismo color en toda la figura, distinto personaje por celda. */
	public function writeShapeBloops(offsets:Array<{x:Int, y:Int}>, anchorX:Int, anchorY:Int, colorIdx:Int, bloopNums:Array<Int>):Bool {
		if (!canPlaceShape(offsets, anchorX, anchorY) || bloopNums.length != offsets.length)
			return false;
		for (i in 0...offsets.length) {
			var o = offsets[i];
			var gx = anchorX + o.x;
			var gy = anchorY + o.y;
			cells[gy][gx] = BloopSprites.packCell(bloopNums[i], colorIdx);
		}
		return true;
	}

	/**
		Block Blast / inicio: quita líneas completas sin otorgar puntos (p. ej. tras generar el tablero).
	**/
	public function sanitizeBoardNoScore():Void {
		while (stripCompleteLinesOnce() > 0) {}
	}

	/**
		Presupuesto de intentos de colocación por partida: en la mayoría de casos pocos → tablero bastante vacío;
		a veces más intentos → más bloques (sigue siendo aleatorio qué encaja).
	**/
	static function randomSeedIterationBudget():Int {
		var u = Math.random();
		if (u < 0.66)
			return 2 + Std.random(10);
		if (u < 0.88)
			return 12 + Std.random(16);
		return 28 + Std.random(38);
	}

	/**
		Tablero inicial: bloques ya colocados (el jugador no los puso), tipo Block Blast.
		Presupuesto de intentos sesgado a “poco” (puede quedar vacío); a veces más densidad. Luego sanea líneas.
	**/
	public function seedBlockBlastRandom():Void {
		for (y in 0...SIZE)
			for (x in 0...SIZE)
				cells[y][x] = 0;

		var budget = randomSeedIterationBudget();
		if (budget > SEED_ATTEMPT_HARD_CAP)
			budget = SEED_ATTEMPT_HARD_CAP;
		var tries = 0;
		while (tries < budget) {
			tries++;
			var sh = ShapeCatalog.randomShape();
			var ax = Std.random(SIZE);
			var ay = Std.random(SIZE);
			if (!canPlaceShape(sh, ax, ay))
				continue;
			var pick = BloopSprites.pickColorAndDistinctVariants(sh.length);
			if (pick != null) {
				for (i in 0...sh.length) {
					var o = sh[i];
					cells[ay + o.y][ax + o.x] = BloopSprites.packCell(pick.variants[i], pick.colorIdx);
				}
			} else {
				var fid = BloopSprites.loadedPairCount() > 0 ? BloopSprites.randomPackedId() : (1 + Std.random(280));
				for (o in sh) {
					var gx = ax + o.x;
					var gy = ay + o.y;
					cells[gy][gx] = fid;
				}
			}
		}
		sanitizeBoardNoScore();
		rebuildVisual();
	}

	public function countFilledCells():Int {
		var n = 0;
		for (y in 0...SIZE)
			for (x in 0...SIZE)
				if (cells[y][x] != 0)
					n++;
		return n;
	}

	public function countEmptyCells():Int {
		return SIZE * SIZE - countFilledCells();
	}

	/** Mayor id de bloque ocupado (para no repetir tintes al colocar piezas nuevas). */
	public function maxOccupiedId():Int {
		var m = 0;
		for (y in 0...SIZE)
			for (x in 0...SIZE) {
				var v = cells[y][x];
				if (v > m) m = v;
			}
		return m;
	}

	/**
		Coloca la forma si cabe en celdas vacías — **no** se exige completar línea (así el tablero puede llenarse y el jugador puede perder).
		Tras colocar, si hay filas/columnas completas se limpian en una pasada y `score` refleja eso; si no hubo líneas, `score` es 0.
	**/
	public function placeShapeAndClear(offsets:Array<{x:Int, y:Int}>, anchorX:Int, anchorY:Int, fillId:Int):{placed:Bool, score:Int} {
		if (!writeShapeOnly(offsets, anchorX, anchorY, fillId))
			return {placed: false, score: 0};
		var lines = stripCompleteLinesOnce();
		rebuildVisual();
		return {placed: true, score: lines * POINTS_PER_LINE};
	}

	/**
		Detecta filas y columnas completas en el estado actual, borra celdas en su unión y devuelve puntos.
	**/
	public function clearCompletedLinesAndScore():Int {
		return stripCompleteLinesOnce() * POINTS_PER_LINE;
	}

	/**
		Ancla de rejilla (esquina celda 0,0) a partir de coordenadas de escena.
	**/
	public function anchorFromScene(sx:Float, sy:Float):{x:Int, y:Int} {
		var gx = Math.floor((sx - x) / CELL_SIZE);
		var gy = Math.floor((sy - y) / CELL_SIZE);
		return {x: gx, y: gy};
	}

	// --- Simulación ligera (solo matriz) para validar tríos del carril ---

	public function copyCellMatrix():Array<Array<Int>> {
		return [for (y in 0...SIZE) [for (x in 0...SIZE) cells[y][x]]];
	}

	public static function duplicateMatrix(src:Array<Array<Int>>):Array<Array<Int>> {
		return [for (y in 0...SIZE) [for (x in 0...SIZE) src[y][x]]];
	}

	public static function matrixCanPlace(m:Array<Array<Int>>, shape:Array<{x:Int, y:Int}>, anchorX:Int, anchorY:Int):Bool {
		for (o in shape) {
			var gx = anchorX + o.x;
			var gy = anchorY + o.y;
			if (gx < 0 || gy < 0 || gx >= SIZE || gy >= SIZE)
				return false;
			if (m[gy][gx] != 0)
				return false;
		}
		return true;
	}

	public static function matrixWriteShape(m:Array<Array<Int>>, shape:Array<{x:Int, y:Int}>, anchorX:Int, anchorY:Int, fillId:Int):Bool {
		if (!matrixCanPlace(m, shape, anchorX, anchorY))
			return false;
		for (o in shape)
			m[anchorY + o.y][anchorX + o.x] = fillId;
		return true;
	}

	/** Una pasada de clear sobre una matriz copiada (misma regla que `stripCompleteLinesOnce`). */
	public static function matrixStripCompleteOnce(m:Array<Array<Int>>):Int {
		var rowDone = [for (_ in 0...SIZE) false];
		var colDone = [for (_ in 0...SIZE) false];
		var nr = 0;
		var nc = 0;
		for (y in 0...SIZE) {
			var full = true;
			for (x in 0...SIZE)
				if (m[y][x] == 0) {
					full = false;
					break;
				}
			if (full) {
				rowDone[y] = true;
				nr++;
			}
		}
		for (x in 0...SIZE) {
			var full = true;
			for (y in 0...SIZE)
				if (m[y][x] == 0) {
					full = false;
					break;
				}
			if (full) {
				colDone[x] = true;
				nc++;
			}
		}
		if (nr == 0 && nc == 0)
			return 0;
		for (y in 0...SIZE)
			for (x in 0...SIZE)
				if (rowDone[y] || colDone[x])
					m[y][x] = 0;
		return nr + nc;
	}

	public static function matrixCountEmpty(m:Array<Array<Int>>):Int {
		var n = 0;
		for (y in 0...SIZE)
			for (x in 0...SIZE)
				if (m[y][x] == 0)
					n++;
		return n;
	}

	/**
		¿Existe algún orden de colocación de las 3 formas (con una pasada de clear tras cada una,
		igual que en partida) que permita colocar las tres? Puede quedar basura en el tablero.
	**/
	public function existsSolvableSequenceForThreeShapes(shapes:Array<Array<{x:Int, y:Int}>>):Bool {
		if (shapes.length != 3)
			return false;
		var perms = [
			[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0],
		];
		for (p in perms) {
			var ordered = [
				ShapeCatalog.copyShape(shapes[p[0]]),
				ShapeCatalog.copyShape(shapes[p[1]]),
				ShapeCatalog.copyShape(shapes[p[2]]),
			];
			var m0 = copyCellMatrix();
			if (matrixCountEmpty(m0) < ordered[0].length)
				continue;
			if (tryPlacementSequenceOnMatrix(m0, ordered, 0))
				return true;
		}
		return false;
	}

	function tryPlacementSequenceOnMatrix(m:Array<Array<Int>>, ordered:Array<Array<{x:Int, y:Int}>>, depth:Int):Bool {
		if (depth >= 3)
			return true;
		var s = ordered[depth];
		if (s.length == 0 || matrixCountEmpty(m) < s.length)
			return false;
		var order = [for (k in 0...SIZE * SIZE) k];
		var n = order.length;
		while (n > 1) {
			var j = Std.random(n);
			n--;
			var t = order[n];
			order[n] = order[j];
			order[j] = t;
		}
		for (k in 0...order.length) {
			var flat = order[k];
			var ax = flat % SIZE;
			var ay = Std.int(flat / SIZE);
			if (matrixCanPlace(m, s, ax, ay)) {
				var next = duplicateMatrix(m);
				matrixWriteShape(next, s, ax, ay, 1);
				matrixStripCompleteOnce(next);
				if (tryPlacementSequenceOnMatrix(next, ordered, depth + 1))
					return true;
			}
		}
		return false;
	}

	public function rebuildVisual():Void {
		tiles.clear();
		tiles.invalidate();

		var cs = CELL_SIZE;
		var inset = CELL_INSET;
		var inner = cs - 2 * inset;
		var innerScale = inner / cs;

		for (y in 0...SIZE) {
			for (x in 0...SIZE) {
				var px = x * cs;
				var py = y * cs;
				var id = cells[y][x];
				if (id == 0) {
					tiles.setDefaultColor(EMPTY_CELL_COLOR);
					tiles.addTransform(px + inset, py + inset, innerScale, innerScale, 0., cellTile);
				} else {
					var bt = BloopSprites.tileForCellId(id);
					if (bt != null) {
						tiles.smooth = true;
						tiles.setDefaultColor(0xffffff);
						var L = BloopSprites.layoutInCell(cs, inset, bt);
						tiles.addTransform(px + L.ox, py + L.oy, L.sc, L.sc, 0., bt);
					} else {
						tiles.setDefaultColor(tintRgbFromBlockId(id));
						tiles.addTransform(px + inset, py + inset, innerScale, innerScale, 0., cellTile);
					}
				}
			}
		}
	}
}
