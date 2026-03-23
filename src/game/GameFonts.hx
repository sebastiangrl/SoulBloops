package game;

import hxd.res.DefaultFont;
import hxd.res.FontBuilder;

/**
	Fuente UI: Road Rage desde `res/fonts/RoadRage-Regular.ttf` (JS: FontFace + FontBuilder).
	En otros targets usa `DefaultFont` hasta que enlaces TTF nativo.
**/
class GameFonts {

	public static inline var ROAD_RAGE_TTF_PATH = "res/fonts/RoadRage-Regular.ttf";
	public static inline var ROAD_RAGE_FAMILY = "Road Rage";

	/** Tamaño base rasterizado para Heaps (ajusta con `Text.scale`). */
	public static inline var UI_FONT_SIZE = 44;

	public static var roadRage:h2d.Font = null;

	public static function getUi():h2d.Font {
		return roadRage != null ? roadRage : DefaultFont.get();
	}

	#if js

	/**
		Carga el TTF local y construye el bitmap font. Llamar una vez al inicio.
	**/
	public static function loadRoadRageLocal(onDone:Void->Void, ?onFailed:Void->Void):Void {
		if (roadRage != null) {
			haxe.Timer.delay(onDone, 0);
			return;
		}
		var src = 'url("' + ROAD_RAGE_TTF_PATH + '")';
		untyped {
			var face = js.Syntax.code("new FontFace({0}, {1})", ROAD_RAGE_FAMILY, src);
			face.load().then(function() {
				js.Browser.document.fonts.add(face);
				haxe.Timer.delay(function() {
					try {
						roadRage = FontBuilder.getFont(ROAD_RAGE_FAMILY, UI_FONT_SIZE, null);
					} catch (_:Dynamic) {
						roadRage = null;
					}
					onDone();
				}, 0);
			}, function(_err:Dynamic) {
				if (onFailed != null)
					onFailed();
				else
					haxe.Log.trace("No se pudo cargar " + ROAD_RAGE_TTF_PATH, null);
				haxe.Timer.delay(onDone, 0);
			});
		}
	}

	#else

	public static function loadRoadRageLocal(onDone:Void->Void, ?onFailed:Void->Void):Void {
		haxe.Timer.delay(onDone, 0);
	}

	#end
}
