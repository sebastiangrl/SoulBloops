package game;

/**
	Vibración corta: JS (`navigator.vibrate`) o Android hxcpp (JNI + SDL; ver `native/android/README.md`).
**/
class Haptics {

	public static function lightPlace():Void {
		#if js
		untyped {
			if (navigator.vibrate != null)
				navigator.vibrate(10);
		}
		#elseif (android && cpp)
		AndroidHapticsNative.place();
		#end
	}

	public static function clearLines(lineCount:Int):Void {
		#if js
		untyped {
			if (navigator.vibrate != null) {
				if (lineCount >= 2)
					navigator.vibrate([15, 35, 20, 40, 25]);
				else
					navigator.vibrate(22);
			}
		}
		#elseif (android && cpp)
		if (lineCount >= 2)
			AndroidHapticsNative.clearCombo();
		else
			AndroidHapticsNative.clearSingle();
		#end
	}
}

#if (android && cpp)

@:keep
@:buildXml('
<files id="haxe">
	<file name="native/android/hxcpp_android_haptics.cpp" />
</files>
')
private class __LinkAndroidHapticsCpp {}

private class AndroidHapticsNative {
	public static inline function place():Void {
		untyped __cpp__("::hxcpp_android_haptics_place()");
	}

	public static inline function clearSingle():Void {
		untyped __cpp__("::hxcpp_android_haptics_clear_single()");
	}

	public static inline function clearCombo():Void {
		untyped __cpp__("::hxcpp_android_haptics_clear_combo()");
	}
}

#end
