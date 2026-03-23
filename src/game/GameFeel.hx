package game;

import h2d.Bitmap;
import h2d.Graphics;
import h2d.Object;
import h2d.Text;
import h2d.Text.Align;
import h2d.Tile;
import game.GameFonts;
import game.I18n;

/**
	Partículas, flash y shake en clears. Requiere `step(dt)` desde `Main.update`.
**/
class GameFeel {

	static inline var CELL = Grid.CELL_SIZE;
	static inline var CLEAR_DURATION = 0.36;

	var scene:h2d.Object;
	var grid:Grid;
	var fxHost:Object;

	public var gridRestX:Float = 0.;
	public var gridRestY:Float = 0.;

	var shakeTime:Float = 0.;
	var shakeStrength:Float = 0.;

	var clearRun:Null<{
		elapsed:Float,
		onDone:Void->Void,
		flash:Graphics
	}>;

	var bits:Array<{b:Bitmap, vx:Float, vy:Float, life:Float, av:Float}>;
	var comboFloats:Array<{t:Text, age:Float, maxAge:Float}>;

	public function new(sceneParent:h2d.Object, targetGrid:Grid) {
		scene = sceneParent;
		grid = targetGrid;
		fxHost = new Object(targetGrid);
		bits = [];
		comboFloats = [];
	}

	public function playLineClear(rowDone:Array<Bool>, colDone:Array<Bool>, lineCount:Int, clearStreak:Int, onComplete:Void->Void):Void {
		syncGridRestPos();
		shakeTime = 0.26;
		shakeStrength = lineCount >= 2 ? 5.5 : 3.2;

		spawnClearFeedbackFloat(lineCount, clearStreak);

		var flash = new Graphics(fxHost);
		flash.blendMode = Add;
		for (y in 0...Grid.SIZE) {
			for (x in 0...Grid.SIZE) {
				if (rowDone[y] || colDone[x]) {
					var id = grid.getCell(x, y);
					if (id != 0) {
						var c = Grid.tintRgbFromBlockId(id);
						flash.beginFill(c, 0.42);
						flash.drawRect(x * CELL, y * CELL, CELL, CELL);
						flash.endFill();
					}
				}
			}
		}

		spawnParticlesForMask(rowDone, colDone);

		clearRun = {elapsed: 0., onDone: onComplete, flash: flash};
	}

	/** Tras un clear: racha = veces seguidas que el jugador ha completado al menos una línea. */
	function spawnClearFeedbackFloat(lineCount:Int, clearStreak:Int):Void {
		var msg:Null<String> = null;
		var scale = 2.45;
		if (clearStreak >= 2)
			msg = I18n.tf("feel.comboStreak", [Std.string(clearStreak)]);
		else if (lineCount >= 4) {
			msg = I18n.t("feel.brutal");
			scale = 2.75;
		} else if (lineCount >= 3) {
			msg = I18n.t("feel.great");
			scale = 2.65;
		} else if (lineCount >= 2)
			msg = I18n.tf("feel.linesMult", [Std.string(lineCount)]);
		if (msg == null)
			return;
		var t = new Text(GameFonts.getUi(), scene);
		t.textAlign = Center;
		t.text = msg;
		t.textColor = clearStreak >= 3 ? 0xffc4ff : 0xffe8a0;
		t.scale(scale);
		var cx = grid.x + gw() * 0.5;
		var cy = grid.y + gh() * 0.26;
		t.x = cx;
		t.y = cy;
		comboFloats.push({t: t, age: 0., maxAge: 0.92});
	}

	/** Bonificación por dejar el tablero sin bloques (tras el clear). */
	public function playBoardClearCelebration(bonusPts:Int):Void {
		syncGridRestPos();
		shakeTime = Math.max(shakeTime, 0.34);
		shakeStrength = Math.max(shakeStrength, 6.8);
		var gold = 0xffee88;
		for (k in 0...52) {
			var tile = Tile.fromColor(0xFFFFFFFF, 9, 9);
			var b = new Bitmap(tile, fxHost);
			b.x = grid.x + Math.random() * gw();
			b.y = grid.y + Math.random() * gh();
			var ang = Math.random() * 6.28318;
			var sp = 95 + Math.random() * 200;
			bits.push({
				b: b,
				vx: Math.cos(ang) * sp * 0.45,
				vy: -Math.abs(Math.sin(ang)) * sp - 55,
				life: 0.45 + Math.random() * 0.35,
				av: (Math.random() - 0.5) * 14
			});
		}
		var t = new Text(GameFonts.getUi(), scene);
		t.textAlign = Center;
		t.text = I18n.tf("feel.boardClear", [Std.string(bonusPts)]);
		t.textColor = gold;
		t.scale(2.35);
		t.x = grid.x + gw() * 0.5;
		t.y = grid.y + gh() * 0.38;
		comboFloats.push({t: t, age: 0., maxAge: 1.55});
	}

	function spawnParticlesForMask(rowDone:Array<Bool>, colDone:Array<Bool>):Void {
		for (y in 0...Grid.SIZE) {
			for (x in 0...Grid.SIZE) {
				if (!(rowDone[y] || colDone[x]))
					continue;
				var id = grid.getCell(x, y);
				if (id == 0)
					continue;
				var col = Grid.tintRgbFromBlockId(id);
				for (k in 0...4) {
					var tile = Tile.fromColor(0xFF000000 | col, 10, 10);
					var b = new Bitmap(tile, fxHost);
					b.x = x * CELL + CELL * 0.5 - 5;
					b.y = y * CELL + CELL * 0.5 - 5;
					var ang = Math.random() * 6.28318;
					var sp = 80 + Math.random() * 160;
					bits.push({
						b: b,
						vx: Math.cos(ang) * sp * 0.35,
						vy: -Math.abs(Math.sin(ang)) * sp - 40,
						life: 0.32 + Math.random() * 0.2,
						av: (Math.random() - 0.5) * 12
					});
				}
			}
		}
	}

	inline function gw():Float {
		return Grid.SIZE * CELL;
	}

	inline function gh():Float {
		return gw();
	}

	public function syncGridRestPos():Void {
		gridRestX = grid.x;
		gridRestY = grid.y;
	}

	public function step(dt:Float):Void {
		if (shakeTime > 0) {
			shakeTime -= dt;
			var m = shakeStrength * (shakeTime > 0 ? (shakeTime / 0.26) : 0);
			grid.x = gridRestX + (Math.random() * 2 - 1) * m;
			grid.y = gridRestY + (Math.random() * 2 - 1) * m;
			if (shakeTime <= 0) {
				grid.x = gridRestX;
				grid.y = gridRestY;
			}
		}

		if (clearRun != null) {
			var cr = clearRun;
			cr.elapsed += dt;
			if (cr.flash != null)
				cr.flash.alpha = Math.max(0., 1. - cr.elapsed / (CLEAR_DURATION * 0.65));

			var i = 0;
			while (i < bits.length) {
				var p = bits[i];
				p.life -= dt;
				p.b.x += p.vx * dt;
				p.b.y += p.vy * dt;
				p.vy += 420 * dt;
				p.b.rotation += p.av * dt;
				p.b.alpha = Math.max(0., p.life / 0.25);
				if (p.life <= 0) {
					p.b.remove();
					bits.splice(i, 1);
				} else
					i++;
			}

			var j = 0;
			while (j < comboFloats.length) {
				var c = comboFloats[j];
				c.age += dt;
				c.t.y -= 55 * dt;
				var ma = c.maxAge > 0 ? c.maxAge : 0.92;
				c.t.alpha = Math.max(0., 1. - c.age / ma);
				if (c.age > ma) {
					c.t.remove();
					comboFloats.splice(j, 1);
				} else
					j++;
			}

			if (cr.elapsed >= CLEAR_DURATION) {
				if (cr.flash != null) {
					cr.flash.remove();
					cr.flash = null;
				}
				var done = cr.onDone;
				clearRun = null;
				for (b in bits) {
					b.b.remove();
				}
				bits.resize(0);
				done();
			}
		} else {
			var k = 0;
			while (k < bits.length) {
				var p = bits[k];
				p.life -= dt;
				p.b.x += p.vx * dt;
				p.b.y += p.vy * dt;
				p.vy += 420 * dt;
				p.b.alpha = Math.max(0., p.life / 0.25);
				if (p.life <= 0) {
					p.b.remove();
					bits.splice(k, 1);
				} else
					k++;
			}
			var m = 0;
			while (m < comboFloats.length) {
				var c = comboFloats[m];
				c.age += dt;
				c.t.y -= 55 * dt;
				var ma = c.maxAge > 0 ? c.maxAge : 0.92;
				c.t.alpha = Math.max(0., 1. - c.age / ma);
				if (c.age > ma) {
					c.t.remove();
					comboFloats.splice(m, 1);
				} else
					m++;
			}
		}
	}
}
