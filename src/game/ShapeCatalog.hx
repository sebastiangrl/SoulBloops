package game;

/**
	Formas tipo block-puzzle (1–9 celdas). Literales {x,y}; `Piece` vuelve a normalizar el bbox.
	Referencia de nombres y medidas: `docs/FIGURAS.md`.
**/
class ShapeCatalog {

	static inline var PLACEABLE_GUESS_TRIES = 80;

	static var POOL:Array<Array<{x:Int, y:Int}>> = [
		[{x: 0, y: 0}],
		[{x: 0, y: 0}, {x: 1, y: 0}],
		[{x: 0, y: 0}, {x: 0, y: 1}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}],
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 0, y: 2}],
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 0, y: 2}, {x: 0, y: 3}],
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 0, y: 2}, {x: 0, y: 3}, {x: 0, y: 4}],
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 0, y: 2}, {x: 0, y: 3}, {x: 0, y: 4}, {x: 0, y: 5}],
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 1, y: 0}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 1, y: 1}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 1, y: 1}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 3, y: 0}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 0, y: 1}],
		[{x: 0, y: 1}, {x: 1, y: 1}, {x: 2, y: 1}, {x: 2, y: 0}],
		[{x: 1, y: 0}, {x: 2, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 1, y: 1}, {x: 2, y: 1}],
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 2, y: 1}],
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 3, y: 0}, {x: 4, y: 0}],
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 0, y: 2}, {x: 1, y: 2}, {x: 2, y: 2}],
		[{x: 1, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 2, y: 1}, {x: 1, y: 2}],
		// Rectángulo 2×3 (2 cols × 3 filas), bloque sólido 6 celdas
		[{x: 0, y: 0}, {x: 1, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 0, y: 2}, {x: 1, y: 2}],
		// Cuadrado 3×3, bloque sólido 9 celdas
		[
			{x: 0, y: 0}, {x: 1, y: 0}, {x: 2, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 2, y: 1}, {x: 0, y: 2}, {x: 1, y: 2},
			{x: 2, y: 2}
		],
		// Columna de 3 con saliente en el centro hacia la izquierda
		[{x: 1, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 1, y: 2}],
		// Columna de 3 con saliente en el centro hacia la derecha
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 0, y: 2}],
		// 2×3: #. / ## / .#  y espejo horizontal .# / ## / #.
		[{x: 0, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 1, y: 2}],
		[{x: 1, y: 0}, {x: 0, y: 1}, {x: 1, y: 1}, {x: 0, y: 2}],
	];

	public static function randomShape():Array<{x:Int, y:Int}> {
		var raw = POOL[Std.random(POOL.length)];
		return copyShape(raw);
	}

	/**
		Forma aleatoria que **sí encaja** en al menos un ancla del tablero actual.
	**/
	public static function randomPlaceableShape(grid:Grid):Array<{x:Int, y:Int}> {
		for (_ in 0...PLACEABLE_GUESS_TRIES) {
			var s = randomShape();
			if (grid.canPlaceShapeAnywhere(s))
				return s;
		}
		for (raw in POOL) {
			var c = copyShape(raw);
			if (grid.canPlaceShapeAnywhere(c))
				return c;
		}
		return copyShape(POOL[0]);
	}

	static inline var RESOLVABLE_TRIPLE_RANDOM_TRIES = 360;
	/** Muestras extra sin barrer 24³ (rápido). */
	static inline var RESOLVABLE_TRIPLE_EXTRA_SAMPLES = 500;

	static function randomIndependentPoolTriple():Array<Array<{x:Int, y:Int}>> {
		var pl = POOL.length;
		var i = Std.random(pl);
		var j = Std.random(pl);
		var k = Std.random(pl);
		return [copyShape(POOL[i]), copyShape(POOL[j]), copyShape(POOL[k])];
	}

	/**
		Tres piezas tales que **existe** un orden de colocación válido en el tablero actual
		(con clear de líneas tras cada colocación, como en juego). No exige dejar el tablero vacío.
	**/
	public static function randomResolvableTriple(grid:Grid):Array<Array<{x:Int, y:Int}>> {
		for (_ in 0...RESOLVABLE_TRIPLE_RANDOM_TRIES) {
			var s1 = randomShape();
			var s2 = randomShape();
			var s3 = randomShape();
			if (grid.existsSolvableSequenceForThreeShapes([s1, s2, s3]))
				return [copyShape(s1), copyShape(s2), copyShape(s3)];
		}
		for (_ in 0...RESOLVABLE_TRIPLE_EXTRA_SAMPLES) {
			var t = randomIndependentPoolTriple();
			if (grid.existsSolvableSequenceForThreeShapes(t))
				return t;
		}
		return [copyShape(POOL[0]), copyShape(POOL[0]), copyShape(POOL[0])];
	}

	public static function copyShape(raw:Array<{x:Int, y:Int}>):Array<{x:Int, y:Int}> {
		return [for (c in raw) {x: c.x, y: c.y}];
	}

	/** RGB 0–1 estilo neón-pastel. */
	public static function randomNeonRGB():{r:Float, g:Float, b:Float} {
		var hue = Std.random(360);
		var hr = hue * Math.PI / 180;
		return {
			r: 0.45 + 0.45 * Math.cos(hr),
			g: 0.5 + 0.4 * Math.cos(hr + 2.09),
			b: 0.55 + 0.35 * Math.cos(hr + 4.18),
		};
	}
}
