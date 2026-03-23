package game;

import h2d.Tile;
import h3d.mat.Data.TextureFlags;
import StringTools;

/**
	Sprites por celda, nombres **exactos** que pasas tú:
	`res/img/bloops/Bloop {Color} - {n}.png`
	Ej.: `Bloop Blue - 1.png`, `Bloop Red - 3.png`.

	- **n** = variante de personaje (1, 2, 3…); sube `MAX_BLOOP` cuando añadas más.
	- **Color** = solo estos seis: Blue, Green, Orange, Pink, Purple, Red.

	En el grid: `packCell(bloopNum, colorIdx)` con `colorIdx` 1…6 en el mismo orden que arriba.
**/
class BloopSprites {

	public static inline var CELL_ID_BASE = 10000;
	/** Variantes de bloop a intentar cargar: 1 … MAX_BLOOP. */
	public static inline var MAX_BLOOP = 32;

	static var COLORS:Array<String> = ["Blue", "Green", "Orange", "Pink", "Purple", "Red"];

	static var cache:Map<String, Tile> = new Map();
	static var pairs:Array<{d:Int, c:Int}> = [];

	/** Por color: permutación barajada + cursor; reparte variantes sin repetir hasta agotar y volver a barajar. */
	static var variantPoolByColor:Map<Int, {perm:Array<Int>, i:Int}> = new Map();

	public static function colorCount():Int {
		return COLORS.length;
	}

	public static function colorName(colorIdx1:Int):String {
		return COLORS[colorIdx1 - 1];
	}

	/** Ruta en disco / servidor (con espacios). */
	public static function cellPath(bloopNum:Int, colorIdx1:Int):String {
		return "res/img/bloops/Bloop " + colorName(colorIdx1) + " - " + bloopNum + ".png";
	}

	/** Para `Image.src` en el navegador (espacios → %20). */
	static function urlPath(filePath:String):String {
		#if js
		return StringTools.replace(filePath, " ", "%20");
		#else
		return filePath;
		#end
	}

	public static inline function packCell(bloopNum:Int, colorIdx1:Int):Int {
		return CELL_ID_BASE + bloopNum * 100 + colorIdx1;
	}

	/** Número de variante de bloop (1, 2, 3…). */
	public static function unpackBloopNum(cellId:Int):Int {
		return Std.int((cellId - CELL_ID_BASE) / 100);
	}

	/** 1 = Blue … 6 = Red (orden de `COLORS`). */
	public static function unpackColorIdx(cellId:Int):Int {
		return (cellId - CELL_ID_BASE) % 100;
	}

	public static function isPackedBloopId(cellId:Int):Bool {
		return cellId >= CELL_ID_BASE;
	}

	public static function getTile(bloopNum:Int, colorIdx1:Int):Null<Tile> {
		return cache.get(key(bloopNum, colorIdx1));
	}

	public static function tileForCellId(cellId:Int):Null<Tile> {
		if (!isPackedBloopId(cellId))
			return null;
		return getTile(unpackBloopNum(cellId), unpackColorIdx(cellId));
	}

	public static function loadedPairCount():Int {
		return pairs.length;
	}

	public static function randomPair():Null<{d:Int, c:Int}> {
		if (pairs.length == 0)
			return null;
		return pairs[Std.random(pairs.length)];
	}

	public static function randomPackedId():Int {
		var p = randomPair();
		if (p == null)
			return 0;
		return packCell(p.d, p.c);
	}

	static function uniqVariantsForColor(colorIdx1:Int):Array<Int> {
		var seen:Map<Int, Bool> = new Map();
		var uniq:Array<Int> = [];
		for (p in pairs)
			if (p.c == colorIdx1 && !seen.exists(p.d)) {
				seen.set(p.d, true);
				uniq.push(p.d);
			}
		return uniq;
	}

	static function shuffleCopyInts(a:Array<Int>):Array<Int> {
		var u = a.slice(0);
		var i = u.length;
		while (i > 1) {
			var j = Std.random(i);
			i--;
			var t = u[i];
			u[i] = u[j];
			u[j] = t;
		}
		return u;
	}

	/**
		Toma `need` personajes **distintos** para ese color usando un pool por color: se baraja 1…N y se van
		consumiendo; al no alcanzar, se baraja de nuevo. Así con pocas variantes (p. ej. 4) no se pisan tanto
		entre piezas consecutivas como con muestreo i.i.d.
	**/
	static function takeDistinctVariantsForColor(colorIdx1:Int, need:Int):Null<Array<Int>> {
		var base = uniqVariantsForColor(colorIdx1);
		if (base.length < need)
			return null;
		if (!variantPoolByColor.exists(colorIdx1))
			variantPoolByColor.set(colorIdx1, {perm: shuffleCopyInts(base), i: 0});
		var st = variantPoolByColor.get(colorIdx1);
		if (st.i + need > st.perm.length) {
			st.perm = shuffleCopyInts(base);
			st.i = 0;
		}
		var out:Array<Int> = [];
		for (k in 0...need) {
			out.push(st.perm[st.i]);
			st.i++;
		}
		return out;
	}

	/**
		Elige un color que tenga al menos `need` variantes de bloop cargadas y devuelve `need` números de personaje **distintos**.
		Usado para que cada celda de una figura sea un bloop distinto pero mismo color.
	**/
	public static function pickColorAndDistinctVariants(need:Int):Null<{colorIdx:Int, variants:Array<Int>}> {
		if (need <= 0 || pairs.length == 0)
			return null;
		var candidates:Array<Int> = [];
		for (ci in 1...COLORS.length + 1) {
			if (uniqVariantsForColor(ci).length >= need)
				candidates.push(ci);
		}
		if (candidates.length == 0)
			return null;
		var colorIdx = candidates[Std.random(candidates.length)];
		var variants = takeDistinctVariantsForColor(colorIdx, need);
		if (variants == null)
			return null;
		return {colorIdx: colorIdx, variants: variants};
	}

	static function key(bloopNum:Int, colorIdx1:Int):String {
		return bloopNum + "_" + colorIdx1;
	}

	#if js

	public static function preloadAll(onDone:Void->Void):Void {
		cache.clear();
		pairs = [];
		variantPoolByColor = new Map();
		var left = MAX_BLOOP * COLORS.length;
		if (left <= 0) {
			onDone();
			return;
		}
		function step() {
			left--;
			if (left <= 0)
				onDone();
		}
		for (b in 1...MAX_BLOOP + 1)
			for (ci in 0...COLORS.length)
				tryLoad(b, ci + 1, step);
	}

	static function tryLoad(bloopNum:Int, colorIdx1:Int, onDone:Void->Void):Void {
		var path = cellPath(bloopNum, colorIdx1);
		var img = new js.html.Image();
		img.onload = function(_) {
			var bmp = new hxd.fs.LoadedBitmap(img).toBitmap();
			var tex = new h3d.mat.Texture(bmp.width, bmp.height, [TextureFlags.Target]);
			tex.uploadBitmap(bmp);
			bmp.dispose();
			var t = Tile.fromTexture(tex);
			cache.set(key(bloopNum, colorIdx1), t);
			pairs.push({d: bloopNum, c: colorIdx1});
			onDone();
		};
		img.onerror = function(_) {
			onDone();
		};
		img.src = urlPath(path);
	}

	#else

	public static function preloadAll(onDone:Void->Void):Void {
		cache.clear();
		pairs = [];
		onDone();
	}

	#end

	/** Tinte FX alineado con cada color de bloop. */
	public static function accentRgbForColor(colorIdx1:Int):Int {
		switch (colorIdx1) {
			case 1:
				return 0x5599ff;
			case 2:
				return 0x55dd77;
			case 3:
				return 0xff9944;
			case 4:
				return 0xff77cc;
			case 5:
				return 0xaa77ff;
			case 6:
				return 0xff5555;
			default:
				return 0xccccff;
		}
	}

	public static function layoutInCell(cellSize:Float, inset:Float, tile:Tile):{ox:Float, oy:Float, sc:Float} {
		var inner = cellSize - 2 * inset;
		var tw = tile.width;
		var th = tile.height;
		var sc = inner / Math.max(tw, th);
		var dw = tw * sc;
		var dh = th * sc;
		return {
			ox: inset + (inner - dw) * 0.5,
			oy: inset + (inner - dh) * 0.5,
			sc: sc,
		};
	}
}
