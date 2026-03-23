package game;

import h2d.Bitmap;
import h2d.Layers;
import h2d.Object;
import h2d.Tile;
import h3d.mat.Data.TextureFlags;

/**
	Carga de fondos en coordenadas de escena (p. ej. 720×1280 con LetterBox).
	Para más fondos: cambia `DEFAULT_PATH` o añade `loadCover(..., otraRuta, ...)`.
**/
class Backgrounds {

	public static inline var DEFAULT_PATH = "res/img/bg/background.jpg";

	#if js

	/**
		Carga asíncrona por URL relativa al HTML (sirve desde `http://localhost:8080/`, no desde file://).
		El bitmap queda al fondo (`addChildAt(..., 0)`) y rellena el rectángulo coverW×coverH (modo cover).
	**/
	public static function loadCover(parent:Object, path:String, coverW:Float, coverH:Float, onLoaded:Bitmap->Void, ?onError:Void->Void):Void {
		var img = new js.html.Image();
		img.onload = function(_) {
			var bmp = new hxd.fs.LoadedBitmap(img).toBitmap();
			var tex = new h3d.mat.Texture(bmp.width, bmp.height, [TextureFlags.Target]);
			tex.uploadBitmap(bmp);
			bmp.dispose();
			var tile = Tile.fromTexture(tex);
			var bitmap = new Bitmap(tile);
			var layers = Std.downcast(parent, Layers);
			if (layers != null)
				layers.add(bitmap, 0, 0);
			else
				parent.addChildAt(bitmap, 0);
			layoutCover(bitmap, img.width, img.height, coverW, coverH);
			onLoaded(bitmap);
		};
		img.onerror = function(_) {
			if (onError != null)
				onError();
			else
				haxe.Log.trace("No se pudo cargar el fondo: " + path, null);
		};
		img.src = path;
	}

	/**
		Sprite encima del fondo (último hijo = dibuja al frente). Opcional `maxH` escala uniforme por altura.
	**/
	public static function loadSprite(parent:Object, path:String, onLoaded:Bitmap->Void, ?maxH:Float, ?onError:Void->Void):Void {
		var img = new js.html.Image();
		img.onload = function(_) {
			var bmp = new hxd.fs.LoadedBitmap(img).toBitmap();
			var tex = new h3d.mat.Texture(bmp.width, bmp.height, [TextureFlags.Target]);
			tex.uploadBitmap(bmp);
			bmp.dispose();
			var tile = Tile.fromTexture(tex);
			var bitmap = new Bitmap(tile);
			var sc = 1.;
			if (maxH != null && img.height > maxH)
				sc = maxH / img.height;
			bitmap.scaleX = bitmap.scaleY = sc;
			parent.addChild(bitmap);
			onLoaded(bitmap);
		};
		img.onerror = function(_) {
			if (onError != null)
				onError();
			else
				haxe.Log.trace("No se pudo cargar: " + path, null);
		};
		img.src = path;
	}

	#else

	public static function loadCover(_parent:Object, _path:String, _coverW:Float, _coverH:Float, _onLoaded:Bitmap->Void, ?_onError:Void->Void):Void {}

	public static function loadSprite(_parent:Object, _path:String, _onLoaded:Bitmap->Void, ?_maxH:Float, ?_onError:Void->Void):Void {}

	#end

	public static function layoutCover(bitmap:Bitmap, srcW:Float, srcH:Float, coverW:Float, coverH:Float):Void {
		if (srcW <= 0 || srcH <= 0)
			return;
		var sc = Math.max(coverW / srcW, coverH / srcH);
		bitmap.scaleX = bitmap.scaleY = sc;
		bitmap.x = (coverW - srcW * sc) * 0.5;
		bitmap.y = (coverH - srcH * sc) * 0.5;
	}
}
