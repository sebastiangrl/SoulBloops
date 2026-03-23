package game;

#if js
import js.Browser;
#end

/**
	Puente para **anuncio premiado** (p. ej. AdMob en WebView / Google Play).
	El host asigna `window.soulBloopsRewardedAd` antes de cargar el juego. Ver `docs/ADS_ANDROID.md`.
**/
class RewardedAdBridge {

	#if js

	public static function isConfigured():Bool {
		var ad:Dynamic = Reflect.field(Browser.window, "soulBloopsRewardedAd");
		if (ad == null)
			return false;
		var show = Reflect.field(ad, "show");
		return Reflect.isFunction(show);
	}

	static function isLocalDevHost():Bool {
		try {
			var h:String = Browser.location.hostname;
			return h == "localhost" || h == "127.0.0.1" || h == "" || h == null;
		} catch (_:Dynamic) {
			return false;
		}
	}

	/**
		`onReward` — el usuario completó el anuncio y debe recibir la recompensa.
		`onDismiss` — cerró el anuncio sin recompensa (o canceló).
		`onFail` — no hay inventario / error (mostrar mensaje en UI).
	**/
	public static function show(?onReward:Void->Void, ?onDismiss:Void->Void, ?onFail:Void->Void):Void {
		if (isConfigured()) {
			var ad:Dynamic = Reflect.field(Browser.window, "soulBloopsRewardedAd");
			var opts:Dynamic = {
				onRewarded: function() {
					if (onReward != null)
						onReward();
				},
				onDismissed: function() {
					if (onDismiss != null)
						onDismiss();
				},
				onFailed: function(_msg:Dynamic) {
					if (onFail != null)
						onFail();
					else if (onDismiss != null)
						onDismiss();
				},
			};
			Reflect.callMethod(ad, Reflect.field(ad, "show"), [opts]);
			return;
		}
		if (isLocalDevHost()) {
			haxe.Timer.delay(function() {
				if (onReward != null)
					onReward();
			}, 450);
			return;
		}
		if (onFail != null)
			onFail();
		else if (onDismiss != null)
			onDismiss();
	}

	#else

	public static function isConfigured():Bool {
		return false;
	}

	public static function show(?onReward:Void->Void, ?onDismiss:Void->Void, ?onFail:Void->Void):Void {
		if (onFail != null)
			onFail();
	}

	#end
}
