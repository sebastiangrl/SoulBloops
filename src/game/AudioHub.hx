package game;

#if js
import js.Browser;
#end

/**
	SFX ligeros: Web Audio en JS; stub en otros targets (añade OGG + hxd.Res después si quieres).
	Volumen maestro y silencio: `masterVolume` 0…1, `muted`.
**/
class AudioHub {

	static var ctx:Dynamic = null;

	/** 0…1 aplicado a todas las ganancias (persistido en JS). */
	public static var masterVolume:Float = 1.;
	public static var muted:Bool = false;

	#if js

	public static function loadPersistedSettings():Void {
		try {
			var sv = Browser.window.localStorage.getItem("soulBloops_masterVolume");
			if (sv != null) {
				var v = Std.parseFloat(sv);
				if (!Math.isNaN(v))
					masterVolume = Math.max(0., Math.min(1., v));
			}
			muted = Browser.window.localStorage.getItem("soulBloops_muted") == "1";
		} catch (_:Dynamic) {}
	}

	public static function persistSettings():Void {
		try {
			Browser.window.localStorage.setItem("soulBloops_masterVolume", Std.string(masterVolume));
			Browser.window.localStorage.setItem("soulBloops_muted", muted ? "1" : "0");
		} catch (_:Dynamic) {}
	}

	#end

	public static function setMasterVolume(v:Float):Void {
		masterVolume = Math.max(0., Math.min(1., v));
		#if js
		persistSettings();
		#end
	}

	public static function setMuted(m:Bool):Void {
		muted = m;
		#if js
		persistSettings();
		#end
	}

	static inline function effectiveGain(base:Float):Float {
		if (muted)
			return 0.;
		return base * masterVolume;
	}

	static function ensureCtx():Void {
		#if js
		if (ctx != null)
			return;
		untyped {
			var AC = window.AudioContext != null ? window.AudioContext : window.webkitAudioContext;
			if (AC != null)
				ctx = js.Syntax.construct(AC, []);
		}
		#end
	}

	public static function playPlace():Void {
		beep(240, 0.035, 0.12);
	}

	public static function playClear(lineCount:Int):Void {
		var f = lineCount >= 2 ? 520. : 360.;
		beep(f, 0.07, 0.18);
	}

	public static function playBoardClear():Void {
		#if js
		beep(380., 0.05, 0.11);
		haxe.Timer.delay(function() beep(520., 0.06, 0.12), 45);
		haxe.Timer.delay(function() beep(660., 0.08, 0.14), 95);
		#end
	}

	public static function playDeny():Void {
		beep(110, 0.055, 0.2);
	}

	static function beep(freqHz:Float, durSec:Float, gain:Float):Void {
		#if js
		ensureCtx();
		if (ctx == null)
			return;
		untyped {
			var o = ctx.createOscillator();
			var g = ctx.createGain();
			o.type = "sine";
			o.frequency.value = freqHz;
			var gEff = effectiveGain(gain);
			g.gain.value = gEff;
			o.connect(g);
			g.connect(ctx.destination);
			var t0 = ctx.currentTime;
			g.gain.setValueAtTime(0.0001, t0);
			g.gain.exponentialRampToValueAtTime(Math.max(0.0001, gEff), t0 + 0.008);
			g.gain.exponentialRampToValueAtTime(0.0001, t0 + durSec);
			o.start(t0);
			o.stop(t0 + durSec + 0.02);
		}
		#end
	}
}
