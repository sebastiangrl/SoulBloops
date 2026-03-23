import h2d.Text.Align;
import h2d.Bitmap;
import h2d.Interactive;
import h2d.Scene.ScaleMode;
import h2d.Scene.ScaleModeAlign;
import h2d.Text;
import h2d.Tile;
import hxd.res.DefaultFont;
import game.AudioHub;
import game.Backgrounds;
import game.GameFonts;
import game.GameFeel;
import game.Grid;
import game.Haptics;
import game.BloopSprites;
import game.Piece;
import game.RewardedAdBridge;
import game.ShapeCatalog;
import StringTools;

#if js
import js.Browser;
import js.html.Element;
import js.html.InputElement;
#end

/**
	Soul Bloops — Studio Sylf
	Punto de entrada Heaps (`hxd.App`).
**/
class Main extends hxd.App {

	static inline var DESIGN_W = 720;
	static inline var DESIGN_H = 1280;

	/** Color de fondo (ARGB). */
	static inline var BG = 0xFF12101c;

	static inline var SCORE_COLOR_NORMAL = 0xc8b8ff;
	static inline var SCORE_COLOR_TENSE = 0xff9966;
	static inline var TENSION_EMPTY_THRESHOLD = 20;
	/** Racha: multiplicador sobre puntos de línea (tope). */
	static inline var COMBO_MULT_STEP = 0.16;
	static inline var COMBO_MULT_MAX = 2.5;
	/** Bonus extra si tras un clear no queda ningún bloque: base + 140 × racha de clears (mín. racha 1 en ese tiro). */
	static inline var GRID_CLEAR_BASE_BONUS = 450;
	static inline var GRID_CLEAR_STREAK_BONUS = 140;

	/** Desplaza hacia abajo tablero + carril de piezas (espacio superior). */
	static inline var LAYOUT_DROP_Y = 120;
	static inline var GRID_Y_BASE = 200;

	public static inline var MASCOT_PATH = "res/img/eternalsInk/eternal-ink-1.png";
	/** Altura máx. del personaje junto al marco de puntos. */
	static inline var MASCOT_MAX_HEIGHT = 92.;
	static inline var MASCOT_GAP_FROM_SCORE = 10.;
	public static inline var POINTS_FRAME_PATH = "res/img/blocks/points-tile.png";
	public static inline var HIGH_SCORE_CROWN_PATH = "res/img/ui/corona.png";
	/** Logos menú (también referenciados en `index.html` para carga inmediata). */
	public static inline var LOGO_SOUL_BLOOPS_PATH = "res/img/ui/LogoSoulBloops.png";
	public static inline var STUDIO_SYLF_LOGO_PATH = "res/img/ui/studio-sylf.png";
	public static inline var SOUL_BLOOPS_TITLE_ART_PATH = "res/img/ui/soul-bloops.png";
	/** Récord + corona pegados al borde izquierdo del área de juego (diseño ~720×1280). */
	static inline var HIGH_SCORE_MARGIN_LEFT = 16.;
	static inline var HIGH_SCORE_ANCHOR_Y = 48.;
	static inline var SCORE_FRAME_MAX_W = 272.;
	static inline var SCORE_ABOVE_BOARD_GAP = 14.;
	static inline var SCORE_TEXT_PT = GameFonts.UI_FONT_SIZE * 1.45;
	static inline var HIGH_SCORE_TEXT_PT = GameFonts.UI_FONT_SIZE * 0.96;
	/** Botón ajustes en coords de diseño 720×1280 (esquina sup. derecha zona jugable). */
	static inline var SETTINGS_FAB_DESIGN_SIZE = 48.;
	static inline var SETTINGS_FAB_MARGIN_X = 14.;
	static inline var SETTINGS_FAB_MARGIN_TOP = 14.;
	static inline var SPLASH_STEP_MS = 1700;
	#if js
	static inline var LOCAL_STORAGE_BEST = "soulBloops_highScore";
	#end

	var cellTile:h2d.Tile;
	var grid:Grid;
	var feel:GameFeel;
	/** Hasta 3 piezas por turno; ranura `null` = ya colocada en este turno. Nuevo trío solo al colocar las 3. */
	var tray:Array<Piece> = [null, null, null];
	/** Centro horizontal de cada ranura + Y de apoyo para las piezas. */
	var slotAnchor:Array<{x:Float, y:Float}>;
	var score:Int = 0;
	/** Mejor puntuación en esta sesión / persistida (JS). */
	var bestScore:Int = 0;
	/** Colocaciones seguidas que han borrado al menos una línea (se corta si coloca sin línea). */
	var clearStreak:Int = 0;
	/** Puntuación mostrada (interpola hacia `score`). */
	var displayScore:Float = 0.;
	/** Marco PNG en WebGL. En JS el número va en DOM (`#soulBloopsScore`) encima del canvas. */
	var scoreHud:h2d.Object;
	#if js
	var scoreDom:Element;
	var highScoreDom:Element;
	var highScoreValueDom:Element;
	var scoreDomRgb:Int = SCORE_COLOR_NORMAL;
	#else
	var scoreText:h2d.Text;
	var highScoreText:h2d.Text;
	#end
	var scoreFrame:h2d.Bitmap = null;
	var nextBlockId:Int = 1;

	var gameOver:Bool = false;
	var gameOverRoot:h2d.Object = null;
	/** Tras revivir con anuncio, no se ofrece otro hasta nueva partida. */
	var reviveUsedThisMatch:Bool = false;
	#if js
	var goOverlay:Element = null;
	var goScoreEl:Element = null;
	var goReviveBtn:Element = null;
	var goRestartBtn:Element = null;
	var goHintEl:Element = null;
	var goAdPending:Bool = false;
	var titleScreenActive:Bool = true;
	var mainMenuEl:Element = null;
	var settingsModalEl:Element = null;
	var settingsFabEl:Element = null;
	var volumeSliderEl:Element = null;
	var muteToggleEl:Element = null;
	var howToModalEl:Element = null;
	var splashRootEl:Element = null;
	var splashFrameEl:Element = null;
	var splashStudioEl:Element = null;
	var splashGameEl:Element = null;
	var splashFinished:Bool = false;
	var splashGen:Int = 0;
	#end

	/** Fondo `res/img/bg/…` (async en JS); `null` hasta que cargue. */
	var bgBitmap:h2d.Bitmap = null;
	var mascotBitmap:h2d.Bitmap = null;

	override function init() {
		engine.backgroundColor = BG;
		s2d.scaleMode = LetterBox(DESIGN_W, DESIGN_H, false, ScaleModeAlign.Center, ScaleModeAlign.Center);

		#if js
		Backgrounds.loadCover(s2d, Backgrounds.DEFAULT_PATH, s2d.width, s2d.height, function(bmp) {
			bgBitmap = bmp;
			relayoutBackground();
		});
		Backgrounds.loadSprite(s2d, MASCOT_PATH, function(bmp) {
			mascotBitmap = bmp;
			layoutMascot();
		}, MASCOT_MAX_HEIGHT);
		#end

		cellTile = Tile.fromColor(0xffffff, Grid.CELL_SIZE, Grid.CELL_SIZE);

		grid = new Grid(cellTile, s2d);
		feel = new GameFeel(s2d, grid);
		grid.seedBlockBlastRandom();
		nextBlockId = BloopSprites.loadedPairCount() > 0 ? 1 : (grid.maxOccupiedId() + 1);

		slotAnchor = [{x: 0., y: 0.}, {x: 0., y: 0.}, {x: 0., y: 0.}];

		scoreHud = new h2d.Object(s2d);
		#if js
		scoreDom = Browser.document.getElementById("soulBloopsScore");
		if (scoreDom == null) {
			scoreDom = Browser.document.createSpanElement();
			scoreDom.id = "soulBloopsScore";
			Browser.document.body.appendChild(scoreDom);
		}
		highScoreDom = Browser.document.getElementById("soulBloopsHighScore");
		if (highScoreDom == null) {
			highScoreDom = Browser.document.createSpanElement();
			highScoreDom.id = "soulBloopsHighScore";
			Browser.document.body.appendChild(highScoreDom);
		}
		ensureHighScoreHudDom();
		highScoreValueDom = Browser.document.getElementById("soulBloopsHighScoreValue");
		loadBestScoreFromStorage();
		scoreDomRgb = SCORE_COLOR_NORMAL;
		scoreDom.style.color = rgbToCss(SCORE_COLOR_NORMAL);
		initGameOverDom();
		initTitleAndSettingsDom();
		#else
		scoreText = new Text(DefaultFont.get(), scoreHud);
		scoreText.textAlign = Center;
		scoreText.textColor = SCORE_COLOR_NORMAL;
		scoreText.scale(1.45);
		highScoreText = new Text(DefaultFont.get(), s2d);
		highScoreText.textAlign = Left;
		highScoreText.textColor = 0xffffff;
		highScoreText.scale(0.92);
		#end
		displayScore = 0.;
		updateScoreLabel();
		updateHighScoreLabel();
		layoutBoard();

		#if js
		GameFonts.loadRoadRageLocal(function() {
			#if !js
			scoreText.font = GameFonts.getUi();
			highScoreText.font = GameFonts.getUi();
			#end
			updateScoreLabel();
			layoutScoreHud();
			layoutMascot();
		});
		Backgrounds.loadSprite(scoreHud, POINTS_FRAME_PATH, function(b) {
			scoreFrame = b;
			if (b.tile.width > SCORE_FRAME_MAX_W) {
				var sc = SCORE_FRAME_MAX_W / b.tile.width;
				b.scaleX = b.scaleY = sc;
			}
			b.remove();
			#if js
			scoreHud.addChild(b);
			#else
			scoreHud.addChildAt(b, 0);
			#end
			layoutScoreHud();
			layoutMascot();
		});
		#end

		#if js
		#else
		haxe.Timer.delay(dealNewTray, 0);
		#end
	}

	override function update(dt:Float) {
		super.update(dt);
		#if js
		if (!titleScreenActive) {
		#end
		grid.updateNeon(dt);
		feel.step(dt);
		#if js
		}
		#end
		if (displayScore < score) {
			displayScore += (score - displayScore) * Math.min(1., dt * 11.);
			if (score - displayScore < 0.45)
				displayScore = score;
		} else if (displayScore > score)
			displayScore = score;
		updateScoreLabel();
		maybeUpgradeBestScore();
		updateTensionHud(dt);
	}

	function updateTensionHud(dt:Float):Void {
		#if js
		if (!splashFinished || titleScreenActive)
			return;
		#end
		if (gameOver || grid.interactionLocked)
			return;
		var tense = grid.countEmptyCells() <= TENSION_EMPTY_THRESHOLD;
		var target = tense ? SCORE_COLOR_TENSE : SCORE_COLOR_NORMAL;
		#if js
		scoreDomRgb = lerpColor(scoreDomRgb, target, Math.min(1., dt * 2.8));
		if (scoreDom != null)
			scoreDom.style.color = rgbToCss(scoreDomRgb);
		#else
		scoreText.textColor = lerpColor(scoreText.textColor, target, Math.min(1., dt * 2.8));
		#end
	}

	static function lerpColor(from:Int, to:Int, t:Float):Int {
		var rf = (from >> 16) & 0xFF, gf = (from >> 8) & 0xFF, bf = from & 0xFF;
		var rt = (to >> 16) & 0xFF, gt = (to >> 8) & 0xFF, bt = to & 0xFF;
		var r = Std.int(rf + (rt - rf) * t) & 0xFF;
		var g = Std.int(gf + (gt - gf) * t) & 0xFF;
		var b = Std.int(bf + (bt - bf) * t) & 0xFF;
		return (r << 16) | (g << 8) | b;
	}

	function layoutBoard():Void {
		var boardW = Grid.SIZE * Grid.CELL_SIZE;
		grid.x = (s2d.width - boardW) * 0.5;
		grid.y = GRID_Y_BASE + LAYOUT_DROP_Y;

		var trayY = grid.y + boardW + 36;
		var margin = 20.;
		var usable = s2d.width - margin * 2;
		var slotW = usable / 3;
		for (i in 0...3) {
			var cx = margin + slotW * i + slotW * 0.5;
			slotAnchor[i] = {x: cx, y: trayY};
		}

		feel.syncGridRestPos();

		relayoutBackground();

		layoutScoreHud();
		layoutMascot();
	}

	function scoreHudFrameSize():{w:Float, h:Float} {
		var fw = 172.;
		var fh = 56.;
		if (scoreFrame != null && scoreFrame.tile != null) {
			fw = scoreFrame.tile.width * scoreFrame.scaleX;
			fh = scoreFrame.tile.height * scoreFrame.scaleY;
		}
		return {w: fw, h: fh};
	}

	function layoutScoreHud():Void {
		#if js
		if (scoreHud == null || scoreDom == null)
			return;
		#else
		if (scoreHud == null || scoreText == null)
			return;
		#end
		var sz = scoreHudFrameSize();
		var fw = sz.w;
		var fh = sz.h;
		scoreHud.x = s2d.width * 0.5 - fw * 0.5;
		scoreHud.y = grid.y - fh - SCORE_ABOVE_BOARD_GAP;
		#if js
		syncScoreDomLayout(fw, fh);
		syncHighScoreDomLayout();
		syncSettingsFabLayout();
		syncSplashFrameLayout();
		updatePlayHudDomVisibility();
		#else
		scoreText.x = fw * 0.5;
		scoreText.y = (fh - scoreText.textHeight) * 0.5;
		if (highScoreText != null) {
			highScoreText.x = HIGH_SCORE_MARGIN_LEFT;
			highScoreText.y = HIGH_SCORE_ANCHOR_Y;
		}
		#end
	}

	#if js
	function canvasLetterbox():Null<{ox:Float, oy:Float, scale:Float}> {
		var canvas = Browser.document.getElementById("webgl");
		if (canvas == null)
			return null;
		var cr = canvas.getBoundingClientRect();
		var scale = Math.min(cr.width / DESIGN_W, cr.height / DESIGN_H);
		var ox = cr.left + (cr.width - DESIGN_W * scale) * 0.5;
		var oy = cr.top + (cr.height - DESIGN_H * scale) * 0.5;
		return {ox: ox, oy: oy, scale: scale};
	}

	function shouldShowPlayHudDom():Bool {
		return splashFinished && !titleScreenActive;
	}

	function updatePlayHudDomVisibility():Void {
		var show = shouldShowPlayHudDom();
		if (scoreDom != null)
			scoreDom.style.visibility = show ? "visible" : "hidden";
		if (highScoreDom != null)
			highScoreDom.style.visibility = show ? "visible" : "hidden";
	}

	function syncSettingsFabLayout():Void {
		if (settingsFabEl == null)
			return;
		var L = canvasLetterbox();
		if (L == null)
			return;
		var sz = SETTINGS_FAB_DESIGN_SIZE * L.scale;
		var left = L.ox + (DESIGN_W - SETTINGS_FAB_MARGIN_X - SETTINGS_FAB_DESIGN_SIZE) * L.scale;
		var top = L.oy + SETTINGS_FAB_MARGIN_TOP * L.scale;
		settingsFabEl.style.left = Std.string(left) + "px";
		settingsFabEl.style.top = Std.string(top) + "px";
		settingsFabEl.style.width = Std.string(sz) + "px";
		settingsFabEl.style.height = Std.string(sz) + "px";
		settingsFabEl.style.fontSize = Std.string(Math.max(13., 21. * L.scale)) + "px";
	}

	function syncSplashFrameLayout():Void {
		if (splashFrameEl == null)
			return;
		var L = canvasLetterbox();
		if (L == null)
			return;
		splashFrameEl.style.left = Std.string(L.ox) + "px";
		splashFrameEl.style.top = Std.string(L.oy) + "px";
		splashFrameEl.style.width = Std.string(DESIGN_W * L.scale) + "px";
		splashFrameEl.style.height = Std.string(DESIGN_H * L.scale) + "px";
	}

	function syncScoreDomLayout(w:Float, h:Float):Void {
		if (scoreDom == null)
			return;
		var L = canvasLetterbox();
		if (L == null)
			return;
		var ax = scoreHud.x + w * 0.5;
		var ay = scoreHud.y + h * 0.5;
		scoreDom.style.left = Std.string(L.ox + ax * L.scale) + "px";
		scoreDom.style.top = Std.string(L.oy + ay * L.scale) + "px";
		scoreDom.style.fontSize = Std.string(SCORE_TEXT_PT * L.scale) + "px";
	}

	function ensureHighScoreHudDom():Void {
		if (highScoreDom == null)
			return;
		var val = Browser.document.getElementById("soulBloopsHighScoreValue");
		if (val != null)
			return;
		while (highScoreDom.firstChild != null)
			highScoreDom.removeChild(highScoreDom.firstChild);
		var img:Dynamic = Browser.document.createElement("img");
		untyped {
			img.className = "soul-bloops-crown";
			img.id = "soulBloopsCrown";
			img.src = HIGH_SCORE_CROWN_PATH;
			img.alt = "";
		}
		highScoreDom.appendChild(img);
		val = Browser.document.createSpanElement();
		untyped {
			val.className = "soul-bloops-high-score-value";
			val.id = "soulBloopsHighScoreValue";
		}
		highScoreDom.appendChild(val);
	}

	function syncHighScoreDomLayout():Void {
		if (highScoreDom == null)
			return;
		var L = canvasLetterbox();
		if (L == null)
			return;
		highScoreDom.style.left = Std.string(L.ox + HIGH_SCORE_MARGIN_LEFT * L.scale) + "px";
		highScoreDom.style.top = Std.string(L.oy + HIGH_SCORE_ANCHOR_Y * L.scale) + "px";
		var fs = HIGH_SCORE_TEXT_PT * L.scale;
		highScoreDom.style.fontSize = Std.string(fs) + "px";
		var crown = Browser.document.getElementById("soulBloopsCrown");
		if (crown != null)
			untyped crown.style.height = Std.string(fs * 1.35) + "px";
	}

	function loadBestScoreFromStorage():Void {
		#if js
		try {
			untyped {
				var ls = window.localStorage;
				if (ls != null) {
					var raw = ls.getItem(LOCAL_STORAGE_BEST);
					if (raw != null && raw != "") {
						var v = Std.parseInt(raw);
						bestScore = v != null ? v : 0;
					}
				}
			}
		} catch (_:Dynamic) {
			bestScore = 0;
		}
		if (bestScore < 0)
			bestScore = 0;
		#end
	}

	function persistBestScore():Void {
		#if js
		try {
			untyped {
				var ls = window.localStorage;
				if (ls != null)
					ls.setItem(LOCAL_STORAGE_BEST, Std.string(bestScore));
			}
		} catch (_:Dynamic) {}
		#end
	}

	function maybeUpgradeBestScore():Void {
		if (score <= bestScore)
			return;
		bestScore = score;
		persistBestScore();
		updateHighScoreLabel();
		#if js
		syncHighScoreDomLayout();
		#end
	}

	function updateHighScoreLabel():Void {
		#if js
		if (highScoreValueDom != null)
			highScoreValueDom.textContent = Std.string(bestScore);
		else if (highScoreDom != null)
			highScoreDom.textContent = Std.string(bestScore);
		#else
		if (highScoreText != null)
			highScoreText.text = Std.string(bestScore);
		#end
	}

	static function rgbToCss(rgb:Int):String {
		return "#" + StringTools.hex(rgb & 0xffffff, 6);
	}
	#end

	function layoutMascot():Void {
		if (mascotBitmap == null || mascotBitmap.tile == null)
			return;
		var sz = scoreHudFrameSize();
		var mw = mascotBitmap.tile.width * mascotBitmap.scaleX;
		var mh = mascotBitmap.tile.height * mascotBitmap.scaleY;
		mascotBitmap.x = scoreHud.x + sz.w + MASCOT_GAP_FROM_SCORE;
		mascotBitmap.y = scoreHud.y + (sz.h - mh) * 0.5;
	}

	function relayoutBackground():Void {
		if (bgBitmap == null || bgBitmap.tile == null)
			return;
		var tw = bgBitmap.tile.width;
		var th = bgBitmap.tile.height;
		if (tw <= 0 || th <= 0)
			return;
		Backgrounds.layoutCover(bgBitmap, tw, th, s2d.width, s2d.height);
	}

	function positionPieceInSlot(p:Piece, slot:Int):Void {
		var cx = slotAnchor[slot].x;
		var cy = slotAnchor[slot].y;
		var bb = p.pixelBbox();
		var s = Piece.TRAY_SCALE;
		p.setRestPosition(cx - bb.w * s * 0.5, cy);
	}

	function updateScoreLabel():Void {
		var s = Std.string(Std.int(Math.round(displayScore)));
		#if js
		if (scoreDom != null)
			scoreDom.textContent = s;
		if (scoreFrame != null)
			layoutScoreHud();
		#else
		scoreText.text = s;
		if (scoreFrame != null)
			layoutScoreHud();
		#end
	}

	/** Hay piezas en el carril y ninguna puede colocarse. (Si no queda ninguna, no es game over.) */
	function checkNoMoves():Bool {
		var n = 0;
		for (i in 0...3) {
			var p = tray[i];
			if (p == null)
				continue;
			n++;
			if (grid.canPlaceShapeAnywhere(p.shape))
				return false;
		}
		return n > 0;
	}

	function evaluateGameOver():Void {
		#if js
		if (!splashFinished || titleScreenActive)
			return;
		#end
		if (gameOver || grid.interactionLocked)
			return;
		if (!checkNoMoves())
			return;
		gameOver = true;
		setTrayInputEnabled(false);
		showGameOverUI();
	}

	#if js

	function initGameOverDom():Void {
		goOverlay = Browser.document.getElementById("soulBloopsGameOver");
		if (goOverlay == null)
			return;
		goScoreEl = Browser.document.getElementById("soulBloopsGoScore");
		goReviveBtn = Browser.document.getElementById("soulBloopsGoRevive");
		goRestartBtn = Browser.document.getElementById("soulBloopsGoRestart");
		goHintEl = Browser.document.getElementById("soulBloopsGoHint");
		if (goRestartBtn != null)
			goRestartBtn.onclick = function(_ev:js.html.MouseEvent) {
				if (!goAdPending)
					restartMatch();
			};
		if (goReviveBtn != null)
			goReviveBtn.onclick = function(_ev:js.html.MouseEvent) {
				onReviveButtonClicked();
			};
	}

	function setGameOverButtonsEnabled(on:Bool):Void {
		if (goReviveBtn != null)
			(cast goReviveBtn : js.html.ButtonElement).disabled = !on;
		if (goRestartBtn != null)
			(cast goRestartBtn : js.html.ButtonElement).disabled = !on;
	}

	function hideGameOverUi():Void {
		if (gameOverRoot != null) {
			gameOverRoot.remove();
			gameOverRoot = null;
		}
		if (goOverlay != null) {
			goOverlay.classList.add("soul-bloops-go--hidden");
			goOverlay.setAttribute("aria-hidden", "true");
		}
	}

	function onReviveButtonClicked():Void {
		if (!gameOver || goAdPending || reviveUsedThisMatch)
			return;
		goAdPending = true;
		setGameOverButtonsEnabled(false);
		if (goHintEl != null) {
			goHintEl.textContent = "";
			goHintEl.classList.remove("soul-bloops-go-hint--visible");
		}
		RewardedAdBridge.show(function() {
			goAdPending = false;
			setGameOverButtonsEnabled(true);
			reviveUsedThisMatch = true;
			performReviveAfterReward();
		}, function() {
			goAdPending = false;
			setGameOverButtonsEnabled(true);
		}, function() {
			goAdPending = false;
			setGameOverButtonsEnabled(true);
			if (goHintEl != null) {
				goHintEl.textContent = "Los anuncios premiados estarán en la app para Android.";
				goHintEl.classList.add("soul-bloops-go-hint--visible");
			}
		});
	}

	function initTitleAndSettingsDom():Void {
		AudioHub.loadPersistedSettings();
		splashRootEl = Browser.document.getElementById("soulBloopsSplash");
		splashFrameEl = Browser.document.getElementById("soulBloopsSplashFrame");
		splashStudioEl = Browser.document.getElementById("soulBloopsSplashStudio");
		splashGameEl = Browser.document.getElementById("soulBloopsSplashGame");
		mainMenuEl = Browser.document.getElementById("soulBloopsMainMenu");
		settingsModalEl = Browser.document.getElementById("soulBloopsSettingsModal");
		settingsFabEl = Browser.document.getElementById("soulBloopsSettingsFab");
		volumeSliderEl = Browser.document.getElementById("soulBloopsVolumeSlider");
		muteToggleEl = Browser.document.getElementById("soulBloopsMuteToggle");
		howToModalEl = Browser.document.getElementById("soulBloopsHowToModal");
		var btnPlay = Browser.document.getElementById("soulBloopsBtnPlay");
		var btnHow = Browser.document.getElementById("soulBloopsBtnHow");
		var btnHowClose = Browser.document.getElementById("soulBloopsBtnHowClose");
		var btnReplay = Browser.document.getElementById("soulBloopsBtnReplay");
		var btnMainMenu = Browser.document.getElementById("soulBloopsBtnMainMenu");
		var btnSettingsClose = Browser.document.getElementById("soulBloopsBtnSettingsClose");
		if (splashRootEl != null)
			splashRootEl.onclick = function(_e:js.html.MouseEvent) {
				skipSplashToMenu();
			};
		if (settingsFabEl != null)
			settingsFabEl.onclick = function(_e:js.html.MouseEvent) {
				openSettingsModal();
			};
		if (btnPlay != null)
			btnPlay.onclick = function(_e:js.html.MouseEvent) {
				startGameFromTitleMenu();
			};
		if (btnHow != null)
			btnHow.onclick = function(_e:js.html.MouseEvent) {
				openHowToModal();
			};
		if (btnHowClose != null)
			btnHowClose.onclick = function(_e:js.html.MouseEvent) {
				closeHowToModal();
			};
		if (btnReplay != null)
			btnReplay.onclick = function(_e:js.html.MouseEvent) {
				restartMatchFromSettings();
			};
		if (btnMainMenu != null)
			btnMainMenu.onclick = function(_e:js.html.MouseEvent) {
				returnToMainMenuFromSettings();
			};
		if (btnSettingsClose != null)
			btnSettingsClose.onclick = function(_e:js.html.MouseEvent) {
				closeSettingsModal();
			};
		if (settingsModalEl != null)
			settingsModalEl.onclick = function(ev:js.html.MouseEvent) {
				if (ev.target == settingsModalEl)
					closeSettingsModal();
			};
		if (howToModalEl != null)
			howToModalEl.onclick = function(ev:js.html.MouseEvent) {
				if (ev.target == howToModalEl)
					closeHowToModal();
			};
		if (volumeSliderEl != null)
			volumeSliderEl.oninput = function(_e:js.html.Event) {
				var inp:InputElement = cast volumeSliderEl;
				var pv = Std.parseInt(inp.value);
				var v = pv != null ? pv : 100;
				if (v < 0)
					v = 0;
				if (v > 100)
					v = 100;
				AudioHub.setMasterVolume(v / 100.);
				syncAudioControlsFromHub();
			};
		if (muteToggleEl != null)
			muteToggleEl.onchange = function(_e:js.html.Event) {
				var ch:InputElement = cast muteToggleEl;
				AudioHub.setMuted(ch.checked);
				syncAudioControlsFromHub();
			};
		syncAudioControlsFromHub();
		startSplashSequence();
	}

	function skipSplashToMenu():Void {
		if (splashFinished)
			return;
		finishSplash();
	}

	/** Anula temporizadores del splash y lo oculta (p. ej. ajustes durante la intro). */
	function forceHideSplashKillTimers():Void {
		splashGen++;
		if (splashRootEl != null) {
			splashRootEl.classList.add("soul-bloops-splash--hidden");
			splashRootEl.setAttribute("aria-hidden", "true");
		}
	}

	function finishSplash():Void {
		if (splashFinished)
			return;
		splashFinished = true;
		splashGen++;
		if (splashRootEl != null) {
			splashRootEl.classList.add("soul-bloops-splash--hidden");
			splashRootEl.setAttribute("aria-hidden", "true");
		}
		if (mainMenuEl != null) {
			mainMenuEl.classList.remove("soul-bloops-main-menu--hidden");
			mainMenuEl.setAttribute("aria-hidden", "false");
		}
		updatePlayHudDomVisibility();
		layoutScoreHud();
	}

	function startSplashSequence():Void {
		splashFinished = false;
		if (splashRootEl == null || splashFrameEl == null) {
			finishSplash();
			return;
		}
		splashGen++;
		var g = splashGen;
		splashRootEl.classList.remove("soul-bloops-splash--hidden");
		splashRootEl.setAttribute("aria-hidden", "false");
		if (splashStudioEl != null)
			splashStudioEl.classList.remove("soul-bloops-splash-img--hidden");
		if (splashGameEl != null)
			splashGameEl.classList.add("soul-bloops-splash-img--hidden");
		haxe.Timer.delay(function() {
			if (g != splashGen)
				return;
			if (splashGameEl != null)
				splashGameEl.classList.remove("soul-bloops-splash-img--hidden");
			if (splashStudioEl != null)
				splashStudioEl.classList.add("soul-bloops-splash-img--hidden");
			haxe.Timer.delay(function() {
				if (g != splashGen)
					return;
				finishSplash();
			}, SPLASH_STEP_MS);
		}, SPLASH_STEP_MS);
		layoutScoreHud();
	}

	function returnToMainMenuFromSettings():Void {
		forceHideSplashKillTimers();
		splashFinished = true;
		gameOver = false;
		reviveUsedThisMatch = false;
		titleScreenActive = true;
		hideGameOverUi();
		closeSettingsModal();
		closeHowToModal();
		for (i in 0...3)
			if (tray[i] != null) {
				tray[i].remove();
				tray[i] = null;
			}
		score = 0;
		clearStreak = 0;
		displayScore = 0.;
		scoreDomRgb = SCORE_COLOR_NORMAL;
		if (scoreDom != null)
			scoreDom.style.color = rgbToCss(SCORE_COLOR_NORMAL);
		updateScoreLabel();
		grid.seedBlockBlastRandom();
		nextBlockId = BloopSprites.loadedPairCount() > 0 ? 1 : (grid.maxOccupiedId() + 1);
		layoutBoard();
		setTrayInputEnabled(false);
		if (mainMenuEl != null) {
			mainMenuEl.classList.remove("soul-bloops-main-menu--hidden");
			mainMenuEl.setAttribute("aria-hidden", "false");
		}
		updatePlayHudDomVisibility();
	}

	function syncAudioControlsFromHub():Void {
		if (volumeSliderEl != null) {
			var sl:InputElement = cast volumeSliderEl;
			sl.value = Std.string(Math.round(AudioHub.masterVolume * 100.));
		}
		if (muteToggleEl != null) {
			var mt:InputElement = cast muteToggleEl;
			mt.checked = AudioHub.muted;
		}
	}

	function openSettingsModal():Void {
		if (settingsModalEl == null)
			return;
		syncAudioControlsFromHub();
		settingsModalEl.classList.remove("soul-bloops-modal--hidden");
		settingsModalEl.setAttribute("aria-hidden", "false");
	}

	function closeSettingsModal():Void {
		if (settingsModalEl == null)
			return;
		settingsModalEl.classList.add("soul-bloops-modal--hidden");
		settingsModalEl.setAttribute("aria-hidden", "true");
	}

	function openHowToModal():Void {
		if (howToModalEl == null)
			return;
		howToModalEl.classList.remove("soul-bloops-modal--hidden");
		howToModalEl.setAttribute("aria-hidden", "false");
	}

	function closeHowToModal():Void {
		if (howToModalEl == null)
			return;
		howToModalEl.classList.add("soul-bloops-modal--hidden");
		howToModalEl.setAttribute("aria-hidden", "true");
	}

	function hideMainMenuEl():Void {
		if (mainMenuEl == null)
			return;
		mainMenuEl.classList.add("soul-bloops-main-menu--hidden");
		mainMenuEl.setAttribute("aria-hidden", "true");
	}

	function startGameFromTitleMenu():Void {
		titleScreenActive = false;
		hideMainMenuEl();
		closeSettingsModal();
		closeHowToModal();
		dealNewTray();
		setTrayInputEnabled(true);
		updatePlayHudDomVisibility();
		layoutScoreHud();
	}

	function restartMatchFromSettings():Void {
		forceHideSplashKillTimers();
		splashFinished = true;
		gameOver = false;
		reviveUsedThisMatch = false;
		titleScreenActive = false;
		hideGameOverUi();
		hideMainMenuEl();
		closeSettingsModal();
		closeHowToModal();
		performFullGameRestart();
	}

	#end

	/** Sigue la partida: mismo tablero y puntuación, nuevo trío colocable. */
	function performReviveAfterReward():Void {
		if (!gameOver)
			return;
		gameOver = false;
		#if js
		hideGameOverUi();
		#else
		if (gameOverRoot != null) {
			gameOverRoot.remove();
			gameOverRoot = null;
		}
		#end
		setTrayInputEnabled(true);
		for (i in 0...3)
			if (tray[i] != null) {
				tray[i].remove();
				tray[i] = null;
			}
		var triple = ShapeCatalog.randomResolvableTriple(grid);
		for (i in 0...3)
			spawnSlot(i, triple[i], true);
		ensureCurrentTrayPlayable();
		evaluateGameOver();
	}

	function setTrayInputEnabled(on:Bool):Void {
		for (p in tray)
			if (p != null)
				p.setInputEnabled(on);
	}

	function ensureCurrentTrayPlayable():Void {
		for (_ in 0...8) {
			if (!checkNoMoves())
				return;
			var triple = ShapeCatalog.randomResolvableTriple(grid);
			for (i in 0...3) {
				if (tray[i] != null) {
					tray[i].remove();
					tray[i] = null;
				}
				spawnSlot(i, triple[i], true);
			}
		}
	}

	function showGameOverUI():Void {
		if (gameOverRoot != null) {
			gameOverRoot.remove();
			gameOverRoot = null;
		}
		#if js
		if (goOverlay != null) {
			if (goScoreEl != null)
				goScoreEl.textContent = Std.string(score);
			if (goReviveBtn != null) {
				if (reviveUsedThisMatch)
					goReviveBtn.style.display = "none";
				else
					goReviveBtn.style.removeProperty("display");
			}
			if (goHintEl != null) {
				goHintEl.textContent = "";
				goHintEl.classList.remove("soul-bloops-go-hint--visible");
			}
			goAdPending = false;
			setGameOverButtonsEnabled(true);
			goOverlay.classList.remove("soul-bloops-go--hidden");
			goOverlay.setAttribute("aria-hidden", "false");
			return;
		}
		#end
		showGameOverHeaps();
	}

	/** Fallback si no hay DOM (p. ej. canvas embebido sin `index.html`). */
	function showGameOverHeaps():Void {
		var w = s2d.width;
		var h = s2d.height;
		gameOverRoot = new h2d.Object(s2d);

		var dim = new Bitmap(Tile.fromColor(0x000000, Std.int(w), Std.int(h), 0.72), gameOverRoot);

		var blocker = new Interactive(w, h, gameOverRoot);
		blocker.cursor = hxd.Cursor.Button;
		blocker.onPush = function(_e) restartMatch();

		var titleFont = GameFonts.getUi();
		var title = new Text(titleFont, gameOverRoot);
		title.text = "Sin movimientos";
		title.textColor = 0xf0e8ff;
		title.textAlign = Center;
		title.scale(1.15);
		var sub = new Text(titleFont, gameOverRoot);
		sub.text = "Puntuación: " + score + "\n\nToca para jugar de nuevo";
		sub.textColor = 0xc8b8ff;
		sub.textAlign = Center;
		sub.scale(0.72);
		sub.maxWidth = w * 0.88;

		var titleH = title.textHeight * title.scaleY;
		var gap = 22.;
		var blockH = titleH + gap + sub.textHeight * sub.scaleY;
		var top = (h - blockH) * 0.5 - 24.;
		title.x = w * 0.5;
		title.y = top;
		sub.x = w * 0.5;
		sub.y = top + titleH + gap;
	}

	function performFullGameRestart():Void {
		for (i in 0...3) {
			if (tray[i] != null) {
				tray[i].remove();
				tray[i] = null;
			}
		}
		score = 0;
		clearStreak = 0;
		displayScore = 0.;
		#if js
		scoreDomRgb = SCORE_COLOR_NORMAL;
		if (scoreDom != null)
			scoreDom.style.color = rgbToCss(SCORE_COLOR_NORMAL);
		#else
		scoreText.textColor = SCORE_COLOR_NORMAL;
		#end
		updateScoreLabel();
		grid.seedBlockBlastRandom();
		nextBlockId = BloopSprites.loadedPairCount() > 0 ? 1 : (grid.maxOccupiedId() + 1);
		layoutBoard();
		haxe.Timer.delay(dealNewTray, 0);
		setTrayInputEnabled(true);
	}

	function restartMatch():Void {
		if (!gameOver)
			return;
		gameOver = false;
		reviveUsedThisMatch = false;
		#if js
		hideGameOverUi();
		#else
		if (gameOverRoot != null) {
			gameOverRoot.remove();
			gameOverRoot = null;
		}
		#end
		performFullGameRestart();
	}

	function dealNewTray():Void {
		var triple = ShapeCatalog.randomResolvableTriple(grid);
		for (i in 0...3)
			spawnSlot(i, triple[i], true);
		ensureCurrentTrayPlayable();
		evaluateGameOver();
	}

	function spawnSlot(slot:Int, shape:Array<{x:Int, y:Int}>, skipGameOverCheck:Bool = false):Void {
		var rgb = ShapeCatalog.randomNeonRGB();
		var p:Piece;
		if (BloopSprites.loadedPairCount() > 0) {
			var pick = BloopSprites.pickColorAndDistinctVariants(shape.length);
			if (pick != null)
				p = new Piece(cellTile, grid, shape, rgb.r, rgb.g, rgb.b, 0, s2d, pick.colorIdx, pick.variants);
			else {
				var fill = nextBlockId;
				nextBlockId = (nextBlockId % 240) + 1;
				p = new Piece(cellTile, grid, shape, rgb.r, rgb.g, rgb.b, fill, s2d);
			}
		} else {
			var fill = nextBlockId;
			nextBlockId = (nextBlockId % 240) + 1;
			p = new Piece(cellTile, grid, shape, rgb.r, rgb.g, rgb.b, fill, s2d);
		}
		p.traySlot = slot;

		var sIndex = slot;
		p.onPlacementResolved = function(lc, rr, cc) resolvePlacement(sIndex, lc, rr, cc);

		positionPieceInSlot(p, slot);
		tray[slot] = p;
		if (!skipGameOverCheck)
			evaluateGameOver();
	}

	function resolvePlacement(slot:Int, lineCount:Int, rowDone:Array<Bool>, colDone:Array<Bool>):Void {
		tray[slot] = null;
		if (lineCount == 0) {
			clearStreak = 0;
			feel.syncGridRestPos();
			AudioHub.playPlace();
			Haptics.lightPlace();
			afterPieceResolved(0);
		} else {
			var nextStreak = clearStreak + 1;
			grid.interactionLocked = true;
			AudioHub.playClear(lineCount);
			Haptics.clearLines(lineCount);
			feel.syncGridRestPos();
			feel.playLineClear(rowDone, colDone, lineCount, nextStreak, function() {
				grid.applyLineClearMask(rowDone, colDone);
				grid.rebuildVisual();
				grid.interactionLocked = false;
				clearStreak = nextStreak;
				var mult = comboMultiplierForStreak(nextStreak);
				var basePts = lineCount * Grid.POINTS_PER_LINE;
				var pts = Std.int(basePts * mult);
				score += pts;
				var extra = 0;
				if (grid.countFilledCells() == 0) {
					extra = GRID_CLEAR_BASE_BONUS + nextStreak * GRID_CLEAR_STREAK_BONUS;
					score += extra;
					AudioHub.playBoardClear();
					Haptics.clearLines(3);
					feel.playBoardClearCelebration(extra);
				}
				afterPieceResolved(pts + extra);
			});
		}
	}

	static function comboMultiplierForStreak(streak:Int):Float {
		if (streak <= 1)
			return 1.;
		return Math.min(COMBO_MULT_MAX, 1. + COMBO_MULT_STEP * (streak - 1));
	}

	function afterPieceResolved(_lastPts:Int):Void {
		var turnDone = tray[0] == null && tray[1] == null && tray[2] == null;
		if (turnDone)
			dealNewTray();
		else
			evaluateGameOver();
	}

	override function onResize() {
		super.onResize();
		layoutBoard();
		for (i in 0...3) {
			var p = tray[i];
			if (p != null)
				positionPieceInSlot(p, i);
		}
		if (gameOver)
			showGameOverUI();
	}

	override function loadAssets(onLoaded:Void->Void) {
		#if js
		BloopSprites.preloadAll(onLoaded);
		#else
		onLoaded();
		#end
	}

	static function main() {
		new Main();
	}
}
