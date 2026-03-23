package game;

import StringTools;

/**
	Textos UI (menú, ajustes, game over, splash).
	Por defecto inglés; si no hay preferencia guardada, se usa el idioma del navegador (`es*` → español, `ja*` → japonés; resto → inglés).
**/
class I18n {

	public static var current(default, null):String = "en";

	static inline var LS_KEY = "soulBloops_locale";

	static var strings:Map<String, Map<String, String>> = null;

	static function addLocale(code:String, pairs:Array<String>):Void {
		var m = new Map<String, String>();
		var i = 0;
		while (i + 1 < pairs.length) {
			m.set(pairs[i], pairs[i + 1]);
			i += 2;
		}
		strings.set(code, m);
	}

	static function ensureMaps():Void {
		if (strings != null)
			return;
		strings = new Map();
		addLocale("en", [
			"splash.skip", "Tap to skip",
			"menu.play", "Play",
			"menu.howTo", "How to play",
			"settings.title", "Settings",
			"settings.mute", "Mute sound",
			"settings.volume", "Volume",
			"settings.language", "Language",
			"settings.langEn", "English",
			"settings.langEs", "Español",
			"settings.langJa", "日本語",
			"settings.restart", "Restart game",
			"settings.mainMenu", "Main menu",
			"settings.close", "Close",
			"settings.fabAria", "Settings",
			"howTo.title", "How to play",
			"howTo.li1", "Drag pieces from the rail to the 8×8 board.",
			"howTo.li2", "Complete a full row or column to clear it and score points.",
			"howTo.li3", "When you place all three pieces in the turn, you get a new trio.",
			"howTo.li4", "If you can’t place any piece, the game ends (unless you revive with an ad!).",
			"howTo.close", "Close",
			"gameOver.title", "No moves left",
			"gameOver.scoreLabel", "Score:",
			"gameOver.revive", "Revive",
			"gameOver.reviveSub", "Watch ad (1 per match)",
			"gameOver.playAgain", "Play again",
			"gameOver.adHint", "Rewarded ads will be in the Android app.",
			"gameOver.heapSub", "Score: {0}\n\nTap to play again",
			"hud.bestScoreAria", "High score",
			"feel.comboStreak", "Streak ×{0}!",
			"feel.brutal", "Brutal!",
			"feel.great", "Awesome!",
			"feel.linesMult", "Lines ×{0}!",
			"feel.boardClear", "Board clear!\n+{0}",
		]);
		addLocale("es", [
			"splash.skip", "Toca para saltar",
			"menu.play", "Jugar",
			"menu.howTo", "Cómo jugar",
			"settings.title", "Ajustes",
			"settings.mute", "Silenciar sonido",
			"settings.volume", "Volumen",
			"settings.language", "Idioma",
			"settings.langEn", "Inglés",
			"settings.langEs", "Español",
			"settings.langJa", "Japonés",
			"settings.restart", "Reiniciar partida",
			"settings.mainMenu", "Menú principal",
			"settings.close", "Cerrar",
			"settings.fabAria", "Ajustes",
			"howTo.title", "Cómo jugar",
			"howTo.li1", "Arrastra las piezas del carril al tablero de 8×8.",
			"howTo.li2", "Completa una fila o columna entera para limpiarla y sumar puntos.",
			"howTo.li3", "Cuando coloques las tres piezas del turno, recibirás un nuevo trío.",
			"howTo.li4", "Si no puedes colocar ninguna pieza, la partida termina (¡a menos que revivas con un anuncio!).",
			"howTo.close", "Cerrar",
			"gameOver.title", "Sin movimientos",
			"gameOver.scoreLabel", "Puntuación:",
			"gameOver.revive", "Revivir",
			"gameOver.reviveSub", "Ver anuncio (1 por partida)",
			"gameOver.playAgain", "Jugar de nuevo",
			"gameOver.adHint", "Los anuncios premiados estarán en la app para Android.",
			"gameOver.heapSub", "Puntuación: {0}\n\nToca para jugar de nuevo",
			"hud.bestScoreAria", "Mejor puntuación",
			"feel.comboStreak", "¡Racha ×{0}!",
			"feel.brutal", "¡Brutal!",
			"feel.great", "¡Genial!",
			"feel.linesMult", "¡Líneas ×{0}!",
			"feel.boardClear", "¡Tablero limpio!\n+{0}",
		]);
		addLocale("ja", [
			"splash.skip", "タップでスキップ",
			"menu.play", "プレイ",
			"menu.howTo", "遊び方",
			"settings.title", "設定",
			"settings.mute", "音をミュート",
			"settings.volume", "音量",
			"settings.language", "言語",
			"settings.langEn", "English",
			"settings.langEs", "Español",
			"settings.langJa", "日本語",
			"settings.restart", "ゲームを再開",
			"settings.mainMenu", "メインメニュー",
			"settings.close", "閉じる",
			"settings.fabAria", "設定",
			"howTo.title", "遊び方",
			"howTo.li1", "レールから8×8の盤へピースをドラッグ。",
			"howTo.li2", "行か列を1本そろえると消去して得点。",
			"howTo.li3", "3つ置き終えると新しい3つが届く。",
			"howTo.li4", "どれも置けなくなると終了（広告で復活できる場合あり）。",
			"howTo.close", "閉じる",
			"gameOver.title", "手がない",
			"gameOver.scoreLabel", "スコア:",
			"gameOver.revive", "復活",
			"gameOver.reviveSub", "広告を見る（1試合1回）",
			"gameOver.playAgain", "もう一度",
			"gameOver.adHint", "リワード広告はAndroidアプリで利用できます。",
			"gameOver.heapSub", "スコア: {0}\n\nタップでもう一度",
			"hud.bestScoreAria", "ハイスコア",
			"feel.comboStreak", "コンボ ×{0}！",
			"feel.brutal", "激！",
			"feel.great", "ナイス！",
			"feel.linesMult", "ライン×{0}！",
			"feel.boardClear", "盤面クリア！\n+{0}",
		]);
	}

	public static function init():Void {
		ensureMaps();
		#if js
		current = resolveLocaleJs();
		applyDom();
		syncHtmlLang();
		#else
		current = "en";
		#end
	}

	#if js
	static function resolveLocaleJs():String {
		try {
			untyped {
				var ls = window.localStorage;
				if (ls != null) {
					var s = ls.getItem(LS_KEY);
					if (s == "en" || s == "es" || s == "ja")
						return s;
				}
			}
		} catch (_:Dynamic) {}
		var nav = js.Browser.navigator;
		var lang:String = nav.language;
		if ((lang == null || lang == "") && untyped nav.languages != null && untyped nav.languages.length > 0)
			lang = untyped nav.languages[0];
		if (lang != null) {
			var low = lang.toLowerCase();
			if (StringTools.startsWith(low, "ja"))
				return "ja";
			if (StringTools.startsWith(low, "es"))
				return "es";
		}
		return "en";
	}

	public static function setLocale(l:String):Void {
		if (l != "en" && l != "es" && l != "ja")
			return;
		current = l;
		try {
			untyped {
				var ls = window.localStorage;
				if (ls != null)
					ls.setItem(LS_KEY, l);
			}
		} catch (_:Dynamic) {}
		applyDom();
		syncHtmlLang();
	}

	public static function applyDom():Void {
		ensureMaps();
		var doc = js.Browser.document;
		var nodes = doc.querySelectorAll("[data-i18n]");
		for (i in 0...nodes.length) {
			var el:js.html.Element = cast nodes.item(i);
			var k = el.getAttribute("data-i18n");
			if (k != null && k != "")
				el.textContent = t(k);
		}
		var ariaNodes = doc.querySelectorAll("[data-i18n-aria]");
		for (i in 0...ariaNodes.length) {
			var el:js.html.Element = cast ariaNodes.item(i);
			var k = el.getAttribute("data-i18n-aria");
			if (k != null && k != "")
				el.setAttribute("aria-label", t(k));
		}
		var titleNodes = doc.querySelectorAll("[data-i18n-title]");
		for (i in 0...titleNodes.length) {
			var el:js.html.Element = cast titleNodes.item(i);
			var k = el.getAttribute("data-i18n-title");
			if (k != null && k != "")
				el.setAttribute("title", t(k));
		}
	}

	static function syncHtmlLang():Void {
		var h = js.Browser.document.documentElement;
		h.lang = current == "ja" ? "ja" : (current == "es" ? "es" : "en");
	}
	#end

	public static function t(key:String):String {
		ensureMaps();
		var m = strings.get(current);
		if (m == null)
			m = strings.get("en");
		var v = m.get(key);
		if (v == null) {
			m = strings.get("en");
			v = m.get(key);
		}
		return v != null ? v : key;
	}

	public static function tf(key:String, args:Array<String>):String {
		var s = t(key);
		for (i in 0...args.length)
			s = StringTools.replace(s, "{" + i + "}", args[i]);
		return s;
	}
}
